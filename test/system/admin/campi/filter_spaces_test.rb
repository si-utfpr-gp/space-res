require "application_system_test_case"

class FilterSpacesTest < ApplicationSystemTestCase
  setup do
    sign_in_as create(:user, :admin)
    @campus = create(:campus, name: "Guarapuava")
    @bloco_b = create(:building, campus: @campus, name: "Bloco B")
    @bloco_c = create(:building, campus: @campus, name: "Bloco C")
    create(:space, campus: @campus, building: @bloco_b, name: "Sala 1")
    create(:space, campus: @campus, building: @bloco_c, name: "Laboratório de Informática C3")
    create(:space, :unavailable, campus: @campus, name: "Quadra")
    create(:space, campus: create(:campus, name: "Pato Branco"), name: "Sala de outro campus")
  end

  test "choosing a building updates the table without reloading the page and the URL gains the filter" do
    visit admin_campus_spaces_path(@campus)
    assert_selector "#spaces_count", text: "3 espaços"
    mark_page

    select "Bloco C", from: "Bloco"

    assert_selector "#spaces_count", text: "1 espaço"
    assert_selector "tbody tr", count: 1
    assert_selector "tbody tr", text: "Laboratório de Informática C3"
    assert_no_text "Sala 1"
    assert_current_path(/filters(%5B|\[)building(%5D|\])=#{@bloco_c.id}/, ignore_query: false)
    assert_page_not_reloaded
  end

  test "choosing a status and the option without building filters the listing" do
    visit admin_campus_spaces_path(@campus)

    select "Indisponível", from: "Situação"
    assert_selector "tbody tr", count: 1
    assert_selector "tbody tr", text: "Quadra"

    select "Todas as situações", from: "Situação"
    select "Sem bloco", from: "Bloco"
    assert_selector "tbody tr", count: 1
    assert_selector "tbody tr", text: "Quadra"
  end

  test "typing a name without accents shows the matching spaces and their count" do
    visit admin_campus_spaces_path(@campus)
    mark_page

    fill_in "Nome", with: "laboratorio"

    assert_selector "#spaces_count", text: "1 espaço"
    assert_selector "tbody tr", count: 1
    assert_selector "tbody tr", text: "Laboratório de Informática C3"
    assert_current_path(/filters(%5B|\[)name(%5D|\])=laboratorio/, ignore_query: false)
    assert_page_not_reloaded
  end

  test "the focus stays in the name field after the results update" do
    visit admin_campus_spaces_path(@campus)

    fill_in "Nome", with: "sala"
    assert_selector "#spaces_count", text: "1 espaço"
    assert_selector "tbody tr", text: "Sala 1"

    assert_equal find_field("Nome"), page.active_element
    send_keys "x"
    assert_text "Nenhum espaço encontrado com estes filtros."
    assert_field "Nome", with: "salax"
  end

  test "reloading keeps the filters in the fields and in the results" do
    visit admin_campus_spaces_path(@campus)
    select "Bloco C", from: "Bloco"
    fill_in "Nome", with: "informatica"
    assert_selector "tbody tr", count: 1
    assert_current_path(/filters(%5B|\[)name(%5D|\])=informatica/, ignore_query: false)

    page.refresh

    assert_field "Nome", with: "informatica"
    assert_select "Bloco", selected: "Bloco C"
    assert_selector "#spaces_count", text: "1 espaço"
    assert_selector "tbody tr", count: 1
    assert_selector "tbody tr", text: "Laboratório de Informática C3"
  end

  test "clear filters resets the fields and the results" do
    visit admin_campus_spaces_path(@campus)
    select "Bloco B", from: "Bloco"
    fill_in "Nome", with: "sala"
    assert_current_path(/filters(%5B|\[)name(%5D|\])=sala/, ignore_query: false)
    assert_selector "tbody tr", count: 1

    click_on "Limpar filtros"

    assert_current_path admin_campus_spaces_path(@campus), ignore_query: false
    assert_field "Nome", with: ""
    assert_select "Bloco", selected: "Todos os blocos"
    assert_select "Situação", selected: "Todas as situações"
    assert_selector "#spaces_count", text: "3 espaços"
    assert_selector "tbody tr", count: 3
    assert_no_link "Limpar filtros"
  end

  test "shows a message and the way to clear the filters when nothing matches" do
    visit admin_campus_spaces_path(@campus)

    fill_in "Nome", with: "auditório"

    assert_text "Nenhum espaço encontrado com estes filtros."
    assert_selector "#spaces_count", text: "0 espaços"
    assert_no_selector "table"
    assert_link "Limpar filtros"
  end

  test "the filter button is hidden when JavaScript runs" do
    visit admin_campus_spaces_path(@campus)

    assert_field "Nome"
    assert_no_button "Filtrar"
  end

  private

    # A property of the window disappears if the page is loaded again, so it tells a frame update
    # from a full reload.
    def mark_page
      page.execute_script("window.__notReloaded = true")
    end

    def assert_page_not_reloaded
      assert page.evaluate_script("window.__notReloaded === true"), "the page was reloaded"
    end
end
