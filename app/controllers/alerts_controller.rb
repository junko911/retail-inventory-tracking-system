class AlertsController < ApplicationController
  def index
    scope = Alert.order(triggered_at: :desc, id: :desc)
    scope = scope.where(brand_id: params[:brand_id]) if params[:brand_id].present?
    @alert_count = scope.count
    current_page(@alert_count)
    @alerts = scope.includes(:brand, :product, :store).offset(page_offset).limit(PER_PAGE)
  end

  def show
    @alert = Alert.includes(:brand, :product, :store, :opening_tracking_event, :confirming_tracking_event).find(params[:id])
  end
end
