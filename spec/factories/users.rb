FactoryBot.define do
  factory :user do
    sequence(:username)   { |n| "user_#{n}_#{SecureRandom.hex(2)}" }
    sequence(:email)      { |n| "user_#{n}_#{SecureRandom.hex(2)}@example.com" }
    sequence(:auth_token) { SecureRandom.urlsafe_base64(32) }
    balance_persistent    { 0.0 }

    trait :guest do
      username { "pilot_#{SecureRandom.hex(4)}" }
      email    { "#{SecureRandom.uuid}@fake_unreal_game.com" }
      auth_token { SecureRandom.urlsafe_base64(32) }
      balance_persistent { 20000.00 }
    end
  end
end
