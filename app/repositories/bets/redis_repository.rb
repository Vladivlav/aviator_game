# app/repositories/bets/redis_repository.rb

module Bets
  class RedisRepository
    REDIS_POOL  = Redis.current
    BETS_PREFIX = "aviator:bets"

    def self.for_game(game_id)
      redis.hgetall("#{BETS_PREFIX}:#{game_id}")
    end

    def self.store(game_id:, user_id:, bet_data:)
      redis.hset("#{BETS_PREFIX}:#{game_id}", user_id, bet_data.to_json)
    end

    def self.delete(game_id)
      redis.del("#{BETS_PREFIX}:#{game_id}")
    end

    def self.redis
      REDIS_POOL.respond_to?(:with) ? REDIS_POOL.with { |conn| conn } : REDIS_POOL
    end
  end
end
