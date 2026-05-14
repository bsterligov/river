use anyhow::Result;
use regex::Regex;

#[derive(Debug, Clone)]
pub struct Symbol {
    pub name: String,
    pub kind: String,
    pub line: usize,
    pub col: usize,
    pub signature: Option<String>,
}

#[derive(Debug, Clone)]
pub struct ParseResult {
    pub symbols: Vec<Symbol>,
    pub imports: Vec<String>,
    pub lines: usize,
}

struct RustPatterns {
    fn_re: Regex,
    struct_re: Regex,
    enum_re: Regex,
    trait_re: Regex,
    impl_re: Regex,
    type_re: Regex,
    const_re: Regex,
    use_re: Regex,
    mod_re: Regex,
}

impl RustPatterns {
    fn new() -> Result<Self> {
        Ok(Self {
            fn_re: Regex::new(
                r"(?m)^[ \t]*(pub(?:\([^)]*\))?\s+)?(async\s+)?fn\s+([a-zA-Z_][a-zA-Z0-9_]*)([^{;]*)",
            )?,
            struct_re: Regex::new(
                r"(?m)^[ \t]*(pub(?:\([^)]*\))?\s+)?struct\s+([a-zA-Z_][a-zA-Z0-9_<>, ]*)",
            )?,
            enum_re: Regex::new(
                r"(?m)^[ \t]*(pub(?:\([^)]*\))?\s+)?enum\s+([a-zA-Z_][a-zA-Z0-9_<>, ]*)",
            )?,
            trait_re: Regex::new(
                r"(?m)^[ \t]*(pub(?:\([^)]*\))?\s+)?trait\s+([a-zA-Z_][a-zA-Z0-9_<>, ]*)",
            )?,
            impl_re: Regex::new(
                r"(?m)^[ \t]*impl(?:<[^>]*>)?\s+(?:[a-zA-Z_][a-zA-Z0-9_:]*\s+for\s+)?([a-zA-Z_][a-zA-Z0-9_<>, ]*)",
            )?,
            type_re: Regex::new(
                r"(?m)^[ \t]*(pub(?:\([^)]*\))?\s+)?type\s+([a-zA-Z_][a-zA-Z0-9_]*)",
            )?,
            const_re: Regex::new(r"(?m)^[ \t]*(pub(?:\([^)]*\))?\s+)?const\s+([A-Z_][A-Z0-9_]*)")?,
            use_re: Regex::new(r"(?m)^[ \t]*use\s+([a-zA-Z_][a-zA-Z0-9_::{}, *]*)")?,
            mod_re: Regex::new(
                r"(?m)^[ \t]*(pub(?:\([^)]*\))?\s+)?mod\s+([a-zA-Z_][a-zA-Z0-9_]*)",
            )?,
        })
    }
}

struct DartPatterns {
    class_re: Regex,
    mixin_re: Regex,
    fn_re: Regex,
    import_re: Regex,
    enum_re: Regex,
    typedef_re: Regex,
}

