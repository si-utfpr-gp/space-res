require "test_helper"

class Admin::HomeControllerTest < ActionDispatch::IntegrationTest
  test "shows the campi shortcut to administrators" do
    sign_in create(:user, :admin)

    get admin_root_path

    assert_select "main a[href='#{admin_campi_path}']", text: /Campi/
    assert_no_match(/translation missing/i, response.body)
  end
end
