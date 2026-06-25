class Space < ApplicationRecord
  belongs_to :sector
  has_many :reservations
end
