require "test_helper"
require "support/helpers/breadcrumb_assertions"

class Admin::SpacesControllerAccessTest < ActionDispatch::IntegrationTest
  include BreadcrumbAssertions

  setup do
    @campus = create(:campus, name: "Guarapuava")
    @space = create(:space, campus: @campus, name: "Sala 1", description: "Sala do térreo.")
    @unavailable_space = create(:space, :unavailable, campus: @campus, name: "Sala 2")
    @deactivated_space = create(:space, :deactivated, campus: @campus, name: "Sala 4")
  end

  test "redirects visitors to sign in on every action" do
    each_spaces_request do |method, path, params|
      public_send(method, path, params: params)

      assert_redirected_to new_session_path, "#{method.upcase} #{path}"
    end

    assert_spaces_unchanged
  end

  test "denies regular users with forbidden on every action" do
    sign_in create(:user)

    each_spaces_request do |method, path, params|
      public_send(method, path, params: params)

      assert_response :forbidden, "#{method.upcase} #{path}"
    end

    assert_spaces_unchanged
  end

  test "denies users of the department that answers for the space" do
    department = create(:department)
    @space.update!(department: department)
    sign_in create(:user, department: department)

    post admin_space_deactivation_path(@space)

    assert_response :forbidden
    assert @space.reload.available?
  end

  test "hides the admin breadcrumbs and the space from regular users" do
    sign_in create(:user)

    get admin_space_path(@space)

    assert_response :forbidden
    assert_no_breadcrumbs
    assert_no_match "Sala do térreo.", response.body
  end

  test "denies regular users before looking up the space" do
    sign_in create(:user)

    [ admin_space_path(id: 0), new_admin_space_unavailability_path(space_id: 0) ].each do |path|
      get path

      assert_response :forbidden, path
    end
    post admin_space_deactivation_path(space_id: 0)
    assert_response :forbidden
  end

  private

    def each_spaces_request(&)
      params = { space: { campus_id: @campus.id, name: "Sala 3", description: "Outra sala." } }
      reason_params = { space: { unavailability_reason: "Sala interditada" } }

      [
        [ :get, admin_spaces_path, {} ],
        [ :get, admin_space_path(@space), {} ],
        [ :get, new_admin_space_path, {} ],
        [ :post, admin_spaces_path, params ],
        [ :get, edit_admin_space_path(@space), {} ],
        [ :patch, admin_space_path(@space), params ],
        [ :get, new_admin_space_unavailability_path(@space), {} ],
        [ :post, admin_space_unavailability_path(@space), reason_params ],
        [ :get, edit_admin_space_unavailability_path(@unavailable_space), {} ],
        [ :patch, admin_space_unavailability_path(@unavailable_space), reason_params ],
        [ :delete, admin_space_unavailability_path(@unavailable_space), {} ],
        [ :post, admin_space_deactivation_path(@space), {} ],
        [ :delete, admin_space_deactivation_path(@deactivated_space), {} ],
        [ :delete, admin_space_path(@space), {} ]
      ].each(&)
    end

    def assert_spaces_unchanged
      assert_equal [ [ "Sala 1", "Sala do térreo.", "available", nil ], [ "Sala 2", nil, "unavailable", "Sala em reforma" ],
                     [ "Sala 4", nil, "deactivated", nil ] ],
                   Space.order(:name).map { |space| [ space.name, space.description, space.status, space.unavailability_reason ] }
    end
end
