class GameKeyGeneratorService
  prepend ServiceModule::Base

  DEFAULT_CLIENT_SEED = [ "cl-def-seed" ]
  LOWEST_MILTIPLIER   = 1.01

  def initialize(bets_repo: Bets::RedisRepository)
    @bets_repo = bets_repo
  end

  def call(game_id:, server_seed:)
    return failure(game_id, :no_game)             if game_id.nil?
    return failure(game_id, :missing_server_seed) if server_seed.nil?

    raw_bets     = bets_repo.for_game(game_id)
    client_seeds = extract_client_seeds(raw_bets)

    client_seeds = DEFAULT_CLIENT_SEED if client_seeds.empty?

    full_seed  = generate_full_seed(server_seed, client_seeds)
    multiplier = calculate_multiplier(full_seed)

    success(
      full_multiplier_seed: full_seed,
      final_multiplier: multiplier
    )
  rescue => e
    failure(game, :unexpected_error, e.message)
  end

  private

  attr_reader :bets_repo

  def extract_client_seeds(raw_bets)
    raw_bets.values.map do |json|
      begin
        JSON.parse(json)["client_seed"]
      rescue JSON::ParserError
        nil
      end
    end.compact.sort
  end

  def generate_full_seed(server_seed, client_seeds)
    ([ server_seed ] + client_seeds).join("-")
  end

  def calculate_multiplier(full_seed)
    hash = Digest::SHA256.hexdigest(full_seed)
    int = hash[0..7].to_i(16)
    normalized = int % 10000 / 1000.0
    normalized.round(4)

    [ LOWEST_MILTIPLIER, normalized.round(4) ].max
  end
end
