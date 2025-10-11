require "rails_helper"

RSpec.describe Bets::PayloadMapper do
  let(:game_id) { 42 }

  let(:valid_json) do
    {
      id:            999,
      user_id:       101,
      amount:        "100.0",
      client_seed:   "seed123",
      status:        "pending",
      cashed_out_at: "2.5",
      payout:        "250.0"
    }.to_json
  end

  describe ".from_redis" do
    it "returns mapped attributes for valid JSON" do
      result = described_class.from_redis(valid_json, game_id)

      expect(result[:id]).to eq(999)
      expect(result[:user_id]).to eq(101)
      expect(result[:game_id]).to eq(game_id)
      expect(result[:amount]).to eq("100.0")
      expect(result[:client_seed]).to eq("seed123")
      expect(result[:status]).to eq("pending")
      expect(result[:cashed_out_at]).to eq("2.5")
      expect(result[:payout]).to eq("250.0")
      expect(result[:created_at]).to be_a(Time)
      expect(result[:updated_at]).to be_a(Time)
    end

    it "raises error if required fields are missing" do
      invalid_json = { user_id: 101, amount: "100.0" }.to_json

      expect {
        described_class.from_redis(invalid_json, game_id)
      }.to raise_error(JSON::ParserError, /Missing required fields: id, client_seed, status/)
    end

    it "raises error for invalid JSON" do
      expect {
        described_class.from_redis("not-a-json", game_id)
      }.to raise_error(JSON::ParserError)
    end
  end
end
