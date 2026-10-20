require "test_helper"
require "support/helpers/breadcrumb_assertions"

class Admin::CampiControllerAccessTest < ActionDispatch::IntegrationTest
  include BreadcrumbAssertions

  setup do
    @campus = create(:campus, name: "Guarapuava")
  end

  test "redirects visitors to sign in on every action" do
    each_campi_request do |method, path, params|
      public_send(method, path, params: params)

      assert_redirected_to new_session_path, "#{method.upcase} #{path}"
    end

    assert_campi_unchanged
  end

  test "denies regular users with forbidden on every action" do
    sign_in create(:user)

    each_campi_request do |method, path, params|
      public_send(method, path, params: params)

      assert_response :forbidden, "#{method.upcase} #{path}"
    end

    assert_campi_unchanged
  end

  test "hides the admin breadcrumbs from regular users" do
    sign_in create(:user)

    get edit_admin_campus_path(@campus)

    assert_response :forbidden
    assert_no_breadcrumbs
  end

  test "denies regular users before looking up the campus" do
    sign_in create(:user)

    get edit_admin_campus_path(id: 0)

    assert_response :forbidden
  end

  private

    def each_campi_request(&)
      [
        [ :get, admin_campi_path, {} ],
        [ :get, new_admin_campus_path, {} ],
        [ :post, admin_campi_path, { campus: { name: "Pato Branco" } } ],
        [ :get, edit_admin_campus_path(@campus), {} ],
        [ :patch, admin_campus_path(@campus), { campus: { name: "Pato Branco" } } ],
        [ :delete, admin_campus_path(@campus), {} ]
      ].each(&)
    end

    def assert_campi_unchanged
      assert_equal [ "Guarapuava" ], Campus.pluck(:name)
    end
end
