# app/repositories/games/redis_repository.rb

module Games
  class RedisRepository
    REDIS_POOL = Redis.current

    class << self
      def mark_betting_open
        redis.set("aviator:betting_open", "true")
      end

      def set_active_game_id(game_id)
        redis.set("aviator:active_game_id", game_id)
      end

      private

      def redis
        REDIS_POOL.respond_to?(:with) ? REDIS_POOL.with { |conn| conn } : REDIS_POOL
      end
    end
  end
end
