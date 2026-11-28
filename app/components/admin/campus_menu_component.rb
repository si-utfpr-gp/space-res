# frozen_string_literal: true

# The side menu of the pages of one campus: the way back to the entry, the campus selector and the
# sections of the campus.
class Admin::CampusMenuComponent < ViewComponent::Base
  SECTIONS = { overview: :gauge, spaces: :door, buildings: :building_office }.freeze

  def initialize(campus:, campi:, section:)
    @campus = campus
    @campi = campi.to_a
    @section = section
  end

  # The saved name, so a rejected edit of the campus does not rename it in the menu.
  def campus_name
    @campus.name_in_database
  end

  def selector?
    @campi.many?
  end

  def current_section?(section)
    section == @section
  end

  def current_campus?(campus)
    campus == @campus
  end

  # The selector opens the chosen campus on the section being viewed; from a form or a space page,
  # on the listing of that section.
  def section_path(section, campus = @campus)
    case section
    when :overview then admin_campus_path(campus)
    when :spaces then admin_campus_spaces_path(campus)
    when :buildings then admin_campus_buildings_path(campus)
    else raise ArgumentError, "Unknown campus section: #{section.inspect}"
    end
  end
end
