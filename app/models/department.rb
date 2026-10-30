class Department < ApplicationRecord
  normalizes :name, with: ->(name) { name.squish }

  validates :name, presence: true, normalized_uniqueness: true

  scope :sorted, -> { order(:name) }
end
