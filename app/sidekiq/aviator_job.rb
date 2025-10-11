class AviatorJob
  include Sidekiq::Job
  sidekiq_options queue: :streamer_critical

  BETTING_TIME = 5

  def perform(game_id = nil)
    Game.where(id: game_id).update_all(is_completed: true) if game_id

    result = Games::StartGameRoundService.call
    if result.failure?
      Rails.logger.error("Failed to start new game round: #{result.error.value}")
      return
    end

    game = result.value[:game]

    ActionCable.server.broadcast("AlertsChannel", { action: "betting_open" })

    FlightSimulatorJob.set(wait: BETTING_TIME.seconds).perform_async(
      "game_id" => game.id,
      "server_seed" => game.server_seed
    )
  end
end
