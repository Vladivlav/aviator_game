# app/controllers/api/v1/bets_controller.rb

class Api::V1::BetsController < ApplicationController
  before_action :authenticate_user_from_redis!

  def create
    form_attributes = bet_params.merge(user_id: current_user.id)
    bet_form        = BetForm.new(form_attributes)
    bet             = Bet.new(bet_form)

    unless bet_form.valid?
      return render json: { success: false, errors: bet_form.errors.messages }, status: :unprocessable_entity
    end

    result = PlaceBetService.call(bet_form)

    if result[:success]
      render json: {
          success: true,
          message: "Bet placed successfully on Game ID: #{result[:game_id]}",
          game_id: result[:game_id]
      }, status: :created
    else
      render json: result, status: :unprocessable_entity
    end
  end

  private

  def bet_params
    params.require(:bet).permit(:amount, :auto_cashout, :client_seed, :session_token)
  end
end
