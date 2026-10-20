# A brand alert for one stockout streak at a store.
#
# A streak is a run of tracking events for the same store and product, ordered by
# event_time and then id, whose inventory_present value is false. The alert is
# created when that run reaches two events. Later no-inventory events in the same
# run do not create another alert. An inventory-present event ends the run, so the
# next two consecutive stockouts open a new alert.
#
# opening_tracking_event is the first no-inventory event in the run.
# confirming_tracking_event is the second, and triggered_at is that event's time.
# Events may arrive out of event_time order. Saving a tracking event repairs only
# the alerts adjacent to it.
class Alert < ApplicationRecord
  belongs_to :brand
  belongs_to :store
  belongs_to :product
  belongs_to :opening_tracking_event, class_name: "TrackingEvent"
  belongs_to :confirming_tracking_event, class_name: "TrackingEvent"

  validates :triggered_at, presence: true
  validates :opening_tracking_event_id, uniqueness: true
  validates :confirming_tracking_event_id, uniqueness: true
end
