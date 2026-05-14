use crate::db::{self, FileRecord};
use crate::query;
use rusqlite::Connection;

fn mem_db() -> Connection {
    let conn = Connection::open_in_memory().unwrap();
    conn.execute_batch(
        "PRAGMA journal_mode=WAL; PRAGMA synchronous=NORMAL; PRAGMA foreign_keys=ON;",
    )
    .unwrap();
    db::migrate(&conn).unwrap();
    conn
}

fn insert_file(conn: &Connection, path: &str, lang: &str) -> i64 {
    db::upsert_file(
        conn,
        &FileRecord {
            path,
            lang,
            size_bytes: 100,
            mtime: 1000,
            hash: "h",
            lines: 10,
            indexed_at: 2000,
        },
    )
    .unwrap()
}

#[test]
fn file_summary_returns_symbols_and_imports() {
    let conn = mem_db();
    let id = insert_file(&conn, "src/main.rs", "rust");
    db::insert_symbol(&conn, id, "main", "fn", 1, 0, Some("fn main()")).unwrap();
    db::insert_symbol(&conn, id, "Foo", "struct", 5, 0, None).unwrap();
    db::insert_import(&conn, id, "std").unwrap();
    db::insert_import(&conn, id, "serde").unwrap();

    let summary = query::file_summary(&conn, "src/main.rs").unwrap();
    assert_eq!(summary.path, "src/main.rs");
    assert_eq!(summary.lang, "rust");
    assert_eq!(summary.lines, 10);
    assert_eq!(summary.symbols.len(), 2);
    assert_eq!(summary.imports.len(), 2);
}

#[test]
fn file_summary_excludes_path_imports() {
    let conn = mem_db();
    let id = insert_file(&conn, "src/main.rs", "rust");
    db::insert_import(&conn, id, "std").unwrap();
    db::insert_import(&conn, id, "std::collections::HashMap").unwrap();

    let summary = query::file_summary(&conn, "src/main.rs").unwrap();
    assert!(summary.imports.contains(&"std".to_string()));
    assert!(!summary.imports.iter().any(|i| i.contains("::")));
}

#[test]
fn file_summary_not_found_errors() {
    let conn = mem_db();
    assert!(query::file_summary(&conn, "nonexistent.rs").is_err());
}

#[test]
fn symbols_finds_by_name() {
    let conn = mem_db();
    let id = insert_file(&conn, "src/main.rs", "rust");
    db::insert_symbol(&conn, id, "get_logs", "fn", 10, 0, None).unwrap();
    db::insert_symbol(&conn, id, "get_traces", "fn", 20, 0, None).unwrap();
    db::insert_symbol(&conn, id, "Foo", "struct", 1, 0, None).unwrap();

    let hits = query::symbols(&conn, "get").unwrap();
    assert_eq!(hits.len(), 2);
    assert!(hits.iter().all(|h| h.name.contains("get")));
}

#[test]
fn symbols_exact_match() {
    let conn = mem_db();
    let id = insert_file(&conn, "src/main.rs", "rust");
    db::insert_symbol(&conn, id, "main", "fn", 1, 0, None).unwrap();

    let hits = query::symbols(&conn, "main").unwrap();
    assert_eq!(hits.len(), 1);
    assert_eq!(hits[0].name, "main");
    assert_eq!(hits[0].file, "src/main.rs");
}

#[test]
fn symbols_no_match_returns_empty() {
    let conn = mem_db();
    let hits = query::symbols(&conn, "nonexistent").unwrap();
    assert!(hits.is_empty());
}

#[test]
fn search_finds_content() {
    let conn = mem_db();
    let id = insert_file(&conn, "src/main.rs", "rust");
    db::insert_content(&conn, id, "src/main.rs", "fn get_logs() -> Vec<LogRow> {}").unwrap();

    let hits = query::search(&conn, "get_logs", 10).unwrap();
    assert!(!hits.is_empty());
    assert_eq!(hits[0].path, "src/main.rs");
}

#[test]
fn search_no_match_returns_empty() {
    let conn = mem_db();
    let hits = query::search(&conn, "xyzzy_not_found", 10).unwrap();
    assert!(hits.is_empty());
}

#[test]
fn deps_returns_file_imports() {
    let conn = mem_db();
    let id = insert_file(&conn, "src/main.rs", "rust");
    db::insert_import(&conn, id, "axum").unwrap();
    db::insert_import(&conn, id, "serde").unwrap();

    let deps = query::deps(&conn, "src/main.rs").unwrap();
    assert!(!deps.is_empty());
    let entry = deps.iter().find(|d| d.file == "src/main.rs").unwrap();
    assert!(entry.imports.contains(&"axum".to_string()));
}

#[test]
fn deps_finds_files_by_import_name() {
    let conn = mem_db();
    let id = insert_file(&conn, "src/a.rs", "rust");
    db::insert_import(&conn, id, "river_config").unwrap();

    let deps = query::deps(&conn, "river_config").unwrap();
    assert!(deps.iter().any(|d| d.file == "src/a.rs"));
}

#[test]
fn status_reports_correct_counts() {
    let conn = mem_db();
    let id1 = insert_file(&conn, "src/a.rs", "rust");
    let id2 = insert_file(&conn, "src/b.dart", "dart");
    db::insert_symbol(&conn, id1, "foo", "fn", 1, 0, None).unwrap();
    db::insert_symbol(&conn, id1, "Bar", "struct", 2, 0, None).unwrap();
    db::insert_import(&conn, id2, "flutter").unwrap();

    let s = query::status(&conn).unwrap();
    assert_eq!(s.total_files, 2);
    assert_eq!(s.total_symbols, 2);
    assert_eq!(s.total_imports, 1);
    assert!(s.last_indexed.is_some());
    assert_eq!(s.by_lang.len(), 2);
}

#[test]
fn status_empty_db() {
    let conn = mem_db();
    let s = query::status(&conn).unwrap();
    assert_eq!(s.total_files, 0);
    assert_eq!(s.total_symbols, 0);
    assert_eq!(s.total_imports, 0);
    assert!(s.by_lang.is_empty());
}

#[test]
fn file_summary_to_compact_format() {
    let conn = mem_db();
    let id = insert_file(&conn, "src/main.rs", "rust");
    db::insert_symbol(&conn, id, "main", "fn", 1, 0, Some("fn main()")).unwrap();
    db::insert_symbol(&conn, id, "Foo", "struct", 5, 0, None).unwrap();
    db::insert_import(&conn, id, "std").unwrap();

    let summary = query::file_summary(&conn, "src/main.rs").unwrap();
    let compact = summary.to_compact();

    assert!(compact.contains("src/main.rs"));
    assert!(compact.contains("rust"));
    assert!(compact.contains("10L"));
    assert!(compact.contains("fns:"));
    assert!(compact.contains("structs:"));
    assert!(compact.contains("deps:"));
    assert!(compact.contains("std"));
}

#[test]
fn file_summary_to_compact_no_symbols() {
    let conn = mem_db();
    insert_file(&conn, "src/empty.rs", "rust");

    let summary = query::file_summary(&conn, "src/empty.rs").unwrap();
    let compact = summary.to_compact();
    assert!(compact.contains("src/empty.rs"));
    assert!(!compact.contains("fns:"));
    assert!(!compact.contains("deps:"));
}
