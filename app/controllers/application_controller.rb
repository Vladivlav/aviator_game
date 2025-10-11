class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
  skip_before_action :verify_authenticity_token

  def authenticate_user_from_redis
    session_token = params[:session_token] || params.dig(:bet, :session_token)

    user = find_user_from_redis(session_token)

    unless user
      render json: { success: false, error: "Authentication required or session expired." }, status: :unauthorized
    else
      @current_user = user
    end
  end

  def current_user
    current_user ||= @current_user
  end

  private

  def find_user_from_redis(session_token)
    return nil if session_token.blank?

    user_data_json = REDIS_POOL.with { |conn| conn.get("session_token:#{session_token}") }

    if user_data_json.present?
      # Успех! Создаем OpenStruct из кэшированных данных
      user_data = JSON.parse(user_data_json).with_indifferent_access
      user = OpenStruct.new(user_data)
      user.session_token = session_token
      return user
    end
    nil
  end
end
