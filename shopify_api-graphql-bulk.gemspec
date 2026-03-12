require_relative "lib/shopify_api/graphql/bulk/version"

Gem::Specification.new do |spec|
  spec.name = "shopify_api-graphql-bulk"
  spec.version = ShopifyAPI::GraphQL::Bulk::VERSION
  spec.authors = ["Skye Shaw"]
  spec.email = ["skye.shaw@gmail.com"]

  spec.name = "shopify_api-graphql-bulk"
  spec.version = ShopifyAPI::GraphQL::Bulk::VERSION
  spec.authors       = ["Skye Shaw"]
  spec.email         = ["skye.shaw@gmail.com"]

  spec.summary = "Bulk import data using the Shopify GraphQL Admin Bulk API"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.5.0"
  spec.metadata = {
    "bug_tracker_uri"   => "https://github.com/ScreenStaring/shopify_api-graphql-bulk/issues",
    # "changelog_uri"     => "https://github.com/ScreenStaring/shopify_api-graphql-bulk/blob/master/Changes",
    "documentation_uri" => "https://rubydoc.info/gems/shopify_api-graphql-bulk",
    "source_code_uri"   => "https://github.com/ScreenStaring/shopify_api-graphql-bulk",
  }

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ Gemfile .gitignore .rspec spec/ .github/])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "multipart-post"
  spec.add_dependency "shopify_api-graphql-request"
  spec.add_dependency "strings-case"

  spec.add_development_dependency "vcr"
  spec.add_development_dependency "dotenv"
  spec.add_development_dependency "rake", ">= 13.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "webmock", "~> 3.0"
end
