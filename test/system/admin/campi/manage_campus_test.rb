require "application_system_test_case"

class ManageCampusTest < ApplicationSystemTestCase
  setup do
    sign_in_as create(:user, :admin)
  end

  test "admin creates a campus from the entry, edits it and deletes it" do
    visit admin_root_path

    click_on "Cadastrar campus"
    fill_in "Nome", with: "Pato Branco"
    click_on "Salvar"

    assert_flash_message "Campus cadastrado com sucesso."
    assert_current_path admin_root_path
    assert_selector "article[id^='campus_']", text: "Pato Branco"

    click_on "Gerenciar Pato Branco"
    assert_selector "h1", text: "Campus Pato Branco"

    click_on "Editar campus"
    fill_in "Nome", with: "Ponta Grossa"
    click_on "Salvar"

    assert_flash_message "Campus atualizado com sucesso."
    assert_selector "h1", text: "Campus Ponta Grossa"

    accept_confirm "Excluir o campus Ponta Grossa?" do
      click_on "Excluir campus"
    end

    assert_flash_message "Campus excluído com sucesso."
    assert_current_path admin_root_path
    assert_text "Nenhum campus cadastrado."
  end

  test "shows the counts of each campus on the entry and leads to the campus page" do
    campus = create(:campus, name: "Guarapuava")
    create(:building, campus:, name: "Bloco B")
    create(:space, :unavailable, campus:, name: "Sala 1")
    create(:campus, name: "Pato Branco")
    visit admin_root_path

    within("#campus_#{campus.id}") do
      assert_text "1 espaço indisponível"
      click_on "Gerenciar Guarapuava"
    end

    assert_current_path admin_campus_path(campus)
    assert_selector "h1", text: "Campus Guarapuava"
    within("#spaces_summary") { assert_link "Ver todos" }
    within("#buildings_summary") { assert_link "Cadastrar" }
    within("#unavailable_spaces") { assert_link "Ver espaço" }
  end

  test "keeps the campus when the deletion is not confirmed" do
    campus = create(:campus, name: "Guarapuava")
    visit admin_campus_path(campus)

    dismiss_confirm "Excluir o campus Guarapuava?" do
      click_on "Excluir campus"
    end

    assert_current_path admin_campus_path(campus)
    assert_selector "h1", text: "Campus Guarapuava"
    assert Campus.exists?(campus.id)
  end

  test "explains why a campus with buildings cannot be deleted and stays on the campus page" do
    campus = create(:campus, name: "Guarapuava")
    create(:building, campus:)
    visit admin_campus_path(campus)

    accept_confirm "Excluir o campus Guarapuava?" do
      click_on "Excluir campus"
    end

    assert_flash_message "Não é possível excluir o campus porque ele tem blocos cadastrados. Exclua-os antes."
    assert_current_path admin_campus_path(campus)
    assert_selector "h1", text: "Campus Guarapuava"
  end

  test "shows the error when the name is already taken" do
    create(:campus, name: "Campo Mourão")
    visit new_admin_campus_path

    fill_in "Nome", with: "campo mourao"
    click_on "Salvar"

    assert_text "Já existe um campus cadastrado com este nome."
    assert_field "Nome", with: "campo mourao"
  end

  test "campus selector opens the same section of another campus" do
    guarapuava = create(:campus, name: "Guarapuava")
    pato_branco = create(:campus, name: "Pato Branco")
    create(:space, campus: pato_branco, name: "Sala de Pato Branco")
    create(:building, campus: pato_branco, name: "Bloco V")

    visit admin_campus_spaces_path(guarapuava)
    switch_campus_to "Pato Branco"
    assert_current_path admin_campus_spaces_path(pato_branco)
    assert_text "Sala de Pato Branco"

    visit admin_campus_buildings_path(guarapuava)
    switch_campus_to "Pato Branco"
    assert_current_path admin_campus_buildings_path(pato_branco)
    assert_text "Bloco V"

    visit admin_campus_path(guarapuava)
    switch_campus_to "Pato Branco"
    assert_current_path admin_campus_path(pato_branco)
    assert_selector "h1", text: "Campus Pato Branco"
  end

  test "campus menu shows the sections, marks the current one and leads back to the entry" do
    campus = create(:campus, name: "Guarapuava")
    create(:campus, name: "Pato Branco")
    visit admin_campus_buildings_path(campus)

    within("nav[aria-label='Menu do campus']") do
      assert_selector "#campus_selector summary", text: /Guarapuava\s+Trocar de campus/
      assert_link "Visão geral"
      assert_link "Espaços"
      assert_selector "a[aria-current='page']", text: "Blocos"
      assert_link "Dashboard"
      assert_link "Minhas reservas"
      click_on "Área administrativa"
    end

    assert_current_path admin_root_path
    assert_selector "h1", text: "Área administrativa"
  end

  test "campus menu shows only the name when there is a single campus" do
    campus = create(:campus, name: "Guarapuava")
    visit admin_campus_path(campus)

    within("nav[aria-label='Menu do campus']") do
      assert_text "Guarapuava"
      assert_no_selector "#campus_selector"
    end
  end

  private

    def switch_campus_to(name)
      find("#campus_selector summary").click
      within("#campus_selector") { click_on name }
    end
end
