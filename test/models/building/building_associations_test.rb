require "test_helper"

class BuildingAssociationsTest < ActiveSupport::TestCase
  subject { build(:building) }

  should belong_to(:campus)
  should have_many(:spaces).dependent(:restrict_with_error)

  test "keeps a building that has spaces, even deactivated ones, and explains why" do
    building = create(:space, :with_building, :deactivated).building

    assert_not building.destroy
    assert Building.exists?(building.id)
    assert_equal [ "Não é possível excluir o bloco porque ele tem espaços cadastrados. Mova os espaços para outro bloco ou exclua-os antes." ],
                 building.errors.full_messages
  end

  test "deletes a building after its last space is deleted" do
    space = create(:space, :with_building)
    space.destroy!

    assert space.building.destroy
    assert_not Building.exists?(space.building_id)
  end

  test "translates the model name" do
    assert_equal "Bloco", Building.model_name.human
    assert_equal "Blocos", Building.model_name.human(count: 2)
  end
end
