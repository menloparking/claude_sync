# frozen_string_literal: true

require "rake"

module ClaudeSync
  # Defines rake tasks for fetching claude.md from a gist:
  #   claude_sync:fetch       - fetch (respects freshness)
  #   claude_sync:force_fetch - fetch regardless of freshness
  #   claude_sync:status      - show current sync state
  class RakeTask
    include Rake::DSL

    def initialize
      define_tasks
    end

    private

    def define_tasks
      namespace :claude_sync do
        desc "Fetch claude.md from GitHub Gist"
        task :fetch do
          run_fetch(force: false)
        end

        desc "Force fetch claude.md (ignore freshness)"
        task :force_fetch do
          run_fetch(force: true)
        end

        desc "Show claude_sync status"
        task :status do
          show_status
        end
      end
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

    def run_fetch(force:)
      require "claude_sync"
      result = Syncer.new(force: force).sync
      puts "claude_sync: #{result}"
    end

    def show_status
      require "claude_sync"
      info = Syncer.new.status
      print_status(info)
    end
  end
end
