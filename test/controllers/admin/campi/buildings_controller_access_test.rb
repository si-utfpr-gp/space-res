require "test_helper"
require "support/helpers/breadcrumb_assertions"

class Admin::Campi::BuildingsControllerAccessTest < ActionDispatch::IntegrationTest
  include BreadcrumbAssertions

  setup do
    @campus = create(:campus, name: "Guarapuava")
    @building = create(:building, campus: @campus, name: "Bloco R")
  end

  test "redirects visitors to sign in on every action" do
    each_buildings_request do |method, path, params|
      public_send(method, path, params: params)

      assert_redirected_to new_session_path, "#{method.upcase} #{path}"
    end

    assert_buildings_unchanged
  end

  test "denies regular users with forbidden on every action" do
    sign_in create(:user)

    each_buildings_request do |method, path, params|
      public_send(method, path, params: params)

      assert_response :forbidden, "#{method.upcase} #{path}"
    end

    assert_buildings_unchanged
  end

  test "hides the admin breadcrumbs and the campus menu from regular users" do
    sign_in create(:user)

    get edit_admin_campus_building_path(@campus, @building)

    assert_response :forbidden
    assert_no_breadcrumbs
    assert_select "aside nav[aria-label='Menu do campus']", count: 0
  end

  test "denies regular users before looking up the campus or the building" do
    sign_in create(:user)

    [ admin_campus_buildings_path(campus_id: 0), edit_admin_campus_building_path(@campus, id: 0) ].each do |path|
      get path

      assert_response :forbidden, path
    end
  end

  test "denies a user who may not manage the campus in the URL" do
    sign_in create(:user, :admin)
    AdminPolicy.any_instance.stubs(:manage_campus?).with(@campus).returns(false)

    get admin_campus_buildings_path(@campus)
    assert_response :forbidden

    patch admin_campus_building_path(@campus, @building), params: { building: { name: "Bloco S" } }
    assert_response :forbidden
    assert_buildings_unchanged
  end

  private

    def each_buildings_request(&)
      params = { building: { name: "Bloco S" } }

      [
        [ :get, admin_campus_buildings_path(@campus), {} ],
        [ :get, new_admin_campus_building_path(@campus), {} ],
        [ :post, admin_campus_buildings_path(@campus), params ],
        [ :get, edit_admin_campus_building_path(@campus, @building), {} ],
        [ :patch, admin_campus_building_path(@campus, @building), params ],
        [ :delete, admin_campus_building_path(@campus, @building), {} ]
      ].each(&)
    end

    def assert_buildings_unchanged
      assert_equal [ "Bloco R" ], Building.pluck(:name)
    end
end
