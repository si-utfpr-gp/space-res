require "test_helper"
require "support/helpers/breadcrumb_assertions"

class Admin::Campi::SpacesControllerAccessTest < ActionDispatch::IntegrationTest
  include BreadcrumbAssertions

  setup do
    @campus = create(:campus, name: "Guarapuava")
    @space = create(:space, campus: @campus, name: "Sala 1", description: "Sala do térreo.")
    @unavailable_space = create(:space, :unavailable, campus: @campus, name: "Sala 2", description: "Sala do 1º andar.")
    @deactivated_space = create(:space, :deactivated, campus: @campus, name: "Sala 4", description: "Sala unificada.")
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

    post admin_campus_space_deactivation_path(@campus, @space)

    assert_response :forbidden
    assert @space.reload.available?
  end

  test "hides the admin breadcrumbs and the space from regular users" do
    sign_in create(:user)

    get admin_campus_space_path(@campus, @space)

    assert_response :forbidden
    assert_no_breadcrumbs
    assert_no_match "Sala do térreo.", response.body
  end

  test "denies regular users before looking up the space" do
    sign_in create(:user)

    [ admin_campus_spaces_path(campus_id: 0), admin_campus_space_path(@campus, id: 0),
      new_admin_campus_space_unavailability_path(@campus, space_id: 0) ].each do |path|
      get path

      assert_response :forbidden, path
    end
    post admin_campus_space_deactivation_path(@campus, space_id: 0)
    assert_response :forbidden

    get admin_campus_space_path(campus_id: 0, id: 0)
    assert_response :forbidden
  end

  test "denies a user who may not manage the campus in the URL on every action" do
    sign_in create(:user, :admin)
    AdminPolicy.any_instance.stubs(:manage_campus?).with(@campus).returns(false)

    each_spaces_request do |method, path, params|
      public_send(method, path, params: params)

      assert_response :forbidden, "#{method.upcase} #{path}"
    end

    assert_spaces_unchanged
  end

  test "shows nothing of the campus to an administrator denied it, even in the results frame" do
    sign_in create(:user, :admin)
    AdminPolicy.any_instance.stubs(:manage_campus?).with(@campus).returns(false)

    get admin_campus_spaces_path(@campus), headers: { "Turbo-Frame" => "spaces_results" }

    assert_response :forbidden
    assert_no_breadcrumbs
    assert_select "aside nav[aria-label='Menu do campus']", count: 0
    assert_no_match "Sala 1", response.body
    assert_no_match "Guarapuava", response.body
  end

  private

    def each_spaces_request(&)
      params = { space: { name: "Sala 3", description: "Outra sala." } }
      reason_params = { space: { unavailability_reason: "Sala interditada" } }

      [
        [ :get, admin_campus_spaces_path(@campus), {} ],
        [ :get, admin_campus_space_path(@campus, @space), {} ],
        [ :get, new_admin_campus_space_path(@campus), {} ],
        [ :post, admin_campus_spaces_path(@campus), params ],
        [ :get, edit_admin_campus_space_path(@campus, @space), {} ],
        [ :patch, admin_campus_space_path(@campus, @space), params ],
        [ :get, new_admin_campus_space_unavailability_path(@campus, @space), {} ],
        [ :post, admin_campus_space_unavailability_path(@campus, @space), reason_params ],
        [ :get, edit_admin_campus_space_unavailability_path(@campus, @unavailable_space), {} ],
        [ :patch, admin_campus_space_unavailability_path(@campus, @unavailable_space), reason_params ],
        [ :delete, admin_campus_space_unavailability_path(@campus, @unavailable_space), {} ],
        [ :post, admin_campus_space_deactivation_path(@campus, @space), {} ],
        [ :delete, admin_campus_space_deactivation_path(@campus, @deactivated_space), {} ],
        [ :delete, admin_campus_space_path(@campus, @space), {} ]
      ].each(&)
    end

    def assert_spaces_unchanged
      assert_equal [ [ "Sala 1", "Sala do térreo.", "available", nil ], [ "Sala 2", "Sala do 1º andar.", "unavailable", "Sala em reforma" ],
                     [ "Sala 4", "Sala unificada.", "deactivated", nil ] ],
                   Space.order(:name).map { |space| [ space.name, space.description, space.status, space.unavailability_reason ] }
    end
end
