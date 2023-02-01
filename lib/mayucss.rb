# frozen_string_literal: true

require "json"
require_relative "mayucss/version"
require_relative "mayucss/mayucss"

module MayuCSS
  class Error < StandardError; end

  class TransformResult
    def dependencies
      JSON.parse(serialized_dependencies, symbolize_names: true)
    end
  end
end
