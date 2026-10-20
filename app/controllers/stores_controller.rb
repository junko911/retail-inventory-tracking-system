class StoresController < ApplicationController
  def index
    @stores = Store.order(:address)
    @tracking_event_counts = TrackingEvent.group(:store_id).count
    @price_check_counts = PriceCheck.group(:store_id).count
  end

  def show
    @store = Store.find(params[:id])
    @tracking_event_count = @store.tracking_events.count
    @tracking_events = @store.tracking_events
      .includes(product: :brand)
      .order(event_time: :desc, id: :desc)
      .limit(PREVIEW_LIMIT)
    @price_check_count = @store.price_checks.count
    @price_checks = @store.price_checks
      .includes(product: :brand)
      .order(event_time: :desc, id: :desc)
      .limit(PREVIEW_LIMIT)
  end
end
