use crate::parser::{parse_dart, parse_generic, parse_rust};

#[test]
fn rust_detects_functions() {
    let src = r#"
pub fn hello() -> String { String::new() }
async fn world(x: i32) -> i32 { x }
pub(crate) fn internal() {}
"#;
    let r = parse_rust(src);
    let names: Vec<&str> = r
        .symbols
        .iter()
        .filter(|s| s.kind == "fn")
        .map(|s| s.name.as_str())
        .collect();
    assert!(names.contains(&"hello"), "missing hello");
    assert!(names.contains(&"world"), "missing world");
    assert!(names.contains(&"internal"), "missing internal");
}

#[test]
fn rust_detects_structs_enums_traits() {
    let src = r#"
pub struct Foo { x: i32 }
enum Bar { A, B }
pub trait Baz { fn run(&self); }
"#;
    let r = parse_rust(src);
    let kinds: Vec<(&str, &str)> = r
        .symbols
        .iter()
        .map(|s| (s.name.as_str(), s.kind.as_str()))
        .collect();
    assert!(kinds.contains(&("Foo", "struct")));
    assert!(kinds.contains(&("Bar", "enum")));
    assert!(kinds.contains(&("Baz", "trait")));
}

#[test]
fn rust_detects_impl_type_const_mod() {
    let src = r#"
impl Foo { fn new() -> Self { Foo { x: 0 } } }
type Alias = Vec<i32>;
const MAX: usize = 100;
pub mod utils {}
"#;
    let r = parse_rust(src);
    let kinds: Vec<(&str, &str)> = r
        .symbols
        .iter()
        .map(|s| (s.name.as_str(), s.kind.as_str()))
        .collect();
    assert!(kinds.iter().any(|(_, k)| *k == "impl"), "missing impl");
    assert!(kinds.contains(&("Alias", "type")));
    assert!(kinds.contains(&("MAX", "const")));
    assert!(kinds.contains(&("utils", "mod")));
}

#[test]
fn rust_extracts_top_level_imports() {
    let src = r#"
use std::collections::HashMap;
use serde::{Deserialize, Serialize};
use anyhow::Result;
"#;
    let r = parse_rust(src);
    assert!(r.imports.contains(&"std".to_string()));
    assert!(r.imports.contains(&"serde".to_string()));
    assert!(r.imports.contains(&"anyhow".to_string()));
}

#[test]
fn rust_skips_self_super_crate_imports() {
    let src = r#"
use self::foo;
use super::bar;
use crate::baz;
"#;
    let r = parse_rust(src);
    assert!(!r.imports.contains(&"self".to_string()));
    assert!(!r.imports.contains(&"super".to_string()));
    assert!(!r.imports.contains(&"crate".to_string()));
}

#[test]
fn rust_line_numbers_are_correct() {
    let src = "fn first() {}\nfn second() {}\nfn third() {}\n";
    let r = parse_rust(src);
    let lines: Vec<usize> = r.symbols.iter().map(|s| s.line).collect();
    assert_eq!(lines[0], 1);
    assert_eq!(lines[1], 2);
    assert_eq!(lines[2], 3);
}

#[test]
fn rust_fn_signature_captured() {
    let src = "pub fn greet(name: &str) -> String { name.to_string() }\n";
    let r = parse_rust(src);
    let sym = r.symbols.iter().find(|s| s.name == "greet").unwrap();
    let sig = sym.signature.as_deref().unwrap_or("");
    assert!(sig.contains("greet"));
}

#[test]
fn rust_symbols_sorted_by_line() {
    let src = "struct B {}\nstruct A {}\nstruct C {}\n";
    let r = parse_rust(src);
    let lines: Vec<usize> = r.symbols.iter().map(|s| s.line).collect();
    assert!(lines.windows(2).all(|w| w[0] <= w[1]));
}

#[test]
fn rust_empty_source() {
    let r = parse_rust("");
    assert!(r.symbols.is_empty());
    assert!(r.imports.is_empty());
    assert_eq!(r.lines, 0);
}

#[test]
fn rust_line_count() {
    let src = "fn a() {}\nfn b() {}\n";
    let r = parse_rust(src);
    assert_eq!(r.lines, 2);
}

#[test]
fn dart_detects_classes() {
    let src = r#"
class Foo extends StatelessWidget {}
abstract class Bar {}
"#;
    let r = parse_dart(src);
    let names: Vec<&str> = r
        .symbols
        .iter()
        .filter(|s| s.kind == "class")
        .map(|s| s.name.as_str())
        .collect();
    assert!(names.contains(&"Foo"));
    assert!(names.contains(&"Bar"));
}

#[test]
fn dart_detects_enums_mixins_typedefs() {
    let src = r#"
enum Color { red, green, blue }
mixin Serializable {}
typedef Callback = void Function();
"#;
    let r = parse_dart(src);
    let kinds: Vec<(&str, &str)> = r
        .symbols
        .iter()
        .map(|s| (s.name.as_str(), s.kind.as_str()))
        .collect();
    assert!(kinds.contains(&("Color", "enum")));
    assert!(kinds.contains(&("Serializable", "mixin")));
    assert!(kinds.contains(&("Callback", "typedef")));
}

#[test]
fn dart_extracts_imports() {
    let src = r#"
import 'package:flutter/material.dart';
import 'dart:async';
import '../widgets/button.dart';
"#;
    let r = parse_dart(src);
    assert!(r
        .imports
        .contains(&"package:flutter/material.dart".to_string()));
    assert!(r.imports.contains(&"dart:async".to_string()));
    assert!(r.imports.contains(&"../widgets/button.dart".to_string()));
}

#[test]
fn dart_skips_control_flow_keywords() {
    let src = "void build() {}\nvoid runIf() {}\n";
    let r = parse_dart(src);
    let names: Vec<&str> = r.symbols.iter().map(|s| s.name.as_str()).collect();
    assert!(!names.contains(&"if"));
    assert!(!names.contains(&"for"));
    assert!(!names.contains(&"while"));
}

#[test]
fn dart_empty_source() {
    let r = parse_dart("");
    assert!(r.symbols.is_empty());
    assert!(r.imports.is_empty());
    assert_eq!(r.lines, 0);
}

#[test]
fn dart_symbols_sorted_by_line() {
    let src = "class B {}\nclass A {}\nclass C {}\n";
    let r = parse_dart(src);
    let lines: Vec<usize> = r.symbols.iter().map(|s| s.line).collect();
    assert!(lines.windows(2).all(|w| w[0] <= w[1]));
}

#[test]
fn generic_returns_line_count_only() {
    let src = "line1\nline2\nline3\n";
    let r = parse_generic(src);
    assert_eq!(r.lines, 3);
    assert!(r.symbols.is_empty());
    assert!(r.imports.is_empty());
}
