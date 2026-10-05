require "test_helper"

class BuildingConstraintsTest < ActiveSupport::TestCase
  test "does not accept a duplicated name in the same campus" do
    building = create(:building)

    assert_raises(ActiveRecord::RecordNotUnique) do
      build(:building, campus: building.campus, name: building.name).save(validate: false)
    end
  end

  test "accepts the same name in another campus" do
    building = create(:building)

    assert build(:building, name: building.name).save(validate: false)
  end

  test "does not accept a null name" do
    assert_raises(ActiveRecord::NotNullViolation) do
      build(:building, name: nil).save(validate: false)
    end
  end

  test "does not accept a nonexistent campus" do
    assert_raises(ActiveRecord::InvalidForeignKey) do
      build(:building, campus_id: Campus.maximum(:id).to_i + 1).save(validate: false)
    end
  end
end
