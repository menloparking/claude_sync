# frozen_string_literal: true

require_relative "lib/claude_sync/version"

Gem::Specification.new do |spec|
  spec.name = "claude_sync"
  spec.version = ClaudeSync::VERSION
  spec.authors = ["Menlo Parking"]
  spec.email = ["admin@menloparking.com"]

  spec.summary = "Sync claude.md from a GitHub Gist"
  spec.description =
    "A development gem that syncs your project's " \
    "claude.md file from a GitHub Gist. Keeps your " \
    "Claude Code instructions in sync across dev " \
    "containers and local environments."
  spec.homepage =
    "https://github.com/menloparking/claude_sync"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] =
    "https://github.com/menloparking/claude_sync"
  spec.metadata["changelog_uri"] =
    "https://github.com/menloparking/claude_sync" \
    "/blob/main/CHANGELOG.md"

  spec.files = Dir.glob(%w[
    lib/**/*.rb
    exe/*
    LICENSE.txt
    README.md
    CHANGELOG.md
  ])

  spec.bindir = "exe"
  spec.executables = ["claude-sync"]
  spec.require_paths = ["lib"]
end
