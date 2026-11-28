require "test_helper"

class SpaceCampusReadonlyTest < ActiveSupport::TestCase
  setup do
    @guarapuava = create(:campus, name: "Guarapuava")
    @pato_branco = create(:campus, name: "Pato Branco")
    @space = create(:space, campus: @guarapuava, name: "Planetário")
  end

  test "refuses to change the campus of a saved space" do
    assert_raises(ActiveRecord::ReadonlyAttributeError) { @space.update(campus: @pato_branco) }
    assert_raises(ActiveRecord::ReadonlyAttributeError) { @space.campus_id = @pato_branco.id }

    assert_equal @guarapuava, @space.reload.campus
  end

  test "keeps the other attributes editable" do
    building = create(:building, campus: @guarapuava)

    assert @space.update(name: "Planetário Digital", building: building)

    assert_equal [ @guarapuava, building, "Planetário Digital" ], [ @space.reload.campus, @space.building, @space.name ]
  end
end
