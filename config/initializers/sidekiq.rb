require "sidekiq/api"

Sidekiq.configure_server do |config|
  # --- 1. ЗАПУСК И ОЧИСТКА ПРИ СТАРТЕ ПРОЦЕССА ---
  config.on(:startup) do
    Rails.logger.info "--- Sidekiq Server Startup: Initializing Aviator Cycle ---"

    # А. Очистка старых запланированных джобов AviatorJob,
    # которые могли остаться после сбоя
    Sidekiq::ScheduledSet.new.each do |job|
      if job.klass == "AviatorJob"
        job.delete
        Rails.logger.warn "Deleted stale scheduled AviatorJob: #{job.jid}"
      end
    end

    Rails.logger.info "Starting fresh AviatorJob cycle."
    AviatorJob.set(wait: 5.seconds).perform_async(nil)
  end

  config.on(:shutdown) do
    Rails.logger.info "--- Sidekiq Server Shutdown: Deleting Scheduled Jobs ---"

    Sidekiq::ScheduledSet.new.each do |job|
      job.delete if job.klass == "AviatorJob"
    end
  end
end
