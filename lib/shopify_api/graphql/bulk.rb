# frozen_string_literal: true

require "shopify_api/graphql/request"
require "tiny_gid"

require_relative "bulk/version"

module ShopifyAPI
  module GraphQL
    module Bulk
      Error = Class.new(Request::Error)

      BULK_OPERATION_FIELDS = <<~GQL
        fragment BulkOperationFields on BulkOperation {
          id
          status
          errorCode
          objectCount
          partialDataUrl
          rootObjectCount
          url
          createdAt
          completedAt
        }
      GQL

      class << self
        def new(shop, token, options = nil)
          Executor.new(shop, token, options)
        end
      end

      class Executor            # :nodoc:
        def initialize(shop, token, options)
          @gid = TinyGID.new("shopify")

          @create = Bulk::Create.new(shop, token, options)
          @cancel = Bulk::Cancel.new(shop, token, options)
          @result = Bulk::Result.new(shop, token, options)
        end

        def create(mutation, data = nil, &block)
          @create.execute(mutation, data, &block)
        end

        def result(id, options = nil)
          @result.execute(to_gid(id), options)
        end

        def cancel(id)
          @cancel.execute(to_gid(id), options = nil)
        end

        private

        def to_gid(id)
          return id if id.to_s.start_with?("gid://")

          @gid::BulkOperation(id)
        end
      end

      private_constant :Executor
    end
  end
end

require_relative "bulk/create"
require_relative "bulk/result"
require_relative "bulk/cancel"
require_relative "bulk/operation"
