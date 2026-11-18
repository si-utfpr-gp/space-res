class Campus < ApplicationRecord
  has_many :buildings, dependent: :restrict_with_error
  has_many :spaces, dependent: :restrict_with_error

  normalizes :name, with: ->(name) { name.squish }

  validates :name, presence: true, normalized_uniqueness: true

  # The groups of a building select: campi without buildings are left out, and both come in name order.
  scope :having_buildings_ordered_by_name, -> {
    eager_load(:buildings).where.not(buildings: { id: nil }).order(:name, "buildings.name")
  }
end
