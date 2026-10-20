require "test_helper"

class CampusValidationsTest < ActiveSupport::TestCase
  subject { @campus }
  setup do
    @campus = create(:campus, name: "Campo Mourão")
  end

  should validate_presence_of(:name)
  should validate_uniqueness_of(:name).case_insensitive

  test "rejects a taken name without accents" do
    assert_name_taken build(:campus, name: "Campo Mourao")
  end

  test "rejects a taken name without cedilla" do
    create(:campus, name: "Foz do Iguaçu")

    assert_name_taken build(:campus, name: "Foz do Iguacu")
  end

  test "rejects a taken name written without spaces" do
    assert_name_taken build(:campus, name: "campomourao")
  end

  test "rejects a taken name with punctuation" do
    assert_name_taken build(:campus, name: "Campo-Mourão.")
  end

  test "lets a campus change the letter case and accents of its own name" do
    assert @campus.update(name: "CAMPO MOURAO")
  end

  test "rejects renaming a campus to the name of another campus" do
    campus = create(:campus, name: "Pato Branco")

    assert_not campus.update(name: "CAMPO MOURÃO")
    assert_includes campus.errors[:name], "Já existe um campus cadastrado com este nome."
  end

  private

    def assert_name_taken(campus)
      assert_not campus.valid?
      assert_includes campus.errors[:name], "Já existe um campus cadastrado com este nome."
    end
end
