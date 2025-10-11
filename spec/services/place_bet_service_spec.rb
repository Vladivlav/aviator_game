require "rails_helper"

RSpec.describe PlaceBetService do
  let(:redis) { Redis.current }
  let(:game)  { create(:game) }
  let(:user)  { create(:user, balance_persistent: 100.0) }
  let(:bet)   { create(:bet, user: user, game: game, amount: 25.0) }
  let(:balance_key) { "user:#{user.id}:balance" }
  let(:bets_key)    { "aviator:bets:#{game.id}" }

  before do
    redis.with do |conn|
      conn.set("aviator:active_game_id", game.id)
      conn.set(balance_key, user.balance_persistent.to_s)
      conn.del(bets_key)
    end
  end

  describe "#call" do
    context "when betting is open and user has sufficient balance" do
      it "places the bet and saves it to Redis" do
        result = described_class.new.call(bet: bet)

        expect(result.success?).to be true

        redis.with do |conn|
          stored = JSON.parse(conn.hget(bets_key, user.id))
          expect(stored["id"]).to eq(bet.id)
          expect(stored["amount"].to_f).to eq(25.0)
          expect(stored["status"]).to eq("pending")
        end

        expect(redis.with { |conn| conn.get(balance_key).to_f }).to eq(75.0)
      end
    end

    context "when betting is closed" do
      before { redis.with { |conn| conn.del("aviator:active_game_id") } }

      it "returns failure" do
        result = described_class.new.call(bet: bet)

        expect(result.failure?).to be true
        expect(result.value[:base]).to include("Betting is closed.")
      end
    end

    context "when user has insufficient balance" do
      let(:user) { create(:user, balance_persistent: 10.0) }
      let(:bet)  { create(:bet, user: user, game: game, amount: 50.0) }

      before { redis.with { |conn| conn.set(balance_key, user.balance_persistent.to_s) } }

      it "returns failure and does not save to Redis" do
        result = described_class.new.call(bet: bet)

        expect(result.failure?).to be true
        expect(result.error.value).to include("Insufficient funds or concurrent transaction conflict. Please try again.")
        expect(redis.with { |conn| conn.hget(bets_key, user.id) }).to be_nil
        expect(redis.with { |conn| conn.get(balance_key).to_f }).to eq(10.0)
      end
    end

    context "when multiple users place bets" do
      let(:user2) { create(:user, balance_persistent: 150.0) }
      let(:bet2)  { create(:bet, user: user2, game: game, amount: 50.0) }
      let(:balance_key2) { "user:#{user2.id}:balance" }

      before do
        redis.with do |conn|
          conn.set(balance_key2, user2.balance_persistent.to_s)
          conn.del(bets_key)
        end
      end

      it "stores both bets in Redis under separate user keys" do
        result1 = described_class.new.call(bet: bet)
        result2 = described_class.new.call(bet: bet2)

        expect(result1.success?).to be true
        expect(result2.success?).to be true

        redis.with do |conn|
          all_bets = conn.hgetall(bets_key)

          expect(all_bets.keys).to include(user.id.to_s, user2.id.to_s)
          expect(all_bets.size).to eq(2)

          stored1 = JSON.parse(all_bets[user.id.to_s])
          stored2 = JSON.parse(all_bets[user2.id.to_s])

          expect(stored1["id"]).to eq(bet.id)
          expect(stored2["id"]).to eq(bet2.id)
          expect(stored1["user_id"]).to eq(user.id)
          expect(stored2["user_id"]).to eq(user2.id)
        end
      end
    end


    context "when a bet already exists for the user" do
      let(:new_bet) { create(:bet, user: user, game: game, amount: 99.0) }

      before do
        redis.with do |conn|
          conn.hset(bets_key, user.id, JSON.dump(bet.as_json(only: [ :id, :user_id, :amount, :status ])))
        end
      end

      it "does not overwrite the existing bet" do
        result = described_class.new.call(bet: new_bet)

        expect(result.success?).to be true

        redis.with do |conn|
          stored = JSON.parse(conn.hget(bets_key, user.id))
          expect(stored["amount"].to_f).to eq(25.0) # старая ставка
          expect(stored["id"]).to eq(bet.id)        # старая ставка
        end
      end
    end
  end
end
