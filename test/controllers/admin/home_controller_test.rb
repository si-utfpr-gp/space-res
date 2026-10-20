require "test_helper"
require "support/helpers/breadcrumb_assertions"

class Admin::HomeControllerTest < ActionDispatch::IntegrationTest
  include BreadcrumbAssertions

  test "shows the title, subtitle and breadcrumbs" do
    sign_in create(:user, :admin)

    get admin_root_path

    assert_select "main h1", count: 1, text: "Área administrativa"
    assert_select "header p", text: "Gerencie os cadastros e as configurações do sistema."
    assert_breadcrumbs({ "Dashboard" => users_root_path }, current: "Área administrativa")
  end

  test "shows the campi shortcut to administrators" do
    sign_in create(:user, :admin)

    get admin_root_path

    assert_select "main a[href='#{admin_campi_path}']", text: /Campi/
    assert_no_match(/translation missing/i, response.body)
  end
end
