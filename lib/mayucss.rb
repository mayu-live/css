# frozen_string_literal: true

require "json"
require_relative "mayucss/version"

# https://github.com/matsadler/halton-rb/commit/ce9887c3d36ca1328e5133675b7fdd97e879f421
%w[mayucss/mayucss mayucss.bundle mayucss.so]
  .find do |path|
    require_relative path
  rescue LoadError
    # noop
  end

module MayuCSS
  class Error < StandardError; end

  class TransformResult
    def dependencies
      JSON.parse(serialized_dependencies, symbolize_names: true)
    end
  end
end
