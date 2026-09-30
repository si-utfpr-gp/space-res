require "test_helper"

class Users::HomeControllerTest < ActionDispatch::IntegrationTest
  test "shows the admin link in the sidebar to super admins" do
    sign_in create(:user, :super_admin)

    get users_root_path
    assert_select "aside a[href='#{admin_root_path}']", text: I18n.t("users.home.layouts.sidebar.admin")
  end

  test "hides the admin link in the sidebar from common users" do
    sign_in create(:user)

    get users_root_path
    assert_select "aside a[href='#{admin_root_path}']", count: 0
  end
end
