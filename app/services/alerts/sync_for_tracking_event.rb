module Alerts
  # Keeps alerts correct after one tracking event is created.
  #
  # Alerts are based on event_time order for a store/product pair, not insert
  # order. Inserting one event can change whether that event, the one before it,
  # or the one after it is the start of a two-stockout streak.
  class SyncForTrackingEvent
    def self.call(event)
      new(event).call
    end

    def initialize(event)
      @event = event
    end

    def call
      return if @event.event_time.blank?

      previous_event, next_event = neighbors(@event)

      # Each of these may gain or lose "opening of a streak" status.
      # Syncing the previous event also updates or clears an alert that used to
      # treat previous+next as a consecutive pair before @event was inserted.
      sync_opening_alert(previous_event)
      sync_opening_alert(@event)
      sync_opening_alert(next_event)
    end

    private

    # Create or update an alert when this event starts a two-stockout streak
    # (stockout, previous not, next is). Otherwise delete any alert opened by it.
    def sync_opening_alert(event)
      return if event.nil?

      previous_event, next_event = neighbors(event)
      if stockout?(event) && !stockout?(previous_event) && stockout?(next_event)
        alert = Alert.find_or_initialize_by(opening_tracking_event_id: event.id)
        alert.assign_attributes(
          confirming_tracking_event: next_event,
          brand_id: event.product.brand_id,
          store_id: event.store_id,
          product_id: event.product_id,
          triggered_at: next_event.event_time
        )
        alert.save!
      else
        Alert.where(opening_tracking_event_id: event.id).delete_all
      end
    end

    def stockout?(event)
      event.present? && event.inventory_present == false
    end

    def neighbors(event)
      scope = TrackingEvent.where(store_id: event.store_id, product_id: event.product_id)
      previous_event = scope
        .where("(event_time, id) < (?, ?)", event.event_time, event.id)
        .order(event_time: :desc, id: :desc)
        .first
      next_event = scope
        .where("(event_time, id) > (?, ?)", event.event_time, event.id)
        .order(event_time: :asc, id: :asc)
        .first

      [previous_event, next_event]
    end
  end
end
