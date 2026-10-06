require "test_helper"

class UserAssociationsTest < ActiveSupport::TestCase
  subject { create(:user) }

  should belong_to(:department).optional
  should have_many(:sessions).dependent(:destroy)
end
