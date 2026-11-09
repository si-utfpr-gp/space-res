require "test_helper"
require "support/helpers/breadcrumb_assertions"

class Admin::UsersControllerAccessTest < ActionDispatch::IntegrationTest
  include BreadcrumbAssertions

  setup do
    @user = create(:user, name: "Ana Lima")
    @department = create(:department, name: "Biblioteca")
  end

  test "redirects visitors to sign in on every action" do
    each_users_request do |method, path, params|
      public_send(method, path, params: params)

      assert_redirected_to new_session_path, "#{method.upcase} #{path}"
    end

    assert_user_unchanged
  end

  test "denies regular users with forbidden on every action" do
    sign_in create(:user)

    each_users_request do |method, path, params|
      public_send(method, path, params: params)

      assert_response :forbidden, "#{method.upcase} #{path}"
    end

    assert_user_unchanged
  end

  test "denies a regular user changing their own department or admin flag" do
    sign_in @user

    patch admin_user_path(@user), params: { user: { department_id: @department.id, admin: "1" } }

    assert_response :forbidden
    assert_user_unchanged
  end

  test "hides the admin breadcrumbs from regular users" do
    sign_in create(:user)

    get edit_admin_user_path(@user)

    assert_response :forbidden
    assert_no_breadcrumbs
  end

  test "denies regular users before looking up the user" do
    sign_in create(:user)

    get edit_admin_user_path(id: 0)

    assert_response :forbidden
  end

  private

    def each_users_request(&)
      [
        [ :get, admin_users_path, {} ],
        [ :get, edit_admin_user_path(@user), {} ],
        [ :patch, admin_user_path(@user), { user: { department_id: @department.id } } ]
      ].each(&)
    end

    def assert_user_unchanged
      @user.reload
      assert_nil @user.department_id
      assert_not @user.admin?
    end
end