impl DartPatterns {
    fn new() -> Result<Self> {
        Ok(Self {
            class_re: Regex::new(r"(?m)^[ \t]*(abstract\s+)?class\s+([A-Za-z_][A-Za-z0-9_]*)")?,
            mixin_re: Regex::new(r"(?m)^[ \t]*mixin\s+([A-Za-z_][A-Za-z0-9_]*)")?,
            fn_re: Regex::new(
                r"(?m)^[ \t]*(?:static\s+|async\s+|@\w+\s+)*(?:[A-Za-z_][A-Za-z0-9_<>?,\[\]]*\s+)+([a-z_][A-Za-z0-9_]*)\s*\(",
            )?,
            import_re: Regex::new(r#"(?m)^[ \t]*import\s+['"]([^'"]+)['"]\s*"#)?,
            enum_re: Regex::new(r"(?m)^[ \t]*enum\s+([A-Za-z_][A-Za-z0-9_]*)")?,
            typedef_re: Regex::new(r"(?m)^[ \t]*typedef\s+([A-Za-z_][A-Za-z0-9_]*)")?,
        })
    }
}

fn line_of(src: &str, byte_offset: usize) -> usize {
    src[..byte_offset].chars().filter(|&c| c == '\n').count() + 1
}

fn push_sym(symbols: &mut Vec<Symbol>, name: String, kind: &str, src: &str, byte_offset: usize) {
    symbols.push(Symbol {
        name,
        kind: kind.into(),
        line: line_of(src, byte_offset),
        col: 1,
        signature: None,
    });
}

pub fn parse_rust(src: &str) -> ParseResult {
    let p = match RustPatterns::new() {
        Ok(p) => p,
        Err(_) => {
            return ParseResult {
                symbols: vec![],
                imports: vec![],
                lines: src.lines().count(),
            }
        }
    };

    let mut symbols = Vec::new();

    for cap in p.fn_re.captures_iter(src) {
        let offset = cap.get(0).map_or(0, |m| m.start());
        let name = cap[3].to_string();
        let sig = format!("fn {}{}", &cap[3], cap[4].trim());
        symbols.push(Symbol {
            name,
            kind: "fn".into(),
            line: line_of(src, offset),
            col: 1,
            signature: Some(sig),
        });
    }
    for cap in p.struct_re.captures_iter(src) {
        let offset = cap.get(0).map_or(0, |m| m.start());
        push_sym(
            &mut symbols,
            cap[2].trim().to_string(),
            "struct",
            src,
            offset,
        );
    }
    for cap in p.enum_re.captures_iter(src) {
        let offset = cap.get(0).map_or(0, |m| m.start());
        push_sym(&mut symbols, cap[2].trim().to_string(), "enum", src, offset);
    }
    for cap in p.trait_re.captures_iter(src) {
        let offset = cap.get(0).map_or(0, |m| m.start());
        push_sym(
            &mut symbols,
            cap[2].trim().to_string(),
            "trait",
            src,
            offset,
        );
    }
    for cap in p.impl_re.captures_iter(src) {
        let offset = cap.get(0).map_or(0, |m| m.start());
        push_sym(&mut symbols, cap[1].trim().to_string(), "impl", src, offset);
    }
    for cap in p.type_re.captures_iter(src) {
        let offset = cap.get(0).map_or(0, |m| m.start());
        push_sym(&mut symbols, cap[2].trim().to_string(), "type", src, offset);
    }
    for cap in p.const_re.captures_iter(src) {
        let offset = cap.get(0).map_or(0, |m| m.start());
        push_sym(
            &mut symbols,
            cap[2].trim().to_string(),
            "const",
            src,
            offset,
        );
    }
    for cap in p.mod_re.captures_iter(src) {
        let offset = cap.get(0).map_or(0, |m| m.start());
        push_sym(&mut symbols, cap[2].trim().to_string(), "mod", src, offset);
    }

    let mut imports = Vec::new();
    for cap in p.use_re.captures_iter(src) {
        let raw = cap[1].trim().to_string();
        if let Some(top) = raw.split("::").next() {
            let top = top.trim_matches(|c: char| !c.is_alphanumeric() && c != '_');
            if !top.is_empty()
                && top != "self"
                && top != "super"
                && top != "crate"
                && !imports.contains(&top.to_string())
            {
                imports.push(top.to_string());
            }
        }
        if !imports.contains(&raw) {
            imports.push(raw);
        }
    }

    symbols.sort_by_key(|s| s.line);
    ParseResult {
        symbols,
        imports,
        lines: src.lines().count(),
    }
}

pub fn parse_dart(src: &str) -> ParseResult {
    let p = match DartPatterns::new() {
        Ok(p) => p,
        Err(_) => {
            return ParseResult {
                symbols: vec![],
                imports: vec![],
                lines: src.lines().count(),
            }
        }
    };

    let mut symbols = Vec::new();

    for cap in p.class_re.captures_iter(src) {
        let offset = cap.get(0).map_or(0, |m| m.start());
        push_sym(
            &mut symbols,
            cap[2].trim().to_string(),
            "class",
            src,
            offset,
        );
    }
    for cap in p.mixin_re.captures_iter(src) {
        let offset = cap.get(0).map_or(0, |m| m.start());
        push_sym(
            &mut symbols,
            cap[1].trim().to_string(),
            "mixin",
            src,
            offset,
        );
    }
    for cap in p.enum_re.captures_iter(src) {
        let offset = cap.get(0).map_or(0, |m| m.start());
        push_sym(&mut symbols, cap[1].trim().to_string(), "enum", src, offset);
    }
    for cap in p.typedef_re.captures_iter(src) {
        let offset = cap.get(0).map_or(0, |m| m.start());
        push_sym(
            &mut symbols,
            cap[1].trim().to_string(),
            "typedef",
            src,
            offset,
        );
    }
    for cap in p.fn_re.captures_iter(src) {
        let name = cap[1].trim().to_string();
        if matches!(name.as_str(), "if" | "for" | "while" | "switch" | "catch") {
            continue;
        }
        let offset = cap.get(0).map_or(0, |m| m.start());
        push_sym(&mut symbols, name, "fn", src, offset);
    }

    let mut imports = Vec::new();
    for cap in p.import_re.captures_iter(src) {
        imports.push(cap[1].to_string());
    }

    symbols.sort_by_key(|s| s.line);
    symbols.dedup_by(|a, b| a.name == b.name && a.kind == b.kind && a.line == b.line);
    ParseResult {
        symbols,
        imports,
        lines: src.lines().count(),
    }
}

pub fn parse_generic(src: &str) -> ParseResult {
    ParseResult {
        symbols: vec![],
        imports: vec![],
        lines: src.lines().count(),
    }
}
