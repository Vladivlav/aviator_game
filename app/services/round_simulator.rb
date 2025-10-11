class RoundSimulator
  def self.broadcast_multiplier_progress(game_id:, server_seed:)
    result = GameKeyGeneratorService.new.call(game_id: game_id, server_seed: server_seed)

    unless result.success?
      Rails.logger.error("Multiplier generation failed: #{result.error.value}")
      return
    end

    final_multiplier = result.value[:final_multiplier]
    current_multiplier = 1.00
    step = 0.01

    while current_multiplier <= final_multiplier
      ActionCable.server.broadcast("AlertsChannel", {
        multiplier: current_multiplier.round(2)
      })

      sleep(0.05)
      current_multiplier += step
      step += 0.0001
    end

    ActionCable.server.broadcast("AlertsChannel", {
      type: "GAME_CRASH",
      final_multiplier: final_multiplier.round(2)
    })

    puts "\n--- ДАННЫЕ РАУНДА ---"
    puts "FINAL MULTIPLIER: #{final_multiplier.round(2)}X"
    puts "---------------------\n"
  end
end
