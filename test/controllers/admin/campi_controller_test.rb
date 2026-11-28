require "test_helper"
require "support/helpers/breadcrumb_assertions"

class Admin::CampiControllerTest < ActionDispatch::IntegrationTest
  include BreadcrumbAssertions

  setup do
    sign_in create(:user, :admin)
    @campus = create(:campus, name: "Guarapuava")
  end

  test "shows the campus page with its title, subtitle and breadcrumbs" do
    get admin_campus_path(@campus)

    assert_response :success
    assert_select "main h1", count: 1, text: "Campus Guarapuava"
    assert_select "header p", text: "Visão geral dos cadastros do campus e do que precisa de atenção."
    assert_breadcrumbs(admin_breadcrumbs, current: "Guarapuava")
    assert_no_match(/translation missing/i, response.body)
  end

  test "shows the campus menu with the overview as the current section" do
    create(:campus, name: "Pato Branco")

    get admin_campus_path(@campus)

    assert_select "aside nav[aria-label='Menu do campus']" do
      assert_select "a.active[aria-current='page'][href='#{admin_campus_path(@campus)}']", text: /Visão geral/
      assert_select "details summary", text: /Guarapuava/
    end
  end

  test "summarizes the spaces of the campus by status" do
    create_list(:space, 5, campus: @campus)
    create(:space, :unavailable, campus: @campus)
    create(:space, :deactivated, campus: @campus)
    create(:space)

    get admin_campus_path(@campus)

    assert_select "#spaces_summary" do
      assert_select "p", text: "7"
      assert_select "p", text: "5 disponíveis, 1 indisponível e 1 desativado."
      assert_select "a[href='#{admin_campus_spaces_path(@campus)}']", text: "Ver todos os espaços"
      assert_select "a[href='#{new_admin_campus_space_path(@campus)}']", text: "Cadastrar espaço"
    end
  end

  test "summarizes the buildings of the campus by name" do
    [ "Bloco R", "Bloco B", "Bloco C" ].each { |name| create(:building, campus: @campus, name: name) }
    create(:building, name: "Bloco A")

    get admin_campus_path(@campus)

    assert_select "#buildings_summary" do
      assert_select "p", text: "3"
      assert_select "p", text: "Bloco B, Bloco C e Bloco R."
      assert_select "a[href='#{admin_campus_buildings_path(@campus)}']", text: "Ver todos os blocos"
      assert_select "a[href='#{new_admin_campus_building_path(@campus)}']", text: "Cadastrar bloco"
    end
  end

  test "lists the unavailable spaces of the campus with the reason" do
    building = create(:building, campus: @campus, name: "Bloco B")
    space = create(:space, :unavailable, campus: @campus, building: building, name: "Sala B102")
    create(:space, :unavailable, name: "Sala de outro campus")

    get admin_campus_path(@campus)

    assert_select "#unavailable_spaces" do
      assert_select "h2", text: "Espaços indisponíveis"
      assert_select "li", count: 1
      assert_select "li p", text: /Sala B102\s+· Bloco B/
      assert_select "li p", text: "Motivo: Sala em reforma"
      assert_select "li a[href='#{admin_campus_space_path(@campus, space)}']", text: "Ver espaço Sala B102"
    end
  end

  test "shows quotes and HTML typed in names as text" do
    create(:building, campus: @campus, name: "<b>Bloco</b>")
    create(:space, :unavailable, campus: @campus, name: "Sala \"<i>1</i>\"")

    get admin_campus_path(@campus)

    assert_select "#buildings_summary p", text: "<b>Bloco</b>."
    assert_select "#unavailable_spaces li a", text: "Ver espaço Sala \"<i>1</i>\""
    assert_select "#buildings_summary b, #unavailable_spaces i", count: 0
  end

  test "tells when the campus has no registrations" do
    get admin_campus_path(@campus)

    assert_select "#spaces_summary p", text: "Nenhum espaço cadastrado."
    assert_select "#buildings_summary p", text: "Nenhum bloco cadastrado."
    assert_select "#unavailable_spaces p", text: "Nenhum espaço indisponível."
  end

  test "offers to edit the campus and asks for confirmation before deleting it" do
    get admin_campus_path(@campus)

    assert_select "main a[href='#{edit_admin_campus_path(@campus)}']", text: "Editar campus"
    assert_select "form[action='#{admin_campus_path(@campus)}'][data-turbo-confirm='Excluir o campus Guarapuava?']" do
      assert_select "input[name='_method'][value='delete']"
      assert_select "button", text: "Excluir campus"
    end
  end

  test "shows the new campus form" do
    get new_admin_campus_path

    assert_response :success
    assert_select "main h1", count: 1, text: "Novo campus"
    assert_select "header p", text: "Preencha as informações do novo campus."
    assert_breadcrumbs(admin_breadcrumbs, current: "Novo campus")
    assert_select "form[action='#{admin_campi_path}'] input[name='campus[name]'][placeholder='Ex.: Guarapuava']"
    assert_select "form a[href='#{admin_root_path}']", text: "Cancelar"
    assert_select "aside nav[aria-label='Menu do campus']", count: 0
    assert_no_match(/translation missing/i, response.body)
  end

  test "creates a campus and goes back to the entry" do
    assert_difference("Campus.count", 1) do
      post admin_campi_path, params: { campus: { name: "  Pato   Branco " } }
    end

    assert_redirected_to admin_root_path
    follow_redirect!
    assert_success_toast "Campus cadastrado com sucesso."
    assert_select "article h3", text: "Pato Branco"
  end

  test "rejects a campus without a name" do
    assert_no_difference("Campus.count") do
      post admin_campi_path, params: { campus: { name: "" } }
    end

    assert_response :unprocessable_content
    assert_select "h1", text: "Novo campus"
    assert_breadcrumbs(admin_breadcrumbs, current: "Novo campus")
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

  test "shows the edit form inside the campus" do
    get edit_admin_campus_path(@campus)

    assert_response :success
    assert_select "main h1", count: 1, text: "Editar campus"
    assert_select "header p", text: "Altere as informações do campus."
    assert_breadcrumbs(admin_breadcrumbs.merge("Guarapuava" => admin_campus_path(@campus)), current: "Editar")
    assert_select "form[action='#{admin_campus_path(@campus)}'] input[name='campus[name]'][value='Guarapuava']"
    assert_select "form a[href='#{admin_campus_path(@campus)}']", text: "Cancelar"
    assert_select "aside nav[aria-label='Menu do campus'] a[aria-current='page']", text: /Visão geral/
    assert_no_match(/translation missing/i, response.body)
  end

  test "updates a campus and goes back to its page" do
    patch admin_campus_path(@campus), params: { campus: { name: "Ponta Grossa" } }

    assert_redirected_to admin_campus_path(@campus)
    assert_equal "Ponta Grossa", @campus.reload.name
    follow_redirect!
    assert_success_toast "Campus atualizado com sucesso."
  end

  test "rejects renaming a campus to a name already taken and keeps the saved name in the trail" do
    create(:campus, name: "Pato Branco")

    patch admin_campus_path(@campus), params: { campus: { name: "PATO BRANCO" } }

    assert_response :unprocessable_content
    assert_select "h1", text: "Editar campus"
    assert_breadcrumbs(admin_breadcrumbs.merge("Guarapuava" => admin_campus_path(@campus)), current: "Editar")
    assert_select "p", text: "Já existe um campus cadastrado com este nome."
    assert_select "aside details summary", text: /Guarapuava/
    assert_equal "Guarapuava", @campus.reload.name
  end

  test "deletes a campus and goes back to the entry" do
    assert_difference("Campus.count", -1) do
      delete admin_campus_path(@campus)
    end

    assert_response :see_other
    assert_redirected_to admin_root_path
    follow_redirect!
    assert_success_toast "Campus excluído com sucesso."
    assert_select "p", text: "Nenhum campus cadastrado."
  end

  test "refuses to delete a campus that has buildings and stays on its page" do
    create(:building, campus: @campus)

    assert_no_difference([ "Campus.count", "Building.count" ]) do
      delete admin_campus_path(@campus)
    end

    assert_response :see_other
    assert_redirected_to admin_campus_path(@campus)
    follow_redirect!
    assert_alert_toast "Não é possível excluir o campus porque ele tem blocos cadastrados. Exclua-os antes."
  end

  test "refuses to delete a campus that has spaces and stays on its page" do
    create(:space, campus: @campus)

    assert_no_difference([ "Campus.count", "Space.count" ]) do
      delete admin_campus_path(@campus)
    end

    assert_redirected_to admin_campus_path(@campus)
    follow_redirect!
    assert_alert_toast "Não é possível excluir o campus porque ele tem espaços cadastrados. Exclua-os antes."
  end

  test "responds not found for a campus that does not exist" do
    [ admin_campus_path(id: 0), edit_admin_campus_path(id: 0) ].each do |path|
      get path

      assert_response :not_found, path
    end
  end

  private

    def admin_breadcrumbs
      { "Dashboard" => users_root_path, "Área administrativa" => admin_root_path }
    end

    def assert_success_toast(message)
      assert_select "[data-controller='ui--toast'][data-ui--toast-message-type-value='success']" \
                    "[data-ui--toast-message-text-value='#{message}']"
    end

    def assert_alert_toast(message)
      assert_select "[data-controller='ui--toast'][data-ui--toast-message-type-value='alert']" \
                    "[data-ui--toast-message-text-value='#{message}']"
    end
end
