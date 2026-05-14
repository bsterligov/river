mod db;
mod indexer;
mod parser;
mod query;
mod walker;

#[cfg(test)]
mod db_tests;
#[cfg(test)]
mod indexer_tests;
#[cfg(test)]
mod parser_tests;
#[cfg(test)]
mod query_tests;
#[cfg(test)]
mod walker_tests;

use anyhow::{Context, Result};
use clap::{Parser, Subcommand};
use std::path::PathBuf;
use std::process;

#[derive(Parser)]
#[command(name = "river-index", about = "Workspace code index for Claude Code")]
struct Cli {
    /// Path to the SQLite database
    #[arg(long, default_value = ".river-index/index.db")]
    db: PathBuf,

    /// Workspace root (defaults to current directory)
    #[arg(long)]
    root: Option<PathBuf>,

    #[command(subcommand)]
    cmd: Cmd,
}

#[derive(Subcommand)]
enum Cmd {
    /// Index or reindex the workspace
    Index {
        /// Force reindex of all files regardless of mtime/hash
        #[arg(long)]
        force: bool,
    },
    /// Show a compact JSON summary of a file (symbols + imports)
    File { path: String },
    /// Find symbol definitions by name (supports % wildcard)
    Symbols { name: String },
    /// Full-text search across all indexed files
    Search {
        term: String,
        #[arg(long, default_value = "20")]
        limit: usize,
    },
    /// Show dependency graph for a file or module name
    Deps { path: String },
    /// Show index statistics
    Status,
    /// Pre-tool-use hook: reads Claude Code JSON from stdin, returns summary or passes through
    Hook,
    /// Post-tool-use hook: triggers incremental reindex after git commits
    PostCommitHook,
}

fn main() -> Result<()> {
    let cli = Cli::parse();

    let root = match cli.root.or_else(|| std::env::current_dir().ok()) {
        Some(p) => p,
        None => anyhow::bail!("could not determine working directory"),
    };

    if let Some(parent) = cli.db.parent() {
        if !parent.as_os_str().is_empty() {
            std::fs::create_dir_all(parent)
                .with_context(|| format!("create db dir {:?}", parent))?;
        }
    }

    let conn = db::open(&cli.db)?;
    db::migrate(&conn)?;

    match cli.cmd {
        Cmd::Index { force } => {
            let stats = indexer::run(&root, &conn, force)?;
            eprintln!(
                "indexed={} skipped={} removed={} errors={}",
                stats.indexed, stats.skipped, stats.removed, stats.errors
            );
        }
        Cmd::File { path } => {
            let summary = query::file_summary(&conn, &path)
                .with_context(|| format!("file not found in index: {path}"))?;
            print!("{}", summary.to_compact());
        }
        Cmd::Symbols { name } => {
            let hits = query::symbols(&conn, &name)?;
            println!("{}", serde_json::to_string_pretty(&hits)?);
        }
        Cmd::Search { term, limit } => {
            let hits = query::search(&conn, &term, limit)?;
            println!("{}", serde_json::to_string_pretty(&hits)?);
        }
        Cmd::Deps { path } => {
            let deps = query::deps(&conn, &path)?;
            println!("{}", serde_json::to_string_pretty(&deps)?);
        }
        Cmd::Status => {
            let s = query::status(&conn)?;
            println!("{}", serde_json::to_string_pretty(&s)?);
        }
        Cmd::Hook => {
            run_hook(&root, &cli.db)?;
        }
        Cmd::PostCommitHook => {
            run_post_commit_hook(&root, &cli.db)?;
        }
    }

    Ok(())
}

static PASSTHROUGH_EXTS: &[&str] = &[
    "md",
    "txt",
    "yaml",
    "yml",
    "toml",
    "json",
    "sql",
    "sh",
    "lock",
    "xcconfig",
    "plist",
    "entitlements",
    "pbxproj",
    "xib",
    "xcscheme",
    "xcworkspacedata",
    "slnx",
    "csproj",
    "cs",
    "swift",
];

fn run_hook(root: &std::path::Path, db_path: &std::path::Path) -> Result<()> {
    use std::io::{IsTerminal, Read as _};

    // If stdin is a terminal (not piped), nothing to do — passthrough
    if std::io::stdin().is_terminal() {
        eprintln!("river-index hook: reads JSON from stdin (piped by Claude Code)");
        return Ok(());
    }

    let mut input = String::new();
    std::io::stdin().read_to_string(&mut input)?;

    let v: serde_json::Value = match serde_json::from_str(&input) {
        Ok(v) => v,
        Err(_) => return Ok(()), // malformed input → passthrough
    };

    let tool_input = &v["tool_input"];

    // Passthrough if offset or limit requested (targeted read)
    if !tool_input["offset"].is_null() || !tool_input["limit"].is_null() {
        return Ok(());
    }

    let file_path = match tool_input["file_path"].as_str() {
        Some(p) => p,
        None => return Ok(()),
    };

    // Convert to relative path inside the repo
    let rel = match std::path::Path::new(file_path).strip_prefix(root) {
        Ok(r) => r.to_string_lossy().to_string(),
        Err(_) => return Ok(()), // outside repo → passthrough
    };

    // Passthrough for non-parseable extensions
    let ext = std::path::Path::new(file_path)
        .extension()
        .and_then(|e| e.to_str())
        .unwrap_or("");
    if PASSTHROUGH_EXTS.contains(&ext) {
        return Ok(());
    }

    // Query index
    if !db_path.exists() {
        return Ok(());
    }
    let conn = db::open(db_path)?;
    db::migrate(&conn)?;

    let summary = match query::file_summary(&conn, &rel) {
        Ok(s) => s,
        Err(_) => return Ok(()), // not indexed → passthrough
    };

    print!("{}", summary.to_compact());

    process::exit(2);
}

fn run_post_commit_hook(root: &std::path::Path, db_path: &std::path::Path) -> Result<()> {
    use std::io::{IsTerminal, Read as _};

    if std::io::stdin().is_terminal() {
        return Ok(());
    }

    let mut input = String::new();
    std::io::stdin().read_to_string(&mut input)?;

    let v: serde_json::Value = match serde_json::from_str(&input) {
        Ok(v) => v,
        Err(_) => return Ok(()),
    };

    // PostToolUse JSON: { "tool_name": "Bash", "tool_input": { "command": "..." }, "tool_response": {...} }
    let cmd = v["tool_input"]["command"].as_str().unwrap_or("");

    let is_commit = cmd.contains("git commit")
        || cmd.contains("git -C") && cmd.contains("commit")
        || cmd.contains("rtk git commit");

    if !is_commit {
        return Ok(());
    }

    if !db_path.exists() {
        return Ok(());
    }

    let conn = db::open(db_path)?;
    db::migrate(&conn)?;
    let stats = indexer::run(root, &conn, false)?;

    eprintln!(
        "[river-index] reindexed after commit: indexed={} skipped={} removed={}",
        stats.indexed, stats.skipped, stats.removed
    );

    Ok(())
}
