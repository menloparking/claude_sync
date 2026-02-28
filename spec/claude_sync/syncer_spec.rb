# frozen_string_literal: true

require "spec_helper"
require "json"

RSpec.describe ClaudeSync::Syncer do
  let(:gist_id) { "abc123" }
  let(:api_url) do
    "https://api.github.com/gists/#{gist_id}"
  end
  let(:gist_body) do
    {
      "files" => {
        "claude.md" => {"content" => "# Test content"}
      }
    }.to_json
  end

  around do |example|
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) { example.run }
    end
  end

  before do
    ENV["CLAUDE_SYNC_GIST_URL"] =
      "https://gist.github.com/user/#{gist_id}"
    ENV["CLAUDE_SYNC_QUIET"] = "1"
    ClaudeSync.reset_configuration!
  end

  describe "#sync" do
    it "returns :skipped when not configured" do
      ENV.delete("CLAUDE_SYNC_GIST_URL")
      ClaudeSync.reset_configuration!
      syncer = described_class.new
      expect(syncer.sync).to eq(:skipped)
    end

    it "writes file and returns :ok on success" do
      stub_request(:get, api_url)
        .to_return(
          status: 200,
          body: gist_body,
          headers: {"ETag" => '"etag1"'}
        )

      syncer = described_class.new
      expect(syncer.sync).to eq(:ok)
      expect(File.read("claude.md")).to eq("# Test content")
    end

    it "saves metadata after successful sync" do
      stub_request(:get, api_url)
        .to_return(
          status: 200,
          body: gist_body,
          headers: {"ETag" => '"etag1"'}
        )

      described_class.new.sync

      meta = JSON.parse(
        File.read(".claude_sync_metadata.json")
      )
      expect(meta["etag"]).to eq('"etag1"')
      expect(meta["last_sync"]).not_to be_nil
    end

    it "returns :fresh within interval" do
      meta = {
        "last_sync" => Time.now.iso8601,
        "etag" => '"etag1"'
      }
      File.write(
        ".claude_sync_metadata.json",
        JSON.pretty_generate(meta)
      )

      syncer = described_class.new
      expect(syncer.sync).to eq(:fresh)
    end

    it "syncs when metadata is stale" do
      meta = {
        "last_sync" => (Time.now - 90_000).iso8601,
        "etag" => '"old_etag"'
      }
      File.write(
        ".claude_sync_metadata.json",
        JSON.pretty_generate(meta)
      )

      stub_request(:get, api_url)
        .with(
          headers: {"If-None-Match" => '"old_etag"'}
        )
        .to_return(
          status: 200,
          body: gist_body,
          headers: {"ETag" => '"new_etag"'}
        )

      syncer = described_class.new
      expect(syncer.sync).to eq(:ok)
    end

    it "returns :not_modified on 304" do
      meta = {
        "last_sync" => (Time.now - 90_000).iso8601,
        "etag" => '"etag1"'
      }
      File.write(
        ".claude_sync_metadata.json",
        JSON.pretty_generate(meta)
      )

      stub_request(:get, api_url)
        .to_return(status: 304)

      syncer = described_class.new
      expect(syncer.sync).to eq(:not_modified)
    end

    it "returns :error on fetch failure" do
      stub_request(:get, api_url)
        .to_return(status: 500, body: "Server Error")

      syncer = described_class.new
      expect(syncer.sync).to eq(:error)
    end

    it "bypasses freshness check when force is true" do
      meta = {
        "last_sync" => Time.now.iso8601,
        "etag" => '"etag1"'
      }
      File.write(
        ".claude_sync_metadata.json",
        JSON.pretty_generate(meta)
      )

      stub_request(:get, api_url)
        .to_return(
          status: 200,
          body: gist_body,
          headers: {"ETag" => '"etag2"'}
        )

      syncer = described_class.new(force: true)
      expect(syncer.sync).to eq(:ok)
    end

    it "ensures files are in .gitignore" do
      stub_request(:get, api_url)
        .to_return(
          status: 200,
          body: gist_body,
          headers: {"ETag" => '"etag1"'}
        )

      described_class.new.sync

      gitignore = File.read(".gitignore")
      expect(gitignore).to include("claude.md")
      expect(gitignore).to include(
        ".claude_sync_metadata.json"
      )
    end
  end

  describe "#status" do
    it "reports unconfigured when URL not set" do
      ENV.delete("CLAUDE_SYNC_GIST_URL")
      ClaudeSync.reset_configuration!
      syncer = described_class.new
      info = syncer.status
      expect(info[:configured]).to be false
    end

    it "reports configured with details" do
      syncer = described_class.new
      info = syncer.status
      expect(info[:configured]).to be true
      expect(info[:gist_url]).to include("abc123")
      expect(info[:file]).to eq("claude.md")
    end
  end
end
