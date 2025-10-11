# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_10_14_125404) do
  create_table "bets", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "game_id", null: false
    t.decimal "amount", precision: 15, scale: 2, null: false
    t.string "client_seed", null: false
    t.string "status", default: "pending", null: false
    t.decimal "cashed_out_at", precision: 15, scale: 4
    t.decimal "payout", precision: 15, scale: 2
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["game_id"], name: "index_bets_on_game_id"
    t.index ["user_id", "game_id"], name: "index_bets_on_user_id_and_game_id"
    t.index ["user_id"], name: "index_bets_on_user_id"
  end

  create_table "games", force: :cascade do |t|
    t.string "server_seed"
    t.string "server_seed_hash"
    t.decimal "final_multiplier", precision: 15, scale: 4
    t.boolean "is_completed"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
    t.string "username", null: false
    t.string "email", null: false
    t.string "auth_token", null: false
    t.decimal "balance_persistent", precision: 15, scale: 2, default: "20000.0", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["auth_token"], name: "index_users_on_auth_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "bets", "games"
  add_foreign_key "bets", "users"
end
