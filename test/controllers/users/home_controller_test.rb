require "test_helper"

class Users::HomeControllerTest < ActionDispatch::IntegrationTest
  test "shows the admin area shortcut to administrators" do
    sign_in create(:user, :admin)

    get users_root_path

    assert_select "aside nav a[href='#{admin_root_path}']", text: "Área administrativa"
    assert_no_match(/translation missing/i, response.body)
  end

  test "hides the admin area shortcut from regular users" do
    sign_in create(:user)

    get users_root_path

    assert_select "aside nav a[href='#{admin_root_path}']", count: 0
  end
end
