require "test_helper"

class SpaceCountsByStatusTest < ActiveSupport::TestCase
  test "counts the spaces of a campus in each status" do
    campus = create(:campus)
    create_list(:space, 2, campus: campus)
    create(:space, :unavailable, campus: campus)
    create(:space, :deactivated, campus: campus)
    create(:space)

    assert_equal({ "available" => 2, "unavailable" => 1, "deactivated" => 1 }, campus.spaces.counts_by_status)
  end

  test "leaves out the statuses without spaces" do
    campus = create(:campus)
    create(:space, campus: campus)

    assert_equal({ "available" => 1 }, campus.spaces.counts_by_status)
  end

  test "is empty for a campus without spaces" do
    assert_empty create(:campus).spaces.counts_by_status
  end
end
