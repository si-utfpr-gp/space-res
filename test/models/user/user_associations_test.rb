require "test_helper"

class UserAssociationsTest < ActiveSupport::TestCase
  subject { create(:user) }

  should have_many(:sessions).dependent(:destroy)
end
