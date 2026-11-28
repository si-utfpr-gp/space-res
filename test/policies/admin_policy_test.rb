require "test_helper"

class AdminPolicyTest < ActiveSupport::TestCase
  test "grants access to administrators" do
    assert AdminPolicy.new(build(:user, :admin)).access_area?
  end

  test "denies access to regular users" do
    assert_not AdminPolicy.new(build(:user)).access_area?
  end

  test "lets administrators manage any campus" do
    policy = AdminPolicy.new(build(:user, :admin))

    assert policy.manage_campus?(build(:campus, name: "Guarapuava"))
    assert policy.manage_campus?(build(:campus, name: "Pato Branco"))
  end

  test "does not let regular users manage a campus" do
    assert_not AdminPolicy.new(build(:user)).manage_campus?(build(:campus))
  end
end
