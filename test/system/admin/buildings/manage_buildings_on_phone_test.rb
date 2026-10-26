require "application_system_test_case"

class ManageBuildingsOnPhoneTest < ApplicationSystemTestCase
  setup do
    sign_in_as create(:user, :admin)
    page.current_window.resize_to(320, 640)
  end

  teardown do
    page.current_window.resize_to(1400, 1400)
  end

  # 320 CSS px is the width WCAG 1.4.10 (Reflow) requires to work without horizontal scrolling.
  test "fits the buildings list on a 320px wide screen, with the campus under the name" do
    create(:building, campus: create(:campus, name: "Campo Mourão"), name: "Bloco Química")
    visit admin_buildings_path

    assert_selector "thead th", count: 2
    within("tbody tr", text: "Bloco Química") do
      assert_text "Campo Mourão"
      assert_link "Editar"
      assert_button "Excluir"
    end
    assert_operator page.evaluate_script("document.querySelector('table').getBoundingClientRect().right"),
                    :<=, page.evaluate_script("window.innerWidth")
  end

  test "admin creates a building on a phone" do
    create(:campus, name: "Guarapuava")
    visit admin_buildings_path
    click_on "Novo bloco"

    select "Guarapuava", from: "Campus"
    assert_operator page.evaluate_script("document.querySelector('select').getBoundingClientRect().height"), :>=, 44
    fill_in "Nome", with: "Bloco R"
    click_on "Salvar"

    assert_flash_message "Bloco cadastrado com sucesso."
    assert_selector "tbody tr", text: "Bloco R"
  end
end
