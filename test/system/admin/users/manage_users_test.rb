require "application_system_test_case"

class ManageUsersTest < ApplicationSystemTestCase
  setup do
    sign_in_as create(:user, :admin, name: "Admin Demo")
    create(:department, name: "Biblioteca")
    create(:department, name: "Departamento de Educação")
  end

  test "admin sets, changes and removes the department of a user" do
    create(:user, name: "Ana Lima")

    visit admin_root_path
    click_on "Usuários"
    assert_selector "tbody tr", text: "Admin Demo"
    assert_selector "tbody tr", text: /Ana Lima.*Sem departamento/m

    within("tbody tr", text: "Ana Lima") { click_on "Editar" }
    select "Biblioteca", from: "Departamento"
    click_on "Salvar"

    assert_flash_message "Usuário atualizado com sucesso."
    assert_selector "tbody tr", text: /Ana Lima.*Biblioteca/m

    within("tbody tr", text: "Ana Lima") { click_on "Editar" }
    assert_select "Departamento", selected: "Biblioteca"
    select "Departamento de Educação", from: "Departamento"
    click_on "Salvar"

    assert_selector "tbody tr", text: /Ana Lima.*Departamento de Educação/m

    within("tbody tr", text: "Ana Lima") { click_on "Editar" }
    select "Sem departamento", from: "Departamento"
    click_on "Salvar"

    assert_selector "tbody tr", text: /Ana Lima.*Sem departamento/m
  end

  test "admin cannot delete a department that has users" do
    create(:user, name: "Ana Lima", department: Department.find_by!(name: "Biblioteca"))
    visit admin_departments_path

    accept_confirm "Excluir o departamento Biblioteca?" do
      within("tbody tr", text: "Biblioteca") { click_on "Excluir" }
    end

    assert_flash_message "Não é possível excluir o departamento porque ele tem usuários vinculados."
    assert_selector "tbody tr", text: "Biblioteca"
  end
end
