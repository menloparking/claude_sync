# frozen_string_literal: true

require "minitest/autorun"
require "webmock/minitest"
require "tmpdir"
require "fileutils"
require "claude_sync"

# Clear env vars that affect configuration before each test
module ClaudeSyncTestSetup
  def before_setup
    super
    ClaudeSync.reset_configuration!
    %w[
      CLAUDE_SYNC_GIST_URL
      CLAUDE_SYNC_FILE
      CLAUDE_SYNC_INTERVAL
      CLAUDE_SYNC_QUIET
      GITHUB_TOKEN
    ].each { |key| ENV.delete(key) }
  end
end

Minitest::Test.prepend(ClaudeSyncTestSetup)
