require "application_system_test_case"

class ManageBuildingsTest < ApplicationSystemTestCase
  setup do
    sign_in_as create(:user, :admin)
    @guarapuava = create(:campus, name: "Guarapuava")
    create(:campus, name: "Pato Branco")
  end

  test "admin creates, edits and deletes a building" do
    visit admin_root_path
    click_on "Blocos"

    click_on "Novo bloco"
    select "Guarapuava", from: "Campus"
    fill_in "Nome", with: "Bloco R"
    click_on "Salvar"

    assert_flash_message "Bloco cadastrado com sucesso."
    within("tbody tr", text: "Bloco R") { assert_text "Guarapuava" }

    within("tbody tr", text: "Bloco R") { click_on "Editar" }
    select "Pato Branco", from: "Campus"
    fill_in "Nome", with: "Bloco S"
    click_on "Salvar"

    assert_flash_message "Bloco atualizado com sucesso."
    within("tbody tr", text: "Bloco S") { assert_text "Pato Branco" }

    accept_confirm "Excluir o bloco Bloco S do campus Pato Branco?" do
      within("tbody tr", text: "Bloco S") { click_on "Excluir" }
    end

    assert_flash_message "Bloco excluído com sucesso."
    assert_text "Nenhum bloco cadastrado."
  end

  test "keeps the building when the deletion is not confirmed" do
    create(:building, campus: @guarapuava, name: "Bloco R")
    visit admin_buildings_path

    dismiss_confirm "Excluir o bloco Bloco R do campus Guarapuava?" do
      click_on "Excluir"
    end

    visit admin_buildings_path
    assert_selector "tbody tr", text: "Bloco R"
  end

  test "shows the error when no campus is chosen" do
    visit new_admin_building_path

    fill_in "Nome", with: "Bloco R"
    click_on "Salvar"

    assert_text "Selecione o campus."
    assert_select "Campus", selected: "Selecione o campus"
    assert_field "Nome", with: "Bloco R"
  end

  test "shows the error when the name is already taken in the campus" do
    create(:building, campus: @guarapuava, name: "Bloco R")
    visit new_admin_building_path

    select "Guarapuava", from: "Campus"
    fill_in "Nome", with: "bloco r"
    click_on "Salvar"

    assert_text "Já existe um bloco com este nome neste campus."
    assert_select "Campus", selected: "Guarapuava"
    assert_field "Nome", with: "bloco r"
  end
end
