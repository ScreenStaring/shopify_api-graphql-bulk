require "spec_helper"

RSpec.describe ShopifyAPI::GraphQL::Bulk, :vcr do
  subject do
    described_class.new(
      ENV.fetch("SHOPIFY_DOMAIN"),
      ENV.fetch("SHOPIFY_TOKEN"),
      :version => "2026-01"
    )
  end

  before do
    @mutation = <<~GQL
      mutation productSet($input: ProductSetInput!, $identifier: ProductSetIdentifiers) {
        productSet(input: $input, identifier: $identifier) {
          product {
            id
          }
          userErrors {
            field
            message
          }
        }
      }
    GQL

    @params = [
      :identifier => { :handle => "handle-1" },
      :input => {
        :title => "My New Title",
        :handle => "handle-1",
        :productOptions => [
          :name => "Title",
          :values => [:name => "Default Title"]
        ],
        :variants => [
          :sku => "SKU-001",
          :optionValues => [
            :optionName => "Title",
            :name => "Default Title"
          ]
        ]
      }
    ]
  end

  describe "#mutation" do
    it "raises an ArgumentError when no bulk data is provided" do
      expect { subject.create(@mutation)  }.to raise_error(ArgumentError, /no data proviced to upload/)
      expect { subject.create(@mutation) { |m| }  }.to raise_error(ArgumentError, /no data proviced to upload/)
    end

    # Match on :uri because we make a multi-part request and I'm to lazy to do it another way
    it "returns an Operation with the result's properties", :vcr => { :match_requests_on => [:uri] } do
      op = subject.create(@mutation, @params)

      expect(op).to be_created
      expect(op).to have_attributes(
        :id => match(%r{\Agid://shopify/BulkOperation/\d+\z}),
        :error_code => nil,
        :object_count => "0",
        :partial_data_url => nil,
        :root_object_count => "0",
        :created_at => an_instance_of(Time),
        :completed_at => nil,
        :url => nil
      )
    end
  end

  describe "#query" do
    # TODO: test :group_objects option
    it "returns an Operation with the result's properties", :vcr => { :match_requests_on => [:uri] } do
      query=<<-GQL
        query {
          products {
            edges {
              node {
                id
              }
            }
          }
        }
      GQL

      op = subject.query(query)

      expect(op).to be_created
      expect(op).to have_attributes(
        :id => match(%r{\Agid://shopify/BulkOperation/\d+\z}),
        :error_code => nil,
        :object_count => "0",
        :partial_data_url => nil,
        :root_object_count => "0",
        :created_at => an_instance_of(Time),
        :completed_at => nil,
        :url => nil
      )
    end
  end

  describe "#cancel" do
    it "cancels the operation and returns an Operation with the result's properties", :vcr => { :match_requests_on => [:uri] } do
      created = subject.create(@mutation, @params)
      op = subject.cancel(created.id)

      expect(op).to be_canceling
      expect(op).to have_attributes(
        :error_code => nil,
        :object_count => "0",
        :partial_data_url => nil,
        :root_object_count => "0",
        :created_at => an_instance_of(Time),
        :completed_at => nil,
        :url => nil,
        :results => nil
      )
    end

    it "raises an error when the result cannot be canceled" do
      expect {
        subject.cancel(ENV.fetch("BULK_SUCCESS_ID"))
      }.to raise_error(ShopifyAPI::GraphQL::Bulk::Error, /cancel request failed/)
    end

    # TODO
    # it "returns an Operation with the parsed partial result data" do
    # end

    # it "returns an Operation that does not parse the partial result data" do
    # end
  end

  describe "#result" do
    context "when the operation failed" do
      it "returns an Operation with the result's properties" do
        op = subject.result(ENV.fetch("BULK_FAILED_ID_USER_ERRORS"))

        expect(op.id).to match("gid://shopify/BulkOperation/#{ENV["BULK_FAILED_ID_USER_ERRORS"]}")
        expect(op).to be_completed
        expect(op).to have_attributes(
          :error_code => nil,
          :object_count => "1",
          :partial_data_url => nil,
          :root_object_count => "1",
          :created_at => an_instance_of(Time),
          :completed_at => an_instance_of(Time),
          :url => start_with("https://storage.googleapis.com/")
        )
      end

      it "returns parsed user errors" do
        op = subject.result(ENV.fetch("BULK_FAILED_ID_USER_ERRORS"))

        expect(op.results.size).to eq 1
        expect(op.results[0]).to have_attributes(
          :line => 0,
          :data => {},
          :errors => [],
          :user_errors => [
            {
              :field => %w[query],
              :message => "Variable $input of type ProductSetInput! was provided invalid value for productOptions.0.optionName (Field is not defined on OptionSetInput)"
            },
            {
              :field => %w[query],
              :message =>"Variable $identifier of type ProductSetIdentifiers was provided invalid value"
            }
          ]
        )
      end

      it "returns parsed errors" do
        op = subject.result(ENV.fetch("BULK_FAILED_ID_ERRORS"))

        expect(op.results.size).to eq 1
        expect(op.results[0]).to have_attributes(
          :line => 0,
          :data => nil,
          :errors => [{ :message => "OptionSetInput requires at least one of id, name" }],
          :user_errors => []
        )
      end
    end

    context "when the operation succeeded", :vcr => { :cassette_name => "ShopifyAPI::GraphQL::Bulk/#result/when the operation succeeded" } do
      it "returns an Operation with the result's properties" do
        op = subject.result(ENV.fetch("BULK_SUCCESS_ID"))

        expect(op).to be_completed
        expect(op).to have_attributes(
          :id => "gid://shopify/BulkOperation/#{ENV["BULK_SUCCESS_ID"]}",
          :error_code => nil,
          :object_count => "2",
          :partial_data_url => nil,
          :root_object_count => "2",
          :created_at => an_instance_of(Time),
          :completed_at => an_instance_of(Time),
          :url => start_with("https://storage.googleapis.com/")
        )
      end

      it "returns an Operation containing the parsed data" do
        op = subject.result(ENV.fetch("BULK_SUCCESS_ID"))

        expect(op.results.size).to eq 2
        expect(op.results[0]).to have_attributes(
          :line => 0,
          :data => {
            :product => {
              :id => match(%r{\Agid://shopify/Product/\d+\z}),
              :handle => be_a(String),
              :tags => []
            }
          },
          :errors => [],
          :user_errors => []
        )
        expect(op.results[1]).to have_attributes(
          :line => 1,
          :data => {
            :product => {
              :id => match(%r{\Agid://shopify/Product/\d+\z}),
              :handle => be_a(String),
              :tags => []
            }
          },
          :errors => [],
          :user_errors => []
        )
      end

      it "returns an Operation that does not contain the parsed data" do
        op = subject.result(ENV.fetch("BULK_SUCCESS_ID"), :parse_results => false)
        expect(op.results).to be_nil
      end
    end

    # context "when the operation is pending" do
    #   it "returns an Operation with the result's properties" do
    #     expect(op).to be_created
    #   end
    # end
  end
end
