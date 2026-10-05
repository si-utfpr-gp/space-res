require "test_helper"

class CampusValidationsTest < ActiveSupport::TestCase
  subject { @campus }
  setup do
    @campus = create(:campus)
  end

  should validate_presence_of(:name)
  should validate_uniqueness_of(:name).case_insensitive
end
