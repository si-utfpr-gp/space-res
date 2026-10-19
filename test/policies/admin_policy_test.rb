require "test_helper"

class AdminPolicyTest < ActiveSupport::TestCase
  test "grants access to administrators" do
    assert AdminPolicy.new(build(:user, :admin)).access_area?
  end

  test "denies access to regular users" do
    assert_not AdminPolicy.new(build(:user)).access_area?
  end
end
