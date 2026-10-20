class AlertsController < ApplicationController
  def index
    @alerts = Alert.includes(:brand, :product, :store).order(triggered_at: :desc, id: :desc)
    @alerts = @alerts.where(brand_id: params[:brand_id]) if params[:brand_id].present?
  end

  def show
    @alert = Alert.includes(:brand, :product, :store, :opening_tracking_event, :confirming_tracking_event).find(params[:id])
  end
end
