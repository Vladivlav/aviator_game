module Bets
  class SaveFromCache
    prepend ServiceModule::Base

    def initialize(
      bets_redis_repo: Bets::RedisRepository,
      bets_mapper: Bets::PayloadMapper
    )
      @bets_redis_repo = bets_redis_repo
      @bets_mapper     = bets_mapper
    end

    def call(game:)
      bets = bets_redis_repo.for_game(game.id)
      return success(game: game) if bets.empty?

      bets_attrs = bets.map { |_, json| bets_mapper.from_redis(json, game.id) }

      ActiveRecord::Base.transaction do
        Bet.upsert_all(bets_attrs, unique_by: :id)
      end

      success(game: game)
    rescue JSON::ParserError => e
      failure(game, "Invalid JSON: #{e.message}")
    rescue ActiveRecord::RecordInvalid => e
      failure(game, "Bet creation failed: #{e.record.errors.full_messages.join(", ")}")
    rescue ActiveRecord::StatementInvalid => e
      failure(game, "Bet creation failed: #{e.message}")
    rescue => e
      failure(game, "Unexpected error: #{e.message}")
    end

    private

    attr_reader :bets_redis_repo, :bets_mapper
  end
end
