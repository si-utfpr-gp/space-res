require "test_helper"
require "support/helpers/breadcrumb_assertions"

class Admin::Campi::BuildingsControllerTest < ActionDispatch::IntegrationTest
  include BreadcrumbAssertions

  setup do
    sign_in create(:user, :admin)
    @guarapuava = create(:campus, name: "Guarapuava")
    @pato_branco = create(:campus, name: "Pato Branco")
  end

  test "lists only the buildings of the campus, ordered by name" do
    create(:building, campus: @pato_branco, name: "Bloco A")
    create(:building, campus: @guarapuava, name: "Bloco R")
    create(:building, campus: @guarapuava, name: "Bloco B")

    get admin_campus_buildings_path(@guarapuava)

    assert_response :success
    assert_equal [ "Bloco B", "Bloco R" ], listed_building_names
    assert_select "th", text: "Campus", count: 0
    assert_select "a[href='#{new_admin_campus_building_path(@guarapuava)}']", text: "Novo bloco"
    assert_no_match(/translation missing/i, response.body)
  end

  test "shows the list title, subtitle, breadcrumbs and the campus menu" do
    get admin_campus_buildings_path(@guarapuava)

    assert_select "main h1", count: 1, text: "Blocos"
    assert_select "header p", text: "Gerencie os blocos do campus Guarapuava, que organizam os espaços."
    assert_breadcrumbs(campus_breadcrumbs, current: "Blocos")
    assert_select "aside nav[aria-label='Menu do campus'] a.active[aria-current='page']", text: /Blocos/
  end

  test "opens another campus on its buildings from the campus selector" do
    get admin_campus_buildings_path(@guarapuava)

    assert_select "aside details a[href='#{admin_campus_buildings_path(@pato_branco)}']", text: "Pato Branco"
  end

  test "shows a message when the campus has no buildings" do
    create(:building, campus: @pato_branco)

    get admin_campus_buildings_path(@guarapuava)

    assert_response :success
    assert_select "p", text: "Nenhum bloco cadastrado neste campus."
    assert_select "table", count: 0
  end

  test "links each building to its edit page" do
    building = create(:building, campus: @guarapuava, name: "Bloco R")

    get admin_campus_buildings_path(@guarapuava)

    assert_select "##{dom_id(building)} a[href='#{edit_admin_campus_building_path(@guarapuava, building)}']", text: "Editar"
  end

  test "shows the new building form with the name only" do
    get new_admin_campus_building_path(@guarapuava)

    assert_response :success
    assert_select "main h1", count: 1, text: "Novo bloco"
    assert_select "header p", text: "Preencha as informações do novo bloco do campus Guarapuava."
    assert_breadcrumbs(buildings_breadcrumbs, current: "Novo")
    assert_select "form[action='#{admin_campus_buildings_path(@guarapuava)}']" do
      assert_select "select", count: 0
      assert_select "input[name='building[name]'][placeholder='Ex.: Bloco R']"
      assert_select "a[href='#{admin_campus_buildings_path(@guarapuava)}']", text: "Cancelar"
    end
    assert_select "aside nav[aria-label='Menu do campus'] a[aria-current='page']", text: /Blocos/
    assert_no_match(/translation missing/i, response.body)
  end

  test "creates a building in the campus of the URL and shows a confirmation" do
    assert_difference("@guarapuava.buildings.count", 1) do
      post admin_campus_buildings_path(@guarapuava), params: { building: { name: "  Bloco   D " } }
    end

    assert_redirected_to admin_campus_buildings_path(@guarapuava)
    follow_redirect!
    assert_success_toast "Bloco cadastrado com sucesso."
    assert_equal [ "Bloco D" ], listed_building_names
  end

  test "ignores a campus sent with a new building" do
    post admin_campus_buildings_path(@guarapuava), params: { building: { campus_id: @pato_branco.id, name: "Bloco D" } }

    assert_equal @guarapuava, Building.find_by!(name: "Bloco D").campus
    assert_empty @pato_branco.buildings
  end

  test "rejects a building without a name" do
    assert_no_difference("Building.count") do
      post admin_campus_buildings_path(@guarapuava), params: { building: { name: "" } }
    end

    assert_response :unprocessable_content
    assert_select "h1", text: "Novo bloco"
    assert_breadcrumbs(buildings_breadcrumbs, current: "Novo")
    assert_select "p", text: "Informe o nome do bloco."
  end

  test "rejects a name already taken in the same campus" do
    create(:building, campus: @guarapuava, name: "Bloco R")

    assert_no_difference("Building.count") do
      post admin_campus_buildings_path(@guarapuava), params: { building: { name: "bloco-r" } }
    end

    assert_response :unprocessable_content
    assert_select "input[name='building[name]'][value='bloco-r']"
    assert_select "p", text: "Já existe um bloco com este nome neste campus."
  end

  test "accepts the name of a building of another campus" do
    create(:building, campus: @pato_branco, name: "Bloco R")

    assert_difference("@guarapuava.buildings.count", 1) do
      post admin_campus_buildings_path(@guarapuava), params: { building: { name: "Bloco R" } }
    end
  end

  test "shows the edit form with the current name" do
    building = create(:building, campus: @guarapuava, name: "Bloco R")

    get edit_admin_campus_building_path(@guarapuava, building)

    assert_response :success
    assert_select "main h1", count: 1, text: "Editar bloco"
    assert_select "header p", text: "Altere as informações do bloco do campus Guarapuava."
    assert_breadcrumbs(buildings_breadcrumbs, current: "Editar")
    assert_select "form[action='#{admin_campus_building_path(@guarapuava, building)}']" do
      assert_select "select", count: 0
      assert_select "input[name='building[name]'][value='Bloco R']"
    end
    assert_no_match(/translation missing/i, response.body)
  end

  test "updates the name of a building and shows a confirmation" do
    building = create(:building, campus: @guarapuava, name: "Bloco R")

    patch admin_campus_building_path(@guarapuava, building), params: { building: { name: "Bloco S" } }

    assert_redirected_to admin_campus_buildings_path(@guarapuava)
    assert_equal "Bloco S", building.reload.name
    follow_redirect!
    assert_success_toast "Bloco atualizado com sucesso."
  end

  test "keeps the building and its spaces in their campus when another campus is sent" do
    building = create(:building, campus: @guarapuava, name: "Bloco R")
    space = create(:space, campus: @guarapuava, building: building)

    patch admin_campus_building_path(@guarapuava, building), params: { building: { campus_id: @pato_branco.id, name: "Bloco S" } }

    assert_redirected_to admin_campus_buildings_path(@guarapuava)
    assert_equal [ @guarapuava, "Bloco S" ], [ building.reload.campus, building.name ]
    assert_equal @guarapuava, space.reload.campus
    follow_redirect!
    assert_success_toast "Bloco atualizado com sucesso."
  end

  test "rejects renaming a building to a name taken in its campus" do
    create(:building, campus: @guarapuava, name: "Bloco B")
    building = create(:building, campus: @guarapuava, name: "Bloco R")

    patch admin_campus_building_path(@guarapuava, building), params: { building: { name: "BLOCO B" } }

    assert_response :unprocessable_content
    assert_select "h1", text: "Editar bloco"
    assert_breadcrumbs(buildings_breadcrumbs, current: "Editar")
    assert_select "p", text: "Já existe um bloco com este nome neste campus."
    assert_equal "Bloco R", building.reload.name
  end

  test "asks for confirmation before deleting a building" do
    building = create(:building, campus: @guarapuava, name: "Bloco R")

    get admin_campus_buildings_path(@guarapuava)

    assert_select "##{dom_id(building)} form[action='#{admin_campus_building_path(@guarapuava, building)}']" \
                  "[data-turbo-confirm='Excluir o bloco Bloco R?']" do
      assert_select "input[name='_method'][value='delete']"
      assert_select "button", text: "Excluir"
    end
  end

  test "deletes a building and shows a confirmation" do
    building = create(:building, campus: @guarapuava, name: "Bloco R")

    assert_difference("Building.count", -1) do
      delete admin_campus_building_path(@guarapuava, building)
    end

    assert_response :see_other
    assert_redirected_to admin_campus_buildings_path(@guarapuava)
    follow_redirect!
    assert_success_toast "Bloco excluído com sucesso."
    assert_select "p", text: "Nenhum bloco cadastrado neste campus."
  end

  test "refuses to delete a building that has spaces and tells the next step" do
    building = create(:building, campus: @guarapuava, name: "Bloco B")
    create(:space, campus: @guarapuava, building: building)

    assert_no_difference([ "Building.count", "Space.count" ]) do
      delete admin_campus_building_path(@guarapuava, building)
    end

    assert_response :see_other
    assert_redirected_to admin_campus_buildings_path(@guarapuava)
    follow_redirect!
    assert_select "[data-controller='ui--toast'][data-ui--toast-message-type-value='alert']" \
                  "[data-ui--toast-message-text-value='Não é possível excluir o bloco porque ele tem espaços cadastrados. Mova os espaços para outro bloco ou exclua-os antes.']"
    assert_select "tbody tr", count: 1
  end

  test "does not find a building of another campus through this campus" do
    building = create(:building, campus: @pato_branco, name: "Bloco A")

    get edit_admin_campus_building_path(@guarapuava, building)
    assert_response :not_found

    patch admin_campus_building_path(@guarapuava, building), params: { building: { name: "Bloco Z" } }
    assert_response :not_found

    delete admin_campus_building_path(@guarapuava, building)
    assert_response :not_found

    assert_equal [ @pato_branco, "Bloco A" ], [ building.reload.campus, building.name ]
  end

  test "responds not found for a building or campus that does not exist" do
    [ edit_admin_campus_building_path(@guarapuava, id: 0), admin_campus_buildings_path(campus_id: 0) ].each do |path|
      get path

      assert_response :not_found, path
    end
  end

  private

    def campus_breadcrumbs
      { "Dashboard" => users_root_path, "Área administrativa" => admin_root_path, "Guarapuava" => admin_campus_path(@guarapuava) }
    end

    def buildings_breadcrumbs
      campus_breadcrumbs.merge("Blocos" => admin_campus_buildings_path(@guarapuava))
    end

    def listed_building_names
      css_select("tbody tr td:first-child").map { |cell| cell.text.strip }
    end

    def assert_success_toast(message)
      assert_select "[data-controller='ui--toast'][data-ui--toast-message-type-value='success']" \
                    "[data-ui--toast-message-text-value='#{message}']"
    end
end
