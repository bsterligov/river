use crate::walker::Language;
use std::path::Path;

#[test]
fn language_from_rust_extension() {
    assert_eq!(
        Language::from_path(Path::new("foo.rs")),
        Some(Language::Rust)
    );
}

#[test]
fn language_from_dart_extension() {
    assert_eq!(
        Language::from_path(Path::new("foo.dart")),
        Some(Language::Dart)
    );
}

#[test]
fn language_from_toml_extension() {
    assert_eq!(
        Language::from_path(Path::new("Cargo.toml")),
        Some(Language::Toml)
    );
}

#[test]
fn language_from_yaml_extensions() {
    assert_eq!(
        Language::from_path(Path::new("config.yaml")),
        Some(Language::Yaml)
    );
    assert_eq!(
        Language::from_path(Path::new("config.yml")),
        Some(Language::Yaml)
    );
}

#[test]
fn language_from_json_extension() {
    assert_eq!(
        Language::from_path(Path::new("package.json")),
        Some(Language::Json)
    );
}

#[test]
fn language_from_markdown_extension() {
    assert_eq!(
        Language::from_path(Path::new("README.md")),
        Some(Language::Markdown)
    );
}

#[test]
fn language_from_unknown_extension() {
    let lang = Language::from_path(Path::new("foo.xyz"));
    assert!(matches!(lang, Some(Language::Other(ref s)) if s == "xyz"));
}

#[test]
fn language_from_no_extension_is_none() {
    assert_eq!(Language::from_path(Path::new("Makefile")), None);
}

#[test]
fn language_as_str() {
    assert_eq!(Language::Rust.as_str(), "rust");
    assert_eq!(Language::Dart.as_str(), "dart");
    assert_eq!(Language::Toml.as_str(), "toml");
    assert_eq!(Language::Yaml.as_str(), "yaml");
    assert_eq!(Language::Json.as_str(), "json");
    assert_eq!(Language::Markdown.as_str(), "markdown");
    assert_eq!(Language::Other("swift".into()).as_str(), "swift");
}

#[test]
fn walk_finds_files_and_skips_binaries() {
    use crate::walker::walk;
    use std::fs;
    use tempfile::TempDir;

    let dir = TempDir::new().unwrap();
    let root = dir.path();

    fs::write(root.join("main.rs"), "fn main() {}").unwrap();
    fs::write(root.join("config.toml"), "[package]").unwrap();
    fs::write(root.join("icon.png"), &[0u8; 10]).unwrap();

    let entries = walk(root).unwrap();
    let names: Vec<&str> = entries
        .iter()
        .map(|e| {
            std::path::Path::new(&e.rel_path)
                .file_name()
                .unwrap()
                .to_str()
                .unwrap()
        })
        .collect();

    assert!(names.contains(&"main.rs"));
    assert!(names.contains(&"config.toml"));
    assert!(!names.contains(&"icon.png"), "binary should be excluded");
}

#[test]
fn walk_skips_target_directory() {
    use crate::walker::walk;
    use std::fs;
    use tempfile::TempDir;

    let dir = TempDir::new().unwrap();
    let root = dir.path();

    fs::create_dir(root.join("target")).unwrap();
    fs::write(root.join("target").join("build.rs"), "fn main() {}").unwrap();
    fs::write(root.join("lib.rs"), "pub fn foo() {}").unwrap();

    let entries = walk(root).unwrap();
    assert!(entries.iter().all(|e| !e.rel_path.starts_with("target")));
    assert!(entries.iter().any(|e| e.rel_path == "lib.rs"));
}

#[test]
fn walk_skips_river_index_directory() {
    use crate::walker::walk;
    use std::fs;
    use tempfile::TempDir;

    let dir = TempDir::new().unwrap();
    let root = dir.path();

    fs::create_dir(root.join(".river-index")).unwrap();
    fs::write(root.join(".river-index").join("index.db"), &[0u8; 4]).unwrap();
    fs::write(root.join("src.rs"), "fn x() {}").unwrap();

    let entries = walk(root).unwrap();
    assert!(entries
        .iter()
        .all(|e| !e.rel_path.starts_with(".river-index")));
}

#[test]
fn walk_skips_large_files() {
    use crate::walker::walk;
    use std::fs;
    use tempfile::TempDir;

    let dir = TempDir::new().unwrap();
    let root = dir.path();

    // 3MB — over the 2MB limit
    fs::write(root.join("big.rs"), vec![b'x'; 3 * 1024 * 1024]).unwrap();
    fs::write(root.join("small.rs"), b"fn x() {}".as_slice()).unwrap();

    let entries = walk(root).unwrap();
    assert!(entries.iter().all(|e| e.rel_path != "big.rs"));
    assert!(entries.iter().any(|e| e.rel_path == "small.rs"));
}

#[test]
fn walk_entry_has_correct_metadata() {
    use crate::walker::walk;
    use std::fs;
    use tempfile::TempDir;

    let dir = TempDir::new().unwrap();
    let root = dir.path();
    let content = "fn main() {}";
    fs::write(root.join("main.rs"), content).unwrap();

    let entries = walk(root).unwrap();
    let entry = entries.iter().find(|e| e.rel_path == "main.rs").unwrap();

    assert_eq!(entry.lang, Language::Rust);
    assert_eq!(entry.size_bytes, content.len() as u64);
    assert!(!entry.hash.is_empty());
    assert!(entry.mtime > 0);
}
