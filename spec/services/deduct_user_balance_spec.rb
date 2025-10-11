require "rails_helper"

RSpec.describe DeductUserBalance do
  let(:user_id) { 123 }
  let(:balance_key) { "user:#{user_id}:balance" }
  let(:redis) { Redis.current }
  let(:game)  { create(:game) }

  before { redis.with { |conn| conn.del(balance_key) } }

  describe "#call" do
    context "when user has sufficient balance" do
      it "deducts the bet amount and returns success" do
        user = create(:user, balance_persistent: 100.0)
        bet  = create(:bet, user: user, game: game, amount: 25.0)

        balance_key = "user:#{user.id}:balance"
        redis.with { |conn| conn.set(balance_key, user.balance_persistent.to_s) }

        result = described_class.new.call(bet: bet)

        expect(result.success?).to be true
        expect(redis.with { |conn| conn.get(balance_key).to_f }).to eq(75.0)
      end
    end

    context "when user has insufficient balance" do
      it "does not deduct and returns failure" do
        user = create(:user, balance_persistent: 10.0)
        bet = create(:bet, user: user, game: game, amount: 50.0)

        balance_key = "user:#{user.id}:balance"
        redis.with { |conn| conn.set(balance_key, user.balance_persistent.to_s) }

        result = described_class.new.call(bet: bet)

        expect(result.failure?).to be true
        expect(redis.with { |conn| conn.get(balance_key).to_f }).to eq(10.0)
        expect(result.error.value).to include("Insufficient funds or concurrent transaction conflict. Please try again.")
      end
    end

    context "when balance key is missing" do
      it "returns failure with balance not found message" do
        user = create(:user)
        bet = create(:bet, user: user, game: game, amount: 10.0)

        balance_key = "user:#{user.id}:balance"
        redis.with { |conn| conn.del(balance_key) }

        result = described_class.new.call(bet: bet)

        expect(result.failure?).to be true
        expect(result.error.value).to include("Balance not found. Please try again later.")
      end
    end
  end
end
