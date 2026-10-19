class Product < ApplicationRecord
  belongs_to :brand
  has_many :tracking_events
  has_many :price_checks
end
