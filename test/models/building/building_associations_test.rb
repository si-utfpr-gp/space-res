require "test_helper"

class BuildingAssociationsTest < ActiveSupport::TestCase
  subject { create(:building) }

  should belong_to(:campus)
end
