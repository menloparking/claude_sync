# frozen_string_literal: true

require "rake"

module ClaudeSync
  # Defines rake tasks for manual sync operations:
  #   claude_sync:sync       - sync (respects freshness)
  #   claude_sync:force_sync - sync regardless of freshness
  #   claude_sync:status     - show current sync state
  class RakeTask
    include Rake::DSL

    def initialize
      define_tasks
    end

    private

    def define_tasks
      namespace :claude_sync do
        desc "Sync claude.md from GitHub Gist"
        task :sync do
          run_sync(force: false)
        end

        desc "Force sync claude.md (ignore freshness)"
        task :force_sync do
          run_sync(force: true)
        end

        desc "Show claude_sync status"
        task :status do
          show_status
        end
      end
    end

    def run_sync(force:)
      require "claude_sync"
      result = Syncer.new(force: force).sync
      puts "claude_sync: #{result}"
    end

    def show_status
      require "claude_sync"
      info = Syncer.new.status
      print_status(info)
    end

    def print_status(info)
      unless info[:configured]
        puts "claude_sync: not configured"
        puts "  Set CLAUDE_SYNC_GIST_URL to enable."
        return
      end

      puts "claude_sync status:"
      puts "  Gist URL:  #{info[:gist_url]}"
      puts "  File:      #{info[:file]}"
      puts "  Last sync: #{info[:last_sync] || "never"}"
      puts "  ETag:      #{info[:etag] || "none"}"
    end
  end
end
