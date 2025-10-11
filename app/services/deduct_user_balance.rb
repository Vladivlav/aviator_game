# app/services/deduct_user_balance.rb
class DeductUserBalance
  prepend ServiceModule::Base

  def initialize(balance_repo: ::Balances::RedisRepository)
    @balance_repo = balance_repo
  end

  def call(bet:)
    user_id = bet.user_id

    new_balance = balance_repo.watch(user_id) do
      raw_balance = balance_repo.get(user_id)

      if raw_balance.nil?
        balance_repo.unwatch
        return failure(bet, "Balance not found. Please try again later.")
      end

      current_balance = raw_balance.to_f
      balance_after   = current_balance - bet.amount

      if balance_after < 0
        balance_repo.unwatch
        next nil
      end

      result = balance_repo.multi_set(user_id, balance_after)

      result && result.any? ? balance_after : nil
    end

    if new_balance
      success(bet: bet)
    else
      failure(bet, "Insufficient funds or concurrent transaction conflict. Please try again.")
    end
  end

  private

  attr_reader :balance_repo
end
