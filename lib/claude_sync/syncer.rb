# frozen_string_literal: true

require "json"
require "time"

module ClaudeSync
  # Orchestrates the sync: checks freshness, fetches the
  # gist, writes the target file, and saves metadata.
  #
  # Return values:
  #   :ok           - new content written
  #   :fresh        - within the freshness interval
  #   :not_modified - gist unchanged (ETag match)
  #   :skipped      - CLAUDE_SYNC_GIST_URL not set
  #   :error        - fetch or write failed
  class Syncer
    METADATA_FILE = ".claude_sync_metadata.json"

    def initialize(
      configuration: ClaudeSync.configuration,
      force: false
    )
      @config = configuration
      @force = force
      @client = GistClient.new(@config)
    end

    def sync
      return :skipped unless @config.configured?

      GitIgnoreManager.new(@config.file).ensure_ignored

      return :fresh if !@force && fresh?

      result = @client.fetch(etag: stored_etag)
      handle_result(result)
    rescue => e
      log("Error: #{e.message}")
      :error
    end

    # Returns a hash of metadata for status display.
    def status
      return {configured: false} unless @config.configured?

      meta = load_metadata
      {
        configured: true,
        gist_url: @config.gist_url,
        file: @config.file,
        last_sync: meta["last_sync"],
        etag: meta["etag"]
      }
    end

    private

    # Not fresh if the target file is missing on disk,
    # even when the metadata timestamp says otherwise.
    def fresh?
      return false unless File.exist?(@config.file)

      meta = load_metadata
      last = meta["last_sync"]
      return false if last.nil?

      elapsed = Time.now - Time.parse(last)
      elapsed < @config.interval
    end

    def handle_not_modified
      touch_metadata
      log("Already up to date.")
      :not_modified
    end

    def handle_ok(result)
      File.write(@config.file, result[:content])
      save_metadata(result[:etag])
      log("Synced #{@config.file} from gist.")
      :ok
    end

    def handle_result(result)
      case result[:status]
      when :ok then handle_ok(result)
      when :not_modified then handle_not_modified
      else
        log("Sync error: #{result[:error]}")
        :error
      end
    end

    def load_metadata
      return {} unless File.exist?(METADATA_FILE)

      JSON.parse(File.read(METADATA_FILE))
    rescue JSON::ParserError
      {}
    end

    def log(message)
      return if @config.quiet

      warn("[claude_sync] #{message}")
    end

    def save_metadata(etag)
      data = {
        "last_sync" => Time.now.iso8601,
        "etag" => etag
      }
      File.write(METADATA_FILE, JSON.pretty_generate(data))
    end

    def stored_etag
      load_metadata["etag"]
    end

    # Update last_sync without changing the etag, so the
    # freshness window resets on 304 Not Modified.
    def touch_metadata
      meta = load_metadata
      meta["last_sync"] = Time.now.iso8601
      File.write(METADATA_FILE, JSON.pretty_generate(meta))
    end
  end
end
