require "application_system_test_case"

class ManageBuildingsOnPhoneTest < ApplicationSystemTestCase
  setup do
    sign_in_as create(:user, :admin)
    @campus = create(:campus, name: "Campo Mourão")
    page.current_window.resize_to(320, 640)
  end

  teardown do
    page.current_window.resize_to(1400, 1400)
  end

  # 320 CSS px is the width WCAG 1.4.10 (Reflow) requires to work without horizontal scrolling.
  test "fits the buildings list on a 320px wide screen" do
    create(:building, campus: @campus, name: "Bloco Química")
    visit admin_campus_buildings_path(@campus)

    assert_selector "thead th", count: 2
    within("tbody tr", text: "Bloco Química") do
      assert_link "Editar"
      assert_button "Excluir"
    end
    assert_operator page.evaluate_script("document.querySelector('table').getBoundingClientRect().right"),
                    :<=, page.evaluate_script("window.innerWidth")
  end

  test "admin creates a building on a phone" do
    visit admin_campus_buildings_path(@campus)
    click_on "Novo bloco"

    assert_operator find_button("Salvar").rect.height, :>=, 44
    fill_in "Nome", with: "Bloco R"
    click_on "Salvar"

    assert_flash_message "Bloco cadastrado com sucesso."
    assert_selector "tbody tr", text: "Bloco R"
  end

  test "admin reaches the buildings through the menu on a phone" do
    visit admin_campus_path(@campus)

    click_on "Menu de navegação", enable_aria_label: true
    within("nav[aria-label='Menu do campus']") { click_on "Blocos" }

    assert_current_path admin_campus_buildings_path(@campus)
    assert_selector "h1", text: "Blocos"
  end
end
