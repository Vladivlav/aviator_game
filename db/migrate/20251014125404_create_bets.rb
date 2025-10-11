class CreateBets < ActiveRecord::Migration[8.0]
  def change
    create_table :bets do |t|
      t.references :user, null: false, foreign_key: true
      t.references :game, null: false, foreign_key: true

      t.decimal :amount, precision: 15, scale: 2, null: false
      t.string :client_seed, null: false
      t.string :status, null: false, default: 'pending'
      t.decimal :cashed_out_at, precision: 15, scale: 4, default: nil
      t.decimal :payout, precision: 15, scale: 2, default: nil

      t.timestamps
    end

    add_index :bets, [ :user_id, :game_id ]
  end
end
