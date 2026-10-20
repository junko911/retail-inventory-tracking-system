class TrackingEvent < ApplicationRecord
  belongs_to :product
  belongs_to :store

  after_create :sync_stockout_alert, if: -> { event_time.present? }

  private

  def sync_stockout_alert
    Alerts::SyncForTrackingEvent.call(self)
  end
end
