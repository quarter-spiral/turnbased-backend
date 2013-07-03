require_relative './spec_helper.rb'

describe "Create matches" do
  before do
    @harness = Qs::Test::Harness.harness
    @client = @harness.client

    factory = @harness.entity_factory

    @game = factory.create(:game)
    @players = 3.times.map {factory.create(:player, 'game' => @game)}

    @match_data = {
      "game" => @game.uuid,
      "players" => [
        {
          "uuid" => @players.first.uuid,
          "meta" => {
            "color" => 'green',
            "faction" => 0
          }
        }
      ],
      "meta" => {
        "name" => "Some match"
      }
    }
  end

  it "can create a game" do
    @client.authorize_with(@harness.provider(:auth).system_access)
    response = @client.post("/v1/matches", json: {"match" => @match_data})
    response.must_respond_with(status: 201)

    created_match_data = JSON.parse(response.body)

    created_match_data['match']['game'].must_equal @match_data['game']

    created_match_data['match']['players'].size.must_equal 1
    created_match_data['match']['players'].first['uuid'].must_equal @players.first.uuid
    created_match_data['match']['meta'].must_equal("name" => "Some match")

    created_match_data['match']['uuid'].wont_be_empty
  end

  it "can retrieve a game" do
    @client.authorize_with(@harness.provider(:auth).system_access)
    response = @client.post("/v1/matches", json: {"match" => @match_data})
    created_match_data = JSON.parse(response.body)
    response = @client.get("/v1/matches/#{created_match_data['match']['uuid']}")
    retrieved_match_data = JSON.parse(response.body)
    p retrieved_match_data
    p created_match_data

    retrieved_match_data.must_equal created_match_data
  end
end