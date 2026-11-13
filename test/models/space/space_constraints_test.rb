require "test_helper"

class SpaceConstraintsTest < ActiveSupport::TestCase
  test "database rejects a null name" do
    assert_raises(ActiveRecord::NotNullViolation) do
      build(:space, name: nil).save!(validate: false)
    end
  end

  test "database rejects a null campus" do
    assert_raises(ActiveRecord::NotNullViolation) do
      build(:space, campus: nil).save!(validate: false)
    end
  end

  test "database rejects a campus, building, department or usage term that does not exist" do
    %i[ campus_id building_id department_id usage_term_id ].each do |foreign_key|
      assert_raises(ActiveRecord::InvalidForeignKey, "expected #{foreign_key} to be checked") do
        build(:space).tap { |space| space[foreign_key] = 0 }.save!(validate: false)
      end
    end
  end

  test "database rejects a null approval flag and a null status" do
    %i[ requires_approval status ].each do |column|
      assert_raises(ActiveRecord::NotNullViolation, "expected #{column} to be required") do
        build(:space).tap { |space| space[column] = nil }.save!(validate: false)
      end
    end
  end

  test "database rejects an unknown status" do
    space = create(:space)

    assert_raises(ActiveRecord::StatementInvalid) { Space.where(id: space.id).update_all(status: "closed") }
    assert space.reload.available?
  end

  test "database rejects an unavailable space without a reason and a reason on a space that is not unavailable" do
    available = create(:space)
    unavailable = create(:space, :unavailable)

    assert_raises(ActiveRecord::StatementInvalid) { Space.where(id: available.id).update_all(status: "unavailable") }
    assert_raises(ActiveRecord::StatementInvalid) { Space.where(id: available.id).update_all(unavailability_reason: "Sala em reforma") }
    assert_raises(ActiveRecord::StatementInvalid) { Space.where(id: unavailable.id).update_all(unavailability_reason: nil) }
    assert_raises(ActiveRecord::StatementInvalid) { Space.where(id: unavailable.id).update_all(status: "deactivated") }
  end

  test "database rejects a repeated name in the same building, ignoring letter case" do
    space = create(:space, :with_building, name: "Sala 101")

    assert_raises(ActiveRecord::RecordNotUnique) do
      build(:space, campus: space.campus, building: space.building, name: "SALA 101").save!(validate: false)
    end
  end

  test "database accepts the same name in different buildings" do
    space = create(:space, :with_building, name: "Sala 101")
    other_building = create(:building, campus: space.campus)

    assert build(:space, campus: space.campus, building: other_building, name: "Sala 101").save!(validate: false)
  end

  test "database rejects a repeated name without building in the same campus, ignoring letter case" do
    space = create(:space, name: "Planetário")

    assert_raises(ActiveRecord::RecordNotUnique) do
      build(:space, campus: space.campus, name: "PLANETário").save!(validate: false)
    end
  end

  test "database accepts the same name without building in different campi" do
    create(:space, name: "Planetário")

    assert build(:space, name: "Planetário").save!(validate: false)
  end

  test "database accepts the same name with and without building in the same campus" do
    space = create(:space, :with_building, name: "Sala 101")

    assert build(:space, campus: space.campus, name: "Sala 101").save!(validate: false)
  end
end
