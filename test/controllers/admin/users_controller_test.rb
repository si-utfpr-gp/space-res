require "test_helper"
require "support/helpers/breadcrumb_assertions"

class Admin::UsersControllerTest < ActionDispatch::IntegrationTest
  include BreadcrumbAssertions

  setup do
    @admin = create(:user, :admin, name: "Admin Demo", email_address: "admin@utfpr.edu.br")
    sign_in @admin
  end

  test "lists users in alphabetical order with e-mail and department" do
    create(:user, name: "Carla Souza", department: create(:department, name: "Biblioteca"))
    create(:user, name: "Bruno Costa", email_address: "bruno@utfpr.edu.br")

    get admin_users_path

    assert_response :success
    assert_equal [ "Admin Demo", "Bruno Costa", "Carla Souza" ], listed_user_names
    assert_select "tbody tr", text: /bruno@utfpr\.edu\.br/
    assert_select "tbody tr:nth-child(2) td:nth-child(2)", text: "Sem departamento"
    assert_select "tbody tr:nth-child(3) td:nth-child(2)", text: "Biblioteca"
    assert_no_match(/translation missing/i, response.body)
  end

  test "marks administrators with a read-only badge" do
    user = create(:user, name: "Bruno Costa")

    get admin_users_path

    assert_select "##{dom_id(@admin)} span", text: "Administrador"
    assert_select "##{dom_id(user)} span", text: "Administrador", count: 0
  end

  test "offers only the edit action" do
    user = create(:user)

    get admin_users_path

    assert_select "##{dom_id(user)} a[href='#{edit_admin_user_path(user)}']", text: "Editar"
    assert_select "a[href='/admin/users/new']", count: 0
    assert_select "form[action='#{admin_user_path(user)}']", count: 0
  end

  test "shows the list title, subtitle and breadcrumbs" do
    get admin_users_path

    assert_select "main h1", count: 1, text: "Usuários"
    assert_select "header p", text: "Veja os usuários do sistema e defina o departamento de cada um."
    assert_breadcrumbs({ "Dashboard" => users_root_path, "Área administrativa" => admin_root_path }, current: "Usuários")
  end

  test "shows the edit form with the user data and current department" do
    department = create(:department, name: "Biblioteca")
    create(:department, name: "Assessoria de Comunicação")
    user = create(:user, name: "Ana Lima", email_address: "ana@utfpr.edu.br", department: department)

    get edit_admin_user_path(user)

    assert_response :success
    assert_select "main h1", count: 1, text: "Editar usuário"
    assert_select "header p", text: "Defina o departamento do usuário."
    assert_breadcrumbs(users_breadcrumbs, current: "Editar")
    assert_select "dd", text: "Ana Lima"
    assert_select "dd", text: "ana@utfpr.edu.br"
    assert_select "form[action='#{admin_user_path(user)}'] select[name='user[department_id]']" do
      assert_select "option", count: 3
      assert_select "option:first-child[value='']", text: "Sem departamento"
      assert_select "option:nth-child(2)", text: "Assessoria de Comunicação"
      assert_select "option[selected][value='#{department.id}']", text: "Biblioteca"
    end
    assert_select "p", text: "Atribua departamento apenas a docentes e técnicos."
    assert_select "form input[name='user[admin]']", count: 0
    assert_select "form a[href='#{admin_users_path}']", text: "Cancelar"
    assert_no_match(/translation missing/i, response.body)
  end

  test "sets the department of a user without one" do
    department = create(:department, name: "Biblioteca")
    user = create(:user)

    patch admin_user_path(user), params: { user: { department_id: department.id } }

    assert_response :see_other
    assert_redirected_to admin_users_path
    assert_equal department, user.reload.department
    follow_redirect!
    assert_success_toast "Usuário atualizado com sucesso."
  end

  test "changes the department of a user" do
    user = create(:user, department: create(:department, name: "Departamento de Educação"))
    library = create(:department, name: "Biblioteca")

    patch admin_user_path(user), params: { user: { department_id: library.id } }

    assert_redirected_to admin_users_path
    assert_equal library, user.reload.department
  end

  test "removes the department of a user" do
    user = create(:user, :with_department)

    patch admin_user_path(user), params: { user: { department_id: "" } }

    assert_redirected_to admin_users_path
    assert_nil user.reload.department_id
  end

  test "keeps the department when saving without changes" do
    department = create(:department)
    user = create(:user, department: department)

    patch admin_user_path(user), params: { user: { department_id: department.id } }

    assert_redirected_to admin_users_path
    assert_equal department, user.reload.department
  end

  test "lets an administrator set their own department" do
    department = create(:department)

    patch admin_user_path(@admin), params: { user: { department_id: department.id } }

    assert_redirected_to admin_users_path
    assert_equal department, @admin.reload.department
  end

  test "changes only the department, ignoring the admin flag and account data" do
    department = create(:department)
    user = create(:user, name: "Ana Lima", email_address: "ana@utfpr.edu.br")
    password_digest = user.password_digest

    patch admin_user_path(user), params: {
      user: { department_id: department.id, admin: "1", name: "Outro Nome",
              email_address: "outro@utfpr.edu.br", password: "nova-senha", password_confirmation: "nova-senha" }
    }

    assert_redirected_to admin_users_path
    user.reload
    assert_equal department, user.department
    assert_not user.admin?
    assert_equal "Ana Lima", user.name
    assert_equal "ana@utfpr.edu.br", user.email_address
    assert_equal password_digest, user.password_digest
  end

  test "does not remove the admin flag of an administrator" do
    other_admin = create(:user, :admin)

    patch admin_user_path(other_admin), params: { user: { department_id: "", admin: "0" } }

    assert_redirected_to admin_users_path
    assert other_admin.reload.admin?
  end

  test "rejects a department that does not exist" do
    department = create(:department, name: "Biblioteca")
    user = create(:user, department: department)

    patch admin_user_path(user), params: { user: { department_id: 0 } }

    assert_response :unprocessable_content
    assert_select "main h1", text: "Editar usuário"
    assert_breadcrumbs(users_breadcrumbs, current: "Editar")
    assert_select "p", text: "Selecione um departamento cadastrado."
    assert_equal department, user.reload.department
  end

  test "responds not found for a user that does not exist" do
    get edit_admin_user_path(id: 0)
    assert_response :not_found

    patch admin_user_path(id: 0), params: { user: { department_id: "" } }
    assert_response :not_found
  end

  private

    def users_breadcrumbs
      { "Dashboard" => users_root_path, "Área administrativa" => admin_root_path, "Usuários" => admin_users_path }
    end

    def listed_user_names
      css_select("tbody tr td:first-child div span:first-child").map { |cell| cell.text.strip }
    end

    def assert_success_toast(message)
      assert_select "[data-controller='ui--toast'][data-ui--toast-message-type-value='success']" \
                    "[data-ui--toast-message-text-value='#{message}']"
    end
end
