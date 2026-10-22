require "test_helper"
require "support/helpers/breadcrumb_assertions"

class Admin::BuildingsControllerTest < ActionDispatch::IntegrationTest
  include BreadcrumbAssertions

  setup do
    sign_in create(:user, :admin)
    @guarapuava = create(:campus, name: "Guarapuava")
  end

  test "lists buildings ordered by campus and name, with the campus of each" do
    pato_branco = create(:campus, name: "Pato Branco")
    create(:building, campus: pato_branco, name: "Bloco A")
    create(:building, campus: @guarapuava, name: "Bloco R")
    create(:building, campus: @guarapuava, name: "Bloco B")

    get admin_buildings_path

    assert_response :success
    assert_equal [ [ "Bloco B", "Guarapuava" ], [ "Bloco R", "Guarapuava" ], [ "Bloco A", "Pato Branco" ] ],
                 listed_buildings
    assert_select "a[href='#{new_admin_building_path}']", text: "Novo bloco"
    assert_no_match(/translation missing/i, response.body)
  end

  test "shows the list title, subtitle and breadcrumbs" do
    get admin_buildings_path

    assert_select "main h1", count: 1, text: "Blocos"
    assert_select "header p", text: "Gerencie os blocos de cada campus, que organizam os espaços."
    assert_breadcrumbs({ "Dashboard" => users_root_path, "Área administrativa" => admin_root_path }, current: "Blocos")
  end

  test "shows a message when there are no buildings" do
    get admin_buildings_path

    assert_response :success
    assert_select "p", text: "Nenhum bloco cadastrado."
    assert_select "table", count: 0
  end

  test "links each building to its edit page" do
    building = create(:building, campus: @guarapuava, name: "Bloco R")

    get admin_buildings_path

    assert_select "##{dom_id(building)} a[href='#{edit_admin_building_path(building)}']", text: "Editar"
  end

  test "shows the new building form with the campi in alphabetical order" do
    create(:campus, name: "Campo Mourão")

    get new_admin_building_path

    assert_response :success
    assert_select "main h1", count: 1, text: "Novo bloco"
    assert_select "header p", text: "Preencha as informações do novo bloco."
    assert_breadcrumbs(buildings_breadcrumbs, current: "Novo")
    assert_select "form[action='#{admin_buildings_path}']" do
      assert_equal [ "Selecione o campus", "Campo Mourão", "Guarapuava" ],
                   css_select("select[name='building[campus_id]'] option").map(&:text)
      assert_select "input[name='building[name]'][placeholder='Ex.: Bloco R']"
      assert_select "a[href='#{admin_buildings_path}']", text: "Cancelar"
    end
    assert_no_match(/translation missing/i, response.body)
  end

  test "creates a building and shows a confirmation" do
    assert_difference("Building.count", 1) do
      post admin_buildings_path, params: { building: { campus_id: @guarapuava.id, name: "  Bloco   D " } }
    end

    assert_redirected_to admin_buildings_path
    follow_redirect!
    assert_success_toast "Bloco cadastrado com sucesso."
    assert_equal [ [ "Bloco D", "Guarapuava" ] ], listed_buildings
  end

  test "rejects a building without a campus" do
    assert_no_difference("Building.count") do
      post admin_buildings_path, params: { building: { campus_id: "", name: "Bloco D" } }
    end

    assert_response :unprocessable_content
    assert_select "h1", text: "Novo bloco"
    assert_breadcrumbs(buildings_breadcrumbs, current: "Novo")
    assert_select "select[name='building[campus_id]'] + p", text: "Selecione o campus."
    assert_select "input[name='building[name]'][value='Bloco D']"
  end

  test "rejects a building without a name and keeps the chosen campus" do
    assert_no_difference("Building.count") do
      post admin_buildings_path, params: { building: { campus_id: @guarapuava.id, name: "" } }
    end

    assert_response :unprocessable_content
    assert_select "p", text: "Informe o nome do bloco."
    assert_select "option[selected][value='#{@guarapuava.id}']", text: "Guarapuava"
  end

  test "rejects a name already taken in the same campus" do
    create(:building, campus: @guarapuava, name: "Bloco R")

    assert_no_difference("Building.count") do
      post admin_buildings_path, params: { building: { campus_id: @guarapuava.id, name: "bloco-r" } }
    end

    assert_response :unprocessable_content
    assert_select "input[name='building[name]'][value='bloco-r']"
    assert_select "p", text: "Já existe um bloco com este nome neste campus."
  end

  test "shows the edit form with the current campus and name" do
    building = create(:building, campus: @guarapuava, name: "Bloco R")

    get edit_admin_building_path(building)

    assert_response :success
    assert_select "main h1", count: 1, text: "Editar bloco"
    assert_select "header p", text: "Altere as informações do bloco."
    assert_breadcrumbs(buildings_breadcrumbs, current: "Editar")
    assert_select "form[action='#{admin_building_path(building)}']" do
      assert_select "option[selected][value='#{@guarapuava.id}']", text: "Guarapuava"
      assert_select "input[name='building[name]'][value='Bloco R']"
    end
    assert_no_match(/translation missing/i, response.body)
  end

  test "updates the name and the campus of a building and shows a confirmation" do
    pato_branco = create(:campus, name: "Pato Branco")
    building = create(:building, campus: @guarapuava, name: "Bloco R")

    patch admin_building_path(building), params: { building: { campus_id: pato_branco.id, name: "Bloco S" } }

    assert_redirected_to admin_buildings_path
    assert_equal [ pato_branco, "Bloco S" ], [ building.reload.campus, building.name ]
    follow_redirect!
    assert_success_toast "Bloco atualizado com sucesso."
  end

  test "rejects renaming a building to a name taken in its campus" do
    create(:building, campus: @guarapuava, name: "Bloco B")
    building = create(:building, campus: @guarapuava, name: "Bloco R")

    patch admin_building_path(building), params: { building: { campus_id: @guarapuava.id, name: "BLOCO B" } }

    assert_response :unprocessable_content
    assert_select "h1", text: "Editar bloco"
    assert_breadcrumbs(buildings_breadcrumbs, current: "Editar")
    assert_select "p", text: "Já existe um bloco com este nome neste campus."
    assert_equal "Bloco R", building.reload.name
  end

  test "asks for confirmation before deleting a building" do
    building = create(:building, campus: @guarapuava, name: "Bloco R")

    get admin_buildings_path

    assert_select "##{dom_id(building)} form[action='#{admin_building_path(building)}']" \
                  "[data-turbo-confirm='Excluir o bloco Bloco R do campus Guarapuava?']" do
      assert_select "input[name='_method'][value='delete']"
      assert_select "button", text: "Excluir"
    end
  end

  test "deletes a building and shows a confirmation" do
    building = create(:building, campus: @guarapuava, name: "Bloco R")

    assert_difference("Building.count", -1) do
      delete admin_building_path(building)
    end

    assert_response :see_other
    assert_redirected_to admin_buildings_path
    follow_redirect!
    assert_success_toast "Bloco excluído com sucesso."
    assert_select "p", text: "Nenhum bloco cadastrado."
  end

  test "responds not found for a building that does not exist" do
    get edit_admin_building_path(id: 0)

    assert_response :not_found
  end

  private

    def buildings_breadcrumbs
      { "Dashboard" => users_root_path, "Área administrativa" => admin_root_path, "Blocos" => admin_buildings_path }
    end

    # [ name, campus ] of each row, read from the name cell and the campus column.
    def listed_buildings
      css_select("tbody tr").map do |row|
        [ row.at_css("td:nth-child(1) span").text.strip, row.at_css("td:nth-child(2)").text.strip ]
      end
    end

    def assert_success_toast(message)
      assert_select "[data-controller='ui--toast'][data-ui--toast-message-type-value='success']" \
                    "[data-ui--toast-message-text-value='#{message}']"
    end
end
