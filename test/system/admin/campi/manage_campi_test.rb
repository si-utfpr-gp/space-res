require "application_system_test_case"

class ManageCampiTest < ApplicationSystemTestCase
  setup do
    sign_in_as create(:user, :admin)
  end

  test "admin creates, edits and deletes a campus" do
    visit admin_root_path
    click_on "Campi"

    click_on "Novo campus"
    fill_in "Nome", with: "Pato Branco"
    click_on "Salvar"

    assert_flash_message "Campus cadastrado com sucesso."
    assert_selector "tbody tr", text: "Pato Branco"

    within("tbody tr", text: "Pato Branco") { click_on "Editar" }
    fill_in "Nome", with: "Ponta Grossa"
    click_on "Salvar"

    assert_flash_message "Campus atualizado com sucesso."
    assert_selector "tbody tr", text: "Ponta Grossa"

    accept_confirm "Excluir o campus Ponta Grossa?" do
      within("tbody tr", text: "Ponta Grossa") { click_on "Excluir" }
    end

    assert_flash_message "Campus excluído com sucesso."
    assert_text "Nenhum campus cadastrado."
  end

  test "keeps the campus when the deletion is not confirmed" do
    create(:campus, name: "Guarapuava")
    visit admin_campi_path

    dismiss_confirm "Excluir o campus Guarapuava?" do
      click_on "Excluir"
    end

    visit admin_campi_path
    assert_selector "tbody tr", text: "Guarapuava"
  end

  test "shows the error when the name is already taken" do
    create(:campus, name: "Campo Mourão")
    visit new_admin_campus_path

    fill_in "Nome", with: "campo mourao"
    click_on "Salvar"

    assert_text "Já existe um campus cadastrado com este nome."
    assert_field "Nome", with: "campo mourao"
  end
end
