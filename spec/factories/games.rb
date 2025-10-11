FactoryBot.define do
  factory :game do
    transient do
      seed { SecureRandom.hex(16) }
    end

    server_seed { seed }
    server_seed_hash { Digest::SHA256.hexdigest(seed) }
    final_multiplier { nil }
    is_completed { false }
  end
end
