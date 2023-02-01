# frozen_string_literal: true

require "bundler/gem_tasks"
require "rake/extensiontask"

task build: :compile

Rake::ExtensionTask.new("mayucss") do |ext|
  ext.lib_dir = "lib/mayucss"
end

task default: :compile
