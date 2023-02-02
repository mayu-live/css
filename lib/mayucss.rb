# frozen_string_literal: true

require "json"
require_relative "mayucss/version"

begin
  RUBY_VERSION =~ /(\d+\.\d+)/
  require "mayucss/#{$1}/mayucss"
rescue LoadError
  require "mayucss/mayucss"
end

module MayuCSS
  class Error < StandardError; end

  class TransformResult
    def dependencies
      JSON.parse(serialized_dependencies, symbolize_names: true)
    end
  end
end
