require "csv"

module TrackingEvents
  # Bulk-loads tracking events from CSV.
  #
  # Uses insert_all (no per-row callbacks). Alerts are rebuilt once at the end
  # with Alerts::Backfill. Interactive TrackingEvent.create! still syncs alerts
  # via after_create.
  class CsvImporter
    BATCH_SIZE = 5_000

    def initialize(path)
      @path = path
    end

    def call
      store_ids_by_address = Store.pluck(:address, :id).to_h
      product_ids_by_name = Product.pluck(:name, :id).to_h

      row_count = 0
      created_count = 0
      batch = []
      now = Time.current

      CSV.foreach(@path, headers: true) do |row|
        row_count += 1

        store_id = store_ids_by_address[row["Address"]]
        product_id = product_ids_by_name[row["Product Name"]]
        next unless store_id && product_id

        batch << {
          store_id: store_id,
          product_id: product_id,
          event_time: Date.parse(row["Date"]),
          inventory_present: cast_boolean(row["Inventory Present"]),
          created_at: now,
          updated_at: now
        }

        if batch.size >= BATCH_SIZE
          TrackingEvent.insert_all(batch)
          created_count += batch.size
          batch.clear
        end
      end

      if batch.any?
        TrackingEvent.insert_all(batch)
        created_count += batch.size
      end

      alert_count = Alerts::Backfill.call

      Rails.logger.info(
        "[TrackingEvents::CsvImporter] rows processed=#{row_count} " \
        "created=#{created_count} alerts=#{alert_count}"
      )

      { rows_processed: row_count, created: created_count, alerts: alert_count }
    end

    private

    def cast_boolean(value)
      case value
      when true, "true", "TRUE", "t", "T", "1", "True" then true
      else false
      end
    end
  end
end
