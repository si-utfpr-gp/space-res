require "test_helper"

class DepartmentValidationsTest < ActiveSupport::TestCase
  subject { @department }
  setup do
    @department = create(:department)
  end

  should validate_presence_of(:name)
  should validate_uniqueness_of(:name).case_insensitive
end
