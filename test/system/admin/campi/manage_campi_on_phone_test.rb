require "application_system_test_case"

class ManageCampiOnPhoneTest < ApplicationSystemTestCase
  setup do
    sign_in_as create(:user, :admin)
    page.current_window.resize_to(320, 640)
  end

  teardown do
    page.current_window.resize_to(1400, 1400)
  end

  # 320 CSS px is the width WCAG 1.4.10 (Reflow) requires to work without horizontal scrolling.
  test "fits the campi list on a 320px wide screen" do
    create(:campus, name: "Campo Mourão")
    visit admin_campi_path

    within("tbody tr", text: "Campo Mourão") do
      assert_link "Editar"
      assert_button "Excluir"
    end
    assert_operator page.evaluate_script("document.querySelector('table').getBoundingClientRect().right"),
                    :<=, page.evaluate_script("window.innerWidth")
  end

  test "admin creates a campus on a phone" do
    visit admin_campi_path
    click_on "Novo campus"
    fill_in "Nome", with: "Pato Branco"
    click_on "Salvar"

    assert_flash_message "Campus cadastrado com sucesso."
    assert_selector "tbody tr", text: "Pato Branco"
  end
end
