require "rails_helper"

RSpec.describe Games::StartGameRoundService do
  let(:games_repo) { class_double(Games::RedisRepository) }

  describe "#call" do
    context "when game is created successfully" do
      it "returns success and creates a game" do
        allow(games_repo).to receive(:mark_betting_open)
        allow(games_repo).to receive(:set_active_game_id)

        result = described_class.new(games_repo: games_repo).call
        game = result.value[:game]

        expect(result.success?).to be true
        expect(game).to be_persisted
      end

      it "stores active_game_id and opens betting in Redis" do
        expect(games_repo).to receive(:mark_betting_open)
        expect(games_repo).to receive(:set_active_game_id).with(instance_of(Integer))

        result = described_class.new(games_repo: games_repo).call
        game = result.value[:game]

        expect(game).to be_persisted
      end
    end

    context "when game fails to save" do
      before do
        allow(Game).to receive(:new).and_return(Game.new)
        allow_any_instance_of(Game).to receive(:save).and_return(false)
        allow_any_instance_of(Game).to receive(:errors).and_return([ "DB error" ])
      end

      it "returns failure with errors and does not touch Redis" do
        expect(games_repo).not_to receive(:mark_betting_open)
        expect(games_repo).not_to receive(:set_active_game_id)

        result = described_class.new(games_repo: games_repo).call

        expect(result.failure?).to be true
        expect(result.value).to eq([ "DB error" ])
      end
    end
  end
end
