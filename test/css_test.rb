# frozen_string_literal: true

require "minitest/autorun"

require_relative "../lib/mayu/css"

class Mayu::CSS::Test < Minitest::Test
  def test_minify
    minified = Mayu::CSS.minify("#{__method__}.css", <<~CSS)
      foo {
        background: rgb(50 32 42 / 50%);
        background-image: url("foobar.png");
      }
      .bar {
        background: rgb(50 32 42 / 50%);
      }
    CSS

    assert_equal(
      minified,
      'foo{background:#32202a80 url("KuOsZa")}.bar{background:#32202a80}'
    )
  end

  def test_transform
    source = <<~CSS
      @import url("landscape.css") screen and (orientation: landscape);
      @import url("gridy.css") supports(display: grid) screen and (max-width: 400px);

      foo {
        background: rgb(50 32 42 / 50%);
        background-image: url("foobar.png");
      }
      .bar {
        background: rgb(50 32 42 / 50%);
      }
      .baz {
        composes: bar;
        color: #f00;
      }
    CSS

    transformed = Mayu::CSS.transform("#{__method__}.css", source)

    hash = "-DSO1A36"

    assert_equal(transformed.code, <<~CSS.each_line.map(&:strip).join)
      @import "Oe46gG" screen and (orientation:landscape);
      @import "iUNcHG" supports(display:grid) screen and (width<=400px);
      .test_transform_foo\\?#{hash}{background:#32202a80 url("jlJopW")}
      .test_transform\\.bar\\?#{hash}{background:#32202a80}
      .test_transform\\.baz\\?#{hash}{color:red;}
    CSS

    assert_equal(transformed.classes, {
      bar: "test_transform.bar?#{hash}",
      baz: "test_transform.baz?#{hash}",
    })

    assert_equal(transformed.elements, {
      foo: "test_transform_foo?#{hash}"
    })

    assert_equal(
      transformed.exports["test_transform.baz?#{hash}"],
      Mayu::CSS::Export[
        name: "test_transform.baz?#{hash}",
        composes: [
          Mayu::CSS::ComposeLocal[:bar]
        ],
        referenced?: false
      ]
    )

    assert_equal(
      transformed.dependencies.map { _1.with(loc: nil) },
      [
        Mayu::CSS::ImportDependency[
          url: "landscape.css",
          placeholder: "Oe46gG",
          supports: nil,
          media: "screen and (orientation: landscape)",
          loc: nil
        ],
        Mayu::CSS::ImportDependency[
          url: "gridy.css",
          placeholder: "iUNcHG",
          supports: "(display: grid)",
          media: "screen and (width <= 400px)",
          loc: nil
        ],
        Mayu::CSS::UrlDependency[
          url: "foobar.png",
          placeholder: "jlJopW",
          loc: nil
        ]
      ]
    )

    assert_equal(JSON.parse(transformed.source_map, symbolize_names: true), {
      version: 3,
      sourceRoot: nil,
      mappings: "AAAA,oDACA,kEAEA,gEAIA,kDAGA",
      sources: ["test_transform.css"],
      sourcesContent: [source],
      names: []
    })
  end
end
