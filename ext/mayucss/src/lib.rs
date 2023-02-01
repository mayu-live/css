use std::collections::HashMap;
use magnus::{define_module, function, method, prelude::*, wrap, Error};
use lightningcss::{
  stylesheet::{StyleSheet, ParserOptions, MinifyOptions, PrinterOptions},
  visitor::{Visit, VisitTypes, Visitor},
  visit_types,
  selector::{Component, Selector},
  declaration::DeclarationBlock,
};
use lightningcss::dependencies::DependencyOptions;

struct MyVisitor;

impl<'i> Visitor<'i> for MyVisitor {
  const TYPES: VisitTypes = visit_types!(SELECTORS);

  fn visit_selector(&mut self, selector: &mut Selector<'i>) {
    for c in selector.iter_mut_raw_match_order() {

      match c {
        Component::Class(c) => {
          *c = format!("tw-{}", c).into();
        }
        _ => {}
      }
    }
  }
}

fn to_css(stylesheet: StyleSheet) -> String {
  let res = stylesheet.to_css(
    PrinterOptions {
      analyze_dependencies: Some(DependencyOptions::default()),
      ..PrinterOptions::default()
    }
  ).unwrap();

  return res.code;
}

//////////////

fn serialize(filename: String, source: String) -> String {
  let stylesheet = StyleSheet::parse(
    &source,
    ParserOptions {
      filename: filename,
      ..ParserOptions::default()
    },
  ).unwrap();
  return serde_json::to_string(&stylesheet).unwrap();
}

fn transform(filename: String, source: String) -> String {
  let mut stylesheet = StyleSheet::parse(
    &source,
    ParserOptions {
      filename: filename,
      ..ParserOptions::default()
    },
  ).unwrap();
  // let mut style_rules = HashMap::new();

  // stylesheet.visit(&mut StyleRuleCollector { });
  stylesheet.visit(&mut MyVisitor);

  return to_css(stylesheet);
}

fn minify(filename: String, source: String) -> String {
  let mut stylesheet = StyleSheet::parse(
    &source,
    ParserOptions {
      filename: filename,
      ..ParserOptions::default()
    },
  ).unwrap();

  stylesheet.minify(
    MinifyOptions::default()
  ).unwrap();

  return to_css(stylesheet);
}

#[magnus::init]
fn init() -> Result<(), Error> {
    let module = define_module("MayuCSS")?;
    module.define_singleton_method("minify", function!(minify, 2))?;
    module.define_singleton_method("serialize", function!(serialize, 2))?;
    module.define_singleton_method("transform", function!(transform, 2))?;
    Ok(())
}
