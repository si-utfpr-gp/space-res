require "test_helper"

class UserAdminTest < ActiveSupport::TestCase
  test "new users are not administrators" do
    user = create(:user)

    assert_not user.reload.admin?
  end

  test "rejects an empty administrator flag" do
    user = build(:user, admin: nil)

    assert_not user.valid?
    assert_includes user.errors[:admin], "não está incluído na lista"
  end

  test "admin trait builds an administrator" do
    assert build(:user, :admin).admin?
  end
end
