ENV['RACK_ENV'] ||= 'test'

Bundler.require

require 'minitest/autorun'
require 'qs-test-harness'

require 'json'

require 'turnbased/backend'

Qs::Test::Harness.setup! do
  # Provide a multitude of apps as a dependency for the actual test
  provide Qs::Test::Harness::Provider::Datastore
  provide Qs::Test::Harness::Provider::Graph
  provide Qs::Test::Harness::Provider::Auth
  provide Qs::Test::Harness::Provider::Devcenter
  provide Qs::Test::Harness::Provider::Playercenter

  test Turnbased::Backend::API, augment: true
end