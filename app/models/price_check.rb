# A price observation for a product at a store. It does not imply an inventory check.
# Inventory is tracked separately by TrackingEvent.
class PriceCheck < ApplicationRecord
  belongs_to :product
  belongs_to :store

  validates :price, numericality: { greater_than_or_equal_to: 0 }
  validates :event_time, presence: true
end
