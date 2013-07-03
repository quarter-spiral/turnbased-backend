require 'bundler'

Bundler.require

require 'json'
require 'uuid'
require 'grape'
require 'grape_newrelic'
require 'service-client'

module Turnbased
  module Backend
    # Your code goes here...
  end
end
require "turnbased/backend/version"
require "turnbased/backend/error"
require "turnbased/backend/connection"
require "turnbased/backend/match"
require "turnbased/backend/api"