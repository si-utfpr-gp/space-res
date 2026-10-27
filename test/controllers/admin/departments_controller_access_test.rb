require "test_helper"
require "support/helpers/breadcrumb_assertions"

class Admin::DepartmentsControllerAccessTest < ActionDispatch::IntegrationTest
  include BreadcrumbAssertions

  setup do
    @department = create(:department, name: "Biblioteca")
  end

  test "redirects visitors to sign in on every action" do
    each_departments_request do |method, path, params|
      public_send(method, path, params: params)

      assert_redirected_to new_session_path, "#{method.upcase} #{path}"
    end

    assert_departments_unchanged
  end

  test "denies regular users with forbidden on every action" do
    sign_in create(:user)

    each_departments_request do |method, path, params|
      public_send(method, path, params: params)

      assert_response :forbidden, "#{method.upcase} #{path}"
    end

    assert_departments_unchanged
  end

  test "hides the admin breadcrumbs from regular users" do
    sign_in create(:user)

    get edit_admin_department_path(@department)

    assert_response :forbidden
    assert_no_breadcrumbs
  end

  test "denies regular users before looking up the department" do
    sign_in create(:user)

    get edit_admin_department_path(id: 0)

    assert_response :forbidden
  end

  private

    def each_departments_request(&)
      [
        [ :get, admin_departments_path, {} ],
        [ :get, new_admin_department_path, {} ],
        [ :post, admin_departments_path, { department: { name: "Departamento de Educação" } } ],
        [ :get, edit_admin_department_path(@department), {} ],
        [ :patch, admin_department_path(@department), { department: { name: "Departamento de Educação" } } ],
        [ :delete, admin_department_path(@department), {} ]
      ].each(&)
    end

    def assert_departments_unchanged
      assert_equal [ "Biblioteca" ], Department.pluck(:name)
    end
end
