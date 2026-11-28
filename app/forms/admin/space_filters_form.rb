# frozen_string_literal: true

# The filters of the spaces listing of a campus. A value it does not know (a status that does not
# exist, a building of another campus) is ignored, as if "all" had been chosen.
class Admin::SpaceFiltersForm < BaseForm
  WITHOUT_BUILDING = "none"

  attr_reader :campus, :name, :building, :status

  def initialize(campus:, name: nil, building: nil, status: nil)
    @campus = campus
    @buildings = campus.buildings.ordered_by_name.to_a
    @name = comparable_name(name)
    @building = building.to_s if known_building?(building.to_s)
    @status = status.to_s if Space.statuses.key?(status.to_s)
  end

  def applied?
    [ name, building, status ].any?
  end

  def without_building?
    building == WITHOUT_BUILDING
  end

  # "Sem bloco" first, then the buildings of the campus; the blank choice ("all") comes from the select.
  def building_options
    [ [ I18n.t("admin.campi.spaces.no_building"), WITHOUT_BUILDING ] ] +
      @buildings.map { |item| [ item.name, item.id.to_s ] }
  end

  def status_options
    Space.statuses.keys.map { |item| [ I18n.t("admin.campi.spaces.status.#{item}"), item ] }
  end

  private

    # A name with nothing to compare (only spaces or punctuation) filters nothing, so it is dropped.
    def comparable_name(value)
      text = value.to_s.squish
      text if ComparableName.from(text).key.present?
    end

    def known_building?(value)
      value == WITHOUT_BUILDING || @buildings.any? { |item| item.id.to_s == value }
    end
end
