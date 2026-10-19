class StoresController < ApplicationController
  def index
    @stores = Store.all
  end

  def show
    @store = Store.find(params[:id])
    @tracking_events = @store.tracking_events.includes(product: :brand).order(event_time: :desc)
    @price_checks = @store.price_checks.includes(product: :brand).order(event_time: :desc)
  end
end
