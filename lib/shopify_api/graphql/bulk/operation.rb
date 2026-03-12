# frozen_string_literal: true

require "time"

require_relative "operation/result"

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
            results << Operation::Result.new(row)
          end

          results
        end
      end
    end
  end
end
