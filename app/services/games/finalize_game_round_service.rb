module Games
  class FinalizeGameRoundService
    prepend ServiceModule::Base

    def initialize(
      save_bets: ::Bets::SaveFromCache,
      clean_up_redis: CleanUpAfterCrash
    )
      @save_bets      = save_bets
      @clean_up_redis = clean_up_redis
    end

    def call(game_id:)
      game = Game.find(game_id)
      game.update!(is_completed: true)

      save_bets.call(game_id: game_id)
      clean_up_redis.call(game_id: game_id)

      success(game: game)
    rescue ActiveRecord::RecordNotFound
      failure(game, "Game not found")
    end

    private

    attr_reader :clean_up_redis, :save_bets
  end
end
