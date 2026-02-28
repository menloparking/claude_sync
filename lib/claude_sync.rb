# frozen_string_literal: true

require_relative "claude_sync/configuration"
require_relative "claude_sync/gist_client"
require_relative "claude_sync/git_ignore_manager"
require_relative "claude_sync/syncer"
require_relative "claude_sync/version"

# Syncs a project's claude.md from a GitHub Gist, keeping
# Claude Code instructions consistent across dev containers
# and local environments.
module ClaudeSync
  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.reset_configuration!
    @configuration = nil
  end
end
