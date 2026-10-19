class Store < ApplicationRecord
  has_many :tracking_events
  has_many :price_checks
end
