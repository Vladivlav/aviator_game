module Bets
  class PayloadMapper
    REQUIRED_FIELDS = %w[id user_id amount client_seed status].freeze

    def self.from_redis(json, game_id)
      data = JSON.parse(json)

      missing = REQUIRED_FIELDS.select { |field| data[field].nil? }
      raise JSON::ParserError, "Missing required fields: #{missing.join(", ")}" if missing.any?

      {
        id:            data["id"],
        user_id:       data["user_id"],
        game_id:       game_id,
        amount:        data["amount"],
        client_seed:   data["client_seed"],
        status:        data["status"],
        cashed_out_at: data["cashed_out_at"],
        payout:        data["payout"],
        created_at:    Time.current,
        updated_at:    Time.current
      }
    end
  end
end
