require "test_helper"

class UserSuperAdminTest < ActiveSupport::TestCase
  test "is not a super admin by default" do
    assert_not create(:user).super_admin?
  end

  test "does not accept a null super admin flag" do
    user = create(:user)

    assert_raises(ActiveRecord::NotNullViolation) { user.update_column(:super_admin, nil) }
  end
end
