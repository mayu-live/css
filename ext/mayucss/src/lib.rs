use magnus::{define_module, function, method, prelude::*, wrap, Error};
use lightningcss::stylesheet::{
  StyleSheet, ParserOptions, MinifyOptions, PrinterOptions
};
use lightningcss::dependencies::DependencyOptions;

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

  let res = stylesheet.to_css(
    PrinterOptions {
      analyze_dependencies: Some(DependencyOptions::default()),
      ..PrinterOptions::default()
    }
  ).unwrap();

  return res.code;
}

#[magnus::init]
fn init() -> Result<(), Error> {
    let module = define_module("MayuCSS")?;
    module.define_singleton_method("minify", function!(minify, 2))?;
    module.define_singleton_method("serialize", function!(serialize, 2))?;
    Ok(())
}
