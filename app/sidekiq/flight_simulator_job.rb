class FlightSimulatorJob
  include Sidekiq::Job
  sidekiq_options queue: :streamer_critical

  CRASH_DURATION_SEC = 2.seconds

  def perform(args)
    game_id     = args["game_id"]
    server_seed = args["server_seed"]

    RoundSimulator.broadcast_multiplier_progress(game_id: game_id, server_seed: server_seed)

    AviatorJob.set(wait: CRASH_DURATION_SEC).perform_async(nil)
  end
end
