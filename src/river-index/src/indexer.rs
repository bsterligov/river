use crate::db;
use crate::parser;
use crate::walker::{self, Language};
use anyhow::Result;
use rusqlite::Connection;
use std::path::Path;
use std::time::{SystemTime, UNIX_EPOCH};

pub struct IndexStats {
    pub indexed: usize,
    pub skipped: usize,
    pub removed: usize,
    pub errors: usize,
}

pub fn run(root: &Path, conn: &Connection, force: bool) -> Result<IndexStats> {
    let now = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .unwrap_or_default()
        .as_secs() as i64;

    let entries = walker::walk(root)?;
    let mut stats = IndexStats {
        indexed: 0,
        skipped: 0,
        removed: 0,
        errors: 0,
    };

    let known_paths: Vec<String> = entries.iter().map(|e| e.rel_path.clone()).collect();

    for entry in &entries {
        let needs = if force {
            true
        } else {
            match db::file_needs_reindex(conn, &entry.rel_path, entry.mtime, &entry.hash) {
                Ok(v) => v,
                Err(e) => {
                    eprintln!("check {}: {e}", entry.rel_path);
                    stats.errors += 1;
                    continue;
                }
            }
        };

        if !needs {
            stats.skipped += 1;
            continue;
        }

        let src = match std::fs::read_to_string(&entry.path) {
            Ok(s) => s,
            Err(e) => {
                eprintln!("read {}: {e}", entry.rel_path);
                stats.errors += 1;
                continue;
            }
        };

        let parsed = match entry.lang {
            Language::Rust => parser::parse_rust(&src),
            Language::Dart => parser::parse_dart(&src),
            _ => parser::parse_generic(&src),
        };

        let file_id = match db::upsert_file(
            conn,
            &db::FileRecord {
                path: &entry.rel_path,
                lang: entry.lang.as_str(),
                size_bytes: entry.size_bytes,
                mtime: entry.mtime,
                hash: &entry.hash,
                lines: parsed.lines,
                indexed_at: now,
            },
        ) {
            Ok(id) => id,
            Err(e) => {
                eprintln!("upsert {}: {e}", entry.rel_path);
                stats.errors += 1;
                continue;
            }
        };

        if let Err(e) = db::delete_file_children(conn, file_id) {
            eprintln!("delete children {}: {e}", entry.rel_path);
        }

        for sym in &parsed.symbols {
            if let Err(e) = db::insert_symbol(
                conn,
                file_id,
                &sym.name,
                &sym.kind,
                sym.line,
                sym.col,
                sym.signature.as_deref(),
            ) {
                eprintln!("insert symbol {}: {e}", sym.name);
            }
        }

        for imp in &parsed.imports {
            if let Err(e) = db::insert_import(conn, file_id, imp) {
                eprintln!("insert import {}: {e}", imp);
            }
        }

        if let Err(e) = db::insert_content(conn, file_id, &entry.rel_path, &src) {
            eprintln!("insert content {}: {e}", entry.rel_path);
        }

        stats.indexed += 1;
    }

    stats.removed = db::remove_deleted_files(conn, &known_paths)?;

    Ok(stats)
}
