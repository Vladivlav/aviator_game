require "rails_helper"

RSpec.describe Games::FinalizeGameRoundService do
  let(:game)           { create(:game, is_completed: false) }
  let(:save_bets)      { instance_double(Bets::SaveFromCache) }
  let(:clean_up_redis) { instance_double(Games::CleanUpAfterCrash) }

  subject(:service) do
    described_class.new(
      save_bets: save_bets,
      clean_up_redis: clean_up_redis
    )
  end

  describe "#call" do
    context "when game exists" do
      it "marks game as completed and calls dependencies" do
        expect(save_bets).to receive(:call).with(game_id: game.id)
        expect(clean_up_redis).to receive(:call).with(game_id: game.id)

        result = service.call(game_id: game.id)

        expect(result.success?).to be true
        expect(result.value[:game]).to eq(game)
        expect(game.reload.is_completed).to be true
      end
    end

    context "when game does not exist" do
      it "returns failure with error message" do
        result = service.call(game_id: -1)

        expect(result.failure?).to be true
        expect(result.error.value).to eq("Game not found")
      end
    end
  end
end
