require "test_helper"

class UserNormalizeTest < ActiveSupport::TestCase
  setup do
    @user = build(:user, email_address: "  Test@Example.com  ")
  end

  test "should normalize email address" do
    @user.save
    assert_equal "test@example.com", @user.email_address
  end
end
