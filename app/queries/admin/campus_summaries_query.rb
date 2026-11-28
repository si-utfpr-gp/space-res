# One summary per campus, in name order, for the cards of the administrative area entry.
# Four queries in all, whatever the number of campi.
class Admin::CampusSummariesQuery
  CampusSummary = Data.define(:campus, :spaces_count, :buildings_count, :unavailable_spaces_count)

  def call
    spaces = Space.group(:campus_id).count
    unavailable_spaces = Space.unavailable.group(:campus_id).count
    buildings = Building.group(:campus_id).count

    Campus.ordered_by_name.map do |campus|
      CampusSummary.new(campus:,
                        spaces_count: spaces.fetch(campus.id, 0),
                        buildings_count: buildings.fetch(campus.id, 0),
                        unavailable_spaces_count: unavailable_spaces.fetch(campus.id, 0))
    end
  end
end
