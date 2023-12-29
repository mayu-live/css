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

    class TransformResult
      def dependencies = JSON.parse(serialized_dependencies, symbolize_names: true)
      def exports = JSON.parse(serialized_exports, symbolize_names: true)
    end
  end
end
