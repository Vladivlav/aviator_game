require "rails_helper"

RSpec.describe Bets::SaveFromCache do
  let(:game)  { create(:game) }
  let(:user)  { create(:user) }
  let(:json)  { valid_bet_data.to_json }

  let(:valid_bet_data) do
    {
      id:            SecureRandom.random_number(100_000),
      user_id:       user.id,
      amount:        "50.0",
      client_seed:   "abc123",
      status:        "pending",
      cashed_out_at: "1.75",
      payout:        "87.5"
    }
  end

  let(:mapped_attrs) do
    valid_bet_data.merge(
      game_id:    game.id,
      created_at: Time.current,
      updated_at: Time.current
    )
  end

  let(:bets_redis_repo) { class_double(Bets::RedisRepository) }
  let(:bets_mapper)     { class_double(Bets::PayloadMapper) }

  subject do
    described_class.new(
      bets_redis_repo: bets_redis_repo,
      bets_mapper:     bets_mapper
    )
  end

  describe "#call" do
    context "with valid data in Redis" do
      before do
        allow(bets_redis_repo).to receive(:for_game).with(game.id).and_return({ user.id.to_s => json })
        allow(bets_mapper).to receive(:from_redis).with(json, game.id).and_return(mapped_attrs)
      end

      it "creates Bet record and returns success" do
        expect {
          result = subject.call(game: game)

          expect(result.success?).to be true
          expect(result.value[:game]).to eq(game)
        }.to change { Bet.count }.by(1)

        bet = Bet.last
        expect(bet.attributes).to include(
          "id"            => mapped_attrs[:id],
          "user_id"       => mapped_attrs[:user_id],
          "game_id"       => game.id,
          "amount"        => BigDecimal("50.0"),
          "client_seed"   => "abc123",
          "status"        => "pending",
          "cashed_out_at" => BigDecimal("1.75"),
          "payout"        => BigDecimal("87.5")
        )
      end
    end

    context "when Redis is empty" do
      before do
        allow(bets_redis_repo).to receive(:for_game).with(game.id).and_return({})
      end

      it "returns success and does nothing" do
        result = subject.call(game: game)

        expect(result.success?).to be true
        expect(Bet.count).to eq(0)
      end
    end

    context "when Redis contains invalid JSON" do
      before do
        allow(bets_redis_repo).to receive(:for_game).with(game.id).and_return({ user.id.to_s => "not-a-json" })
        allow(bets_mapper).to receive(:from_redis).and_raise(JSON::ParserError.new("unexpected token"))
      end

      it "returns failure with parse error" do
        result = subject.call(game: game)

        expect(result.failure?).to be true
        expect(result.error.value).to include("Invalid JSON")
        expect(Bet.count).to eq(0)
      end
    end

    context "when Bet creation fails due to validation" do
      before do
        invalid_attrs = mapped_attrs.merge(amount: nil)
        allow(bets_redis_repo).to receive(:for_game).with(game.id).and_return({ user.id.to_s => json })
        allow(bets_mapper).to receive(:from_redis).with(json, game.id).and_return(invalid_attrs)
      end

      it "returns failure with validation error" do
        result = subject.call(game: game)

        expect(result.failure?).to be true
        expect(result.error.value).to include("Bet creation failed")
        expect(Bet.count).to eq(0)
      end
    end
  end
end
