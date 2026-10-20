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
    @alert_count = @brand.alerts.count
    @alerts = @brand.alerts.includes(:product, :store).order(triggered_at: :desc, id: :desc).limit(20)
  end
end
