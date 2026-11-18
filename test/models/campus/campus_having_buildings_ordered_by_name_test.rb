require "test_helper"

class CampusHavingBuildingsOrderedByNameTest < ActiveSupport::TestCase
  test "orders the campi and their buildings by name, leaving out the campi without buildings" do
    pato_branco = create(:campus, name: "Pato Branco")
    guarapuava = create(:campus, name: "Guarapuava")
    create(:campus, name: "Apucarana")
    create(:building, campus: pato_branco, name: "Bloco V")
    create(:building, campus: guarapuava, name: "Bloco R")
    create(:building, campus: guarapuava, name: "Bloco B")

    assert_equal [ [ "Guarapuava", [ "Bloco B", "Bloco R" ] ], [ "Pato Branco", [ "Bloco V" ] ] ],
                 Campus.having_buildings_ordered_by_name.map { |campus| [ campus.name, campus.buildings.map(&:name) ] }
  end

  test "loads the buildings of each campus" do
    create(:building)

    assert Campus.having_buildings_ordered_by_name.first.association(:buildings).loaded?
  end
end
