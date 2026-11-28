require "test_helper"

class ComparableNameTest < ActiveSupport::TestCase
  test "keeps only letters and digits, ignoring case and accents" do
    assert_equal "laboratoriodeinformaticac3", ComparableName.from("  Laboratório de Informática C-3. ").key
  end

  test "folds accented capital letters" do
    assert_equal ComparableName.from("área"), ComparableName.from("ÁREA")
  end

  test "treats names that differ only in spaces and punctuation as equal" do
    assert_equal ComparableName.from("Bloco A"), ComparableName.from("bloco-a")
  end

  test "tells apart names with different letters" do
    assert_not_equal ComparableName.from("Bloco A"), ComparableName.from("Bloco B")
  end

  test "includes a part of the name" do
    name = ComparableName.from("Laboratório de Informática C3")

    assert name.include?(ComparableName.from("laboratorio"))
    assert name.include?(ComparableName.from("INFORMÁTICA c3"))
    assert_not name.include?(ComparableName.from("auditório"))
  end

  test "includes a part written with spaces the name does not have" do
    assert ComparableName.from("Sala B102").include?(ComparableName.from("b 102"))
  end

  test "builds an empty key from blank text" do
    assert_equal "", ComparableName.from(nil).key
    assert_equal "", ComparableName.from("  ").key
  end
end
