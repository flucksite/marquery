# frozen_string_literal: true

require_relative "lib/marquery/version"

Gem::Specification.new do |spec|
  spec.name = "marquery"
  spec.version = Marquery::VERSION
  spec.authors = ["Wout"]
  spec.email = ["hi@wout.codes"]

  spec.summary = "Type-friendly markdown query engine for Ruby."
  spec.description = <<~DESC
    Marquery loads markdown files with YAML frontmatter from a conventional
    directory layout, exposes them through a chainable query API, resolves
    associated assets, and renders content to HTML. It is a Ruby companion to
    the Crystal shard of the same name.
  DESC
  spec.homepage = "https://codeberg.org/fluck/marquery"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/src/branch/main/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir[
    "lib/**/*.rb",
    "README.md",
    "CHANGELOG.md",
    "LICENSE"
  ]
  spec.require_paths = ["lib"]

  spec.add_dependency "commonmarker", "~> 2.0"
end
