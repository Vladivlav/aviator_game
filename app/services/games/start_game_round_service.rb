module Games
  class StartGameRoundService
    prepend ServiceModule::Base

    def initialize(games_repo: Games::RedisRepository)
      @games_repo = games_repo
    end

    def call
      game = Game.new(default_game_attrs)

      if game.save
        games_repo.mark_betting_open
        games_repo.set_active_game_id(game.id)
        success(game: game)
      else
        Rails.logger.error(game.errors)
        failure(game.errors)
      end
    end

    private

    attr_reader :games_repo

    def default_game_attrs
      seed      = SecureRandom.hex(16)
      seed_hash = Digest::SHA256.hexdigest(seed)

      { server_seed: seed, server_seed_hash: seed_hash, is_completed: false }
    end
  end
end
