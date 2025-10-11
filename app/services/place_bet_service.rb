class PlaceBetService
  prepend ServiceModule::Base

  ACTIVE_GAME_KEY = "aviator:active_game_id"
  REDIS_POOL      = Redis.current

  def call(bet)
    run :check_betting_phase
    run DeductUserBalance
    run :save_bet_to_redis
  end

  private

  def check_betting_phase(bet:)
    return failure(base: [ "Betting is closed." ]) unless current_game_id

    success(bet: bet)
  end

  def save_bet_to_redis(bet:)
    redis_key = "aviator:bets:#{current_game_id}"

    if redis.hexists(redis_key, bet.user_id)
      existing_json = redis.hget(redis_key, bet.user_id)
      existing_data = JSON.parse(existing_json)

      existing_bet = Bet.new(existing_data)
      existing_bet.id = existing_data["id"]
      existing_bet.readonly!

      return success(bet: existing_bet)
    end

    bet_as_json = JSON.dump(bet.as_json(only: [ :id, :user_id, :amount, :status ]))
    redis.hset(redis_key, bet.user_id, bet_as_json)

    success(bet: bet)
  end

  def current_game_id
    @current_game_id ||= redis.get(ACTIVE_GAME_KEY)
  end

  def redis
    REDIS_POOL.respond_to?(:with) ? REDIS_POOL.with { |conn| conn } : REDIS_POOL
  end
end
