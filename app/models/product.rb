class Product < ApplicationRecord
  belongs_to :brand
  has_many :tracking_events
  has_many :price_checks
  has_many :alerts

  # Globally unique: the tracking CSV identifies products by name only (no brand column).
  validates :name, presence: true, uniqueness: true
end

