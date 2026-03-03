# frozen_string_literal: true

require "test_helper"
require "json"

class SyncerTest < Minitest::Test
  GIST_ID = "abc123"
  API_URL = "https://api.github.com/gists/#{GIST_ID}"

  GIST_BODY = {
    "files" => {
      "claude.md" => {"content" => "# Test content"}
    }
  }.to_json

  def setup
    super
    @tmpdir = Dir.mktmpdir
    @original_dir = Dir.pwd
    Dir.chdir(@tmpdir)

    ENV["CLAUDE_SYNC_GIST_URL"] =
      "https://gist.github.com/user/#{GIST_ID}"
    ENV["CLAUDE_SYNC_QUIET"] = "1"
    ClaudeSync.reset_configuration!
  end

  def teardown
    Dir.chdir(@original_dir)
    FileUtils.remove_entry(@tmpdir)
    super
  end

  def test_sync_returns_skipped_when_not_configured
    ENV.delete("CLAUDE_SYNC_GIST_URL")
    ClaudeSync.reset_configuration!
    syncer = ClaudeSync::Syncer.new
    assert_equal :skipped, syncer.sync
  end

  def test_sync_writes_file_and_returns_ok
    stub_request(:get, API_URL)
      .to_return(
        status: 200,
        body: GIST_BODY,
        headers: {"ETag" => '"etag1"'}
      )

    syncer = ClaudeSync::Syncer.new
    assert_equal :ok, syncer.sync
    assert_equal "# Test content", File.read("claude.md")
  end

  def test_sync_saves_metadata
    stub_request(:get, API_URL)
      .to_return(
        status: 200,
        body: GIST_BODY,
        headers: {"ETag" => '"etag1"'}
      )

    ClaudeSync::Syncer.new.sync

    meta = JSON.parse(
      File.read(".claude_sync_metadata.json")
    )
    assert_equal '"etag1"', meta["etag"]
    refute_nil meta["last_sync"]
  end

  def test_sync_returns_fresh_within_interval
    meta = {
      "last_sync" => Time.now.iso8601,
      "etag" => '"etag1"'
    }
    File.write(
      ".claude_sync_metadata.json",
      JSON.pretty_generate(meta)
    )

    syncer = ClaudeSync::Syncer.new
    assert_equal :fresh, syncer.sync
  end

  def test_sync_when_metadata_is_stale
    meta = {
      "last_sync" => (Time.now - 90_000).iso8601,
      "etag" => '"old_etag"'
    }
    File.write(
      ".claude_sync_metadata.json",
      JSON.pretty_generate(meta)
    )

    stub_request(:get, API_URL)
      .with(
        headers: {"If-None-Match" => '"old_etag"'}
      )
      .to_return(
        status: 200,
        body: GIST_BODY,
        headers: {"ETag" => '"new_etag"'}
      )

    syncer = ClaudeSync::Syncer.new
    assert_equal :ok, syncer.sync
  end

  def test_sync_returns_not_modified_on_304
    meta = {
      "last_sync" => (Time.now - 90_000).iso8601,
      "etag" => '"etag1"'
    }
    File.write(
      ".claude_sync_metadata.json",
      JSON.pretty_generate(meta)
    )

    stub_request(:get, API_URL)
      .to_return(status: 304)

    syncer = ClaudeSync::Syncer.new
    assert_equal :not_modified, syncer.sync
  end

  def test_sync_returns_error_on_fetch_failure
    stub_request(:get, API_URL)
      .to_return(status: 500, body: "Server Error")

    syncer = ClaudeSync::Syncer.new
    assert_equal :error, syncer.sync
  end

  def test_sync_bypasses_freshness_when_forced
    meta = {
      "last_sync" => Time.now.iso8601,
      "etag" => '"etag1"'
    }
    File.write(
      ".claude_sync_metadata.json",
      JSON.pretty_generate(meta)
    )

    stub_request(:get, API_URL)
      .to_return(
        status: 200,
        body: GIST_BODY,
        headers: {"ETag" => '"etag2"'}
      )

    syncer = ClaudeSync::Syncer.new(force: true)
    assert_equal :ok, syncer.sync
  end

  def test_sync_ensures_files_in_gitignore
    stub_request(:get, API_URL)
      .to_return(
        status: 200,
        body: GIST_BODY,
        headers: {"ETag" => '"etag1"'}
      )

    ClaudeSync::Syncer.new.sync

    gitignore = File.read(".gitignore")
    assert_includes gitignore, "claude.md"
    assert_includes gitignore, ".claude_sync_metadata.json"
  end

  def test_status_reports_unconfigured
    ENV.delete("CLAUDE_SYNC_GIST_URL")
    ClaudeSync.reset_configuration!
    syncer = ClaudeSync::Syncer.new
    info = syncer.status
    refute info[:configured]
  end

  def test_status_reports_configured_with_details
    syncer = ClaudeSync::Syncer.new
    info = syncer.status
    assert info[:configured]
    assert_includes info[:gist_url], "abc123"
    assert_equal "claude.md", info[:file]
  end
end
