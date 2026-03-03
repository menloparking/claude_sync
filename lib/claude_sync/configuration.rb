# frozen_string_literal: true

module ClaudeSync
  # Reads sync settings from environment variables, falling
  # back to .env.development and .env files when a variable
  # is not present in the active environment.
  #
  # Precedence (highest to lowest):
  #   1. Active environment (ENV)
  #   2. .env.development
  #   3. .env
  #
  # Required:
  #   CLAUDE_SYNC_GIST_URL - full URL to the GitHub Gist
  #
  # Optional:
  #   CLAUDE_SYNC_FILE     - target filename (default: CLAUDE.md)
  #   CLAUDE_SYNC_INTERVAL - freshness window in seconds
  #                          (default: 86400 = 24 hours)
  #   CLAUDE_SYNC_QUIET    - suppress informational output
  #   GITHUB_TOKEN         - auth token for private gists
  class Configuration
    DEFAULT_FILE = "CLAUDE.md"
    DEFAULT_INTERVAL = 86_400
    DOTENV_FILES = %w[.env.development .env].freeze

    attr_reader :file, :gist_id, :gist_url, :github_token,
      :interval, :quiet

    def initialize
      @dotenv = load_dotenv
      @gist_url = env("CLAUDE_SYNC_GIST_URL")
      @gist_id = extract_gist_id(@gist_url)
      @file = env("CLAUDE_SYNC_FILE") || DEFAULT_FILE
      @interval = parse_interval
      @quiet = env("CLAUDE_SYNC_QUIET") == "1"
      @github_token = env("GITHUB_TOKEN")
    end

    def configured?
      !@gist_url.nil? && !@gist_url.empty?
    end

    private

    # Looks up a key in the active environment first, then
    # falls back to values parsed from dotenv files.
    def env(key)
      ENV[key] || @dotenv[key]
    end

    def extract_gist_id(url)
      return nil if url.nil? || url.empty?

      url.split("/").last
    end

    # Parses .env.development and .env into a single hash.
    # More-specific files are loaded first so their values
    # take precedence over less-specific ones.
    def load_dotenv
      result = {}
      DOTENV_FILES.reverse_each do |path|
        parse_dotenv_file(path).each { |k, v| result[k] = v }
      end
      result
    end

    def parse_dotenv_file(path)
      return {} unless File.exist?(path)

      pairs = {}
      File.foreach(path) do |line|
        line = line.strip
        next if line.empty? || line.start_with?("#")

        # Strip inline comments, then split on first =
        key, value = line.split("=", 2)
        next if key.nil? || value.nil?

        key = key.strip
        value = value.strip
        # Strip surrounding quotes if present
        value = value[1..-2] if value.match?(/\A["'].*["']\z/)
        # Strip export prefix
        key = key.sub(/\Aexport\s+/, "")
        pairs[key] = value
      end
      pairs
    end

    def parse_interval
      raw = env("CLAUDE_SYNC_INTERVAL")
      return DEFAULT_INTERVAL if raw.nil? || raw.empty?

      Integer(raw)
    rescue ArgumentError
      DEFAULT_INTERVAL
    end
  end
end
