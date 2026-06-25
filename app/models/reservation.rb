class Reservation < ApplicationRecord
  belongs_to :user
  belongs_to :space
  has_many :reservation_dates
  has_one :approval
end