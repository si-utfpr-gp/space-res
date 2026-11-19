module Admin::BuildingsHelper
  # Warns, before the campus of a building is changed, that its spaces follow it.
  def building_campus_change_hint(building)
    spaces_count = building.persisted? ? building.spaces.count : 0

    t("admin.buildings.form.campus_change_hint", count: spaces_count) if spaces_count.positive?
  end
end
