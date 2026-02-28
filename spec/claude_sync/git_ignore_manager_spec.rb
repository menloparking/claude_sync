# frozen_string_literal: true

require "spec_helper"

RSpec.describe ClaudeSync::GitIgnoreManager do
  around do |example|
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) { example.run }
    end
  end

  describe "#ensure_ignored" do
    it "creates .gitignore with entries if missing" do
      manager = described_class.new("claude.md")
      manager.ensure_ignored

      content = File.read(".gitignore")
      expect(content).to include("claude.md")
      expect(content).to include(
        ".claude_sync_metadata.json"
      )
    end

    it "appends missing entries to existing .gitignore" do
      File.write(".gitignore", "node_modules/\n")
      manager = described_class.new("claude.md")
      manager.ensure_ignored

      content = File.read(".gitignore")
      expect(content).to include("node_modules/")
      expect(content).to include("claude.md")
      expect(content).to include(
        ".claude_sync_metadata.json"
      )
    end

    it "does not duplicate existing entries" do
      File.write(".gitignore", "claude.md\n")
      manager = described_class.new("claude.md")
      manager.ensure_ignored

      lines = File.readlines(".gitignore")
        .map(&:strip)
        .reject(&:empty?)
      claude_lines = lines.select { |l| l == "claude.md" }
      expect(claude_lines.length).to eq(1)
    end

    it "adds newline before entries if file lacks one" do
      File.write(".gitignore", "node_modules/")
      manager = described_class.new("claude.md")
      manager.ensure_ignored

      content = File.read(".gitignore")
      expect(content).not_to start_with("node_modules/claude")
    end

    it "handles custom target file names" do
      manager = described_class.new("AGENTS.md")
      manager.ensure_ignored

      content = File.read(".gitignore")
      expect(content).to include("AGENTS.md")
      expect(content).not_to include("claude.md")
    end
  end
end
