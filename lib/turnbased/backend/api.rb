module Turnbased
  module Backend
    class API < ::Grape::API
      use GrapeNewrelic::Instrumenter
      version 'v1', :using => :path, :vendor => 'quarter-spiral'

      format :json
      default_format :json
      default_error_formatter :json

      rescue_from Error::ValidationError do |e|
        Rack::Response.new(e.message, 400, {'Content-type' => 'plain/text'}).finish
      end

      class TokenStore
        def self.token(connection)
          @token ||= connection.auth.create_app_token(ENV['QS_OAUTH_CLIENT_ID'], ENV['QS_OAUTH_CLIENT_SECRET'])
        end

        def self.reset!
          @token = nil
        end
      end

      helpers do
        def connection
          @connection ||= Connection.create
        end

        def token
          TokenStore.token(connection)
        end

        def try_twice_and_avoid_token_expiration
          yield
        rescue Service::Client::ServiceError => e
          raise e unless e.error == 'Unauthenticated'
          TokenStore.reset!
          yield
        end

        def not_found!
          error!('Not found', 404)
        end

        def authentication_exception?
          env['PATH_INFO'] =~ /\/avatars\/[^\/]+$/ ||
  env['PATH_INFO'] =~ /^\/v1\/public\//
        end

        def own_data?(uuids)
          uuids.include?(@token_owner['uuid'])
        end

        def system_level_privileges?
          @token_owner['type'] == 'app'
        end

        def is_authorized_to_access?(uuids)
          system_level_privileges? || own_data?(uuids)
        end

        def prevent_access!(msg = 'Unauthenticated')
          error!(msg, 403)
        end

        def owner_only!(uuids)
          prevent_access! unless is_authorized_to_access?(uuids)
        end

        def system_privileges_only!
          prevent_access! unless system_level_privileges?
        end
      end

      before do
        header('Access-Control-Allow-Origin', request.env['HTTP_ORIGIN'] || '*')

        unless authentication_exception?
          token = request.env['HTTP_AUTHORIZATION'] || params[:oauth_token]
          prevent_access! unless token
          token = token.gsub(/^Bearer\s+/, '')

          @token_owner = connection.auth.token_owner(token)
          prevent_access! unless @token_owner
        end
      end

      options '*path' do
        header('Access-Control-Allow-Headers', 'origin, x-requested-with, content-type, accept, authorization')
        header('Access-Control-Allow-Methods', 'GET, PUT, OPTIONS, POST, DELETE')
        header('Access-Control-Max-Age', '1728000')
        ""
      end

      post "/matches" do
        match_data = params['match']
        # match_data = JSON.parse(match_data) if match_data && match_data.kind_of?(String)

        raise Error::ValidationError.new("Match already exists: #{match_data['uuid']}!") if match_data['uuid']

        match = Match.new(token, match_data)

        match.players ||= {}
        if !system_level_privileges? && (!match.players || match.players.empty?)
          match.add_player_uuid @token_owner['uuid']
        end

        if !system_level_privileges? && (match.players.size > 1 || match.players.first['uuid'] != @token_owner['uuid'])
          prevent_access!("Not allowed to create games with more players than yourself")
        end

        match.save!

        match.to_public_hash
      end

      get "/matches/:uuid" do
        match = Match.find(params[:uuid], token)
        return not_found! unless match

        owner_only!(match.players.map {|p| p['uuid']})

        match.to_public_hash
      end
    end
  end
end