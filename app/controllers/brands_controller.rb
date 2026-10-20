class BrandsController < ApplicationController
  def index
    @brands = Brand.all
  end

  def show
    @brand = Brand.find(params[:id])
    @alert_count = @brand.alerts.count
    @alerts = @brand.alerts.includes(:product, :store).order(triggered_at: :desc, id: :desc).limit(20)
  end
end

