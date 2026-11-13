require "test_helper"

class BuildingCampusChangeTest < ActiveSupport::TestCase
  setup do
    @guarapuava = create(:campus, name: "Guarapuava")
    @pato_branco = create(:campus, name: "Pato Branco")
    @building = create(:building, campus: @guarapuava, name: "Bloco B")
  end

  test "moves the spaces of the building to its new campus" do
    spaces = [ create(:space, campus: @guarapuava, building: @building), create(:space, :deactivated, campus: @guarapuava, building: @building) ]

    assert @building.update(campus: @pato_branco)

    assert_equal [ @pato_branco, @pato_branco ], spaces.map { |space| space.reload.campus }
    assert spaces.all? { |space| space.reload.valid? }
  end

  test "records when the spaces were moved" do
    space = create(:space, campus: @guarapuava, building: @building, updated_at: 2.days.ago)

    @building.update!(campus: @pato_branco)

    assert_operator space.reload.updated_at, :>, 1.minute.ago
  end

  test "leaves the spaces without building and the spaces of other buildings where they are" do
    without_building = create(:space, campus: @guarapuava)
    in_other_building = create(:space, campus: @guarapuava, building: create(:building, campus: @guarapuava))
    in_destination = create(:space, campus: @pato_branco)

    @building.update!(campus: @pato_branco)

    assert_equal [ @guarapuava, @guarapuava, @pato_branco ],
                 [ without_building, in_other_building, in_destination ].map { |space| space.reload.campus }
  end

  test "moves nothing when the campus change is refused" do
    create(:building, campus: @pato_branco, name: "Bloco B")
    space = create(:space, campus: @guarapuava, building: @building)

    assert_not @building.update(campus: @pato_branco)

    assert_equal @guarapuava, space.reload.campus
    assert_equal @guarapuava, @building.reload.campus
  end

  test "does not touch the spaces when only the name of the building changes" do
    create(:space, campus: @guarapuava, building: @building)

    assert_no_queries_match(/UPDATE "spaces"/) { @building.update!(name: "Bloco C") }
  end

  test "keeps the building in its campus when moving the spaces fails" do
    space = create(:space, campus: @guarapuava, building: @building)
    @building.stubs(:move_spaces_to_new_campus).raises(ActiveRecord::StatementInvalid)

    assert_raises(ActiveRecord::StatementInvalid) { @building.update(campus: @pato_branco) }

    assert_equal @guarapuava, @building.reload.campus
    assert_equal @guarapuava, space.reload.campus
  end

  test "lets a space with the name of a space without building of the new campus follow the building" do
    create(:space, campus: @pato_branco, name: "Auditório")
    space = create(:space, campus: @guarapuava, building: @building, name: "Auditório")

    assert @building.update(campus: @pato_branco)
    assert space.reload.valid?
  end
end
