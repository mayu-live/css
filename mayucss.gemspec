# frozen_string_literal: true

require_relative "lib/mayucss/version"

Gem::Specification.new do |spec|
  spec.name = "mayucss"
  spec.version = MayuCSS::VERSION
  spec.authors = ["Andreas Alin"]
  spec.email = ["andreas.alin@gmail.com"]

  spec.summary = "CSS parsing for mayu live"
  # spec.description = "TODO: Write a longer description or delete this line."
  spec.homepage = "https://github.com/mayu-live/mayu-css"
  spec.license = "MPL"
  spec.required_ruby_version = ">= 3.1.3"
  spec.required_rubygems_version = ">= 3.3.11"

  # spec.metadata["allowed_push_host"] = "TODO: Set to your gem server 'https://example.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  # spec.metadata["source_code_uri"] = "TODO: Put your gem's public repo URL here."
  # spec.metadata["changelog_uri"] = "TODO: Put your gem's CHANGELOG.md URL here."

  spec.platform = Gem::Platform::RUBY
  spec.files = Dir["lib/**/*.rb"].concat(Dir["ext/mayucss/src/**/*.rs"]) << "ext/mayucss/Cargo.toml" << "Cargo.toml" << "Cargo.lock" << "README.md"
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
  spec.extensions = ["ext/mayucss/Cargo.toml"]

  spec.add_development_dependency "rake-compiler", "~> 1.2.1"
  spec.add_development_dependency "rb_sys", "~> 0.9.58"
  spec.add_development_dependency "rake", "~> 13.0"
end
