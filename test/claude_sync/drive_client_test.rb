# frozen_string_literal: true

require "test_helper"

class DriveClientTest < Minitest::Test
  CLAUDE_ID = "claude-doc"
  AGENTS_ID = "agents-doc"
  CLAUDE_URL = "https://drive.menloparking.com/api/v1/documents/#{CLAUDE_ID}"
  AGENTS_URL = "https://drive.menloparking.com/api/v1/documents/#{AGENTS_ID}"

  def setup
    super
    ENV["CLAUDE_SYNC_DRIVE_DOCUMENT_ID"] = CLAUDE_ID
    ENV["CLAUDE_SYNC_AGENTS_DRIVE_DOCUMENT_ID"] = AGENTS_ID
    ENV["CLAUDE_SYNC_DRIVE_TOKEN"] = "drive-token"
    @config = ClaudeSync::Configuration.new
    @client = ClaudeSync::DriveClient.new(@config)
  end

  def test_fetch_returns_contents_on_200
    stub_request(:get, CLAUDE_URL)
      .to_return(status: 200, body: "# Claude", headers: {"ETag" => '"c1"'})
    stub_request(:get, AGENTS_URL)
      .to_return(status: 200, body: "# Agents", headers: {"ETag" => '"a1"'})

    result = @client.fetch
    assert_equal :ok, result[:status]
    assert_equal "# Claude", result[:contents]["CLAUDE.md"]
    assert_equal "# Agents", result[:contents]["AGENTS.md"]
    assert_equal '"c1"', result[:etag]["CLAUDE.md"]
    assert_equal '"a1"', result[:etag]["AGENTS.md"]
  end

  def test_fetch_sends_plain_text_accept_and_authorization
    stub = stub_request(:get, CLAUDE_URL)
      .with(headers: {"Accept" => "text/plain", "Authorization" => "Bearer drive-token"})
      .to_return(status: 200, body: "# Claude")
    stub_request(:get, AGENTS_URL).to_return(status: 200, body: "# Agents")

    @client.fetch
    assert_requested(stub)
  end

  def test_fetch_sends_per_file_etags
    stub = stub_request(:get, CLAUDE_URL)
      .with(headers: {"If-None-Match" => '"c1"'})
      .to_return(status: 304)
    stub_request(:get, AGENTS_URL)
      .with(headers: {"If-None-Match" => '"a1"'})
      .to_return(status: 304)

    result = @client.fetch(etag: {"CLAUDE.md" => '"c1"', "AGENTS.md" => '"a1"'})
    assert_equal :not_modified, result[:status]
    assert_requested(stub)
  end

  def test_fetch_returns_error_on_http_error
    stub_request(:get, CLAUDE_URL).to_return(status: 404, body: "Not Found")

    result = @client.fetch
    assert_equal :error, result[:status]
    assert_includes result[:error], "404"
  end
end
