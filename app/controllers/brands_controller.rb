class BrandsController < ApplicationController
  def index
    @brands = Brand.order(:name)
    @product_counts = Product.group(:brand_id).count
  end

  def show
    @brand = Brand.find(params[:id])
    @products = @brand.products.order(:name)
    product_ids = @products.map(&:id)

    @tracking_event_counts = TrackingEvent.where(product_id: product_ids).group(:product_id).count
    @price_check_counts = PriceCheck.where(product_id: product_ids).group(:product_id).count

    tracking_scope = TrackingEvent.joins(:product).where(products: { brand_id: @brand.id })
    @tracking_event_count = tracking_scope.count
    @tracking_events = tracking_scope.includes(:store, :product).order(event_time: :desc, id: :desc).limit(PREVIEW_LIMIT)

    price_scope = PriceCheck.joins(:product).where(products: { brand_id: @brand.id })
    @price_check_count = price_scope.count
    @price_checks = price_scope.includes(:store, :product).order(event_time: :desc, id: :desc).limit(PREVIEW_LIMIT)

    @alert_count = @brand.alerts.count
    @alerts = @brand.alerts.includes(:product, :store).order(triggered_at: :desc, id: :desc).limit(PREVIEW_LIMIT)
  end
end
