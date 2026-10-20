require "test_helper"
require "support/helpers/breadcrumb_assertions"

class Admin::HomeControllerAccessTest < ActionDispatch::IntegrationTest
  include BreadcrumbAssertions

  test "redirects visitors to sign in" do
    get admin_root_path

    assert_redirected_to new_session_path
  end

  test "denies regular users with forbidden" do
    sign_in create(:user)

    get admin_root_path

    assert_response :forbidden
    assert_select "main h1", count: 1, text: "Acesso negado"
    assert_select "header p", text: "Você não tem permissão para acessar esta página."
    assert_no_breadcrumbs
    assert_select "a[href='#{users_root_path}']", text: "Voltar ao Dashboard"
    assert_no_match(/translation missing/i, response.body)
  end

  test "shows the admin area to administrators" do
    sign_in create(:user, :admin)

    get admin_root_path

    assert_response :success
    assert_select "h1", text: "Área administrativa"
    assert_no_match(/translation missing/i, response.body)
  end
end
