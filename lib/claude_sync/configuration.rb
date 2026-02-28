# frozen_string_literal: true

module ClaudeSync
  # Reads sync settings from environment variables.
  #
  # Required:
  #   CLAUDE_SYNC_GIST_URL - full URL to the GitHub Gist
  #
  # Optional:
  #   CLAUDE_SYNC_FILE     - target filename (default: claude.md)
  #   CLAUDE_SYNC_INTERVAL - freshness window in seconds
  #                          (default: 86400 = 24 hours)
  #   CLAUDE_SYNC_QUIET    - suppress informational output
  #   GITHUB_TOKEN         - auth token for private gists
  class Configuration
    DEFAULT_FILE = "claude.md"
    DEFAULT_INTERVAL = 86_400

    attr_reader :file, :gist_id, :gist_url, :github_token,
      :interval, :quiet

    def initialize
      @gist_url = ENV["CLAUDE_SYNC_GIST_URL"]
      @gist_id = extract_gist_id(@gist_url)
      @file = ENV.fetch("CLAUDE_SYNC_FILE", DEFAULT_FILE)
      @interval = parse_interval
      @quiet = ENV["CLAUDE_SYNC_QUIET"] == "1"
      @github_token = ENV["GITHUB_TOKEN"]
    end

    def configured?
      !@gist_url.nil? && !@gist_url.empty?
    end

    private

    def extract_gist_id(url)
      return nil if url.nil? || url.empty?

      url.split("/").last
    end

    def parse_interval
      raw = ENV["CLAUDE_SYNC_INTERVAL"]
      return DEFAULT_INTERVAL if raw.nil? || raw.empty?

      Integer(raw)
    rescue ArgumentError
      DEFAULT_INTERVAL
    end
  end
end
