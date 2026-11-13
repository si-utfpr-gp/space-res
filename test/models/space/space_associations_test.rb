require "test_helper"

class SpaceAssociationsTest < ActiveSupport::TestCase
  subject { build(:space) }

  should belong_to(:campus)
  should belong_to(:building).optional
  should belong_to(:department).optional
  should belong_to(:usage_term).optional

  test "translates the model name" do
    assert_equal "Espaço", Space.model_name.human
    assert_equal "Espaços", Space.model_name.human(count: 2)
  end

  test "translates the attributes shown in the forms" do
    assert_equal "Departamento responsável", Space.human_attribute_name(:department_id)
    assert_equal "A reserva precisa de aprovação", Space.human_attribute_name(:requires_approval)
  end
end
