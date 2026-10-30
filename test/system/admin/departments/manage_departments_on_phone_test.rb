require "application_system_test_case"

class ManageDepartmentsOnPhoneTest < ApplicationSystemTestCase
  LONGEST_NAME = "Núcleo de Acompanhamento Psicopedagógico e Assistência Estudantil".freeze

  setup do
    sign_in_as create(:user, :admin)
    page.current_window.resize_to(320, 640)
  end

  teardown do
    page.current_window.resize_to(1400, 1400)
  end

  # 320 CSS px is the width WCAG 1.4.10 (Reflow) requires to work without horizontal scrolling.
  test "fits a long department name on a 320px wide screen" do
    create(:department, name: LONGEST_NAME)
    visit admin_departments_path

    within("tbody tr", text: LONGEST_NAME) do
      assert_link "Editar"
      assert_button "Excluir"
    end
    assert_operator page.evaluate_script("document.querySelector('table').getBoundingClientRect().right"),
                    :<=, page.evaluate_script("window.innerWidth")
  end

  test "admin creates a department on a phone" do
    visit admin_departments_path
    click_on "Novo departamento"
    fill_in "Nome", with: "Biblioteca"
    click_on "Salvar"

    assert_flash_message "Departamento cadastrado com sucesso."
    assert_selector "tbody tr", text: "Biblioteca"
  end
end
