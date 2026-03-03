# frozen_string_literal: true

module ClaudeSync
  # Minimal command-line interface for standalone use
  # outside of Rails/Rake.
  #
  # Commands:
  #   fetch  - fetch (respects freshness)
  #   force  - fetch regardless of freshness
  #   status - show current state
  class CLI
    def run(args = ARGV)
      command = args.first || "fetch"

      case command
      when "fetch" then do_fetch(force: false)
      when "force" then do_fetch(force: true)
      when "status" then show_status
      else usage
      end
    end

    private

    def do_fetch(force:)
      result = Syncer.new(force: force).sync
      puts "claude_sync: #{result}"
      exit((result == :error) ? 1 : 0)
    end

    def print_configured(info)
      puts "claude_sync status:"
      puts "  Gist URL:  #{info[:gist_url]}"
      puts "  File:      #{info[:file]}"
      puts "  Last sync: #{info[:last_sync] || "never"}"
      puts "  ETag:      #{info[:etag] || "none"}"
    end

    def print_unconfigured
      puts "claude_sync: not configured"
      puts "  Set CLAUDE_SYNC_GIST_URL to enable."
    end

    def show_status
      info = Syncer.new.status
      if info[:configured]
        print_configured(info)
      else
        print_unconfigured
      end
    end

    def usage
      puts "Usage: claude-sync [fetch|force|status]"
      exit 1
    end
  end
end
