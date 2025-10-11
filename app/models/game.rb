require "digest/sha2"

class Game < ApplicationRecord
  has_many :bets

  # Класс-метод для создания нового раунда
  def self.create_new_round!
    # Генерация случайного сида (например, 128 символов)
    server_seed = SecureRandom.hex(64)
    # Хеширование сида, которое показывается клиентам ДО раунда
    server_seed_hash = Digest::SHA256.hexdigest(server_seed)

    Game.create!(
      server_seed: server_seed,
      server_seed_hash: server_seed_hash,
      is_completed: false
    )
  end
end
