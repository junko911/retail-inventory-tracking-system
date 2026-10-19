class CreatePriceChecks < ActiveRecord::Migration[7.1]
  def change
    create_table :price_checks do |t|
      t.decimal :price, precision: 10, scale: 2, null: false
      t.references :product, null: false, foreign_key: true, index: false
      t.references :store, null: false, foreign_key: true
      t.datetime :event_time, null: false
      t.timestamps

      t.check_constraint "price >= 0", name: "price_checks_price_non_negative"
    end

    add_index :price_checks, [:product_id, :store_id, :event_time]
  end
end
