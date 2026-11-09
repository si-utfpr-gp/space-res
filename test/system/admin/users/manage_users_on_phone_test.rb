require "application_system_test_case"

class ManageUsersOnPhoneTest < ApplicationSystemTestCase
  LONGEST_DEPARTMENT = "Núcleo de Acompanhamento Psicopedagógico e Assistência Estudantil".freeze

  setup do
    sign_in_as create(:user, :admin, name: "Admin Demo")
    page.current_window.resize_to(320, 640)
  end

  teardown do
    page.current_window.resize_to(1400, 1400)
  end

  # 320 CSS px is the width WCAG 1.4.10 (Reflow) requires to work without horizontal scrolling.
  test "fits long names, e-mails and departments on a 320px wide screen" do
    create(:user, name: "Maria Aparecida dos Santos Albuquerque Ferreira",
                  email_address: "maria.aparecida.santos.albuquerque@utfpr.edu.br",
                  department: create(:department, name: LONGEST_DEPARTMENT))
    visit admin_users_path

    within("tbody tr", text: "Maria Aparecida") do
      assert_text LONGEST_DEPARTMENT
      assert_link "Editar"
    end
    assert_operator page.evaluate_script("document.querySelector('table').getBoundingClientRect().right"),
                    :<=, page.evaluate_script("window.innerWidth")
  end

  test "admin sets the department of a user on a phone" do
    create(:department, name: "Biblioteca")
    create(:user, name: "Ana Lima")
    visit admin_users_path

    within("tbody tr", text: "Ana Lima") { click_on "Editar" }
    select "Biblioteca", from: "Departamento"
    click_on "Salvar"

    assert_flash_message "Usuário atualizado com sucesso."
    assert_selector "tbody tr", text: /Ana Lima.*Biblioteca/m
  end
end
