class Campus < ApplicationRecord
  normalizes :name, with: ->(name) { name.squish }

  validates :name, presence: true, normalized_uniqueness: true
end
