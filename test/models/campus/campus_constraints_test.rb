require "test_helper"

class CampusConstraintsTest < ActiveSupport::TestCase
  test "does not accept a duplicated name" do
    campus = create(:campus)

    assert_raises(ActiveRecord::RecordNotUnique) do
      build(:campus, name: campus.name).save(validate: false)
    end
  end

  test "does not accept a null name" do
    assert_raises(ActiveRecord::NotNullViolation) do
      build(:campus, name: nil).save(validate: false)
    end
  end
end
