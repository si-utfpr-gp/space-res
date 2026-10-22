require "test_helper"
require "support/helpers/breadcrumb_assertions"

class Admin::BuildingsControllerAccessTest < ActionDispatch::IntegrationTest
  include BreadcrumbAssertions

  setup do
    @building = create(:building, campus: create(:campus, name: "Guarapuava"), name: "Bloco R")
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

  test "hides the admin breadcrumbs from regular users" do
    sign_in create(:user)

    get edit_admin_building_path(@building)

    assert_response :forbidden
    assert_no_breadcrumbs
  end

  test "denies regular users before looking up the building" do
    sign_in create(:user)

    get edit_admin_building_path(id: 0)

    assert_response :forbidden
  end

  private

    def each_buildings_request(&)
      params = { building: { campus_id: @building.campus_id, name: "Bloco S" } }

      [
        [ :get, admin_buildings_path, {} ],
        [ :get, new_admin_building_path, {} ],
        [ :post, admin_buildings_path, params ],
        [ :get, edit_admin_building_path(@building), {} ],
        [ :patch, admin_building_path(@building), params ],
        [ :delete, admin_building_path(@building), {} ]
      ].each(&)
    end

    def assert_buildings_unchanged
      assert_equal [ "Bloco R" ], Building.pluck(:name)
    end
end
