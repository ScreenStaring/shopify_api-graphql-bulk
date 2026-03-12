# frozen_string_literal: true

require "vcr"
require "dotenv"

require "shopify_api/graphql/bulk"

Dotenv.load(".env.test", ".env")

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

VCR.configure do |c|
  c.cassette_library_dir = "spec/fixtures/cassettes"
  c.hook_into :webmock
  c.configure_rspec_metadata!
  c.ignore_localhost = true

  if ENV["VCR_DEBUG"]
    #c.debug_logger = Logger.new('log','vcr.log').open('w')
  end

  c.default_cassette_options[:match_requests_on] = [:body]
  c.filter_sensitive_data("<X-Shopify-Access-Token>") { ENV.fetch("SHOPIFY_TOKEN") }
  c.filter_sensitive_data("<Host>") { ENV.fetch("SHOPIFY_DOMAIN") }
end
