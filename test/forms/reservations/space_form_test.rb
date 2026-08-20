require "test_helper"

class Reservations::SpaceFormTest < ActiveSupport::TestCase
  test "requires a selected space" do
    form = Reservations::SpaceForm.new(space_id: "")

    assert_not form.valid?
    assert_includes form.errors[:space_id], "não pode ficar em branco"
  end

  test "exposes its frozen catalog and selected space" do
    form = Reservations::SpaceForm.new(space_id: "2")

    assert form.valid?
    assert_predicate form.spaces, :frozen?
    assert_equal "Lab de Informática", form.selected_space[:name]
  end
end
