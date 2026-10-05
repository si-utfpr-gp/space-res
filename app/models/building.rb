class Building < ApplicationRecord
  belongs_to :campus

  normalizes :name, with: ->(name) { name.squish }

  validates :name, presence: true, uniqueness: { scope: :campus_id, case_sensitive: false }
end
