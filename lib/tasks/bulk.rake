require "shopify_api/graphql/bulk"

namespace :bulk do
  desc "Submit a bulk task that can be used in test cases"
  task :create do
    shop = ENV.fetch("SHOPIFY_DOMAIN")
    token = ENV.fetch("SHOPIFY_TOKEN")

    mutation = <<~GQL
      mutation productSet($input: ProductSetInput!, $identifier: ProductSetIdentifiers) {
        productSet(input: $input, identifier: $identifier) {
          product {
            id
            handle
            tags
          }
          userErrors {
            field
            message
          }
        }
      }
    GQL

    params = [
      {
        :identifier => { :handle => "handle-1" },
        :input => {
          :title => "My New Title",
          :handle => "handle-1",
          :productOptions => [
            { :name => "Title", :values => [{ :name => "Default Title" }] }
          ],
          :variants => [
            {
              :sku => "SKU-001",
              :optionValues => [
                { :optionName => "Title", :name => "Default Title" }
              ]
            }
          ]
        }
      },
      {
        :identifier => { :handle => "handle-2" },
        :input => {
          :title => "Another Title",
          :handle => "handle-2",
          :productOptions => [
            { :name => "Title", :values => [{ :name => "Default Title" }] }
          ],
          :variants => [
            {
              :sku => "SKU-002",
              :optionValues => [
                { :optionName => "Title", :name => "Default Title" }
              ]
            }
          ]
        }
      }
    ]

    bulk = ShopifyAPI::GraphQL::Bulk.new(shop, token, :version => ENV["SHOPIFY_API_VERSION"] || "2026-01")
    puts "Making bulk request..."
    puts bulk.create(mutation, params).id
  end
end
