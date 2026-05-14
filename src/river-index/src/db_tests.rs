use crate::db::{self, FileRecord};
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

fn sample_record(path: &str) -> FileRecord {
    FileRecord {
        path,
        lang: "rust",
        size_bytes: 100,
        mtime: 1_000_000,
        hash: "abc123",
        lines: 10,
        indexed_at: 2_000_000,
    }
}

#[test]
fn migrate_is_idempotent() {
    let conn = mem_db();
    db::migrate(&conn).unwrap();
    db::migrate(&conn).unwrap();
}

#[test]
fn upsert_file_inserts_and_returns_id() {
    let conn = mem_db();
    let id = db::upsert_file(&conn, &sample_record("src/foo.rs")).unwrap();
    assert!(id > 0);
}

#[test]
fn upsert_file_updates_on_conflict() {
    let conn = mem_db();
    let id1 = db::upsert_file(&conn, &sample_record("src/foo.rs")).unwrap();
    let id2 = db::upsert_file(
        &conn,
        &FileRecord {
            path: "src/foo.rs",
            lang: "rust",
            size_bytes: 200,
            mtime: 1_000_001,
            hash: "def456",
            lines: 20,
            indexed_at: 3_000_000,
        },
    )
    .unwrap();
    assert_eq!(id1, id2);
    let lines: i64 = conn
        .query_row("SELECT lines FROM files WHERE path='src/foo.rs'", [], |r| {
            r.get(0)
        })
        .unwrap();
    assert_eq!(lines, 20);
}

#[test]
fn file_needs_reindex_new_file() {
    let conn = mem_db();
    assert!(db::file_needs_reindex(&conn, "src/new.rs", 1000, "hash1").unwrap());
}

#[test]
fn file_needs_reindex_unchanged() {
    let conn = mem_db();
    db::upsert_file(&conn, &sample_record("src/foo.rs")).unwrap();
    assert!(!db::file_needs_reindex(&conn, "src/foo.rs", 1_000_000, "abc123").unwrap());
}

#[test]
fn file_needs_reindex_changed_mtime() {
    let conn = mem_db();
    db::upsert_file(&conn, &sample_record("src/foo.rs")).unwrap();
    assert!(db::file_needs_reindex(&conn, "src/foo.rs", 9_999_999, "abc123").unwrap());
}

#[test]
fn file_needs_reindex_changed_hash() {
    let conn = mem_db();
    db::upsert_file(&conn, &sample_record("src/foo.rs")).unwrap();
    assert!(db::file_needs_reindex(&conn, "src/foo.rs", 1_000_000, "newhash").unwrap());
}

#[test]
fn insert_and_delete_symbols() {
    let conn = mem_db();
    let id = db::upsert_file(&conn, &sample_record("src/foo.rs")).unwrap();
    db::insert_symbol(&conn, id, "main", "fn", 1, 0, Some("fn main()")).unwrap();
    db::insert_symbol(&conn, id, "Foo", "struct", 5, 0, None).unwrap();
    let count: i64 = conn
        .query_row("SELECT COUNT(*) FROM symbols WHERE file_id=?1", [id], |r| {
            r.get(0)
        })
        .unwrap();
    assert_eq!(count, 2);

    db::delete_file_children(&conn, id).unwrap();
    let count: i64 = conn
        .query_row("SELECT COUNT(*) FROM symbols WHERE file_id=?1", [id], |r| {
            r.get(0)
        })
        .unwrap();
    assert_eq!(count, 0);
}

#[test]
fn insert_and_delete_imports() {
    let conn = mem_db();
    let id = db::upsert_file(&conn, &sample_record("src/foo.rs")).unwrap();
    db::insert_import(&conn, id, "std").unwrap();
    db::insert_import(&conn, id, "serde").unwrap();

    db::delete_file_children(&conn, id).unwrap();
    let count: i64 = conn
        .query_row("SELECT COUNT(*) FROM imports WHERE file_id=?1", [id], |r| {
            r.get(0)
        })
        .unwrap();
    assert_eq!(count, 0);
}

#[test]
fn insert_and_delete_content() {
    let conn = mem_db();
    let id = db::upsert_file(&conn, &sample_record("src/foo.rs")).unwrap();
    db::insert_content(&conn, id, "src/foo.rs", "fn main() {}").unwrap();

    let map_count: i64 = conn
        .query_row(
            "SELECT COUNT(*) FROM content_map WHERE file_id=?1",
            [id],
            |r| r.get(0),
        )
        .unwrap();
    assert_eq!(map_count, 1);

    db::delete_file_children(&conn, id).unwrap();
    let map_count: i64 = conn
        .query_row(
            "SELECT COUNT(*) FROM content_map WHERE file_id=?1",
            [id],
            |r| r.get(0),
        )
        .unwrap();
    assert_eq!(map_count, 0);
}

#[test]
fn remove_deleted_files_cleans_up() {
    let conn = mem_db();
    db::upsert_file(&conn, &sample_record("src/a.rs")).unwrap();
    db::upsert_file(&conn, &sample_record("src/b.rs")).unwrap();
    db::upsert_file(&conn, &sample_record("src/c.rs")).unwrap();

    let removed = db::remove_deleted_files(&conn, &["src/a.rs".to_string()]).unwrap();
    assert_eq!(removed, 2);

    let count: i64 = conn
        .query_row("SELECT COUNT(*) FROM files", [], |r| r.get(0))
        .unwrap();
    assert_eq!(count, 1);
}

#[test]
fn remove_deleted_files_empty_list() {
    let conn = mem_db();
    db::upsert_file(&conn, &sample_record("src/a.rs")).unwrap();
    let removed = db::remove_deleted_files(&conn, &[]).unwrap();
    assert_eq!(removed, 0);
}

#[test]
fn delete_file_children_no_content_is_safe() {
    let conn = mem_db();
    let id = db::upsert_file(&conn, &sample_record("src/foo.rs")).unwrap();
    // no content inserted — should not error
    db::delete_file_children(&conn, id).unwrap();
}
