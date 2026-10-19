class ProductsController < ApplicationController
  def index
    @products = Product.all
  end

  def show
    @product = Product.find(params[:id])
    @tracking_events = @product.tracking_events.includes(:store).order(event_time: :desc)
    @price_checks = @product.price_checks.includes(:store).order(event_time: :desc)
  end
end

