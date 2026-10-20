class PriceChecksController < ApplicationController
  def index
    scope = PriceCheck.order(event_time: :desc, id: :desc)
    scope = scope.where(product_id: params[:product_id]) if params[:product_id].present?
    scope = scope.where(store_id: params[:store_id]) if params[:store_id].present?
    if params[:brand_id].present?
      scope = scope.joins(:product).where(products: { brand_id: params[:brand_id] })
    end

    @filter_product = Product.find_by(id: params[:product_id]) if params[:product_id].present?
    @filter_store = Store.find_by(id: params[:store_id]) if params[:store_id].present?
    @filter_brand = Brand.find_by(id: params[:brand_id]) if params[:brand_id].present?

    @price_check_count = scope.count
    current_page(@price_check_count)
    @price_checks = scope.includes(:store, product: :brand).offset(page_offset).limit(PER_PAGE)
  end
end
