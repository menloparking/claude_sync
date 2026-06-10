# frozen_string_literal: true

require "net/http"
require "uri"

module ClaudeSync
  # Fetches document bodies from drive.menloparking.com.
  class DriveClient
    API_BASE = "https://drive.menloparking.com/api/v1"

    def initialize(configuration)
      @config = configuration
    end

    # Returns a hash with:
    #   :status   - :ok, :not_modified, or :error
    #   :contents - hash of filename => content (when :ok)
    #   :etag     - response ETag map (when :ok)
    #   :error    - error message (when :error)
    def fetch(etag: nil)
      contents = {}
      etags = {}

      @config.drive_documents.each do |file, document_id|
        result = fetch_document(document_id, etag_for(etag, file))
        return result if result[:status] == :error

        next if result[:status] == :not_modified

        contents[file] = result[:content]
        etags[file] = result[:etag]
      end

      return {status: :not_modified} if contents.empty?

      {status: :ok, contents: contents, etag: etags}
    rescue => e
      {status: :error, error: e.message}
    end

    private

    def build_request(uri, etag)
      request = Net::HTTP::Get.new(uri)
      request["Accept"] = "text/plain"
      request["Authorization"] = "Bearer #{@config.drive_token}" if @config.drive_token
      request["If-None-Match"] = etag if etag
      request
    end

    def etag_for(etag, file)
      return etag[file] if etag.is_a?(Hash)

      etag
    end

    def execute(uri, request)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.open_timeout = 5
      http.read_timeout = 10
      http.request(request)
    end

    def fetch_document(document_id, etag)
      uri = URI("#{API_BASE}/documents/#{document_id}")
      response = execute(uri, build_request(uri, etag))
      handle_response(response)
    end

    def handle_response(response)
      case response.code.to_i
      when 200
        {status: :ok, content: response.body.to_s.dup.force_encoding("UTF-8"), etag: response["ETag"]}
      when 304
        {status: :not_modified}
      else
        {status: :error, error: "HTTP #{response.code}: #{response.message}"}
      end
    end
  end
end
