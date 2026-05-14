use anyhow::Result;
use rusqlite::{params, Connection};
use std::path::Path;

pub fn open(db_path: &Path) -> Result<Connection> {
    let conn = Connection::open(db_path)?;
    conn.execute_batch(
        "PRAGMA journal_mode=WAL; PRAGMA synchronous=NORMAL; PRAGMA foreign_keys=ON;",
    )?;
    Ok(conn)
}

pub fn migrate(conn: &Connection) -> Result<()> {
    conn.execute_batch(
        "
        CREATE TABLE IF NOT EXISTS files (
            id          INTEGER PRIMARY KEY,
            path        TEXT NOT NULL UNIQUE,
            lang        TEXT NOT NULL,
            size_bytes  INTEGER NOT NULL,
            mtime       INTEGER NOT NULL,
            hash        TEXT NOT NULL,
            lines       INTEGER NOT NULL,
            indexed_at  INTEGER NOT NULL
        );

        CREATE TABLE IF NOT EXISTS symbols (
            id        INTEGER PRIMARY KEY,
            file_id   INTEGER NOT NULL REFERENCES files(id) ON DELETE CASCADE,
            name      TEXT NOT NULL,
            kind      TEXT NOT NULL,
            line      INTEGER NOT NULL,
            col       INTEGER NOT NULL,
            signature TEXT
        );

        CREATE INDEX IF NOT EXISTS idx_symbols_name ON symbols(name);
        CREATE INDEX IF NOT EXISTS idx_symbols_file ON symbols(file_id);

        CREATE TABLE IF NOT EXISTS imports (
            id       INTEGER PRIMARY KEY,
            file_id  INTEGER NOT NULL REFERENCES files(id) ON DELETE CASCADE,
            import   TEXT NOT NULL
        );

        CREATE INDEX IF NOT EXISTS idx_imports_file ON imports(file_id);
        CREATE INDEX IF NOT EXISTS idx_imports_import ON imports(import);

        CREATE VIRTUAL TABLE IF NOT EXISTS content USING fts5(
            path,
            body,
            tokenize='porter unicode61'
        );

        CREATE TABLE IF NOT EXISTS content_map (
            file_id  INTEGER PRIMARY KEY REFERENCES files(id) ON DELETE CASCADE,
            rowid    INTEGER NOT NULL
        );
    ",
    )?;
    Ok(())
}

pub fn file_needs_reindex(conn: &Connection, path: &str, mtime: i64, hash: &str) -> Result<bool> {
    let result: Option<(i64, String)> = conn
        .query_row(
            "SELECT mtime, hash FROM files WHERE path = ?1",
            params![path],
            |row| Ok((row.get(0)?, row.get(1)?)),
        )
        .optional()?;

    match result {
        None => Ok(true),
        Some((stored_mtime, stored_hash)) => Ok(stored_mtime != mtime || stored_hash != hash),
    }
}

pub struct FileRecord<'a> {
    pub path: &'a str,
    pub lang: &'a str,
    pub size_bytes: u64,
    pub mtime: i64,
    pub hash: &'a str,
    pub lines: usize,
    pub indexed_at: i64,
}

pub fn upsert_file(conn: &Connection, rec: &FileRecord<'_>) -> Result<i64> {
    conn.execute(
        "INSERT INTO files (path, lang, size_bytes, mtime, hash, lines, indexed_at)
         VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7)
         ON CONFLICT(path) DO UPDATE SET
           lang=excluded.lang, size_bytes=excluded.size_bytes, mtime=excluded.mtime,
           hash=excluded.hash, lines=excluded.lines, indexed_at=excluded.indexed_at",
        params![
            rec.path,
            rec.lang,
            rec.size_bytes as i64,
            rec.mtime,
            rec.hash,
            rec.lines as i64,
            rec.indexed_at
        ],
    )?;
    let file_id: i64 = conn.query_row(
        "SELECT id FROM files WHERE path = ?1",
        params![rec.path],
        |row| row.get(0),
    )?;
    Ok(file_id)
}

pub fn delete_file_children(conn: &Connection, file_id: i64) -> Result<()> {
    conn.execute("DELETE FROM symbols WHERE file_id = ?1", params![file_id])?;
    conn.execute("DELETE FROM imports WHERE file_id = ?1", params![file_id])?;
    // Remove from FTS
    if let Ok(rowid) = conn.query_row::<i64, _, _>(
        "SELECT rowid FROM content_map WHERE file_id = ?1",
        params![file_id],
        |r| r.get(0),
    ) {
        conn.execute("DELETE FROM content WHERE rowid = ?1", params![rowid])?;
        conn.execute(
            "DELETE FROM content_map WHERE file_id = ?1",
            params![file_id],
        )?;
    }
    Ok(())
}

pub fn insert_symbol(
    conn: &Connection,
    file_id: i64,
    name: &str,
    kind: &str,
    line: usize,
    col: usize,
    signature: Option<&str>,
) -> Result<()> {
    conn.execute(
        "INSERT INTO symbols (file_id, name, kind, line, col, signature) VALUES (?1,?2,?3,?4,?5,?6)",
        params![file_id, name, kind, line as i64, col as i64, signature],
    )?;
    Ok(())
}

pub fn insert_import(conn: &Connection, file_id: i64, import: &str) -> Result<()> {
    conn.execute(
        "INSERT INTO imports (file_id, import) VALUES (?1, ?2)",
        params![file_id, import],
    )?;
    Ok(())
}

pub fn insert_content(conn: &Connection, file_id: i64, path: &str, body: &str) -> Result<()> {
    conn.execute(
        "INSERT INTO content (path, body) VALUES (?1, ?2)",
        params![path, body],
    )?;
    let rowid = conn.last_insert_rowid();
    conn.execute(
        "INSERT OR REPLACE INTO content_map (file_id, rowid) VALUES (?1, ?2)",
        params![file_id, rowid],
    )?;
    Ok(())
}

pub fn remove_deleted_files(conn: &Connection, known_paths: &[String]) -> Result<usize> {
    if known_paths.is_empty() {
        return Ok(0);
    }
    // Build a temp table of still-present paths and delete anything not in it
    conn.execute_batch("CREATE TEMP TABLE IF NOT EXISTS _present_paths (path TEXT PRIMARY KEY);")?;
    conn.execute_batch("DELETE FROM _present_paths;")?;
    {
        let mut stmt = conn.prepare("INSERT INTO _present_paths (path) VALUES (?1)")?;
        for p in known_paths {
            stmt.execute(params![p])?;
        }
    }
    let deleted = conn.execute(
        "DELETE FROM files WHERE path NOT IN (SELECT path FROM _present_paths)",
        [],
    )?;
    conn.execute_batch("DROP TABLE _present_paths;")?;
    Ok(deleted)
}

trait OptionalExt<T> {
    fn optional(self) -> Result<Option<T>>;
}

impl<T> OptionalExt<T> for rusqlite::Result<T> {
    fn optional(self) -> Result<Option<T>> {
        match self {
            Ok(v) => Ok(Some(v)),
            Err(rusqlite::Error::QueryReturnedNoRows) => Ok(None),
            Err(e) => Err(e.into()),
        }
    }
}
