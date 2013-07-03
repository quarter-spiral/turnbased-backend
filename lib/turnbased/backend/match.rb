module Turnbased
  module Backend
    class Match
      attr_reader :game, :players, :meta, :invitations

      def initialize(token, params = {})
        @token = token

        @game = params['game']
        @players = params['players'] || []
        @meta = params['meta']
        @uuid = params['uuid']

        @invitations = []

        @errors = []
      end

      def self.find(uuid, token)
        match = Match.new(token)
        match.load_data!(uuid)
      end

      def load_data!(uuid)
        result = {}

        data = connection.datastore.get(uuid, @token)
        return nil unless data
        from_store_hash!(data)

        @game = (graph.query(@token, [uuid], "MATCH node0-[p:`is-a-match-of`]->game RETURN game.uuid").first || []).first

        player_uuids = graph.query(@token, [uuid], "MATCH player-[p:`participates-in`]->node0 RETURN player.uuid").map(&:first)
        @players = player_uuids.map do |player_uuid|
          {
            'uuid' => player_uuid,
            'meta' => graph.relationship_metadata(player_uuid, uuid, @token, 'participates-in')
          }
        end

        raise(Error::ValidationError.new(error_message)) unless valid?

        self
      end

      def save!
        save || raise(Error::ValidationError.new(error_message))
      end

      def save
        return false unless valid?

        match_was_new = new_record?

        connection.datastore.set(uuid, @token, to_store_hash)
        graph.add_role(uuid, @token, 'turnbased-match')


        if match_was_new
          graph.add_role(uuid, @token, 'turnbased-match')
          graph.add_relationship(uuid, @game, @token, 'is-a-match-of')
        end

        (@players || []).each do |player|
          graph.add_relationship(player['uuid'], uuid, @token, 'participates-in', meta: player['meta'] || {})
        end
      end

      def uuid
        @uuid ||= UUID.new.generate
      end

      def to_store_hash
        {"meta" => meta}
      end

      def started
        true
      end

      def ended
        false
      end

      def results
        nil
      end

      def turns
        []
      end

      def current_player
        players.first['uuid']
      end

      def to_public_hash
        {
          "match" => {
            "game" => game,
            "uuid" => uuid,
            "players" => public_player_info,
            "invitations" => invitations,
            "meta" => meta,
            "started" => started,
            "ended" => ended,
            "results" => results,
            "turns" => turns,
            "currentPlayer" => current_player
          }
        }
      end

      def error_message
        message = "Match invalid! "
        message + @errors.map {|field, message| "#{field}: #{message}"}.join(" | ")
      end

      def valid?
        validate!
        @errors.empty?
      end

      def validate!
        @errors.clear

        @errors << ['game', 'game not set'] if !@game || @game.empty?
        @errors << ['game', 'not a game'] unless graph.list_roles(@game, @token).include?('game')
      end

      def add_player_uuid(player_uuid)
        return if @players.detect {|p| p['uuid'] == player_uuid}

        @players << {
          "uuid" => player_uuid
        }
      end

      protected
      def new_record?
        !@uuid
      end

      def graph
        connection.graph
      end

      def connection
        @connection ||= Connection.create
      end

      def public_player_info
        players.map do |player|
          {
            "uuid" => player['uuid'],
            "meta" => player['meta']
          }
        end
      end

      def from_store_hash!(hash)
        @meta = hash['meta']
      end
    end
  end
end