require "test_helper"

class BuildingConstraintsTest < ActiveSupport::TestCase
  test "database rejects a null name" do
    assert_raises(ActiveRecord::NotNullViolation) do
      build(:building, name: nil).save!(validate: false)
    end
  end

  test "database rejects a null campus" do
    assert_raises(ActiveRecord::NotNullViolation) do
      build(:building, campus: nil).save!(validate: false)
    end
  end

  test "database rejects a campus that does not exist" do
    assert_raises(ActiveRecord::InvalidForeignKey) do
      build(:building, campus: nil, campus_id: 0).save!(validate: false)
    end
  end

  test "database rejects a repeated name in the same campus" do
    building = create(:building, name: "Bloco R")

    assert_raises(ActiveRecord::RecordNotUnique) do
      build(:building, campus: building.campus, name: "Bloco R").save!(validate: false)
    end
  end

  test "database accepts the same name in different campi" do
    create(:building, name: "Bloco R")

    assert build(:building, name: "Bloco R").save!(validate: false)
  end

  test "database rejects deleting a campus that has buildings" do
    building = create(:building)

    assert_raises(ActiveRecord::InvalidForeignKey) do
      building.campus.delete
    end
  end
end
