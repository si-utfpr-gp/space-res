require "test_helper"

class CampusAssociationsTest < ActiveSupport::TestCase
  subject { create(:campus) }

  should have_many(:buildings).dependent(:restrict_with_error)

  context "campus with buildings" do
    setup do
      @campus = create(:building).campus
    end

    should "not be destroyed" do
      assert_not @campus.destroy
      assert Campus.exists?(@campus.id)
      assert_includes @campus.errors[:base], "Não é possível excluir o registro pois existem blocos dependentes"
    end
  end

  context "campus without buildings" do
    should "be destroyed" do
      campus = create(:campus)

      assert campus.destroy
      assert_not Campus.exists?(campus.id)
    end
  end
end
