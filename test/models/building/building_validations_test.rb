require "test_helper"

class BuildingValidationsTest < ActiveSupport::TestCase
  subject { @building }
  setup do
    @campus = create(:campus, name: "Guarapuava")
    @building = create(:building, campus: @campus, name: "Bloco Química")
  end

  should validate_presence_of(:name)
  # `scoped_to` only recognizes Rails' UniquenessValidator; the tests below cover the campus scope.
  should validate_uniqueness_of(:name).case_insensitive

  test "requires a campus" do
    building = build(:building, campus: nil)

    assert_not building.valid?
    assert_includes building.errors[:campus], "Selecione o campus."
  end

  test "rejects a campus that does not exist" do
    building = build(:building, campus: nil, campus_id: 0)

    assert_not building.valid?
    assert_includes building.errors[:campus], "Selecione o campus."
  end

  test "rejects a blank name with its own message" do
    building = build(:building, name: "   ")

    assert_not building.valid?
    assert_includes building.errors[:name], "Informe o nome do bloco."
  end

  test "rejects a taken name without accents in the same campus" do
    assert_name_taken build(:building, campus: @campus, name: "Bloco Quimica")
  end

  test "rejects a taken name written without spaces in the same campus" do
    assert_name_taken build(:building, campus: @campus, name: "blocoquímica")
  end

  test "rejects a taken name with punctuation in the same campus" do
    assert_name_taken build(:building, campus: @campus, name: "Bloco-Química.")
  end

  test "accepts the same name in another campus" do
    assert build(:building, campus: create(:campus, name: "Pato Branco"), name: "Bloco Química").valid?
  end

  test "lets a building change the letter case and accents of its own name" do
    assert @building.update(name: "BLOCO QUIMICA")
  end

  test "rejects renaming a building to the name of another building in the same campus" do
    building = create(:building, campus: @campus, name: "Bloco R")

    assert_not building.update(name: "bloco química")
    assert_includes building.errors[:name], "Já existe um bloco com este nome neste campus."
  end

  test "rejects moving a building to a campus that already has its name" do
    building = create(:building, campus: create(:campus, name: "Pato Branco"), name: "Bloco Química")

    assert_not building.update(campus: @campus)
    assert_includes building.errors[:name], "Já existe um bloco com este nome neste campus."
  end

  private

    def assert_name_taken(building)
      assert_not building.valid?
      assert_includes building.errors[:name], "Já existe um bloco com este nome neste campus."
    end
end
