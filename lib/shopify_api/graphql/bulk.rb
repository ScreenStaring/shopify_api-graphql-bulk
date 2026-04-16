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
          raise ArgumentError, "shop required" if shop.to_s.strip.empty?
          raise ArgumentError, "token required" if token.to_s.strip.empty?

          @gid = TinyGID.new("shopify")

          @mutation = Bulk::Mutation.new(shop, token, options)
          @cancel = Bulk::Cancel.new(shop, token, options)
          @query = Bulk::Query.new(shop, token, options)
          @result = Bulk::Result.new(shop, token, options)
        end

        def mutation(mutation, data = nil, &block)
          @mutation.execute(mutation, data, &block)
        end

        alias create mutation

        def query(query, options = nil)
          @query.execute(query, options)
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

require_relative "bulk/mutation"
require_relative "bulk/query"
require_relative "bulk/result"
require_relative "bulk/cancel"
require_relative "bulk/operation"
