module Alerts
  # Rebuilds alerts from tracking events already in the database.
  # New events do this themselves. Use this after importing events that were
  # saved before alerts existed, or to repair alerts in one pass.
  class Backfill
    def self.call
      new.call
    end

    def call
      now = Time.current
      records = rows(now)

      Alert.transaction do
        Alert.delete_all
        Alert.insert_all(records) if records.any?
      end

      records.length
    end

    private

    def rows(now)
      sql = <<~SQL.squish
        WITH ordered AS (
          SELECT
            tracking_events.id,
            tracking_events.store_id,
            tracking_events.product_id,
            tracking_events.inventory_present,
            LAG(tracking_events.inventory_present) OVER w AS previous_inventory,
            LEAD(tracking_events.id) OVER w AS next_id,
            LEAD(tracking_events.inventory_present) OVER w AS next_inventory,
            LEAD(tracking_events.event_time) OVER w AS next_event_time
          FROM tracking_events
          WHERE tracking_events.event_time IS NOT NULL
          WINDOW w AS (PARTITION BY tracking_events.store_id, tracking_events.product_id ORDER BY tracking_events.event_time, tracking_events.id)
        )
        SELECT
          products.brand_id,
          ordered.store_id,
          ordered.product_id,
          ordered.id AS opening_tracking_event_id,
          ordered.next_id AS confirming_tracking_event_id,
          ordered.next_event_time AS triggered_at,
          ? AS created_at,
          ? AS updated_at
        FROM ordered
        INNER JOIN products ON products.id = ordered.product_id
        WHERE ordered.inventory_present = FALSE
          AND ordered.next_inventory = FALSE
          AND (ordered.previous_inventory IS NULL OR ordered.previous_inventory = TRUE)
      SQL

      Alert.connection.select_all(
        Alert.sanitize_sql_array([sql, now, now])
      ).to_a
    end
  end
end
