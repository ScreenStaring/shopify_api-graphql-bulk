# frozen_string_literal: true

require "time"

module ShopifyAPI
  module GraphQL
    module Bulk
      class Operation
        STATUSES = %w[
          CANCELED
          CANCELING
          COMPLETED
          CREATED
          EXPIRED
          FAILED
          RUNNING
        ].freeze

        STATUSES.each do |status|
          define_method("#{status.downcase}?") do
            self.status == status
          end
        end

        [
          :id,
          :status,
          :error_code,
          :object_count,
          :partial_data_url,
          :root_object_count,
          :url
        ].each do |name|
          define_method(name) { @data[name] }
        end

        attr_reader :results, :created_at, :completed_at

        def initialize(data, options = nil)
          options ||= {}

          url = data[:url] || data[:partial_data_url]

          @data = data
          @created_at = Time.parse(@data[:created_at])
          @completed_at = Time.parse(@data[:completed_at]) if @data[:completed_at]

          @results = parse_results(url) if url && options[:parse_results] != false
        end

        private

        def parse_results(url)
          response = Net::HTTP.get_response(URI(url))
          raise Error, "failed to fetch bulk operation result: unsuccessful HTTP response #{response.code}" unless response.is_a?(Net::HTTPSuccess)

          results = []

          response.body.each_line do |line|
            row = JSON.parse(line)
            entry = { :line => row["__lineNumber"] }

            if row.include?("errors")
              entry[:errors] = row["errors"].map { |e| { :message => e["message"] } }
            end

            if row["data"]
              data = row["data"].values.first

              if data
                errors = data["userErrors"] || []
                entry[:user_errors] = errors.map { |e| { :field => e["field"], :message => e["message"] } } if errors.any?
                entry[:data] = snake_case_keys(data.reject { |k, _| k == "userErrors" })
              end
            end

            results << entry
          end

          results
        end

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
