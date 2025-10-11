# app/repositories/balances/redis_repository.rb

module Balances
  class RedisRepository
    REDIS_POOL = Redis.current

    class << self
      def watch(user_id, &block)
        redis.watch(balance_key(user_id), &block)
      end

      def get(user_id)
        redis.get(balance_key(user_id))
      end

      def set(user_id, new_balance)
        redis.set(balance_key(user_id), new_balance.to_s)
      end

      def multi_set(user_id, value)
        redis.multi do |conn|
          conn.set(balance_key(user_id), value.to_s)
        end
      end

      def multi(&block)
        redis.multi { |conn| block.call(conn) }
      end

      def unwatch
        redis.unwatch
      end

      private

      def balance_key(user_id)
        "user:#{user_id}:balance"
      end

      def redis
        REDIS_POOL.respond_to?(:with) ? REDIS_POOL.with { |conn| conn } : REDIS_POOL
      end
    end
  end
end
