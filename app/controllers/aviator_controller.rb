class AviatorController < ApplicationController
  before_action :authenticate_guest_user!

  def index
  end

  private

  def authenticate_guest_user!
  end
end
