class Campus < ApplicationRecord
  has_many :buildings, dependent: :restrict_with_error
  has_many :spaces, dependent: :restrict_with_error

  normalizes :name, with: ->(name) { name.squish }

  validates :name, presence: true, normalized_uniqueness: true

  scope :ordered_by_name, -> { order(:name) }
end
