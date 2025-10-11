require "rails_helper"

RSpec.describe Bets::RedisRepository do
  let(:redis)     { Redis.current }
  let(:game_id)   { 42 }
  let(:user_id)   { 101 }
  let(:key)       { "aviator:bets:#{game_id}" }

  let(:bet_data) do
    {
      id:            999,
      user_id:       user_id,
      game_id:       game_id,
      amount:        "100.0",
      client_seed:   "seed123",
      status:        "pending",
      cashed_out_at: "2.5",
      payout:        "250.0"
    }
  end

  before do
    redis.with { |conn| conn.del(key) }
  end

  describe ".store" do
    it "stores bet data in Redis under correct key" do
      described_class.store(game_id: game_id, user_id: user_id, bet_data: bet_data)

      stored = redis.with { |conn| conn.hget(key, user_id.to_s) }
      expect(JSON.parse(stored)).to eq(JSON.parse(bet_data.to_json))
    end
  end

  describe ".for_game" do
    it "returns all bets for the game as a hash" do
      redis.with { |conn| conn.hset(key, user_id, bet_data.to_json) }

      result = described_class.for_game(game_id)
      expect(result).to be_a(Hash)
      expect(result[user_id.to_s]).to eq(bet_data.to_json)
    end
  end

  describe ".delete" do
    it "removes all bets for the game from Redis" do
      redis.with { |conn| conn.hset(key, user_id, bet_data.to_json) }

      described_class.delete(game_id)

      result = redis.with { |conn| conn.hgetall(key) }
      expect(result).to be_empty
    end
  end
end
