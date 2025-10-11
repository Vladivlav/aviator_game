class CreateGames < ActiveRecord::Migration[8.0]
  def change
    create_table :games do |t|
      t.string :server_seed
      t.string :server_seed_hash
      t.decimal :final_multiplier, precision: 15, scale: 4, default: nil
      t.string :full_multiplier_seed
      t.boolean :is_completed

      t.timestamps
    end
  end
end
