class Building < ApplicationRecord
  belongs_to :campus
  has_many :spaces, dependent: :restrict_with_error

  normalizes :name, with: ->(name) { name.squish }

  validates :name, presence: true, normalized_uniqueness: { scope: :campus_id }

  # A space never sits in a campus other than its building's, so the spaces follow the building.
  after_update :move_spaces_to_new_campus, if: :saved_change_to_campus_id?

  scope :sorted, -> { eager_load(:campus).order("campi.name", :name) }

  private

    # Runs inside the transaction of the save: the building and its spaces move together or not at all.
    def move_spaces_to_new_campus
      spaces.update_all(campus_id: campus_id, updated_at: Time.current)
    end
end
