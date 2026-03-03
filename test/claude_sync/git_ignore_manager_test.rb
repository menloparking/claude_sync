# frozen_string_literal: true

require "test_helper"

class GitIgnoreManagerTest < Minitest::Test
  def setup
    super
    @tmpdir = Dir.mktmpdir
    @original_dir = Dir.pwd
    Dir.chdir(@tmpdir)
  end

  def teardown
    Dir.chdir(@original_dir)
    FileUtils.remove_entry(@tmpdir)
    super
  end

  def test_creates_gitignore_with_entries_if_missing
    manager = ClaudeSync::GitIgnoreManager.new("claude.md")
    manager.ensure_ignored

    content = File.read(".gitignore")
    assert_includes content, "claude.md"
    assert_includes content, ".claude_sync_metadata.json"
  end

  def test_appends_missing_entries_to_existing_gitignore
    File.write(".gitignore", "node_modules/\n")
    manager = ClaudeSync::GitIgnoreManager.new("claude.md")
    manager.ensure_ignored

    content = File.read(".gitignore")
    assert_includes content, "node_modules/"
    assert_includes content, "claude.md"
    assert_includes content, ".claude_sync_metadata.json"
  end

  def test_does_not_duplicate_existing_entries
    File.write(".gitignore", "claude.md\n")
    manager = ClaudeSync::GitIgnoreManager.new("claude.md")
    manager.ensure_ignored

    lines = File.readlines(".gitignore")
      .map(&:strip)
      .reject(&:empty?)
    claude_lines = lines.select { |l| l == "claude.md" }
    assert_equal 1, claude_lines.length
  end

  def test_adds_newline_before_entries_if_file_lacks_one
    File.write(".gitignore", "node_modules/")
    manager = ClaudeSync::GitIgnoreManager.new("claude.md")
    manager.ensure_ignored

    content = File.read(".gitignore")
    refute content.start_with?("node_modules/claude")
  end

  def test_handles_custom_target_file_names
    manager = ClaudeSync::GitIgnoreManager.new("AGENTS.md")
    manager.ensure_ignored

    content = File.read(".gitignore")
    assert_includes content, "AGENTS.md"
    refute_includes content, "claude.md"
  end
end
