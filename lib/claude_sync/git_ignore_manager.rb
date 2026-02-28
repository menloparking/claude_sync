# frozen_string_literal: true

module ClaudeSync
  # Ensures synced files and metadata are listed in the
  # project's .gitignore so they are never committed.
  class GitIgnoreManager
    METADATA_FILE = ".claude_sync_metadata.json"

    def initialize(target_file)
      @entries = [target_file, METADATA_FILE]
    end

    # Adds missing entries to .gitignore, creating the
    # file if it does not exist.
    def ensure_ignored
      path = File.join(Dir.pwd, ".gitignore")
      existing = read_gitignore(path)
      missing = find_missing(existing)
      return if missing.empty?

      append_entries(path, existing, missing)
    end

    private

    def append_entries(path, existing, missing)
      needs_newline = !existing.empty? &&
        !existing.end_with?("\n")

      File.open(path, "a") do |f|
        f.write("\n") if needs_newline
        missing.each { |entry| f.puts(entry) }
      end
    end

    def find_missing(content)
      lines = content.lines.map(&:strip)
      @entries.reject { |entry| lines.include?(entry) }
    end

    def read_gitignore(path)
      File.exist?(path) ? File.read(path) : ""
    end
  end
end
