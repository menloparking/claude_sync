# frozen_string_literal: true

require "json"
require "net/http"
require "uri"

module ClaudeSync
  # Fetches gist content from the GitHub API with ETag
  # conditional requests to avoid unnecessary downloads.
  class GistClient
    API_BASE = "https://api.github.com"

    def initialize(configuration)
      @config = configuration
    end

    # Fetches the first file's content from the gist.
    #
    # Returns a hash with:
    #   :status  - :ok, :not_modified, or :error
    #   :content - the file content (when :ok)
    #   :etag    - the response ETag (when :ok)
    #   :error   - error message (when :error)
    def fetch(etag: nil)
      uri = build_uri
      request = build_request(uri, etag)
      response = execute(uri, request)
      handle_response(response)
    rescue => e
      {status: :error, error: e.message}
    end

    private

    def build_request(uri, etag)
      request = Net::HTTP::Get.new(uri)
      request["Accept"] = "application/vnd.github.v3+json"
      request["If-None-Match"] = etag if etag
      if @config.github_token
        request["Authorization"] =
          "Bearer #{@config.github_token}"
      end
      request
    end

    def build_uri
      URI("#{API_BASE}/gists/#{@config.gist_id}")
    end

    def execute(uri, request)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.open_timeout = 5
      http.read_timeout = 10
      http.request(request)
    end

    def extract_content(body)
      data = JSON.parse(body)
      files = data["files"]
      return nil if files.nil? || files.empty?

      files.values.first["content"]
    end

    def handle_ok(response)
      content = extract_content(response.body)
      if content
        {status: :ok, content: content,
         etag: response["ETag"]}
      else
        {status: :error, error: "No files in gist"}
      end
    end

    def handle_response(response)
      case response.code.to_i
      when 200 then handle_ok(response)
      when 304 then {status: :not_modified}
      else
        {status: :error,
         error: "HTTP #{response.code}: #{response.message}"}
      end
    end
  end
end
