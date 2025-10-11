require "rails_helper"

RSpec.describe GameKeyGeneratorService do
  let(:bets_repo) { class_double(Bets::RedisRepository) }
  subject(:service) { described_class.new(bets_repo: bets_repo) }

  describe "#call" do
    context "when game is nil" do
      it "returns failure with :no_game" do
        result = service.call(game_id: nil, server_seed: "asfasdfa")

        expect(result.failure?).to be true
        expect(result.error.value).to eq(:no_game)
      end
    end

    context "when game has no server_seed" do
      let(:game) { create(:game, server_seed: nil) }

      it "returns failure with :missing_server_seed" do
        result = service.call(game_id: game.id, server_seed: game.server_seed)

        expect(result.failure?).to be true
        expect(result.error.value).to eq(:missing_server_seed)
      end
    end

    context "when Redis has no client seeds" do
      let(:game) { create(:game, server_seed: "abc123") }

      before do
        allow(bets_repo).to receive(:for_game).with(game.id).and_return({})
      end

      it "returns success with full seed and multiplier" do
        result = service.call(game_id: game.id, server_seed: game.server_seed)

        expect(result.success?).to be true
        expect(result.value[:full_multiplier_seed]).to include("abc123-cl-def-seed")
        expect(result.value[:final_multiplier]).to be_a(Float)
      end
    end

    context "when Redis has valid client seeds" do
      let(:game) { create(:game, server_seed: "abc123") }

      before do
        allow(bets_repo).to receive(:for_game).with(game.id).and_return({
          "user_1" => { client_seed: "seed1" }.to_json,
          "user_2" => { client_seed: "seed2" }.to_json
        })
      end

      it "returns success with full seed and multiplier" do
        result = service.call(game_id: game.id, server_seed: game.server_seed)

        expect(result.success?).to be true
        expect(result.value[:full_multiplier_seed]).to include("abc123", "seed1", "seed2")
        expect(result.value[:final_multiplier]).to be_a(Float)
      end
    end
  end
end
