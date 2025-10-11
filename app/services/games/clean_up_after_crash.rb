module Games
  class CleanUpAfterCrash
    prepend ServiceModule::Base

    REDIS_POOL = Redis.current

    def call(game_id:)
      redis.del("aviator:bets:#{game_id}")
      redis.del("aviator:cashouts:#{game_id}")
      redis.del("aviator:active_game_id")
    end

    private

    def redis
      REDIS_POOL.respond_to?(:with) ? REDIS_POOL.with { |conn| conn } : REDIS_POOL
    end
  end
end
