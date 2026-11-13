class Space < ApplicationRecord
  belongs_to :campus
  belongs_to :building, optional: true
  belongs_to :department, optional: true
  belongs_to :usage_term, optional: true

  UNAVAILABILITY_REASON_MAX_LENGTH = 100

  # A change of status asked from a status it does not start from: a repeated action, or a page opened
  # before another administrator's change.
  class StatusConflict < StandardError; end

  # Unavailable: still listed for reservation, but cannot be reserved. Deactivated: no longer listed.
  enum :status, { available: "available", unavailable: "unavailable", deactivated: "deactivated" }

  normalizes :name, with: ->(name) { name.squish }
  normalizes :unavailability_reason, with: ->(reason) { reason.squish.presence }

  validates :name, presence: true
  validates :name, uniqueness: { case_sensitive: false, scope: :building_id }, unless: :without_building?
  validates :name, uniqueness: { case_sensitive: false, scope: :campus_id, conditions: -> { where(building_id: nil) },
                                 message: :taken_without_building }, if: :without_building?
  # optional: true skips the existence check; these refuse a new id that matches no record.
  validates :building, presence: true, if: -> { building_id_changed? && !without_building? }
  validates :department, presence: true, if: -> { department_id_changed? && !department_id.nil? }
  validates :usage_term, presence: true, if: -> { usage_term_id_changed? && !usage_term_id.nil? }
  # A blank value from a hand-made request becomes nil, which the column refuses.
  validates :requires_approval, inclusion: { in: [ true, false ] }
  validate :building_belongs_to_campus, if: -> { building_id_changed? || campus_id_changed? }
  validates :unavailability_reason, presence: true, length: { maximum: UNAVAILABILITY_REASON_MAX_LENGTH }, if: :unavailable?

  # The reason only means something while the space is unavailable.
  before_save :forget_unavailability_reason, unless: :unavailable?

  scope :ordered_by_campus_building_and_name, -> {
    eager_load(:campus, :building)
      .order("campi.name", Arel.sql("buildings.name IS NULL"), "buildings.name", "spaces.name")
  }

  def without_building?
    building_id.nil?
  end

  def mark_unavailable(reason)
    change_status_from(:available) { update(status: :unavailable, unavailability_reason: reason) }
  end

  def change_unavailability_reason(reason)
    change_status_from(:unavailable) { update(unavailability_reason: reason) }
  end

  def end_unavailability
    change_status_from(:unavailable) { update!(status: :available) }
  end

  def deactivate
    change_status_from(:available, :unavailable) { update!(status: :deactivated) }
  end

  def reactivate
    change_status_from(:deactivated) { update!(status: :available) }
  end

  private

    def building_belongs_to_campus
      return if building.nil? || campus.nil? || building.campus_id == campus_id

      errors.add(:building, :other_campus)
    end

    def forget_unavailability_reason
      self.unavailability_reason = nil
    end

    # Reloads the space inside a locked transaction, so the check and the change see the same saved status.
    def change_status_from(*statuses)
      with_lock do
        raise StatusConflict, "a #{status} space cannot change this way" unless status.to_sym.in?(statuses)

        yield
      end
    end
end
