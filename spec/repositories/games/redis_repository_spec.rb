require "rails_helper"

RSpec.describe Games::RedisRepository do
  let(:redis) { Redis.current }

  describe ".mark_betting_open" do
    it "sets betting flag to true in Redis" do
      redis.with { |conn| conn.del("aviator:betting_open") }

      described_class.mark_betting_open

      value = redis.with { |conn| conn.get("aviator:betting_open") }
      expect(value).to eq("true")
    end
  end

  describe ".set_active_game_id" do
    it "sets active game ID in Redis" do
      redis.with { |conn| conn.del("aviator:active_game_id") }

      described_class.set_active_game_id(42)

      value = redis.with { |conn| conn.get("aviator:active_game_id") }
      expect(value).to eq("42")
    end
  end
end
