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

    get admin_campus_path(@campus)

    assert_response :forbidden
    assert_no_breadcrumbs
    assert_select "aside nav[aria-label='Menu do campus']", count: 0
  end

  test "denies regular users before looking up the campus" do
    sign_in create(:user)

    [ admin_campus_path(id: 0), edit_admin_campus_path(id: 0) ].each do |path|
      get path

      assert_response :forbidden, path
    end
  end

  test "denies an administrator who may not manage the campus, without showing it" do
    create(:space, campus: @campus, description: "Sala do térreo.")
    sign_in create(:user, :admin)
    AdminPolicy.any_instance.stubs(:manage_campus?).with(@campus).returns(false)

    get admin_campus_path(@campus)
    assert_response :forbidden
    assert_no_breadcrumbs
    assert_select "aside nav[aria-label='Menu do campus']", count: 0
    assert_select "main h1", text: "Acesso negado"
    assert_no_match "Sala do térreo.", response.body

    get edit_admin_campus_path(@campus)
    assert_response :forbidden

    patch admin_campus_path(@campus), params: { campus: { name: "Pato Branco" } }
    assert_response :forbidden

    delete admin_campus_path(@campus)
    assert_response :forbidden

    assert_campi_unchanged
  end

  private

    def each_campi_request(&)
      [
        [ :get, admin_campus_path(@campus), {} ],
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
