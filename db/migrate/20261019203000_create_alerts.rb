class CreateAlerts < ActiveRecord::Migration[7.1]
  def change
    create_table :alerts do |t|
      t.references :brand, null: false, foreign_key: true, index: false
      t.references :store, null: false, foreign_key: true, index: false
      t.references :product, null: false, foreign_key: true
      t.references :opening_tracking_event, null: false,
                   foreign_key: { to_table: :tracking_events }, index: { unique: true }
      t.references :confirming_tracking_event, null: false,
                   foreign_key: { to_table: :tracking_events }, index: { unique: true }
      t.datetime :triggered_at, null: false
      t.timestamps
    end

    # Brand's alerts, newest first.
    add_index :alerts, [:brand_id, :triggered_at]
    # Repairing one store/product pair after a tracking event is saved.
    add_index :alerts, [:store_id, :product_id]
    # Global alerts index, newest first.
    add_index :alerts, [:triggered_at, :id]
    add_index :tracking_events, [:store_id, :product_id, :event_time, :id],
      name: "index_tracking_events_on_store_product_time"
    remove_index :tracking_events, :store_id
  end
end
