require "test_helper"
require "support/helpers/breadcrumb_assertions"

class Admin::CampiControllerTest < ActionDispatch::IntegrationTest
  include BreadcrumbAssertions

  setup do
    sign_in create(:user, :admin)
  end

  test "lists campi in alphabetical order" do
    create(:campus, name: "Pato Branco")
    create(:campus, name: "Guarapuava")
    create(:campus, name: "Medianeira")

    get admin_campi_path

    assert_response :success
    assert_select "h1", text: "Campi"
    assert_equal [ "Guarapuava", "Medianeira", "Pato Branco" ], listed_campus_names
    assert_select "a[href='#{new_admin_campus_path}']", text: "Novo campus"
    assert_no_match(/translation missing/i, response.body)
  end

  test "shows the list title, subtitle and breadcrumbs" do
    get admin_campi_path

    assert_select "main h1", count: 1, text: "Campi"
    assert_select "header p", text: "Gerencie os campi da UTFPR que organizam os blocos e os espaços."
    assert_breadcrumbs({ "Dashboard" => users_root_path, "Área administrativa" => admin_root_path }, current: "Campi")
  end

  test "shows a message when there are no campi" do
    get admin_campi_path

    assert_response :success
    assert_select "p", text: "Nenhum campus cadastrado."
    assert_select "table", count: 0
  end

  test "links each campus to its edit page" do
    campus = create(:campus, name: "Guarapuava")

    get admin_campi_path

    assert_select "##{dom_id(campus)} a[href='#{edit_admin_campus_path(campus)}']", text: "Editar"
  end

  test "shows the new campus form" do
    get new_admin_campus_path

    assert_response :success
    assert_select "main h1", count: 1, text: "Novo campus"
    assert_select "header p", text: "Preencha as informações do novo campus."
    assert_breadcrumbs(campi_breadcrumbs, current: "Novo")
    assert_select "form[action='#{admin_campi_path}'] input[name='campus[name]'][placeholder='Ex.: Guarapuava']"
    assert_select "form a[href='#{admin_campi_path}']", text: "Cancelar"
    assert_no_match(/translation missing/i, response.body)
  end

  test "creates a campus and shows a confirmation" do
    assert_difference("Campus.count", 1) do
      post admin_campi_path, params: { campus: { name: "  Pato   Branco " } }
    end

    assert_redirected_to admin_campi_path
    follow_redirect!
    assert_success_toast "Campus cadastrado com sucesso."
    assert_equal [ "Pato Branco" ], listed_campus_names
  end

  test "rejects a campus without a name" do
    assert_no_difference("Campus.count") do
      post admin_campi_path, params: { campus: { name: "" } }
    end

    assert_response :unprocessable_content
    assert_select "h1", text: "Novo campus"
    assert_breadcrumbs(campi_breadcrumbs, current: "Novo")
    assert_select "p", text: "Informe o nome do campus."
  end

  test "rejects a campus with a name already taken" do
    create(:campus, name: "Campo Mourão")

    assert_no_difference("Campus.count") do
      post admin_campi_path, params: { campus: { name: "campo mourao" } }
    end

    assert_response :unprocessable_content
    assert_select "input[name='campus[name]'][value='campo mourao']"
    assert_select "p", text: "Já existe um campus cadastrado com este nome."
  end

  test "shows the edit form with the current name" do
    campus = create(:campus, name: "Guarapuava")

    get edit_admin_campus_path(campus)

    assert_response :success
    assert_select "main h1", count: 1, text: "Editar campus"
    assert_select "header p", text: "Altere as informações do campus."
    assert_breadcrumbs(campi_breadcrumbs, current: "Editar")
    assert_select "form[action='#{admin_campus_path(campus)}'] input[name='campus[name]'][value='Guarapuava']"
    assert_no_match(/translation missing/i, response.body)
  end

  test "updates a campus and shows a confirmation" do
    campus = create(:campus, name: "Pato Branco")

    patch admin_campus_path(campus), params: { campus: { name: "Ponta Grossa" } }

    assert_redirected_to admin_campi_path
    assert_equal "Ponta Grossa", campus.reload.name
    follow_redirect!
    assert_success_toast "Campus atualizado com sucesso."
  end

  test "rejects renaming a campus to a name already taken" do
    create(:campus, name: "Guarapuava")
    campus = create(:campus, name: "Pato Branco")

    patch admin_campus_path(campus), params: { campus: { name: "GUARAPUAVA" } }

    assert_response :unprocessable_content
    assert_select "h1", text: "Editar campus"
    assert_breadcrumbs(campi_breadcrumbs, current: "Editar")
    assert_select "p", text: "Já existe um campus cadastrado com este nome."
    assert_equal "Pato Branco", campus.reload.name
  end

  test "asks for confirmation before deleting a campus" do
    campus = create(:campus, name: "Guarapuava")

    get admin_campi_path

    assert_select "##{dom_id(campus)} form[action='#{admin_campus_path(campus)}']" \
                  "[data-turbo-confirm='Excluir o campus Guarapuava?']" do
      assert_select "input[name='_method'][value='delete']"
      assert_select "button", text: "Excluir"
    end
  end

  test "deletes a campus and shows a confirmation" do
    campus = create(:campus, name: "Guarapuava")

    assert_difference("Campus.count", -1) do
      delete admin_campus_path(campus)
    end

    assert_response :see_other
    assert_redirected_to admin_campi_path
    follow_redirect!
    assert_success_toast "Campus excluído com sucesso."
    assert_select "p", text: "Nenhum campus cadastrado."
  end

  test "responds not found for a campus that does not exist" do
    get edit_admin_campus_path(id: 0)

    assert_response :not_found
  end

  private

    def campi_breadcrumbs
      { "Dashboard" => users_root_path, "Área administrativa" => admin_root_path, "Campi" => admin_campi_path }
    end

    def listed_campus_names
      css_select("tbody tr td:first-child").map { |cell| cell.text.strip }
    end

    def assert_success_toast(message)
      assert_select "[data-controller='ui--toast'][data-ui--toast-message-type-value='success']" \
                    "[data-ui--toast-message-text-value='#{message}']"
    end
end
