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
    visit admin_campus_path(@guarapuava)
    within("#spaces_summary") { click_on "Cadastrar" }

    assert_selector "#space_campus", text: "Campus Guarapuava"
    select "Bloco B", from: "Bloco"
    fill_in "Nome", with: "Laboratório B3"
    fill_in "Descrição", with: "20 computadores."
    select "Biblioteca", from: "Departamento responsável"
    check "A reserva precisa de aprovação"
    select "Termo do laboratório", from: "Termo de uso"
    click_on "Salvar"

    assert_flash_message "Espaço cadastrado com sucesso."
    assert_current_path admin_campus_spaces_path(@guarapuava)
    within("tbody tr", text: "Laboratório B3") do
      assert_text "Bloco B"
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
    assert_text "Nenhum espaço cadastrado neste campus."
  end

  test "the form shows the campus and offers only its buildings" do
    visit new_admin_campus_space_path(@guarapuava)

    assert_selector "#space_campus", text: "Campus Guarapuava"
    assert_no_field "Campus"
    assert_equal [ "Sem bloco", "Bloco B", "Bloco C" ], building_options

    visit new_admin_campus_space_path(@pato_branco)

    assert_selector "#space_campus", text: "Campus Pato Branco"
    assert_equal [ "Sem bloco", "Bloco V" ], building_options
  end

  test "offers only the option without building for a campus without buildings" do
    apucarana = create(:campus, name: "Apucarana")
    visit new_admin_campus_space_path(apucarana)

    assert_equal [ "Sem bloco" ], building_options
  end

  test "keeps the chosen building when the form comes back with an error and when a space is edited" do
    visit new_admin_campus_space_path(@guarapuava)
    select "Bloco C", from: "Bloco"
    click_on "Salvar"

    assert_text "Informe o nome do espaço."
    assert_select "Bloco", selected: "Bloco C"
    assert_equal [ "Sem bloco", "Bloco B", "Bloco C" ], building_options

    space = create(:space, campus: @guarapuava, building: @bloco_b, name: "Sala 1")
    visit edit_admin_campus_space_path(@guarapuava, space)

    assert_select "Bloco", selected: "Bloco B"
    assert_equal [ "Sem bloco", "Bloco B", "Bloco C" ], building_options
  end

  test "admin registers a space without building" do
    visit new_admin_campus_space_path(@guarapuava)
    fill_in "Nome", with: "Quadra poliesportiva"
    fill_in "Descrição", with: "Quadra coberta, ao lado do estacionamento."
    click_on "Salvar"

    assert_flash_message "Espaço cadastrado com sucesso."
    within("tbody tr", text: "Quadra poliesportiva") do
      assert_text "Sem bloco"
      assert_text "Não precisa de aprovação"
    end
  end

  test "cancelling the form goes back to the spaces of the campus" do
    visit new_admin_campus_space_path(@guarapuava)

    click_on "Cancelar"

    assert_current_path admin_campus_spaces_path(@guarapuava)
    assert_selector "h1", text: "Espaços"
  end

  test "admin marks a space as unavailable, changes the reason and makes it available again" do
    space = create(:space, campus: @guarapuava, building: @bloco_b, name: "Sala 1")
    visit admin_campus_space_path(@guarapuava, space)

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

    visit admin_campus_path(@guarapuava)
    within("#unavailable_spaces") do
      assert_text "Sala 1"
      assert_text "Motivo: Sala em reforma até março"
    end
    visit admin_campus_spaces_path(@guarapuava)
    within("tbody tr", text: "Sala 1") { assert_text "Indisponível" }

    visit admin_campus_space_path(@guarapuava, space)
    click_on "Tornar disponível"

    assert_flash_message "Espaço disponível de novo."
    within("#space_status") do
      assert_text "Disponível"
      assert_no_text "Sala em reforma"
    end
  end

  test "admin reaches an unavailable space from the campus page" do
    space = create(:space, :unavailable, campus: @guarapuava, name: "Sala 1")
    visit admin_campus_path(@guarapuava)

    within("#unavailable_spaces") { click_on "Ver espaço" }

    assert_current_path admin_campus_space_path(@guarapuava, space)
    assert_selector "h1", text: "Sala 1"
  end

  test "admin cancels marking a space as unavailable" do
    space = create(:space, campus: @guarapuava, name: "Sala 1")
    visit admin_campus_space_path(@guarapuava, space)

    click_on "Marcar como indisponível"
    fill_in "Motivo", with: "Sala em reforma"
    click_on "Cancelar"

    assert_current_path admin_campus_space_path(@guarapuava, space)
    within("#space_status") { assert_text "Disponível" }
  end

  test "admin deactivates a space after confirming and reactivates it" do
    space = create(:space, campus: @guarapuava, building: @bloco_b, name: "Sala 1")
    visit admin_campus_space_path(@guarapuava, space)

    accept_confirm(/Desativar o espaço Sala 1\? Ele deixará de aparecer na reserva/) do
      click_on "Desativar"
    end

    assert_flash_message "Espaço desativado. Ele deixa de aparecer na reserva."
    within("#space_status") { assert_text "Desativado" }
    assert_button "Reativar"
    assert_no_button "Desativar"
    assert_no_link "Marcar como indisponível"

    visit admin_campus_spaces_path(@guarapuava)
    within("tbody tr", text: "Sala 1") { assert_text "Desativado" }

    visit admin_campus_space_path(@guarapuava, space)
    click_on "Reativar"

    assert_flash_message "Espaço reativado. Ele volta a aparecer na reserva e pode ser reservado."
    within("#space_status") { assert_text "Disponível" }
    assert_button "Desativar"
  end

  test "keeps the status when the deactivation is not confirmed" do
    space = create(:space, :unavailable, campus: @guarapuava, name: "Sala 1")
    visit admin_campus_space_path(@guarapuava, space)

    dismiss_confirm(/Para impedir as reservas só por um tempo/) do
      click_on "Desativar"
    end

    within("#space_status") { assert_text "Indisponível" }
    assert space.reload.unavailable?
  end

  test "keeps the space when the deletion is not confirmed" do
    space = create(:space, campus: @guarapuava, name: "Sala 1")
    visit admin_campus_space_path(@guarapuava, space)

    dismiss_confirm(/A exclusão não pode ser desfeita/) do
      click_on "Excluir"
    end

    visit admin_campus_spaces_path(@guarapuava)
    assert_selector "tbody tr", text: "Sala 1"
  end

  test "admin fills in the form using only the keyboard" do
    visit new_admin_campus_space_path(@guarapuava)

    assert_equal "space_building_id", page.evaluate_script("document.activeElement.id")
    send_keys "Bloco B", :tab, "Sala 7", :tab, "Térreo", :tab, "Biblioteca", :tab, :space, :tab, :tab, :tab, :enter

    assert_flash_message "Espaço cadastrado com sucesso."
    within("tbody tr", text: "Sala 7") do
      assert_text "Bloco B"
      assert_text "Biblioteca"
      assert_text "Precisa de aprovação"
    end
  end

  private

    def building_options
      find_field("Bloco").all("option").map(&:text)
    end
end
