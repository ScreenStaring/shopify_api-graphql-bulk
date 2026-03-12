# frozen_string_literal: true

require "json"
require "net/http"
require "uri"

module ShopifyAPI
  module GraphQL
    module Bulk
      class Result < ShopifyAPI::GraphQL::Request    # :nodoc:
        BULK_OPERATION_STATUS = <<~GQL
          #{BULK_OPERATION_FIELDS}
          query($id: ID!) {
            bulkOperation(id: $id) {
              ...BulkOperationFields
            }
          }
        GQL

        def execute(id, options = nil)
          data = super(BULK_OPERATION_STATUS, :id => id).dig(:data, :bulk_operation)
          Operation.new(data, options)
        end
      end
    end
  end
end
