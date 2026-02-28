# frozen_string_literal: true

require "spec_helper"

RSpec.describe ClaudeSync::Configuration do
  describe "#configured?" do
    it "returns false when CLAUDE_SYNC_GIST_URL is not set" do
      config = described_class.new
      expect(config.configured?).to be false
    end

    it "returns false when CLAUDE_SYNC_GIST_URL is empty" do
      ENV["CLAUDE_SYNC_GIST_URL"] = ""
      config = described_class.new
      expect(config.configured?).to be false
    end

    it "returns true when CLAUDE_SYNC_GIST_URL is set" do
      ENV["CLAUDE_SYNC_GIST_URL"] =
        "https://gist.github.com/user/abc123"
      config = described_class.new
      expect(config.configured?).to be true
    end
  end

  describe "#gist_id" do
    it "extracts gist ID from URL" do
      ENV["CLAUDE_SYNC_GIST_URL"] =
        "https://gist.github.com/user/abc123"
      config = described_class.new
      expect(config.gist_id).to eq("abc123")
    end

    it "returns nil when URL is not set" do
      config = described_class.new
      expect(config.gist_id).to be_nil
    end
  end

  describe "#file" do
    it "defaults to claude.md" do
      config = described_class.new
      expect(config.file).to eq("claude.md")
    end

    it "uses CLAUDE_SYNC_FILE when set" do
      ENV["CLAUDE_SYNC_FILE"] = "AGENTS.md"
      config = described_class.new
      expect(config.file).to eq("AGENTS.md")
    end
  end

  describe "#interval" do
    it "defaults to 86400 seconds" do
      config = described_class.new
      expect(config.interval).to eq(86_400)
    end

    it "uses CLAUDE_SYNC_INTERVAL when set" do
      ENV["CLAUDE_SYNC_INTERVAL"] = "3600"
      config = described_class.new
      expect(config.interval).to eq(3600)
    end

    it "falls back to default on invalid value" do
      ENV["CLAUDE_SYNC_INTERVAL"] = "not_a_number"
      config = described_class.new
      expect(config.interval).to eq(86_400)
    end
  end

  describe "#quiet" do
    it "defaults to false" do
      config = described_class.new
      expect(config.quiet).to be false
    end

    it "is true when CLAUDE_SYNC_QUIET is 1" do
      ENV["CLAUDE_SYNC_QUIET"] = "1"
      config = described_class.new
      expect(config.quiet).to be true
    end
  end

  describe "#github_token" do
    it "returns nil when GITHUB_TOKEN is not set" do
      config = described_class.new
      expect(config.github_token).to be_nil
    end

    it "returns the token when GITHUB_TOKEN is set" do
      ENV["GITHUB_TOKEN"] = "ghp_test123"
      config = described_class.new
      expect(config.github_token).to eq("ghp_test123")
    end
  end
end
