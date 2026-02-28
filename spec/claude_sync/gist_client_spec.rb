# frozen_string_literal: true

require "spec_helper"

RSpec.describe ClaudeSync::GistClient do
  let(:gist_id) { "abc123" }
  let(:config) do
    ENV["CLAUDE_SYNC_GIST_URL"] =
      "https://gist.github.com/user/#{gist_id}"
    ClaudeSync::Configuration.new
  end
  let(:client) { described_class.new(config) }
  let(:api_url) do
    "https://api.github.com/gists/#{gist_id}"
  end

  let(:gist_response) do
    {
      "files" => {
        "claude.md" => {
          "content" => "# Instructions\nDo things."
        }
      }
    }.to_json
  end

  describe "#fetch" do
    it "returns content on 200" do
      stub_request(:get, api_url)
        .to_return(
          status: 200,
          body: gist_response,
          headers: {"ETag" => '"etag123"'}
        )

      result = client.fetch
      expect(result[:status]).to eq(:ok)
      expect(result[:content]).to eq(
        "# Instructions\nDo things."
      )
      expect(result[:etag]).to eq('"etag123"')
    end

    it "returns :not_modified on 304" do
      stub_request(:get, api_url)
        .to_return(status: 304)

      result = client.fetch(etag: '"etag123"')
      expect(result[:status]).to eq(:not_modified)
    end

    it "sends If-None-Match header when etag given" do
      stub = stub_request(:get, api_url)
        .with(headers: {"If-None-Match" => '"etag123"'})
        .to_return(status: 304)

      client.fetch(etag: '"etag123"')
      expect(stub).to have_been_requested
    end

    it "returns :error on 404" do
      stub_request(:get, api_url)
        .to_return(status: 404, body: "Not Found")

      result = client.fetch
      expect(result[:status]).to eq(:error)
      expect(result[:error]).to include("404")
    end

    it "returns :error on network failure" do
      stub_request(:get, api_url)
        .to_raise(SocketError.new("getaddrinfo"))

      result = client.fetch
      expect(result[:status]).to eq(:error)
      expect(result[:error]).to include("getaddrinfo")
    end

    it "returns :error when gist has no files" do
      stub_request(:get, api_url)
        .to_return(
          status: 200,
          body: {"files" => {}}.to_json
        )

      result = client.fetch
      expect(result[:status]).to eq(:error)
      expect(result[:error]).to include("No files")
    end

    it "sends Authorization header when token set" do
      ENV["CLAUDE_SYNC_GIST_URL"] =
        "https://gist.github.com/user/#{gist_id}"
      ENV["GITHUB_TOKEN"] = "ghp_test"
      config_with_token = ClaudeSync::Configuration.new
      authed_client = described_class.new(config_with_token)

      stub = stub_request(:get, api_url)
        .with(
               headers: {"Authorization" => "Bearer ghp_test"}
             )
        .to_return(
          status: 200,
          body: gist_response,
          headers: {"ETag" => '"etag456"'}
        )

      authed_client.fetch
      expect(stub).to have_been_requested
    end
  end
end
