require "rails_helper"

RSpec.describe Balances::RedisRepository do
  let(:redis)         { Redis.current }
  let(:repository)    { described_class }
  let(:user_id)       { 123 }
  let(:balance_key)   { "user:#{user_id}:balance" }

  before do
    redis.with { |conn| conn.del(balance_key) }
  end

  describe "#set and #get" do
    it "stores and retrieves user balance" do
      repository.set(user_id, 100.5)
      result = repository.get(user_id)

      expect(result).to eq("100.5")
    end
  end

  describe "#watch and #multi" do
    it "performs atomic update on balance" do
      repository.set(user_id, 50.0)

      result = repository.watch(user_id) do
        current = repository.get(user_id).to_f
        new_balance = current - 20.0

        repository.multi do |multi|
          multi.set(balance_key, new_balance.to_s)
        end
      end

      expect(result).to be_present
      expect(repository.get(user_id)).to eq("30.0")
    end

    it "returns nil if balance is missing during watch" do
      result = repository.watch(user_id) do
        raw = repository.get(user_id)
        repository.unwatch
        next nil
      end

      expect(result).to be_nil
    end
  end

  describe "#unwatch" do
    it "does not raise when called" do
      expect { repository.unwatch }.not_to raise_error
    end
  end
end
