# frozen_string_literal: true

require "bundler/gem_tasks"
require "rake/extensiontask"

PLATFORMS = [
  "x86_64-linux",
  # "arm-linux",
  "aarch64-linux",
  "x86_64-darwin",
  "arm64-darwin",
  # "x64-mingw32",
  # "x64-mingw-ucrt",
]

spec = Gem::Specification.load("mayucss.gemspec")
spec.requirements.clear
spec.required_ruby_version = nil
spec.required_rubygems_version = nil
spec.extensions.clear
spec.files -= Dir["ext/**/*"]

Rake::ExtensionTask.new("mayucss", spec) do |ext|
  ext.lib_dir = "lib/mayucss"
  ext.cross_compile = true
  ext.cross_platform = PLATFORMS
end

Gem::PackageTask.new(spec) do |pkg|
end

task default: :compile
