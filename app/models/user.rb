# app/models/user.rb

class User < ApplicationRecord
  has_many :bets
  # Этот атрибут существует только в памяти, не в БД.
  attr_accessor :session_token
end
