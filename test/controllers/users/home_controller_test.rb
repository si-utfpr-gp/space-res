require "test_helper"
require "support/helpers/breadcrumb_assertions"

class Users::HomeControllerTest < ActionDispatch::IntegrationTest
  include BreadcrumbAssertions

  test "shows the dashboard title without a breadcrumb trail" do
    sign_in create(:user)

    get users_root_path

    assert_select "main h1", count: 1, text: "Dashboard"
    assert_no_breadcrumbs
  end

  test "shows the admin area shortcut to administrators" do
    sign_in create(:user, :admin)

    get users_root_path

    assert_select "aside nav a[href='#{admin_root_path}']", text: "Área administrativa"
    assert_no_match(/translation missing/i, response.body)
  end

  test "shows flash messages as a toast in the layout" do
    sign_in create(:user)

    get new_session_path
    follow_redirect!

    assert_select "[data-controller='ui--toast'][data-ui--toast-message-type-value='warning']" \
                  "[data-ui--toast-message-text-value='Você já está logado.']"
  end

  test "hides the admin area shortcut from regular users" do
    sign_in create(:user)

    get users_root_path

    assert_select "aside nav a[href='#{admin_root_path}']", count: 0
  end
end
