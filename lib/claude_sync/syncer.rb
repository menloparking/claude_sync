# frozen_string_literal: true

require "json"
require "time"

module ClaudeSync
  # Orchestrates the sync: checks freshness, fetches the
  # source, writes target files, and saves metadata.
  #
  # Return values:
  #   :ok           - new content written
  #   :fresh        - within the freshness interval
  #   :not_modified - source unchanged (ETag match)
  #   :skipped      - no source configured
  #   :error        - fetch or write failed
  class Syncer
    METADATA_FILE = ".claude_sync_metadata.json"

    def initialize(
      configuration: ClaudeSync.configuration,
      force: false
    )
      @config = configuration
      @force = force
      @client = @config.drive_configured? ? DriveClient.new(@config) : GistClient.new(@config)
    end

    def sync
      return :skipped unless @config.configured?

      @config.files.each { |file| GitIgnoreManager.new(file).ensure_ignored }

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
        drive_documents: @config.drive_documents,
        files: @config.files,
        gist_url: @config.gist_url,
        last_sync: meta["last_sync"],
        etag: meta["etag"]
      }
    end

    private

    # Not fresh if any last-synced target file is missing on disk,
    # even when the metadata timestamp says otherwise.
    def fresh?
      meta = load_metadata
      files = meta["files"] || [@config.file]
      return false unless meta["source_key"] == source_key
      return false unless files.all? { |file| File.exist?(file) }

      last = meta["last_sync"]
      return false if last.nil?

      elapsed = Time.now - Time.parse(last)
      elapsed < @config.interval
    end

    # When the server says 304 but the file is gone from
    # disk, re-fetch without the ETag to get full content.
    def handle_not_modified
      files = load_metadata["files"] || [@config.file]
      unless files.all? { |file| File.exist?(file) }
        result = @client.fetch(etag: nil)
        return handle_ok(result) if result[:status] == :ok

        log("Retry failed: #{result[:error] || result[:status]}")
        return :error
      end

      touch_metadata
      log("Already up to date.")
      :not_modified
    end

    def handle_ok(result)
      contents = result[:contents] || {@config.file => result[:content]}
      contents.each { |file, content| File.write(file, content) }
      save_metadata(result[:etag], contents.keys)
      log("Synced #{contents.keys.join(", ")} from #{@config.drive_configured? ? "Drive" : "gist"}.")
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

    def save_metadata(etag, files)
      data = {
        "files" => files,
        "last_sync" => Time.now.iso8601,
        "source_key" => source_key,
        "etag" => etag
      }
      File.write(METADATA_FILE, JSON.pretty_generate(data))
    end

    def stored_etag
      load_metadata["etag"]
    end

    def source_key
      if @config.drive_configured?
        ["drive", @config.drive_documents.sort].inspect
      else
        ["gist", @config.gist_url, @config.files].inspect
      end
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
