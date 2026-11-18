require "test_helper"

class SpaceValidationsTest < ActiveSupport::TestCase
  TAKEN_IN_BUILDING = "Já existe um espaço com este nome neste bloco.".freeze
  TAKEN_WITHOUT_BUILDING = "Já existe um espaço sem bloco com este nome neste campus.".freeze

  subject { @space }
  setup do
    @campus = create(:campus, name: "Guarapuava")
    @building = create(:building, campus: @campus, name: "Bloco B")
    @space = create(:space, campus: @campus, building: @building, name: "Sala 101")
  end

  should validate_presence_of(:name)
  should validate_presence_of(:description)
  should validate_uniqueness_of(:name).scoped_to(:building_id).case_insensitive.with_message(TAKEN_IN_BUILDING)

  test "requires a campus" do
    space = build(:space, campus: nil)

    assert_not space.valid?
    assert_equal [ "Selecione o campus." ], space.errors[:campus]
  end

  test "rejects a campus that does not exist" do
    space = build(:space, campus: nil, campus_id: 0)

    assert_not space.valid?
    assert_equal [ "Selecione o campus." ], space.errors[:campus]
  end

  test "rejects a blank name with its own message" do
    space = build(:space, name: "   ")

    assert_not space.valid?
    assert_equal [ "Informe o nome do espaço." ], space.errors[:name]
  end

  test "rejects a blank description with its own message" do
    space = build(:space, description: "  ")

    assert_not space.valid?
    assert_equal [ "Informe a descrição do espaço." ], space.errors[:description]
  end

  test "accepts a space without building, department and usage term" do
    assert build(:space, building: nil, department: nil, usage_term: nil).valid?
  end

  test "accepts a building of the chosen campus" do
    assert build(:space, campus: @campus, building: @building).valid?
  end

  test "rejects a building of another campus" do
    space = build(:space, campus: create(:campus, name: "Pato Branco"), building: @building)

    assert_not space.valid?
    assert_equal [ "Selecione um bloco do campus escolhido." ], space.errors[:building]
  end

  test "rejects a building that does not exist" do
    space = build(:space, campus: @campus, building_id: 0)

    assert_not space.valid?
    assert_equal [ "Selecione um bloco do campus escolhido." ], space.errors[:building]
  end

  test "reports only the missing campus when the campus is missing and a building is chosen" do
    space = build(:space, campus: nil, building: @building)

    assert_not space.valid?
    assert_equal [ :campus ], space.errors.attribute_names
  end

  test "rejects a taken name in the same building, ignoring letter case" do
    space = build(:space, campus: @campus, building: @building, name: "SALA 101")

    assert_not space.valid?
    assert_equal [ TAKEN_IN_BUILDING ], space.errors[:name]
  end

  test "accepts the same name in another building" do
    other_building = create(:building, campus: @campus, name: "Bloco C")

    assert build(:space, campus: @campus, building: other_building, name: "Sala 101").valid?
  end

  test "rejects a taken name among the spaces without building of the same campus" do
    create(:space, campus: @campus, name: "Planetário")
    space = build(:space, campus: @campus, name: "planetário")

    assert_not space.valid?
    assert_equal [ TAKEN_WITHOUT_BUILDING ], space.errors[:name]
  end

  test "accepts the same name without building in another campus" do
    create(:space, campus: @campus, name: "Planetário")

    assert build(:space, campus: create(:campus, name: "Pato Branco"), name: "Planetário").valid?
  end

  test "accepts a space without building with the name of a space in a building" do
    assert build(:space, campus: @campus, name: "Sala 101").valid?
  end

  test "accepts a space in a building with the name of a space without building" do
    create(:space, campus: @campus, name: "Planetário")

    assert build(:space, campus: @campus, building: @building, name: "Planetário").valid?
  end

  test "lets a space keep its name and change its letter case" do
    assert @space.update(name: "SALA 101")
  end

  test "rejects moving a space to a building that already has its name" do
    other_building = create(:building, campus: @campus, name: "Bloco C")
    space = create(:space, campus: @campus, building: other_building, name: "Sala 101")

    assert_not space.update(building: @building)
    assert_equal [ TAKEN_IN_BUILDING ], space.errors[:name]
  end

  test "rejects removing the building when a space without building has the name" do
    create(:space, campus: @campus, name: "Sala 101")

    assert_not @space.update(building: nil)
    assert_equal [ TAKEN_WITHOUT_BUILDING ], @space.errors[:name]
  end

  test "rejects a blank approval flag instead of leaving it to the database" do
    space = build(:space, requires_approval: "")

    assert_not space.valid?
    assert_equal [ "Informe se a reserva precisa de aprovação." ], space.errors[:requires_approval]
  end

  test "rejects a department that does not exist" do
    space = build(:space, department_id: 0)

    assert_not space.valid?
    assert_equal [ "Selecione um departamento cadastrado." ], space.errors[:department]
  end

  test "rejects a usage term that does not exist" do
    space = build(:space, usage_term_id: 0)

    assert_not space.valid?
    assert_equal [ "Selecione um termo de uso cadastrado." ], space.errors[:usage_term]
  end

  test "accepts an existing department and usage term" do
    assert build(:space, department: create(:department), usage_term: create(:usage_term)).valid?
  end

  test "does not look up the other records again when they did not change" do
    space = create(:space, :with_building, department: create(:department), usage_term: create(:usage_term))
    space.reload

    assert_no_queries_match(/FROM "(buildings|departments|usage_terms)"/) { space.update!(description: "Térreo") }
  end
end
