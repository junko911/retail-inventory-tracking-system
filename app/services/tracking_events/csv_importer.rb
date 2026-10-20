require "csv"

module TrackingEvents
  # Bulk-loads tracking events from CSV.
  #
  # Uses insert_all (no per-row callbacks). Alerts are rebuilt once at the end
  # with Alerts::Backfill. Interactive TrackingEvent.create! still syncs alerts
  # via after_create.
  #
  # Not idempotent: aborts if any tracking events already exist so a second run
  # cannot duplicate the CSV and invent false stockout streaks.
  class CsvImporter
    class AlreadyImportedError < StandardError; end

    BATCH_SIZE = 5_000

    def initialize(path)
      @path = path
      @parsed_dates = {}
    end

    def call
      if TrackingEvent.exists?
        raise AlreadyImportedError,
              "Tracking events already exist. Truncate tracking_events (and alerts) " \
              "or use a fresh database before importing again."
      end

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
        event_time = parse_date(row["Date"])
        next unless store_id && product_id && event_time

        batch << {
          store_id: store_id,
          product_id: product_id,
          event_time: event_time,
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

      alert_count = created_count.positive? ? Alerts::Backfill.call : 0

      Rails.logger.info(
        "[TrackingEvents::CsvImporter] rows processed=#{row_count} " \
        "created=#{created_count} alerts=#{alert_count}"
      )

      { rows_processed: row_count, created: created_count, alerts: alert_count }
    end

    private

    # Memoize: the CSV repeats a small set of calendar dates many times.
    # Returns nil for blank/unparseable values so those rows are skipped.
    def parse_date(value)
      return if value.blank?

      @parsed_dates.fetch(value) do
        @parsed_dates[value] = Date.parse(value)
      rescue ArgumentError, TypeError
        @parsed_dates[value] = nil
      end
    end

    def cast_boolean(value)
      case value
      when true, "true", "TRUE", "t", "T", "1", "True" then true
      else false
      end
    end
  end
end
