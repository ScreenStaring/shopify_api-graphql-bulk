# ShopifyAPI::GraphQL::Bulk

Ruby Gem to Bulk import data using the [Shopify GraphQL Admin Bulk API](https://shopify.dev/docs/api/usage/bulk-operations/imports)

## Install

`Gemfile`:

```rb
gem "shopify_api-graphql-bulk"
```

Or via the `gem` command:

```
gem install "shopify_api-graphql-bulk"
```

## Usage

```rb
# Mutation parameters. In this example we're using the productSet mutation.
params = [
  {
    :identifier => { :handle => "handle-1" },
    :input => {
      :title => "My New Title",
      :handle => "handle-1",
      # More params
    }
  },
  {
    :identifier => { :handle => "handle-2" },
    :input => {
      :title => "Another Title",
      :handle => "handle-2",
      # More params
    }
  },
  # etc...
]

bulk = ShopifyAPI::GraphQL::Bulk.new(shop, token)
id = bulk.create("productSet", params)

# Wait a bit...

operation = bulk.result(id)

# returns a ShopifyAPI::GraphQL::Bulk::Operation instance
p operation.id
p operation.completed_at
p operation.url
# etc...

if operation.completed?
  operation.results.each do |result|
    # Each element is a Hash with the appropriate response, if any
    result.data.each { }
    result.errors.each { }
    result.user_errors.each { }
  end
end
```

`#create` also accepts a block:

```rb
id = bulk.create("productSet") do |args|
  args << input1
  args << input2 # etc...
end
```

If you do not want the result to be fetched and parsed use `:parse_results => false`:

```rb
operation = bulk.result(id, :parse_results => false)
p operation.id
p operation.completed_at
p operation.result # now nil
```

Cancel a pending request:

```rb
operation = bulk.cancel(id) # returns a ShopifyAPI::GraphQL::Bulk::Operation instance
```

`ShopifyAPI::GraphQL::Bulk::Operation` corresponds to the GraphQL `BulkOperation` type.
Hashes returned by this gem have `Symbol` keys that are snake_cased.

## Development

Tests use VCR. To re-record you need to define bulk operation IDs in `.env`. `cp .env.example .env` and update `.env`

There are Rake tasks to help with bulk request generation.

## See Also

- [`ShopifyAPI::GraphQL::Request`](https://github.com/ScreenStaring/shopify_api-graphql-request/) - Simplify Shopify API GraphQL handling. Comes with built-in retry, pagination, error handling, and more!
- [`TinyGID`](https://github.com/sshaw/tiny_gid/) - Build Global ID (`gid://`) URI strings from scalar values
- [Shopify Dev Tools](https://github.com/ScreenStaring/shopify-dev-tools/) - Command-line program to assist with the development and/or maintenance of Shopify apps and stores

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

---

Made by [ScreenStaring](http://screenstaring.com)
