require "test_helper"

class Admin::Campi::SpacesFiltersTest < ActionDispatch::IntegrationTest
  setup do
    sign_in create(:user, :admin)
    @campus = create(:campus, name: "Guarapuava")
    @bloco_b = create(:building, campus: @campus, name: "Bloco B")
    @bloco_c = create(:building, campus: @campus, name: "Bloco C")
    create(:space, campus: @campus, building: @bloco_b, name: "Sala B102")
    create(:space, :unavailable, campus: @campus, building: @bloco_b, name: "Laboratório de Física")
    create(:space, campus: @campus, building: @bloco_c, name: "Laboratório de Informática C3")
    create(:space, :deactivated, campus: @campus, name: "Planetário")
  end

  test "shows the filters above the spaces" do
    get admin_campus_spaces_path(@campus)

    assert_select "form[role='search'][aria-label='Filtrar espaços'][method='get'][action='#{admin_campus_spaces_path(@campus)}']" \
                  "[data-turbo-frame='spaces_results'][data-turbo-action='advance']" do
      assert_select "label", text: "Nome"
      assert_select "input[type='search'][name='filters[name]'][placeholder='Buscar pelo nome']"
      assert_select "label", text: "Bloco"
      assert_equal [ "Todos os blocos", "Sem bloco", "Bloco B", "Bloco C" ],
                   css_select("select[name='filters[building]'] option").map(&:text)
      assert_select "label", text: "Situação"
      assert_equal [ "Todas as situações", "Disponível", "Indisponível", "Desativado" ],
                   css_select("select[name='filters[status]'] option").map(&:text)
      assert_select "button[type='submit']", text: "Filtrar"
      assert_select "[aria-live='polite']"
    end
    assert_select "turbo-frame#spaces_results[target='_top'] #spaces_count", text: "4 espaços"
    assert_select "a", text: "Limpar filtros", count: 0
    assert_no_match(/translation missing/i, response.body)
  end

  test "filters by part of the name, ignoring case and accents" do
    get admin_campus_spaces_path(@campus, filters: { name: "LABORATORIO" })

    assert_equal [ "Laboratório de Física", "Laboratório de Informática C3" ], listed_space_names
    assert_select "#spaces_count", text: "2 espaços"
    assert_select "input[name='filters[name]'][value='LABORATORIO']"
  end

  test "filters by building" do
    get admin_campus_spaces_path(@campus, filters: { building: @bloco_b.id })

    assert_equal [ "Laboratório de Física", "Sala B102" ], listed_space_names
    assert_select "select[name='filters[building]'] option[selected][value='#{@bloco_b.id}']", text: "Bloco B"
  end

  test "filters the spaces without building" do
    get admin_campus_spaces_path(@campus, filters: { building: "none" })

    assert_equal [ "Planetário" ], listed_space_names
    assert_select "#spaces_count", text: "1 espaço"
  end

  test "filters by status" do
    get admin_campus_spaces_path(@campus, filters: { status: "unavailable" })

    assert_equal [ "Laboratório de Física" ], listed_space_names
    assert_select "select[name='filters[status]'] option[selected][value='unavailable']", text: "Indisponível"
  end

  test "combines the filters and offers to clear them" do
    get admin_campus_spaces_path(@campus, filters: { name: "laboratorio", building: @bloco_c.id, status: "available" })

    assert_equal [ "Laboratório de Informática C3" ], listed_space_names
    assert_select "a[href='#{admin_campus_spaces_path(@campus)}'][data-turbo-frame='_top']", text: "Limpar filtros"
  end

  test "tells when no space matches the filters" do
    get admin_campus_spaces_path(@campus, filters: { name: "auditório" })

    assert_select "table", count: 0
    assert_select "#spaces_count", text: "0 espaços"
    assert_select "p", text: "Nenhum espaço encontrado com estes filtros."
    assert_select "a[href='#{admin_campus_spaces_path(@campus)}']", text: "Limpar filtros"
  end

  test "ignores an unknown status and a building of another campus" do
    other_building = create(:building, name: "Bloco A")

    get admin_campus_spaces_path(@campus, filters: { building: other_building.id, status: "archived" })

    assert_response :success
    assert_equal 4, listed_space_names.size
    assert_select "select option[selected]", count: 0
    assert_select "a", text: "Limpar filtros", count: 0
  end

  test "ignores filters sent in another shape" do
    get admin_campus_spaces_path(@campus), params: "filters=sala"

    assert_response :success
    assert_equal 4, listed_space_names.size
  end

  test "answers a request of the results frame with the filtered spaces" do
    get admin_campus_spaces_path(@campus, filters: { status: "deactivated" }), headers: { "Turbo-Frame" => "spaces_results" }

    assert_response :success
    assert_select "turbo-frame#spaces_results" do
      assert_select "#spaces_count", text: "1 espaço"
      assert_select "tbody tr", count: 1, text: /Planetário/
    end
  end

  test "shows no filters for a campus without spaces" do
    empty_campus = create(:campus, name: "Pato Branco")

    get admin_campus_spaces_path(empty_campus)

    assert_select "form[role='search']", count: 0
    assert_select "p", text: "Nenhum espaço cadastrado neste campus."
  end

  private

    def listed_space_names
      css_select("tbody tr td:first-child a").map { |link| link.text.strip }
    end
end
