require "test_helper"

class SpaceDefaultsTest < ActiveSupport::TestCase
  test "starts available, without a reason and without the need for approval" do
    space = Space.new

    assert space.available?
    assert_nil space.unavailability_reason
    assert_not space.requires_approval?
  end

  test "keeps a deactivated space with all its data" do
    space = create(:space, :with_building, :deactivated, description: "Unificada com a Sala 101")

    space.reload
    assert space.deactivated?
    assert_equal "Unificada com a Sala 101", space.description
    assert space.building.present?
  end
end
