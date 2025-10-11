require "rails_helper"

RSpec.describe GuestUserCreator do
  describe "#call" do
    subject(:user) { described_class.call }

    it "creates a persisted guest user with correct attributes" do
      expect(user).to be_persisted
      expect(user.username).to start_with("pilot_")
      expect(user.email).to match(/@fake_unreal_game\.com\z/)
      expect(user.auth_token.length).to be >= 32
      expect(user.balance_persistent).to eq(20000.00)
    end

    it "creates a unique user each time" do
      user1 = described_class.call
      user2 = described_class.call

      expect(user1.username).not_to eq(user2.username)
      expect(user1.email).not_to eq(user2.email)
      expect(user1.auth_token).not_to eq(user2.auth_token)
    end

    context "when RecordNotUnique is raised on first attempt" do
      let(:valid_user) { build(:user, :guest) }

      before do
        call_count = 0
        allow(User).to receive(:create!).and_wrap_original do |original, *args|
          call_count += 1
          call_count == 1 ? raise(ActiveRecord::RecordNotUnique) : valid_user.tap(&:save!)
        end
      end

      it "retries and succeeds" do
        result = described_class.call

        expect(result).to be_persisted
        expect(User).to have_received(:create!).twice
      end
    end
  end
end
