# frozen_string_literal: true

require "rails/railtie"

module ClaudeSync
  # Auto-syncs claude.md on Rails boot in development and
  # test environments. Never raises, never blocks.
  class Railtie < Rails::Railtie
    initializer "claude_sync.sync" do
      Syncer.new.sync if %w[development test].include?(Rails.env)
    end

    rake_tasks do
      require "claude_sync/rake_task"
      ClaudeSync::RakeTask.new
    end
  end
end
