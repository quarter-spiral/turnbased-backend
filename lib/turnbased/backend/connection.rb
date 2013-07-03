module Turnbased::Backend
  class Connection
    attr_reader :auth, :datastore, :graph, :devcenter, :playercenter

    def self.create
      new(
        ENV['QS_AUTH_BACKEND_URL'] || 'http://auth-backend.dev',
        ENV['QS_DATASTORE_BACKEND_URL'] || 'http://datastpre-backend.dev',
        ENV['QS_GRAPH_BACKEND_URL'] || 'http://graph-backend.dev',
        ENV['QS_DEVCENTER_BACKEND_URL'] || 'http://devcenter-backend.dev',
        ENV['QS_PLAYERCENTER_BACKEND_URL'] || 'http://playercenter-backend.dev'
      )
    end

    def initialize(auth_backend_url, datastore_backend_url, graph_backend_url, devcenter_backend_url, playercenter_backend_url)
      @auth = Auth::Client.new(auth_backend_url)
      @datastore = Datastore::Client.new(datastore_backend_url)
      @graph = Graph::Client.new(graph_backend_url)
      @devcenter = Devcenter::Client.new(devcenter_backend_url)
      @playercenter = Playercenter::Client.new(playercenter_backend_url)
    end
  end
end