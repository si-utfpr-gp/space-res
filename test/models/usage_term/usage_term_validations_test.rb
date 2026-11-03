require "test_helper"

class UsageTermValidationsTest < ActiveSupport::TestCase
  subject { @usage_term }
  setup do
    @usage_term = create(:usage_term, title: "Termo do Laboratório")
  end

  should validate_presence_of(:title).with_message("Informe o título do termo.")
  should validate_uniqueness_of(:title).case_insensitive.with_message("Já existe um termo cadastrado com este título.")
  should validate_presence_of(:content).with_message("Informe o texto do termo.")

  test "rejects a title with only spaces" do
    usage_term = build(:usage_term, title: "   ")

    assert_not usage_term.valid?
    assert_includes usage_term.errors[:title], "Informe o título do termo."
  end

  test "rejects a content with only spaces and line breaks" do
    usage_term = build(:usage_term, content: "  \r\n\n \t\n ")

    assert_not usage_term.valid?
    assert_includes usage_term.errors[:content], "Informe o texto do termo."
  end

  test "rejects a taken title in upper case with accents" do
    assert_title_taken build(:usage_term, title: "TERMO DO LABORATÓRIO")
  end

  test "rejects a taken title without accents" do
    assert_title_taken build(:usage_term, title: "Termo do Laboratorio")
  end

  test "rejects a taken title written without spaces" do
    assert_title_taken build(:usage_term, title: "termodolaboratorio")
  end

  test "rejects a taken title with punctuation" do
    assert_title_taken build(:usage_term, title: "Termo-do-Laboratório.")
  end

  test "lets a term change the letter case and accents of its own title" do
    assert @usage_term.update(title: "TERMO DO LABORATORIO")
  end

  test "rejects renaming a term to the title of another term" do
    usage_term = create(:usage_term, title: "Termo da Quadra")

    assert_not usage_term.update(title: "termo do laboratorio")
    assert_includes usage_term.errors[:title], "Já existe um termo cadastrado com este título."
  end

  private

    def assert_title_taken(usage_term)
      assert_not usage_term.valid?
      assert_includes usage_term.errors[:title], "Já existe um termo cadastrado com este título."
    end
end
