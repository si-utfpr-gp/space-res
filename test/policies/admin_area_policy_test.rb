require "test_helper"

class AdminAreaPolicyTest < ActiveSupport::TestCase
  test "grants access to administrators" do
    assert AdminAreaPolicy.new(build(:user, :admin)).access?
  end

  test "denies access to regular users" do
    assert_not AdminAreaPolicy.new(build(:user)).access?
  end
end
