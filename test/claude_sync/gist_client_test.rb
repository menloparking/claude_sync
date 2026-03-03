# frozen_string_literal: true

require "test_helper"

class GistClientTest < Minitest::Test
  GIST_ID = "abc123"
  API_URL = "https://api.github.com/gists/#{GIST_ID}"

  GIST_RESPONSE = {
    "files" => {
      "claude.md" => {
        "content" => "# Instructions\nDo things."
      }
    }
  }.to_json

  def setup
    super
    ENV["CLAUDE_SYNC_GIST_URL"] =
      "https://gist.github.com/user/#{GIST_ID}"
    @config = ClaudeSync::Configuration.new
    @client = ClaudeSync::GistClient.new(@config)
  end

  def test_fetch_returns_content_on_200
    stub_request(:get, API_URL)
      .to_return(
        status: 200,
        body: GIST_RESPONSE,
        headers: {"ETag" => '"etag123"'}
      )

    result = @client.fetch
    assert_equal :ok, result[:status]
    assert_equal "# Instructions\nDo things.", result[:content]
    assert_equal '"etag123"', result[:etag]
  end

  def test_fetch_returns_not_modified_on_304
    stub_request(:get, API_URL)
      .to_return(status: 304)

    result = @client.fetch(etag: '"etag123"')
    assert_equal :not_modified, result[:status]
  end

  def test_fetch_sends_if_none_match_header
    stub = stub_request(:get, API_URL)
      .with(headers: {"If-None-Match" => '"etag123"'})
      .to_return(status: 304)

    @client.fetch(etag: '"etag123"')
    assert_requested(stub)
  end

  def test_fetch_returns_error_on_404
    stub_request(:get, API_URL)
      .to_return(status: 404, body: "Not Found")

    result = @client.fetch
    assert_equal :error, result[:status]
    assert_includes result[:error], "404"
  end

  def test_fetch_returns_error_on_network_failure
    stub_request(:get, API_URL)
      .to_raise(SocketError.new("getaddrinfo"))

    result = @client.fetch
    assert_equal :error, result[:status]
    assert_includes result[:error], "getaddrinfo"
  end

  def test_fetch_returns_error_when_gist_has_no_files
    stub_request(:get, API_URL)
      .to_return(
        status: 200,
        body: {"files" => {}}.to_json
      )

    result = @client.fetch
    assert_equal :error, result[:status]
    assert_includes result[:error], "No files"
  end

  def test_fetch_sends_authorization_header_with_token
    ENV["GITHUB_TOKEN"] = "ghp_test"
    config_with_token = ClaudeSync::Configuration.new
    authed_client =
      ClaudeSync::GistClient.new(config_with_token)

    stub = stub_request(:get, API_URL)
      .with(
             headers: {"Authorization" => "Bearer ghp_test"}
           )
      .to_return(
        status: 200,
        body: GIST_RESPONSE,
        headers: {"ETag" => '"etag456"'}
      )

    authed_client.fetch
    assert_requested(stub)
  end
end
