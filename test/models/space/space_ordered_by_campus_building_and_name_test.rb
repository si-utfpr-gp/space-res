require "test_helper"

class SpaceOrderedByCampusBuildingAndNameTest < ActiveSupport::TestCase
  test "orders by campus, then building, then name, with the spaces without building last in each campus" do
    pato_branco = create(:campus, name: "Pato Branco")
    guarapuava = create(:campus, name: "Guarapuava")
    bloco_c = create(:building, campus: guarapuava, name: "Bloco C")
    bloco_b = create(:building, campus: guarapuava, name: "Bloco B")
    create(:space, campus: pato_branco, name: "Auditório")
    create(:space, campus: guarapuava, name: "Planetário")
    create(:space, campus: guarapuava, building: bloco_c, name: "Sala 1")
    create(:space, campus: guarapuava, building: bloco_b, name: "Sala 2")
    create(:space, campus: guarapuava, building: bloco_b, name: "Sala 1")

    assert_equal [
      [ "Guarapuava", "Bloco B", "Sala 1" ],
      [ "Guarapuava", "Bloco B", "Sala 2" ],
      [ "Guarapuava", "Bloco C", "Sala 1" ],
      [ "Guarapuava", nil, "Planetário" ],
      [ "Pato Branco", nil, "Auditório" ]
    ], Space.ordered_by_campus_building_and_name.map { |space| [ space.campus.name, space.building&.name, space.name ] }
  end

  test "loads the campus and the building of each space" do
    create(:space, :with_building)

    space = Space.ordered_by_campus_building_and_name.first

    assert space.association(:campus).loaded?
    assert space.association(:building).loaded?
  end
end
