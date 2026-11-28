require "application_system_test_case"

class ManageBuildingsTest < ApplicationSystemTestCase
  setup do
    sign_in_as create(:user, :admin)
    @guarapuava = create(:campus, name: "Guarapuava")
  end

  test "admin creates, edits and deletes a building of the campus" do
    visit admin_campus_path(@guarapuava)
    within("#buildings_summary") { click_on "Ver todos" }

    click_on "Novo bloco"
    assert_no_field "Campus"
    fill_in "Nome", with: "Bloco R"
    click_on "Salvar"

    assert_flash_message "Bloco cadastrado com sucesso."
    assert_current_path admin_campus_buildings_path(@guarapuava)
    assert_selector "tbody tr", text: "Bloco R"
    assert_no_selector "thead th", text: "Campus"

    within("tbody tr", text: "Bloco R") { click_on "Editar" }
    fill_in "Nome", with: "Bloco S"
    click_on "Salvar"

    assert_flash_message "Bloco atualizado com sucesso."
    assert_selector "tbody tr", text: "Bloco S"

    accept_confirm "Excluir o bloco Bloco S?" do
      within("tbody tr", text: "Bloco S") { click_on "Excluir" }
    end

    assert_flash_message "Bloco excluído com sucesso."
    assert_text "Nenhum bloco cadastrado neste campus."
  end

  test "lists only the buildings of the campus" do
    create(:building, campus: @guarapuava, name: "Bloco R")
    create(:building, campus: create(:campus, name: "Pato Branco"), name: "Bloco V")
    visit admin_campus_buildings_path(@guarapuava)

    assert_selector "tbody tr", text: "Bloco R"
    assert_no_text "Bloco V"
  end

  test "admin registers a building from the campus summary" do
    visit admin_campus_path(@guarapuava)

    within("#buildings_summary") { click_on "Cadastrar" }
    fill_in "Nome", with: "Bloco R"
    click_on "Salvar"

    assert_flash_message "Bloco cadastrado com sucesso."
    assert_selector "tbody tr", text: "Bloco R"
  end

  test "keeps the building when the deletion is not confirmed" do
    create(:building, campus: @guarapuava, name: "Bloco R")
    visit admin_campus_buildings_path(@guarapuava)

    dismiss_confirm "Excluir o bloco Bloco R?" do
      click_on "Excluir"
    end

    visit admin_campus_buildings_path(@guarapuava)
    assert_selector "tbody tr", text: "Bloco R"
  end

  test "shows the error when the name is blank" do
    visit new_admin_campus_building_path(@guarapuava)

    click_on "Salvar"

    assert_text "Informe o nome do bloco."
  end

  test "shows the error when the name is already taken in the campus" do
    create(:building, campus: @guarapuava, name: "Bloco R")
    visit new_admin_campus_building_path(@guarapuava)

    fill_in "Nome", with: "bloco r"
    click_on "Salvar"

    assert_text "Já existe um bloco com este nome neste campus."
    assert_field "Nome", with: "bloco r"
  end

  test "explains why a building with spaces cannot be deleted" do
    bloco_b = create(:building, campus: @guarapuava, name: "Bloco B")
    create(:space, campus: @guarapuava, building: bloco_b, name: "Sala 1")
    visit admin_campus_buildings_path(@guarapuava)

    accept_confirm "Excluir o bloco Bloco B?" do
      within("tbody tr", text: "Bloco B") { click_on "Excluir" }
    end

    assert_flash_message "Não é possível excluir o bloco porque ele tem espaços cadastrados. " \
                         "Mova os espaços para outro bloco ou exclua-os antes."
    assert_selector "tbody tr", text: "Bloco B"
  end
end
