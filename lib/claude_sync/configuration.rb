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
  #   CLAUDE_SYNC_GIST_URL          - full URL to the GitHub Gist, or
  #   CLAUDE_SYNC_DRIVE_DOCUMENT_ID - Drive document ID/URL for CLAUDE.md
  #
  # Optional:
  #   CLAUDE_SYNC_AGENTS_DRIVE_DOCUMENT_ID - Drive document ID/URL for AGENTS.md
  #   CLAUDE_SYNC_DRIVE_DOCUMENT_IDS       - file:id pairs, comma-separated
  #   CLAUDE_SYNC_FILE                     - target filename (default: CLAUDE.md)
  #   CLAUDE_SYNC_FILES                    - target filenames, comma-separated
  #   CLAUDE_SYNC_INTERVAL                 - freshness window in seconds
  #                                          (default: 86400 = 24 hours)
  #   CLAUDE_SYNC_QUIET                    - suppress informational output
  #   CLAUDE_SYNC_DRIVE_TOKEN              - auth token for Drive documents
  #   CLAUDE_SYNC_DRIVE_TOKEN_FILE         - dotenv-style token file
  #   DRIVE_MENLOPARKING_TOKEN             - fallback auth token for Drive documents
  #   GITHUB_TOKEN                         - auth token for private gists
  class Configuration
    DEFAULT_FILE = "CLAUDE.md"
    DEFAULT_FILES = %w[CLAUDE.md AGENTS.md].freeze
    DEFAULT_INTERVAL = 86_400
    DOTENV_FILES = %w[.env.development .env].freeze

    attr_reader :drive_documents, :drive_token, :file, :files,
      :gist_id, :gist_url, :github_token, :interval, :quiet

    def initialize
      @dotenv = load_dotenv
      @gist_url = env("CLAUDE_SYNC_GIST_URL")
      @gist_id = extract_gist_id(@gist_url)
      @files = parse_files
      @file = @files.first
      @drive_documents = parse_drive_documents
      @drive_token = parse_drive_token
      @interval = parse_interval
      @quiet = env("CLAUDE_SYNC_QUIET") == "1"
      @github_token = env("GITHUB_TOKEN")
    end

    def configured?
      present?(@gist_url) || !@drive_documents.empty?
    end

    def drive_configured?
      !@drive_documents.empty?
    end

    def gist_configured?
      present?(@gist_url)
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

    def parse_drive_document_pairs(raw)
      raw.to_s.split(",").filter_map do |pair|
        file, id = pair.split(":", 2).map(&:strip)
        next if file.nil? || file.empty? || id.nil? || id.empty?

        [file, extract_drive_document_id(id)]
      end.to_h
    end

    def parse_drive_token
      env("CLAUDE_SYNC_DRIVE_TOKEN") ||
        env("DRIVE_MENLOPARKING_TOKEN") ||
        token_from_file(env("CLAUDE_SYNC_DRIVE_TOKEN_FILE")) ||
        token_from_file(File.expand_path("~/.config/opencode/secrets.env"))
    end

    def token_from_file(path)
      return if path.nil? || path.empty? || !File.exist?(path)

      File.foreach(path) do |line|
        key, value = line.strip.split("=", 2)
        next unless %w[CLAUDE_SYNC_DRIVE_TOKEN DRIVE_MENLOPARKING_TOKEN].include?(key)

        return value.to_s.gsub(/\A["']|["']\z/, "")
      end

      nil
    end

    def parse_drive_documents
      documents = parse_drive_document_pairs(env("CLAUDE_SYNC_DRIVE_DOCUMENT_IDS"))
      if present?(env("CLAUDE_SYNC_DRIVE_DOCUMENT_ID"))
        document_id = extract_drive_document_id(env("CLAUDE_SYNC_DRIVE_DOCUMENT_ID"))
        @files.each { |file| documents[file] = document_id }
      end
      if present?(env("CLAUDE_SYNC_AGENTS_DRIVE_DOCUMENT_ID"))
        documents["AGENTS.md"] = extract_drive_document_id(env("CLAUDE_SYNC_AGENTS_DRIVE_DOCUMENT_ID"))
      end
      documents
    end

    def parse_files
      if present?(env("CLAUDE_SYNC_FILES"))
        files = env("CLAUDE_SYNC_FILES").split(",").map(&:strip).reject(&:empty?)
        return files unless files.empty?
      end

      file = env("CLAUDE_SYNC_FILE")
      return [file] if present?(file)

      DEFAULT_FILES
    end

    def present?(value)
      !value.nil? && !value.empty?
    end

    def extract_drive_document_id(value)
      value.to_s.split("/").last
    end
  end
end
