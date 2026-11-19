require "test_helper"

class BaseFormTest < ActiveSupport::TestCase
  test "uses a short parameter scope and Active Model translations without a domain constant" do
    assert_equal "space", Reservations::SpaceForm.model_name.param_key
    assert_equal "Espaço", Reservations::SpaceForm.human_attribute_name(:space_id)
    # Space became a model with the spaces registration; the schedule form still has no constant of its own.
    assert_equal "schedule", Reservations::ScheduleForm.model_name.param_key
    assert_not Object.const_defined?(:Schedule)
  end
end
