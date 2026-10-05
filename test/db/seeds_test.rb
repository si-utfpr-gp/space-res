require "test_helper"

class SeedsTest < ActiveSupport::TestCase
  test "creates the Guarapuava campus when there are no campi" do
    Rails.application.load_seed

    assert_equal [ "Guarapuava" ], Campus.pluck(:name)
  end

  test "is idempotent" do
    2.times { Rails.application.load_seed }

    assert_equal 1, Campus.count
  end

  test "does not create the campus when another one already exists" do
    create(:campus, name: "Câmpus Guarapuava")

    Rails.application.load_seed

    assert_equal [ "Câmpus Guarapuava" ], Campus.pluck(:name)
  end
end
