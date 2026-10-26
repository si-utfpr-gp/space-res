class Building < ApplicationRecord
  belongs_to :campus

  normalizes :name, with: ->(name) { name.squish }

  validates :name, presence: true, normalized_uniqueness: { scope: :campus_id }

  scope :sorted, -> { eager_load(:campus).order("campi.name", :name) }
end
