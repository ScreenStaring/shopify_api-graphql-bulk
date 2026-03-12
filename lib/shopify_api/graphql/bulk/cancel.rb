# frozen_string_literal: true

module ShopifyAPI
  module GraphQL
    module Bulk
      class Cancel < ShopifyAPI::GraphQL::Request  # :nodoc:
        BULK_OPERATION_CANCEL = <<~GQL
          #{BULK_OPERATION_FIELDS}
          mutation bulkOperationCancel($id: ID!) {
            bulkOperationCancel(id: $id) {
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

        def execute(id, options = nil)
          begin
            data = super(BULK_OPERATION_CANCEL, :id => id).dig(:data, :bulk_operation_cancel, :bulk_operation)
          rescue => e
            raise Error, "cancel request failed: #{e}"
          end

          Operation.new(data, options)
        end
      end
    end
  end
end
