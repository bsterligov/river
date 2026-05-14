use anyhow::Result;
use rusqlite::{params, Connection};
use serde::Serialize;

#[derive(Serialize)]
pub struct FileSummary {
    pub path: String,
    pub lang: String,
    pub lines: i64,
    pub size_bytes: i64,
    pub symbols: Vec<SymbolRef>,
    pub imports: Vec<String>,
}

#[derive(Serialize)]
pub struct SymbolRef {
    pub name: String,
    pub kind: String,
    pub line: i64,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub signature: Option<String>,
}

#[derive(Serialize)]
pub struct SymbolHit {
    pub name: String,
    pub kind: String,
    pub file: String,
    pub line: i64,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub signature: Option<String>,
}

#[derive(Serialize)]
pub struct SearchHit {
    pub path: String,
    pub lang: String,
    pub rank: f64,
}

#[derive(Serialize)]
pub struct DepEntry {
    pub file: String,
    pub imports: Vec<String>,
}

#[derive(Serialize)]
pub struct StatusReport {
    pub total_files: i64,
    pub total_symbols: i64,
    pub total_imports: i64,
    pub last_indexed: Option<String>,
    pub by_lang: Vec<LangStat>,
}

#[derive(Serialize)]
pub struct LangStat {
    pub lang: String,
    pub files: i64,
    pub lines: i64,
}

impl FileSummary {
    pub fn to_compact(&self) -> String {
        let mut out = format!("{} {} {}L\n", self.path, self.lang, self.lines);

        // Group symbols by kind
        let kinds = [
            "struct", "enum", "trait", "type", "const", "class", "mixin", "typedef", "mod", "impl",
            "fn",
        ];
        for kind in kinds {
            let names: Vec<&str> = self
                .symbols
                .iter()
                .filter(|s| s.kind == kind)
                .map(|s| s.name.as_str())
                .collect();
            if !names.is_empty() {
                out.push_str(&format!("{}s: {}\n", kind, names.join(" ")));
            }
        }

        if !self.imports.is_empty() {
            out.push_str(&format!("deps: {}\n", self.imports.join(" ")));
        }

        out
    }
}

pub fn file_summary(conn: &Connection, path: &str) -> Result<FileSummary> {
    let (file_id, lang, lines, size_bytes): (i64, String, i64, i64) = conn.query_row(
        "SELECT id, lang, lines, size_bytes FROM files WHERE path = ?1",
        params![path],
        |r| Ok((r.get(0)?, r.get(1)?, r.get(2)?, r.get(3)?)),
    )?;

    let mut stmt = conn.prepare(
        "SELECT name, kind, line, signature FROM symbols WHERE file_id = ?1 ORDER BY line",
    )?;
    let symbols: Vec<SymbolRef> = stmt
        .query_map(params![file_id], |r| {
            Ok(SymbolRef {
                name: r.get(0)?,
                kind: r.get(1)?,
                line: r.get(2)?,
                signature: r.get(3)?,
            })
        })?
        .filter_map(|r| r.ok())
        .collect();

    // Only top-level crate/package names (no :: paths), deduplicated
    let mut stmt = conn.prepare(
        "SELECT DISTINCT import FROM imports WHERE file_id = ?1 AND import NOT LIKE '%::%' ORDER BY import"
    )?;
    let imports: Vec<String> = stmt
        .query_map(params![file_id], |r| r.get(0))?
        .filter_map(|r| r.ok())
        .collect();

    Ok(FileSummary {
        path: path.to_string(),
        lang,
        lines,
        size_bytes,
        symbols,
        imports,
    })
}

pub fn symbols(conn: &Connection, name: &str) -> Result<Vec<SymbolHit>> {
    let pattern = format!("%{}%", name);
    let mut stmt = conn.prepare(
        "SELECT s.name, s.kind, f.path, s.line, s.signature
         FROM symbols s JOIN files f ON f.id = s.file_id
         WHERE s.name LIKE ?1
         ORDER BY f.path, s.line
         LIMIT 200",
    )?;
    let hits: Vec<SymbolHit> = stmt
        .query_map(params![pattern], |r| {
            Ok(SymbolHit {
                name: r.get(0)?,
                kind: r.get(1)?,
                file: r.get(2)?,
                line: r.get(3)?,
                signature: r.get(4)?,
            })
        })?
        .filter_map(|r| r.ok())
        .collect();
    Ok(hits)
}

pub fn search(conn: &Connection, term: &str, limit: usize) -> Result<Vec<SearchHit>> {
    let mut stmt = conn.prepare(
        "SELECT c.path, f.lang, bm25(content) as rank
         FROM content c
         LEFT JOIN files f ON f.path = c.path
         WHERE content MATCH ?1
         ORDER BY rank
         LIMIT ?2",
    )?;
    let hits: Vec<SearchHit> = stmt
        .query_map(params![term, limit as i64], |r| {
            Ok(SearchHit {
                path: r.get(0)?,
                lang: r.get::<_, Option<String>>(1)?.unwrap_or_default(),
                rank: r.get(2)?,
            })
        })?
        .filter_map(|r| r.ok())
        .collect();
    Ok(hits)
}

pub fn deps(conn: &Connection, path: &str) -> Result<Vec<DepEntry>> {
    // Files that import the given path fragment, or the file's own imports
    let mut stmt = conn.prepare(
        "SELECT f.path, i.import
         FROM imports i JOIN files f ON f.id = i.file_id
         WHERE f.path = ?1 OR i.import LIKE ?2
         ORDER BY f.path, i.import",
    )?;
    let pattern = format!("%{}%", path);
    let rows: Vec<(String, String)> = stmt
        .query_map(params![path, pattern], |r| Ok((r.get(0)?, r.get(1)?)))?
        .filter_map(|r| r.ok())
        .collect();

    let mut map: std::collections::BTreeMap<String, Vec<String>> = Default::default();
    for (file, imp) in rows {
        map.entry(file).or_default().push(imp);
    }
    Ok(map
        .into_iter()
        .map(|(file, imports)| DepEntry { file, imports })
        .collect())
}

pub fn status(conn: &Connection) -> Result<StatusReport> {
    let total_files: i64 = conn.query_row("SELECT COUNT(*) FROM files", [], |r| r.get(0))?;
    let total_symbols: i64 = conn.query_row("SELECT COUNT(*) FROM symbols", [], |r| r.get(0))?;
    let total_imports: i64 = conn.query_row("SELECT COUNT(*) FROM imports", [], |r| r.get(0))?;

    let last_indexed: Option<String> = conn
        .query_row(
            "SELECT datetime(MAX(indexed_at), 'unixepoch') FROM files",
            [],
            |r| r.get(0),
        )
        .ok();

    let mut stmt = conn.prepare(
        "SELECT lang, COUNT(*) as files, SUM(lines) as lines FROM files GROUP BY lang ORDER BY files DESC"
    )?;
    let by_lang: Vec<LangStat> = stmt
        .query_map([], |r| {
            Ok(LangStat {
                lang: r.get(0)?,
                files: r.get(1)?,
                lines: r.get::<_, Option<i64>>(2)?.unwrap_or(0),
            })
        })?
        .filter_map(|r| r.ok())
        .collect();

    Ok(StatusReport {
        total_files,
        total_symbols,
        total_imports,
        last_indexed,
        by_lang,
    })
}
