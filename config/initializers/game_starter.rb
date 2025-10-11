# # config/initializers/game_starter.rb

# Rails.application.config.after_initialize do
#   # Простой запуск только в Production, чтобы избежать двойных запусков при hot-reload в Dev
#   if Rails.env.production?
#     Rails.logger.info "Starting AviatorJob cycle from initializer..."
#     # Запускаем, чтобы создать первую игру, если её нет.
#     AviatorJob.perform_async(nil, "betting_start")
#   elsif Rails.env.development?
#     # В Dev-окружении, запустите вручную в консоли, если цикл не начался,
#     # чтобы избежать ложной перезагрузки: AviatorJob.perform_async(nil, "betting_start")
#   end
# end
