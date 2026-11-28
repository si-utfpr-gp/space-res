# The spaces of a campus for its listing, in building and name order, narrowed by the filters.
# Building and status are filtered in SQL; the name is compared in Ruby with ComparableName, so
# case and accents are ignored on SQLite as well. Preloads the campus, the building and the
# department, which the listing shows.
class Admin::CampusSpacesQuery
  def initialize(campus:, filters:)
    @campus = campus
    @filters = filters
  end

  def call
    spaces = @campus.spaces.ordered_by_campus_building_and_name.includes(:department)
    spaces = spaces.where(building_id: building_id) if @filters.building
    spaces = spaces.where(status: @filters.status) if @filters.status
    return spaces.to_a unless @filters.name

    name = ComparableName.from(@filters.name)
    spaces.select { |space| ComparableName.from(space.name).include?(name) }
  end

  private

    def building_id
      @filters.without_building? ? nil : @filters.building
    end
end
