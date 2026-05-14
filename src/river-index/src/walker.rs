use anyhow::Result;
use sha2::{Digest, Sha256};
use std::path::{Path, PathBuf};
use std::time::UNIX_EPOCH;

#[derive(Debug)]
pub struct FileEntry {
    pub path: PathBuf,
    pub rel_path: String,
    pub lang: Language,
    pub size_bytes: u64,
    pub mtime: i64,
    pub hash: String,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum Language {
    Rust,
    Dart,
    Toml,
    Yaml,
    Json,
    Markdown,
    Other(String),
}

impl Language {
    pub fn from_path(path: &Path) -> Option<Self> {
        let ext = path.extension()?.to_str()?;
        Some(match ext {
            "rs" => Language::Rust,
            "dart" => Language::Dart,
            "toml" => Language::Toml,
            "yaml" | "yml" => Language::Yaml,
            "json" => Language::Json,
            "md" => Language::Markdown,
            other => Language::Other(other.to_string()),
        })
    }

    pub fn as_str(&self) -> &str {
        match self {
            Language::Rust => "rust",
            Language::Dart => "dart",
            Language::Toml => "toml",
            Language::Yaml => "yaml",
            Language::Json => "json",
            Language::Markdown => "markdown",
            Language::Other(s) => s.as_str(),
        }
    }
}

static IGNORE_DIRS: &[&str] = &[
    "target",
    ".git",
    "node_modules",
    ".dart_tool",
    ".pub-cache",
    "build",
    ".flutter-plugins",
    ".flutter-plugins-dependencies",
    ".river-index",
];

static IGNORE_FILES: &[&str] = &["Cargo.lock", "pubspec.lock", "lcov.info"];

static BINARY_EXTENSIONS: &[&str] = &[
    "png", "jpg", "jpeg", "gif", "ico", "svg", "woff", "woff2", "ttf", "otf", "pdf", "zip", "gz",
    "tar", "bin", "exe", "so", "dylib", "a", "lib", "db", "db-wal", "db-shm", "pb", "proto",
];

pub fn walk(root: &Path) -> Result<Vec<FileEntry>> {
    let mut entries = Vec::new();

    for result in ignore::WalkBuilder::new(root)
        .hidden(false)
        .git_ignore(true)
        .git_global(false)
        .filter_entry(|e| {
            let name = e.file_name().to_string_lossy();
            if e.file_type().map(|t| t.is_dir()).unwrap_or(false) {
                return !IGNORE_DIRS.iter().any(|d| name == *d);
            }
            !IGNORE_FILES.iter().any(|f| name == *f)
        })
        .build()
    {
        let entry = match result {
            Ok(e) => e,
            Err(_) => continue,
        };

        if !entry.file_type().map(|t| t.is_file()).unwrap_or(false) {
            continue;
        }

        let path = entry.path().to_path_buf();
        let lang = match Language::from_path(&path) {
            Some(l) => l,
            None => continue,
        };

        if let Some(ext) = path.extension().and_then(|e| e.to_str()) {
            if BINARY_EXTENSIONS.contains(&ext) {
                continue;
            }
        }

        let meta = match std::fs::metadata(&path) {
            Ok(m) => m,
            Err(_) => continue,
        };

        let size_bytes = meta.len();
        if size_bytes > 2 * 1024 * 1024 {
            continue;
        }

        let mtime = meta
            .modified()
            .ok()
            .and_then(|t| t.duration_since(UNIX_EPOCH).ok())
            .map(|d| d.as_secs() as i64)
            .unwrap_or(0);

        let rel_path = path
            .strip_prefix(root)
            .unwrap_or(&path)
            .to_string_lossy()
            .to_string();

        let hash = hash_file(&path)?;

        entries.push(FileEntry {
            path,
            rel_path,
            lang,
            size_bytes,
            mtime,
            hash,
        });
    }

    Ok(entries)
}

fn hash_file(path: &Path) -> Result<String> {
    let bytes = std::fs::read(path)?;
    let mut hasher = Sha256::new();
    hasher.update(&bytes);
    Ok(hex::encode(hasher.finalize()))
}
