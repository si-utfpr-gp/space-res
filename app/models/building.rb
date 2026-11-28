class Building < ApplicationRecord
  belongs_to :campus
  has_many :spaces, dependent: :restrict_with_error

  # A building stays in the campus it was registered in; one in the wrong campus is deleted and
  # registered again. Writing the campus of a saved building raises ActiveRecord::ReadonlyAttributeError,
  # even with the same campus (assign_attributes(campus:), campus.buildings << building).
  attr_readonly :campus_id

  normalizes :name, with: ->(name) { name.squish }

  validates :name, presence: true, normalized_uniqueness: { scope: :campus_id }

  scope :ordered_by_name, -> { order(:name) }
end
