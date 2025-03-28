use lightningcss::dependencies::DependencyOptions;
use lightningcss::{
    selector::{Component, Selector},
    stylesheet::{MinifyOptions, ParserOptions, PrinterOptions, StyleSheet},
    visitor::{Visit, VisitTypes, Visitor},
};
use parcel_sourcemap::SourceMap;
use magnus::{
    class, define_module, exception::ExceptionClass, function, gc::register_mark_object, method,
    prelude::*, value::Lazy, Error, RModule, Ruby,
};
use std::{collections::HashMap, convert::Infallible};

static PARSE_ERROR: Lazy<ExceptionClass> = Lazy::new(|ruby| {
    let ex = ruby
        .class_object()
        .const_get::<_, RModule>("Mayu")
        .unwrap()
        .const_get::<_, RModule>("CSS")
        .unwrap()
        .const_get("ParseError")
        .unwrap();
    // ensure `ex` is never garbage collected (e.g. if constant is
    // redefined) and also not moved under compacting GC.
    register_mark_object(ex);
    ex
});

#[allow(dead_code)]
struct TransformOptions {
    component: String,
    filename: String,
    hash: String,
}

#[magnus::wrap(class = "Mayu::CSS::ExtTransformResult", free_immediately, size)]
struct TransformResult {
    code: String,
    classes: HashMap<String, String>,
    elements: HashMap<String, String>,
    serialized_exports: String,
    serialized_dependencies: String,
    source_map: Option<String>,
}

impl TransformResult {
    fn code(&self) -> String {
        self.code.clone()
    }

    fn serialized_dependencies(&self) -> String {
        self.serialized_dependencies.clone()
    }

    fn serialized_exports(&self) -> String {
        self.serialized_exports.clone()
    }

    fn classes(&self) -> HashMap<String, String> {
        self.classes.clone()
    }

    fn elements(&self) -> HashMap<String, String> {
        self.elements.clone()
    }

    fn source_map(&self) -> Option<String> {
        self.source_map.clone()
    }
}

struct TransformNamesVisitor<'a> {
    options: TransformOptions,
    classes: &'a mut HashMap<String, String>,
    elements: &'a mut HashMap<String, String>,
}

impl<'a, 'i> Visitor<'i> for TransformNamesVisitor<'a> {
    type Error = Infallible;

    fn visit_types(&self) -> VisitTypes {
        VisitTypes::RULES
    }

    fn visit_selector(&mut self, selector: &mut Selector<'i>) -> Result<(), Self::Error> {
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

        Ok(())
    }
}

fn serialize(ruby: &Ruby, filename: String, source: String) -> Result<String, Error> {
    match StyleSheet::parse(
        &source,
        ParserOptions {
            filename: filename,
            ..ParserOptions::default()
        },
    ) {
        Ok(stylesheet) => Ok(serde_json::to_string(&stylesheet).unwrap()),
        Err(err) => return Err(Error::new(ruby.get_inner(&PARSE_ERROR), err.to_string())),
    }
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

fn transform(
    ruby: &Ruby,
    filename: String,
    source: String,
    minify: bool,
) -> Result<TransformResult, Error> {
    let mut stylesheet = match StyleSheet::parse(
        &source,
        ParserOptions {
            filename: filename.clone(),
            css_modules: Some(lightningcss::css_modules::Config {
                pattern: lightningcss::css_modules::Pattern::parse("[local]").unwrap(),
                dashed_idents: false,
                animation: false,
                grid: false,
                container: false,
                custom_idents: false,
                pure: false,
            }),
            ..ParserOptions::default()
        },
    ) {
        Ok(style) => style,
        Err(err) => return Err(Error::new(ruby.get_inner(&PARSE_ERROR), err.to_string())),
    };

    let mut classes = HashMap::new();
    let mut elements = HashMap::new();

    let _ = stylesheet.visit(&mut TransformNamesVisitor {
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

    let mut source_map = SourceMap::new("/");
    source_map.add_source(&filename);
    source_map.set_source_content(0, &source).unwrap();

    if minify {
        stylesheet.minify(MinifyOptions::default()).unwrap();
    }

    let res = stylesheet
        .to_css(PrinterOptions {
            analyze_dependencies: Some(DependencyOptions::default()),
            minify: minify,
            source_map: Some(&mut source_map),
            ..PrinterOptions::default()
        })
        .unwrap();

    let serialized_exports = serde_json::to_string(&res.exports.unwrap()).unwrap();
    let serialized_dependencies = serde_json::to_string(&res.dependencies.unwrap()).unwrap();

    Ok(TransformResult {
        code: res.code,
        classes: classes,
        elements: elements,
        serialized_exports: serialized_exports,
        serialized_dependencies: serialized_dependencies,
        source_map: source_map.to_json(None).ok()
    })
}

fn minify(ruby: &Ruby, filename: String, source: String) -> Result<String, Error> {
    let mut stylesheet = match StyleSheet::parse(
        &source,
        ParserOptions {
            filename: filename,
            ..ParserOptions::default()
        },
    ) {
        Ok(style) => style,
        Err(err) => return Err(Error::new(ruby.get_inner(&PARSE_ERROR), err.to_string())),
    };

    stylesheet.minify(MinifyOptions::default()).unwrap();

    let res = stylesheet
        .to_css(PrinterOptions {
            analyze_dependencies: Some(DependencyOptions::default()),
            minify: true,
            ..PrinterOptions::default()
        })
        .unwrap();

    return Ok(res.code);
}

#[magnus::init]
fn init() -> Result<(), Error> {
    let mayu = define_module("Mayu")?;
    let module = mayu.define_module("CSS")?;
    module.define_singleton_method("ext_minify", function!(minify, 2))?;
    module.define_singleton_method("ext_serialize", function!(serialize, 2))?;
    module.define_singleton_method("ext_transform", function!(transform, 3))?;

    let class = module.define_class("ExtTransformResult", class::object())?;
    class.define_method("code", method!(TransformResult::code, 0))?;
    class.define_method("classes", method!(TransformResult::classes, 0))?;
    class.define_method("elements", method!(TransformResult::elements, 0))?;
    class.define_method("source_map", method!(TransformResult::source_map, 0))?;
    class.define_method(
        "serialized_exports",
        method!(TransformResult::serialized_exports, 0),
    )?;
    class.define_method(
        "serialized_dependencies",
        method!(TransformResult::serialized_dependencies, 0),
    )?;
    Ok(())
}
