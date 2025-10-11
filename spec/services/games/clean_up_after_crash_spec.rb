require "rails_helper"

RSpec.describe Games::CleanUpAfterCrash do
  let(:redis)              { Redis.current }
  let(:game_id)            { 123 }
  let(:bets_key)           { "aviator:bets:#{game_id}" }
  let(:cashouts_key)       { "aviator:cashouts:#{game_id}" }
  let(:active_game_id_key) { "aviator:active_game_id" }

  before do
    redis.with do |conn|
      conn.hset(bets_key, "1", { id: 1, amount: 50.0 }.to_json)
      conn.hset(cashouts_key, "1", { multiplier: 1.75 }.to_json)
      conn.set(active_game_id_key, game_id)
    end
    described_class.new.call(game_id: game_id)
  end

  describe "#call" do
    it "removes bets from Redis" do
      redis.with do |conn|
        expect(conn.hgetall(bets_key)).to be_empty
      end
    end

    it "removes cashouts from Redis" do
      redis.with do |conn|
        expect(conn.hgetall(cashouts_key)).to be_empty
      end
    end

    it "removes active_game_id from Redis" do
      redis.with do |conn|
        expect(conn.get(active_game_id_key)).to be_nil
      end
    end
  end
end
