require "test_helper"

class BaseFormTest < ActiveSupport::TestCase
  test "uses a short parameter scope and Active Model translations without a domain constant" do
    assert_equal "space", Reservations::SpaceForm.model_name.param_key
    assert_equal "Espaço", Reservations::SpaceForm.human_attribute_name(:space_id)
    assert_not Object.const_defined?(:Space)
  end
end
