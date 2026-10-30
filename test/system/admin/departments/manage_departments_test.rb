require "application_system_test_case"

class ManageDepartmentsTest < ApplicationSystemTestCase
  setup do
    sign_in_as create(:user, :admin)
  end

  test "admin creates, edits and deletes a department" do
    visit admin_root_path
    click_on "Departamentos"

    click_on "Novo departamento"
    fill_in "Nome", with: "Departamento de Educação"
    click_on "Salvar"

    assert_flash_message "Departamento cadastrado com sucesso."
    assert_selector "tbody tr", text: "Departamento de Educação"

    within("tbody tr", text: "Departamento de Educação") { click_on "Editar" }
    fill_in "Nome", with: "Departamento de Extensão"
    click_on "Salvar"

    assert_flash_message "Departamento atualizado com sucesso."
    assert_selector "tbody tr", text: "Departamento de Extensão"

    accept_confirm "Excluir o departamento Departamento de Extensão?" do
      within("tbody tr", text: "Departamento de Extensão") { click_on "Excluir" }
    end

    assert_flash_message "Departamento excluído com sucesso."
    assert_text "Nenhum departamento cadastrado."
  end

  test "keeps the department when the deletion is not confirmed" do
    create(:department, name: "Biblioteca")
    visit admin_departments_path

    dismiss_confirm "Excluir o departamento Biblioteca?" do
      click_on "Excluir"
    end

    visit admin_departments_path
    assert_selector "tbody tr", text: "Biblioteca"
  end

  test "shows the error when the name is already taken" do
    create(:department, name: "Departamento de Educação")
    visit new_admin_department_path

    fill_in "Nome", with: "departamento de educacao"
    click_on "Salvar"

    assert_text "Já existe um departamento cadastrado com este nome."
    assert_field "Nome", with: "departamento de educacao"
  end
end
