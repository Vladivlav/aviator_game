# app/forms/bet_form.rb

class BetForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :user_id, :integer
  attribute :amount, :decimal
  attribute :auto_cashout, :decimal
  attribute :client_seed, :string
  attribute :session_token, :string

  validates :user_id, presence: true
  validates :amount, presence: true, numericality: { greater_than: 0.0, less_than_or_equal_to: 1_000_000.00 }
  validates :auto_cashout, numericality: { greater_than_or_equal_to: 1.0 }, allow_nil: true
  validates :client_seed, presence: true, length: { minimum: 5 }

  def initialize(attributes = {})
    super(attributes)
  end

  def to_h
    {
      user_id: user_id,
      amount: amount,
      auto_cashout: auto_cashout,
      client_seed: client_seed,
      placed_at: Time.now.to_i
    }.compact
  end
end
