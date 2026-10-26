require "test_helper"

class CampusAssociationsTest < ActiveSupport::TestCase
  subject { build(:campus) }

  should have_many(:buildings).dependent(:restrict_with_error)

  test "keeps a campus that has buildings and explains why" do
    campus = create(:building).campus

    assert_not campus.destroy
    assert Campus.exists?(campus.id)
    assert_equal [ "Não é possível excluir o campus porque ele tem blocos cadastrados." ],
                 campus.errors.full_messages
  end

  test "deletes a campus without buildings" do
    campus = create(:campus)

    assert campus.destroy
    assert_not Campus.exists?(campus.id)
  end
end
