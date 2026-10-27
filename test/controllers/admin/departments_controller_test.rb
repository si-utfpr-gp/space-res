require "test_helper"
require "support/helpers/breadcrumb_assertions"

class Admin::DepartmentsControllerTest < ActionDispatch::IntegrationTest
  include BreadcrumbAssertions

  setup do
    sign_in create(:user, :admin)
  end

  test "lists departments in alphabetical order" do
    create(:department, name: "Coordenadoria de Tecnologia da Informação")
    create(:department, name: "Biblioteca")
    create(:department, name: "Coordenação de Gestão de Recursos Humanos")

    get admin_departments_path

    assert_response :success
    assert_equal [ "Biblioteca", "Coordenação de Gestão de Recursos Humanos", "Coordenadoria de Tecnologia da Informação" ],
                 listed_department_names
    assert_select "a[href='#{new_admin_department_path}']", text: "Novo departamento"
    assert_no_match(/translation missing/i, response.body)
  end

  test "shows the list title, subtitle and breadcrumbs" do
    get admin_departments_path

    assert_select "main h1", count: 1, text: "Departamentos"
    assert_select "header p", text: "Gerencie os departamentos que respondem pelos espaços e liberam as reservas."
    assert_breadcrumbs({ "Dashboard" => users_root_path, "Área administrativa" => admin_root_path }, current: "Departamentos")
  end

  test "shows a message when there are no departments" do
    get admin_departments_path

    assert_response :success
    assert_select "p", text: "Nenhum departamento cadastrado."
    assert_select "table", count: 0
  end

  test "links each department to its edit page" do
    department = create(:department, name: "Biblioteca")

    get admin_departments_path

    assert_select "##{dom_id(department)} a[href='#{edit_admin_department_path(department)}']", text: "Editar"
  end

  test "shows the new department form" do
    get new_admin_department_path

    assert_response :success
    assert_select "main h1", count: 1, text: "Novo departamento"
    assert_select "header p", text: "Preencha as informações do novo departamento."
    assert_breadcrumbs(departments_breadcrumbs, current: "Novo")
    assert_select "form[action='#{admin_departments_path}'] input[name='department[name]']" \
                  "[placeholder='Ex.: Departamento Acadêmico de Engenharia']"
    assert_select "form a[href='#{admin_departments_path}']", text: "Cancelar"
    assert_no_match(/translation missing/i, response.body)
  end

  test "creates a department and shows a confirmation" do
    assert_difference("Department.count", 1) do
      post admin_departments_path, params: { department: { name: "  Departamento   de Educação " } }
    end

    assert_redirected_to admin_departments_path
    follow_redirect!
    assert_success_toast "Departamento cadastrado com sucesso."
    assert_equal [ "Departamento de Educação" ], listed_department_names
  end

  test "rejects a department without a name" do
    assert_no_difference("Department.count") do
      post admin_departments_path, params: { department: { name: "" } }
    end

    assert_response :unprocessable_content
    assert_select "main h1", text: "Novo departamento"
    assert_breadcrumbs(departments_breadcrumbs, current: "Novo")
    assert_select "p", text: "Informe o nome do departamento."
  end

  test "rejects a department with a name already taken" do
    create(:department, name: "Departamento de Educação")

    assert_no_difference("Department.count") do
      post admin_departments_path, params: { department: { name: "departamento de educacao" } }
    end

    assert_response :unprocessable_content
    assert_select "input[name='department[name]'][value='departamento de educacao']"
    assert_select "p", text: "Já existe um departamento cadastrado com este nome."
  end

  test "shows the edit form with the current name" do
    department = create(:department, name: "Biblioteca")

    get edit_admin_department_path(department)

    assert_response :success
    assert_select "main h1", count: 1, text: "Editar departamento"
    assert_select "header p", text: "Altere as informações do departamento."
    assert_breadcrumbs(departments_breadcrumbs, current: "Editar")
    assert_select "form[action='#{admin_department_path(department)}'] input[name='department[name]'][value='Biblioteca']"
    assert_no_match(/translation missing/i, response.body)
  end

  test "updates a department and shows a confirmation" do
    department = create(:department, name: "Departamento de Educação")

    patch admin_department_path(department), params: { department: { name: "Departamento de Extensão" } }

    assert_redirected_to admin_departments_path
    assert_equal "Departamento de Extensão", department.reload.name
    follow_redirect!
    assert_success_toast "Departamento atualizado com sucesso."
  end

  test "rejects renaming a department to a name already taken" do
    create(:department, name: "Biblioteca")
    department = create(:department, name: "Departamento de Educação")

    patch admin_department_path(department), params: { department: { name: "BIBLIOTECA" } }

    assert_response :unprocessable_content
    assert_select "main h1", text: "Editar departamento"
    assert_breadcrumbs(departments_breadcrumbs, current: "Editar")
    assert_select "p", text: "Já existe um departamento cadastrado com este nome."
    assert_equal "Departamento de Educação", department.reload.name
  end

  test "asks for confirmation before deleting a department" do
    department = create(:department, name: "Biblioteca")

    get admin_departments_path

    assert_select "##{dom_id(department)} form[action='#{admin_department_path(department)}']" \
                  "[data-turbo-confirm='Excluir o departamento Biblioteca?']" do
      assert_select "input[name='_method'][value='delete']"
      assert_select "button", text: "Excluir"
    end
  end

  test "deletes a department and shows a confirmation" do
    department = create(:department, name: "Biblioteca")

    assert_difference("Department.count", -1) do
      delete admin_department_path(department)
    end

    assert_response :see_other
    assert_redirected_to admin_departments_path
    follow_redirect!
    assert_success_toast "Departamento excluído com sucesso."
    assert_select "p", text: "Nenhum departamento cadastrado."
  end

  test "responds not found for a department that does not exist" do
    get edit_admin_department_path(id: 0)

    assert_response :not_found
  end

  private

    def departments_breadcrumbs
      { "Dashboard" => users_root_path, "Área administrativa" => admin_root_path, "Departamentos" => admin_departments_path }
    end

    def listed_department_names
      css_select("tbody tr td:first-child").map { |cell| cell.text.strip }
    end

    def assert_success_toast(message)
      assert_select "[data-controller='ui--toast'][data-ui--toast-message-type-value='success']" \
                    "[data-ui--toast-message-text-value='#{message}']"
    end
end
