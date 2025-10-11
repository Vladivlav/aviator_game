FactoryBot.define do
  factory :bet do
    association :user
    association :game

    amount { 10.0 }
    client_seed { SecureRandom.hex(8) }
    status { "pending" }
    cashed_out_at { nil }
    payout { nil }
  end
end
