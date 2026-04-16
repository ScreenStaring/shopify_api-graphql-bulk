# frozen_string_literal: true

module ShopifyAPI
  module GraphQL
    module Bulk
      class Query < ShopifyAPI::GraphQL::Request  # :nodoc:
        BULK_OPERATION_RUN_QUERY = <<~GQL
          #{BULK_OPERATION_FIELDS}
          mutation bulkOperationRunQuery($query: String! $groupObjects: Boolean!) {
            bulkOperationRunQuery(query: $query groupObjects: $groupObjects) {
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

        def execute(query, options = nil)
          raise ArgumentError, "query required" if query.to_s.strip.empty?

          options ||= {}

          begin
            data = super(
              BULK_OPERATION_RUN_QUERY,
              :query => query,
              :group_objects => options[:group_objects] != false
            ).dig(:data, :bulk_operation_run_query, :bulk_operation)
          rescue => e
            raise Error, "bulk run query request failed: #{e}"
          end

          Operation.new(data, options)
        end
      end
    end
  end
end
