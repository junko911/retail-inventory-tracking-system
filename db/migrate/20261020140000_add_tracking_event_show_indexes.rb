class AddTrackingEventShowIndexes < ActiveRecord::Migration[7.1]
  def change
    add_index :tracking_events, [:product_id, :event_time, :id],
              name: "index_tracking_events_on_product_id_and_event_time"
    add_index :tracking_events, [:store_id, :event_time, :id],
              name: "index_tracking_events_on_store_id_and_event_time"
  end
end
