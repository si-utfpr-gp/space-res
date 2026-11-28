require "test_helper"

class BuildingCampusReadonlyTest < ActiveSupport::TestCase
  setup do
    @guarapuava = create(:campus, name: "Guarapuava")
    @pato_branco = create(:campus, name: "Pato Branco")
    @building = create(:building, campus: @guarapuava, name: "Bloco B")
  end

  test "refuses to change the campus of a saved building" do
    assert_raises(ActiveRecord::ReadonlyAttributeError) { @building.update(campus: @pato_branco) }
    assert_raises(ActiveRecord::ReadonlyAttributeError) { @building.campus_id = @pato_branco.id }

    assert_equal @guarapuava, @building.reload.campus
  end

  test "leaves the spaces of the building in its campus" do
    space = create(:space, campus: @guarapuava, building: @building)

    assert_raises(ActiveRecord::ReadonlyAttributeError) { @building.update(campus: @pato_branco) }

    assert_equal @guarapuava, space.reload.campus
  end

  test "keeps the name editable" do
    assert @building.update(name: "Bloco C")

    assert_equal [ @guarapuava, "Bloco C" ], [ @building.reload.campus, @building.name ]
  end

  test "sets the campus of a new building" do
    building = Building.new(name: "Bloco R")
    building.campus = @pato_branco

    assert building.save
    assert_equal @pato_branco, building.reload.campus
  end
end
