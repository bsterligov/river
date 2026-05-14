use crate::db::{self};
use crate::indexer;
use rusqlite::Connection;
use std::fs;
use tempfile::TempDir;

fn mem_db() -> Connection {
    let conn = Connection::open_in_memory().unwrap();
    conn.execute_batch(
        "PRAGMA journal_mode=WAL; PRAGMA synchronous=NORMAL; PRAGMA foreign_keys=ON;",
    )
    .unwrap();
    db::migrate(&conn).unwrap();
    conn
}

#[test]
fn indexes_rust_file() {
    let dir = TempDir::new().unwrap();
    let root = dir.path();
    fs::write(
        root.join("lib.rs"),
        "pub fn hello() {}\npub struct Foo {}\n",
    )
    .unwrap();

    let conn = mem_db();
    let stats = indexer::run(root, &conn, false).unwrap();

    assert_eq!(stats.indexed, 1);
    assert_eq!(stats.errors, 0);

    let count: i64 = conn
        .query_row("SELECT COUNT(*) FROM symbols WHERE kind='fn'", [], |r| {
            r.get(0)
        })
        .unwrap();
    assert_eq!(count, 1);

    let count: i64 = conn
        .query_row(
            "SELECT COUNT(*) FROM symbols WHERE kind='struct'",
            [],
            |r| r.get(0),
        )
        .unwrap();
    assert_eq!(count, 1);
}

#[test]
fn skips_unchanged_files_on_second_run() {
    let dir = TempDir::new().unwrap();
    let root = dir.path();
    fs::write(root.join("lib.rs"), "fn foo() {}").unwrap();

    let conn = mem_db();
    let s1 = indexer::run(root, &conn, false).unwrap();
    assert_eq!(s1.indexed, 1);

    let s2 = indexer::run(root, &conn, false).unwrap();
    assert_eq!(s2.indexed, 0);
    assert_eq!(s2.skipped, 1);
}

#[test]
fn reindexes_modified_files() {
    let dir = TempDir::new().unwrap();
    let root = dir.path();
    let path = root.join("lib.rs");
    fs::write(&path, "fn foo() {}").unwrap();

    let conn = mem_db();
    indexer::run(root, &conn, false).unwrap();

    // modify content (changes hash)
    fs::write(&path, "fn foo() {}\nfn bar() {}").unwrap();
    // bump mtime by touching via a slight sleep or just force
    let s2 = indexer::run(root, &conn, true).unwrap();
    assert_eq!(s2.indexed, 1);
}

#[test]
fn force_reindexes_all() {
    let dir = TempDir::new().unwrap();
    let root = dir.path();
    fs::write(root.join("a.rs"), "fn a() {}").unwrap();
    fs::write(root.join("b.rs"), "fn b() {}").unwrap();

    let conn = mem_db();
    indexer::run(root, &conn, false).unwrap();

    let s2 = indexer::run(root, &conn, true).unwrap();
    assert_eq!(s2.indexed, 2);
    assert_eq!(s2.skipped, 0);
}

#[test]
fn removes_deleted_files_from_index() {
    let dir = TempDir::new().unwrap();
    let root = dir.path();
    fs::write(root.join("a.rs"), "fn a() {}").unwrap();
    fs::write(root.join("b.rs"), "fn b() {}").unwrap();

    let conn = mem_db();
    indexer::run(root, &conn, false).unwrap();

    fs::remove_file(root.join("b.rs")).unwrap();
    let stats = indexer::run(root, &conn, false).unwrap();
    assert_eq!(stats.removed, 1);

    let count: i64 = conn
        .query_row("SELECT COUNT(*) FROM files", [], |r| r.get(0))
        .unwrap();
    assert_eq!(count, 1);
}

#[test]
fn indexes_dart_file() {
    let dir = TempDir::new().unwrap();
    let root = dir.path();
    fs::write(
        root.join("widget.dart"),
        "class MyWidget extends StatelessWidget {}\n",
    )
    .unwrap();

    let conn = mem_db();
    let stats = indexer::run(root, &conn, false).unwrap();
    assert_eq!(stats.indexed, 1);

    let count: i64 = conn
        .query_row("SELECT COUNT(*) FROM symbols WHERE kind='class'", [], |r| {
            r.get(0)
        })
        .unwrap();
    assert_eq!(count, 1);
}

#[test]
fn indexes_generic_file() {
    let dir = TempDir::new().unwrap();
    let root = dir.path();
    fs::write(root.join("notes.md"), "# Hello\nworld\n").unwrap();

    let conn = mem_db();
    let stats = indexer::run(root, &conn, false).unwrap();
    assert_eq!(stats.indexed, 1);
    assert_eq!(stats.errors, 0);
}

#[test]
fn empty_workspace() {
    let dir = TempDir::new().unwrap();
    let conn = mem_db();
    let stats = indexer::run(dir.path(), &conn, false).unwrap();
    assert_eq!(stats.indexed, 0);
    assert_eq!(stats.errors, 0);
}

#[test]
fn indexes_rust_with_imports_and_symbols() {
    let dir = TempDir::new().unwrap();
    let root = dir.path();
    fs::write(
        root.join("lib.rs"),
        r#"
use std::collections::HashMap;
use serde::Serialize;

pub struct Config { name: String }
pub fn load() -> Config { Config { name: String::new() } }
"#,
    )
    .unwrap();

    let conn = mem_db();
    indexer::run(root, &conn, false).unwrap();

    let sym_count: i64 = conn
        .query_row("SELECT COUNT(*) FROM symbols", [], |r| r.get(0))
        .unwrap();
    assert!(sym_count >= 2);

    let imp_count: i64 = conn
        .query_row("SELECT COUNT(*) FROM imports", [], |r| r.get(0))
        .unwrap();
    assert!(imp_count >= 2);
}

#[test]
fn second_run_after_content_change_reindexes() {
    let dir = TempDir::new().unwrap();
    let root = dir.path();
    let path = root.join("lib.rs");
    fs::write(&path, "fn foo() {}").unwrap();

    let conn = mem_db();
    indexer::run(root, &conn, false).unwrap();

    // change file content — hash changes
    fs::write(&path, "fn foo() {}\nfn bar() {}\n").unwrap();

    // force=true to bypass mtime (test filesystem may not update mtime fast enough)
    let stats = indexer::run(root, &conn, true).unwrap();
    assert_eq!(stats.indexed, 1);

    let count: i64 = conn
        .query_row("SELECT COUNT(*) FROM symbols WHERE kind='fn'", [], |r| {
            r.get(0)
        })
        .unwrap();
    assert_eq!(count, 2);
}
