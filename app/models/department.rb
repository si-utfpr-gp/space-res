class Department < ApplicationRecord
  has_many :users, dependent: :restrict_with_error

  normalizes :name, with: ->(name) { name.squish }

  validates :name, presence: true, uniqueness: { case_sensitive: false }
end
