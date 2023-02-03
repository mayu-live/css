use lightningcss::dependencies::DependencyOptions;
use lightningcss::{
    selector::{Component, Selector},
    stylesheet::{MinifyOptions, ParserOptions, PrinterOptions, StyleSheet},
    visit_types,
    visitor::{Visit, VisitTypes, Visitor},
};
use magnus::{define_module, function, method, prelude::*, Error};
use std::collections::HashMap;

#[allow(dead_code)]
struct TransformOptions {
    component: String,
    filename: String,
    hash: String,
}

#[magnus::wrap(class = "Mayu::CSS::TransformResult", free_immediately, size)]
struct TransformResult {
    code: String,
    classes: HashMap<String, String>,
    elements: HashMap<String, String>,
    serialized_dependencies: String,
}

impl TransformResult {
    fn code(&self) -> String {
        self.code.clone()
    }

    fn serialized_dependencies(&self) -> String {
        self.serialized_dependencies.clone()
    }

    fn classes(&self) -> HashMap<String, String> {
        self.classes.clone()
    }

    fn elements(&self) -> HashMap<String, String> {
        self.elements.clone()
    }
}

struct TransformNamesVisitor<'a> {
    options: TransformOptions,
    classes: &'a mut HashMap<String, String>,
    elements: &'a mut HashMap<String, String>,
}

impl<'a, 'i> Visitor<'i> for TransformNamesVisitor<'a> {
    const TYPES: VisitTypes = visit_types!(SELECTORS);

    fn visit_selector(&mut self, selector: &mut Selector<'i>) {
        for s in selector.iter_mut_raw_match_order() {
            match s {
                Component::Class(c) => {
                    let formatted: String = format!(
                        "{component}.{name}?{hash}",
                        component = self.options.component,
                        name = &c,
                        hash = self.options.hash
                    );
                    self.classes.insert((&c).to_string(), formatted.clone());
                    *s = Component::Class(formatted.into());
                }
                Component::LocalName(n) => {
                    let formatted: String = format!(
                        "{component}_{name}?{hash}",
                        component = self.options.component,
                        name = n.name,
                        hash = self.options.hash
                    );
                    self.elements
                        .insert((&n.name).to_string(), formatted.clone());
                    *s = Component::Class(formatted.into());
                }
                _ => {}
            }
        }
    }
}

fn to_css(stylesheet: StyleSheet) -> String {
    let res = stylesheet
        .to_css(PrinterOptions {
            analyze_dependencies: Some(DependencyOptions::default()),
            ..PrinterOptions::default()
        })
        .unwrap();

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
    )
    .unwrap();
    return serde_json::to_string(&stylesheet).unwrap();
}

fn hash(s: String) -> String {
    use base64::{engine::general_purpose, Engine as _};
    use sha2::{Digest, Sha256};

    let mut hasher = Sha256::new();
    hasher.update(&s);
    return general_purpose::URL_SAFE_NO_PAD
        .encode(hasher.finalize())
        .get(0..8)
        .unwrap()
        .to_string();
}

fn transform(filename: String, source: String) -> TransformResult {
    let mut stylesheet = StyleSheet::parse(
        &source,
        ParserOptions {
            filename: filename.clone(),
            ..ParserOptions::default()
        },
    )
    .unwrap();

    let mut classes = HashMap::new();
    let mut elements = HashMap::new();

    stylesheet.visit(&mut TransformNamesVisitor {
        options: TransformOptions {
            component: std::path::Path::new(&filename)
                .with_extension("")
                .display()
                .to_string(),
            filename: filename.clone(),
            hash: hash(source.clone()),
        },
        classes: &mut classes,
        elements: &mut elements,
    });

    let res = stylesheet
        .to_css(PrinterOptions {
            analyze_dependencies: Some(DependencyOptions::default()),
            ..PrinterOptions::default()
        })
        .unwrap();

    let serialized_dependencies = serde_json::to_string(&res.dependencies.unwrap()).unwrap();

    TransformResult {
        code: res.code,
        classes: classes,
        elements: elements,
        serialized_dependencies: serialized_dependencies,
    }
}

fn minify(filename: String, source: String) -> String {
    let mut stylesheet = StyleSheet::parse(
        &source,
        ParserOptions {
            filename: filename,
            ..ParserOptions::default()
        },
    )
    .unwrap();

    stylesheet.minify(MinifyOptions::default()).unwrap();

    return to_css(stylesheet);
}

#[magnus::init]
fn init() -> Result<(), Error> {
    let mayu = define_module("Mayu")?;
    let module = mayu.define_module("CSS")?;
    module.define_singleton_method("minify", function!(minify, 2))?;
    module.define_singleton_method("serialize", function!(serialize, 2))?;
    module.define_singleton_method("transform", function!(transform, 2))?;
    let class = module.define_class("TransformResult", Default::default())?;
    class.define_method("code", method!(TransformResult::code, 0))?;
    class.define_method("classes", method!(TransformResult::classes, 0))?;
    class.define_method("elements", method!(TransformResult::elements, 0))?;
    class.define_method(
        "serialized_dependencies",
        method!(TransformResult::serialized_dependencies, 0),
    )?;
    Ok(())
}
