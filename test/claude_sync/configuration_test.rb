# frozen_string_literal: true

require "test_helper"

class ConfigurationTest < Minitest::Test
  def test_configured_returns_false_when_gist_url_not_set
    config = ClaudeSync::Configuration.new
    refute config.configured?
  end

  def test_configured_returns_false_when_gist_url_empty
    ENV["CLAUDE_SYNC_GIST_URL"] = ""
    config = ClaudeSync::Configuration.new
    refute config.configured?
  end

  def test_configured_returns_true_when_gist_url_set
    ENV["CLAUDE_SYNC_GIST_URL"] =
      "https://gist.github.com/user/abc123"
    config = ClaudeSync::Configuration.new
    assert config.configured?
  end

  def test_extracts_gist_id_from_url
    ENV["CLAUDE_SYNC_GIST_URL"] =
      "https://gist.github.com/user/abc123"
    config = ClaudeSync::Configuration.new
    assert_equal "abc123", config.gist_id
  end

  def test_gist_id_returns_nil_when_url_not_set
    config = ClaudeSync::Configuration.new
    assert_nil config.gist_id
  end

  def test_file_defaults_to_claude_md
    config = ClaudeSync::Configuration.new
    assert_equal "CLAUDE.md", config.file
  end

  def test_file_uses_env_var
    ENV["CLAUDE_SYNC_FILE"] = "AGENTS.md"
    config = ClaudeSync::Configuration.new
    assert_equal "AGENTS.md", config.file
  end

  def test_interval_defaults_to_86400
    config = ClaudeSync::Configuration.new
    assert_equal 86_400, config.interval
  end

  def test_interval_uses_env_var
    ENV["CLAUDE_SYNC_INTERVAL"] = "3600"
    config = ClaudeSync::Configuration.new
    assert_equal 3600, config.interval
  end

  def test_interval_falls_back_on_invalid_value
    ENV["CLAUDE_SYNC_INTERVAL"] = "not_a_number"
    config = ClaudeSync::Configuration.new
    assert_equal 86_400, config.interval
  end

  def test_quiet_defaults_to_false
    config = ClaudeSync::Configuration.new
    refute config.quiet
  end

  def test_quiet_true_when_env_is_1
    ENV["CLAUDE_SYNC_QUIET"] = "1"
    config = ClaudeSync::Configuration.new
    assert config.quiet
  end

  def test_github_token_returns_nil_when_not_set
    config = ClaudeSync::Configuration.new
    assert_nil config.github_token
  end

  def test_github_token_returns_token_when_set
    ENV["GITHUB_TOKEN"] = "ghp_test123"
    config = ClaudeSync::Configuration.new
    assert_equal "ghp_test123", config.github_token
  end
end
