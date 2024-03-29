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

    TransformResult = Data.define(:classes, :elements, :code, :source_map, :dependencies, :exports) do
      def self.from_ext(data) =
        new(
          classes: data.classes.transform_keys(&:to_sym),
          elements: data.elements.transform_keys(&:to_sym),
          code: data.code,
          source_map: data.source_map,
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
                Export[
                  name: export[:name],
                  referenced?: export[:isReferenced],
                  composes: export[:composes].map do |compose|
                    case compose
                    in { type: "local", name: }
                      ComposeLocal[name: name.to_sym]
                    in { type: "dependency", name:, specifier: }
                      ComposeDependency[name: name.to_sym, specifier:]
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

      def code_with_source_map
        <<~CSS
          #{code}
          /*# sourceMappingURL=#{source_map} */
        CSS
      end
    end

    SerializeResult = Data.define(:rules, :sources, :source_map_urls, :license_comments) do
      def self.from_ext(data)
        parsed = JSON.parse(data, symbolize_names: true)
        new(
          rules: parsed[:rules],
          sources: parsed[:sources],
          source_map_urls: parsed[:sourceMapUrls],
          license_comments: parsed[:licenseComments]
        )
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
