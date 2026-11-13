require "application_system_test_case"

class ManageSpacesTest < ApplicationSystemTestCase
  setup do
    sign_in_as create(:user, :admin)
    @guarapuava = create(:campus, name: "Guarapuava")
    @pato_branco = create(:campus, name: "Pato Branco")
    @bloco_b = create(:building, campus: @guarapuava, name: "Bloco B")
    create(:building, campus: @guarapuava, name: "Bloco C")
    create(:building, campus: @pato_branco, name: "Bloco V")
    create(:department, name: "Biblioteca")
    create(:usage_term, title: "Termo do laboratório")
  end

  test "admin registers a space, checks it, edits it and deletes it" do
    visit admin_root_path
    click_on "Espaços"

    click_on "Novo espaço"
    select "Guarapuava", from: "Campus"
    select "Bloco B", from: "Bloco"
    fill_in "Nome", with: "Laboratório B3"
    fill_in "Descrição", with: "20 computadores."
    select "Biblioteca", from: "Departamento responsável"
    check "A reserva precisa de aprovação"
    select "Termo do laboratório", from: "Termo de uso"
    click_on "Salvar"

    assert_flash_message "Espaço cadastrado com sucesso."
    within("tbody tr", text: "Laboratório B3") do
      assert_text "Guarapuava · Bloco B"
      assert_text "Biblioteca"
      assert_text "Precisa de aprovação"
      click_on "Laboratório B3"
    end

    assert_selector "h1", text: "Laboratório B3"
    assert_text "Sim. As reservas são liberadas pelos usuários do departamento Biblioteca."
    assert_link "Termo do laboratório"
    assert_text "20 computadores."

    click_on "Editar"
    fill_in "Nome", with: "Laboratório B4"
    select "Sem departamento", from: "Departamento responsável"
    click_on "Salvar"

    assert_flash_message "Espaço atualizado com sucesso."
    within("tbody tr", text: "Laboratório B4") { assert_text "Sem departamento" }

    accept_confirm(/Excluir o espaço Laboratório B4\?/) do
      within("tbody tr", text: "Laboratório B4") { click_on "Excluir" }
    end

    assert_flash_message "Espaço excluído com sucesso."
    assert_text "Nenhum espaço cadastrado."
  end

  test "offers only the buildings of the chosen campus" do
    visit new_admin_space_path

    assert_equal [ "Sem bloco", "Bloco B", "Bloco C", "Bloco V" ], building_options

    select "Guarapuava", from: "Campus"
    assert_equal [ "Sem bloco", "Bloco B", "Bloco C" ], building_options

    select "Bloco C", from: "Bloco"
    select "Pato Branco", from: "Campus"
    assert_equal [ "Sem bloco", "Bloco V" ], building_options
    assert_select "Bloco", selected: "Sem bloco"

    select "Selecione o campus", from: "Campus"
    assert_equal [ "Sem bloco", "Bloco B", "Bloco C", "Bloco V" ], building_options
  end

  test "keeps the chosen building when the form comes back with an error and when a space is edited" do
    visit new_admin_space_path
    select "Guarapuava", from: "Campus"
    select "Bloco C", from: "Bloco"
    click_on "Salvar"

    assert_text "Informe o nome do espaço."
    assert_select "Campus", selected: "Guarapuava"
    assert_select "Bloco", selected: "Bloco C"
    assert_equal [ "Sem bloco", "Bloco B", "Bloco C" ], building_options

    space = create(:space, campus: @guarapuava, building: @bloco_b, name: "Sala 1")
    visit edit_admin_space_path(space)

    assert_select "Bloco", selected: "Bloco B"
    assert_equal [ "Sem bloco", "Bloco B", "Bloco C" ], building_options
  end

  test "offers every building again after coming back to the form with the browser" do
    visit new_admin_space_path
    select "Guarapuava", from: "Campus"
    assert_equal [ "Sem bloco", "Bloco B", "Bloco C" ], building_options

    click_on "Cancelar"
    assert_selector "h1", text: "Espaços"
    page.go_back

    assert_selector "h1", text: "Novo espaço"
    select "Pato Branco", from: "Campus"
    assert_equal [ "Sem bloco", "Bloco V" ], building_options
  end

  test "admin registers a space without building" do
    visit new_admin_space_path
    select "Guarapuava", from: "Campus"
    fill_in "Nome", with: "Quadra poliesportiva"
    click_on "Salvar"

    assert_flash_message "Espaço cadastrado com sucesso."
    within("tbody tr", text: "Quadra poliesportiva") do
      assert_text "Guarapuava · Sem bloco"
      assert_text "Não precisa de aprovação"
    end
  end

  test "admin marks a space as unavailable, changes the reason and makes it available again" do
    space = create(:space, campus: @guarapuava, building: @bloco_b, name: "Sala 1")
    visit admin_space_path(space)

    click_on "Marcar como indisponível"
    click_on "Salvar"
    assert_text "Informe o motivo da indisponibilidade."
    fill_in "Motivo", with: "Sala em reforma"
    click_on "Salvar"

    assert_flash_message "Espaço marcado como indisponível."
    within("#space_status") do
      assert_text "Indisponível"
      assert_text "Motivo: Sala em reforma"
      click_on "Alterar motivo"
    end
    assert_field "Motivo", with: "Sala em reforma"
    fill_in "Motivo", with: "Sala em reforma até março"
    click_on "Salvar"

    assert_flash_message "Motivo da indisponibilidade alterado."
    within("#space_status") { assert_text "Motivo: Sala em reforma até março" }
    visit admin_spaces_path
    within("tbody tr", text: "Sala 1") { assert_text "Indisponível" }

    visit admin_space_path(space)
    click_on "Tornar disponível"

    assert_flash_message "Espaço disponível de novo."
    within("#space_status") do
      assert_text "Disponível"
      assert_no_text "Sala em reforma"
    end
  end

  test "admin cancels marking a space as unavailable" do
    space = create(:space, campus: @guarapuava, name: "Sala 1")
    visit admin_space_path(space)

    click_on "Marcar como indisponível"
    fill_in "Motivo", with: "Sala em reforma"
    click_on "Cancelar"

    assert_current_path admin_space_path(space)
    within("#space_status") { assert_text "Disponível" }
  end

  test "admin deactivates a space after confirming and reactivates it" do
    space = create(:space, campus: @guarapuava, building: @bloco_b, name: "Sala 1")
    visit admin_space_path(space)

    accept_confirm(/Desativar o espaço Sala 1\? Ele deixará de aparecer na reserva/) do
      click_on "Desativar"
    end

    assert_flash_message "Espaço desativado. Ele deixa de aparecer na reserva."
    within("#space_status") { assert_text "Desativado" }
    assert_button "Reativar"
    assert_no_button "Desativar"
    assert_no_link "Marcar como indisponível"

    visit admin_spaces_path
    within("tbody tr", text: "Sala 1") { assert_text "Desativado" }

    visit admin_space_path(space)
    click_on "Reativar"

    assert_flash_message "Espaço reativado. Ele volta a aparecer na reserva e pode ser reservado."
    within("#space_status") { assert_text "Disponível" }
    assert_button "Desativar"
  end

  test "keeps the status when the deactivation is not confirmed" do
    space = create(:space, :unavailable, campus: @guarapuava, name: "Sala 1")
    visit admin_space_path(space)

    dismiss_confirm(/Para impedir as reservas só por um tempo/) do
      click_on "Desativar"
    end

    within("#space_status") { assert_text "Indisponível" }
    assert space.reload.unavailable?
  end

  test "keeps the space when the deletion is not confirmed" do
    space = create(:space, campus: @guarapuava, name: "Sala 1")
    visit admin_space_path(space)

    dismiss_confirm(/A exclusão não pode ser desfeita/) do
      click_on "Excluir"
    end

    visit admin_spaces_path
    assert_selector "tbody tr", text: "Sala 1"
  end

  test "admin fills in the form using only the keyboard" do
    visit new_admin_space_path

    assert_equal "space_campus_id", page.evaluate_script("document.activeElement.id")
    send_keys "Guarapuava", :tab, "Bloco B", :tab, "Sala 7", :tab, "Térreo", :tab, "Biblioteca", :tab, :space, :tab, :tab, :tab, :enter

    assert_flash_message "Espaço cadastrado com sucesso."
    within("tbody tr", text: "Sala 7") do
      assert_text "Guarapuava · Bloco B"
      assert_text "Biblioteca"
      assert_text "Precisa de aprovação"
    end
  end

  test "explains why a building with spaces cannot be deleted" do
    create(:space, campus: @guarapuava, building: @bloco_b, name: "Sala 1")
    visit admin_buildings_path

    accept_confirm "Excluir o bloco Bloco B do campus Guarapuava?" do
      within("tbody tr", text: "Bloco B") { click_on "Excluir" }
    end

    assert_flash_message "Não é possível excluir o bloco porque ele tem espaços cadastrados. " \
                         "Mova os espaços para outro bloco ou exclua-os antes."
    assert_selector "tbody tr", text: "Bloco B"
  end

  test "moves the spaces of a building along when its campus changes" do
    create(:space, campus: @guarapuava, building: @bloco_b, name: "Sala 1")
    visit admin_buildings_path
    within("tbody tr", text: "Bloco B") { click_on "Editar" }

    assert_text "Este bloco tem 1 espaço. Ao trocar o campus, ele passa para o novo campus."
    select "Pato Branco", from: "Campus"
    click_on "Salvar"

    assert_flash_message "Bloco atualizado com sucesso. 1 espaço passou para o campus Pato Branco."
    visit admin_spaces_path
    within("tbody tr", text: "Sala 1") { assert_text "Pato Branco · Bloco B" }
  end

  private

    def building_options
      find_field("Bloco").all("option").map(&:text)
    end
end
