require "test_helper"

class BuildingValidationsTest < ActiveSupport::TestCase
  subject { @building }
  setup do
    @building = create(:building)
  end

  should validate_presence_of(:name)
  should validate_uniqueness_of(:name).scoped_to(:campus_id).case_insensitive
end
