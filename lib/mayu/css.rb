# frozen_string_literal: true

require "json"
require_relative "css/version"

begin
  RUBY_VERSION =~ /(\d+\.\d+)/
  require "mayu/css/#{$1}/ext"
rescue LoadError
  require "mayu/css/ext"
end

module Mayu
  module CSS
    class Error < StandardError; end
    class ParseError < Error; end

    ImportDependency = Data.define(:url, :placeholder, :supports, :media, :loc)
    UrlDependency = Data.define(:url, :placeholder, :loc)

    Export = Data.define(:name, :composes, :referenced?)

    ComposeLocal = Data.define(:name)
    ComposeDependency = Data.define(:name, :specifier)

    Loc = Data.define(:file_path, :start, :end) do
      def self.from_ext(data) =
        new(
          file_path: data[:filePath],
          start: Pos.from_ext(data[:start]),
          end: Pos.from_ext(data[:end]),
        )
    end

    Pos = Data.define(:line, :column) do
      def self.from_ext(data) =
        new(data[:line], data[:column])
    end

    TransformResult = Data.define(:classes, :elements, :code, :dependencies, :exports) do
      def self.from_ext(data) =
        new(
          classes: data.classes,
          elements: data.elements,
          code: data.code,
          dependencies:
            data.serialized_dependencies
              .then { JSON.parse(_1, symbolize_names: true) }
              .map do |dep|
                case dep
                in { type: "import", url:, placeholder:, supports:, media:, loc: }
                  ImportDependency[url:, placeholder:, supports:, media:, loc: Loc.from_ext(loc) ]
                in { type: "url", url:, placeholder:, loc: }
                  UrlDependency[url:, placeholder:, loc: Loc.from_ext(loc)]
                end
              end,
          exports:
            data.serialized_exports
              .then { JSON.parse(_1, symbolize_names: true) }
              .transform_keys(&:to_s)
              .transform_values do |export|
                export => { name:, composes:, isReferenced: }

                Export[
                  name:,
                  referenced?: isReferenced,
                  composes: composes.map do |compose|
                    case compose
                    in { type: "local", name: }
                      ComposeLocal[name:]
                    in { type: "dependency", name:, specifier: }
                      ComposeDependency[name:, specifier:]
                    end
                  end
                ]
              end
        )

      def replace_dependencies
        dependencies.reduce(code) do |code, dependency|
          code.gsub(dependency.placeholder, (yield dependency))
        end
      end
    end

    SerializeResult = Data.define(:rules, :sources, :source_map_urls, :license_comments) do
      def self.from_ext(data)
        JSON.parse(data, symbolize_names: true) => {
          rules:,
          sources:,
          sourceMapUrls: source_map_urls,
          licenseComments: license_comments,
        }
        new(rules:, sources:, source_map_urls:, license_comments:)
      end
    end

    def self.transform(file, code, minify: true) =
      TransformResult.from_ext(ext_transform(file, code, minify))

    def self.minify(file, code) =
      ext_minify(file, code)

    def self.serialize(file, code) =
      SerializeResult.from_ext(ext_serialize(file, code))
  end
end
