# frozen_string_literal: true

require "claude_sync"
require "webmock/rspec"
require "tmpdir"
require "fileutils"

RSpec.configure do |config|
  config.before do
    ClaudeSync.reset_configuration!
    # Clear env vars that affect configuration
    %w[
      CLAUDE_SYNC_GIST_URL
      CLAUDE_SYNC_FILE
      CLAUDE_SYNC_INTERVAL
      CLAUDE_SYNC_QUIET
      GITHUB_TOKEN
    ].each { |key| ENV.delete(key) }
  end

  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end
end
