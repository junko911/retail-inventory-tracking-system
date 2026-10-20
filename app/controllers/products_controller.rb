class ProductsController < ApplicationController
  def index
    @products = Product.includes(:brand).order(:name)
    @tracking_event_counts = TrackingEvent.group(:product_id).count
    @price_check_counts = PriceCheck.group(:product_id).count
  end

  def show
    @product = Product.find(params[:id])
    @tracking_event_count = @product.tracking_events.count
    @tracking_events = @product.tracking_events
      .includes(:store)
      .order(event_time: :desc, id: :desc)
      .limit(PREVIEW_LIMIT)
    @price_check_count = @product.price_checks.count
    @price_checks = @product.price_checks
      .includes(:store)
      .order(event_time: :desc, id: :desc)
      .limit(PREVIEW_LIMIT)
  end
end
