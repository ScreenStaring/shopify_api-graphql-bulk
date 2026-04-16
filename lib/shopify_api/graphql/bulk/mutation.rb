# frozen_string_literal: true

require "json"
require "net/http"
require "net/http/post/multipart"
require "tempfile"
require "uri"

module ShopifyAPI
  module GraphQL
    module Bulk
      class Mutation < ShopifyAPI::GraphQL::Request  # :nodoc:
        FILENAME = "bulk_import.jsonl"

        STAGED_UPLOADS_CREATE = <<~GQL
          mutation stagedUploadsCreate($input: [StagedUploadInput!]!) {
            stagedUploadsCreate(input: $input) {
              stagedTargets {
                url
                resourceUrl
                parameters {
                  name
                  value
                }
              }
              userErrors {
                field
                message
              }
            }
          }
        GQL

        BULK_OPERATION_RUN_MUTATION = <<~GQL
          #{BULK_OPERATION_FIELDS}
          mutation bulkOperationRunMutation($mutation: String!, $stagedUploadPath: String!) {
            bulkOperationRunMutation(mutation: $mutation, stagedUploadPath: $stagedUploadPath) {
              bulkOperation {
                ...BulkOperationFields
              }
              userErrors {
                field
                message
              }
            }
          }
        GQL

        def initialize(shop, token, options = nil)
          super

          @shop = shop
          @token = token
          @file = Tempfile.new([self.class.name, ".jsonl"])
        end

        def execute(mutation, data = nil)
          @file.truncate(0)
          @file.rewind

          @mutation = mutation

          Array(data).map { |d| self << d } if data
          yield self if block_given?

          @file.flush
          raise ArgumentError, "no data proviced to upload" if @file.size == 0

          input = [
            :resource => "BULK_MUTATION_VARIABLES",
            :filename => FILENAME,
            :mime_type => "text/jsonl",
            :http_method => "POST",
            :file_size => @file.size.to_s
          ]

          begin
            target = super(STAGED_UPLOADS_CREATE, :input => input).dig(:data, :staged_uploads_create, :staged_targets, 0)
          rescue => e
            raise Error, "stage upload request failed: #{e.message}"
          end

          upload_jsonl(target)
          upload_path = target[:parameters].find { |p| p[:name] == :key }

          begin
            data = super(BULK_OPERATION_RUN_MUTATION, :mutation => @mutation, :staged_upload_path => upload_path)
            Operation.new(data.dig(:data, :bulk_operation_run_mutation, :bulk_operation))
          rescue => e
            raise Error, "bulk run mutation request failed: #{e.message}"
          end
        end

        def <<(data)
          @file.puts(JSON.generate(data))
          nil
        end

        private

        def stage_upload
        end

        def upload_jsonl(target)
          uri = URI(target[:url])
          @file.rewind
          io = UploadIO.new(@file, "text/jsonl", FILENAME)

          params = {}
          target[:parameters].each { |p| params[p[:name]] = p[:value] }
          params["file"] = io

          request = Net::HTTP::Post::Multipart.new(uri.path, params)

          http = Net::HTTP.new(uri.host, uri.port)
          http.use_ssl = true

          response = http.request(request)

          unless response.is_a?(Net::HTTPSuccess)
            raise Error, "file upload failed with status #{response.code}: #{response.body}"
          end
        end
      end
    end
  end
end
