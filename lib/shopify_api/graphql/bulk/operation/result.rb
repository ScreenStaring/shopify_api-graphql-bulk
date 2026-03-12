# frozen_string_literal: true

module ShopifyAPI
  module GraphQL
    module Bulk
      class Operation
        class Result
          attr_reader :line, :data, :errors, :user_errors

          def initialize(row)
            @errors = []
            @user_errors = []

            @line = row["__lineNumber"]

            if row.include?("errors")
              @errors = row["errors"].map { |e| { :message => e["message"] } }
            end

            if row["data"]
              data = row["data"].values.first
              if data
                errors = data["userErrors"] || []
                @user_errors = errors.map { |e| { :field => e["field"], :message => e["message"] } } if errors.any?
                @data = snake_case_keys(data.reject { |k, _| k == "userErrors" })
              end
            end
          end

          private

          def snake_case_keys(object)
            case object
            when Hash
              object.each_with_object({}) do |(key, value), result|
                result[Strings::Case.snakecase(key).to_sym] = snake_case_keys(value)
              end
            when Array
              object.map { |value| snake_case_keys(value) }
            else
              object
            end
          end
        end
      end
    end
  end
end
