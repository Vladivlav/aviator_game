class GuestUserCreator
  # Константы для генерации
  GUEST_PREFIX = "pilot_"
  EMAIL_DOMAIN = "fake_unreal_game.com"

  INITIAL_BALANCE = 20000.00

  def self.call
    new.call
  end

  def call
    begin
      @auth_token = generate_token
      @username   = generate_username
      @email      = generate_email

      user = User.create!(
        username: @username,
        email: @email,
        auth_token: @auth_token,
        balance_persistent: INITIAL_BALANCE
      )

      user
    rescue ActiveRecord::RecordNotUnique
      retry
    end
  end

  private

  def generate_token
    SecureRandom.urlsafe_base64(32)
  end

  def generate_username
    "#{GUEST_PREFIX}#{SecureRandom.hex(4)}"
  end

  def generate_email
    "#{SecureRandom.uuid}@#{EMAIL_DOMAIN}"
  end
end
