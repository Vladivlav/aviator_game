class CreateUsers < ActiveRecord::Migration[7.1]
  def change
    create_table :users do |t|
      # Идентификационные данные гостя
      t.string :username, null: false
      t.string :email, null: false, index: { unique: true } # Выступает как уникальный ID

      # Токен аутентификации (для LocalStorage)
      t.string :auth_token, null: false, index: { unique: true }

      # Баланс: DECIMAL для точности финансовых операций
      # NUMERIC в PostgreSQL (или DECIMAL в MySQL) - лучший выбор для денег
      t.numeric :balance_persistent, precision: 15, scale: 2, null: false

      t.timestamps # created_at и updated_at
    end
  end
end
