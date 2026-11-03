require "application_system_test_case"

class ManageUsageTermsTest < ApplicationSystemTestCase
  setup do
    sign_in_as create(:user, :admin)
  end

  test "admin creates, edits and deletes a usage term from its page" do
    visit admin_root_path
    click_on "Termos de uso"

    click_on "Novo termo"
    fill_in "Título", with: "Termo da quadra"
    fill_in "Texto", with: "Use calçado adequado.\n\n1. Chegue no horário.\n2. Recolha o material.\n\nBom jogo."
    click_on "Salvar"

    assert_flash_message "Termo de uso cadastrado com sucesso."
    assert_selector "h1", text: "Termo da quadra"
    within("#usage_term_content") do
      assert_selector "p", count: 3
      assert_selector "p:nth-child(2) br", count: 1, visible: :all
    end

    click_on "Editar"
    fill_in "Texto", with: "Use calçado adequado."
    click_on "Salvar"

    assert_flash_message "Termo de uso atualizado com sucesso."
    assert_selector "h1", text: "Termo da quadra"
    assert_selector "#usage_term_content p", count: 1, text: "Use calçado adequado."

    accept_confirm "Excluir o termo Termo da quadra?" do
      click_on "Excluir"
    end

    assert_flash_message "Termo de uso excluído com sucesso."
    assert_text "Nenhum termo de uso cadastrado."
  end

  test "admin opens and deletes a usage term from the list" do
    create(:usage_term, title: "Termo do planetário")
    visit admin_usage_terms_path

    click_on "Termo do planetário"
    assert_selector "h1", text: "Termo do planetário"

    click_on "Termos de uso"
    accept_confirm "Excluir o termo Termo do planetário?" do
      within("tbody tr", text: "Termo do planetário") { click_on "Excluir" }
    end

    assert_flash_message "Termo de uso excluído com sucesso."
    assert_text "Nenhum termo de uso cadastrado."
  end

  test "keeps the usage term when the deletion is not confirmed" do
    usage_term = create(:usage_term, title: "Termo da quadra")
    visit admin_usage_term_path(usage_term)

    dismiss_confirm "Excluir o termo Termo da quadra?" do
      click_on "Excluir"
    end

    visit admin_usage_terms_path
    assert_selector "tbody tr", text: "Termo da quadra"
  end

  test "shows the error when the title is already taken" do
    create(:usage_term, title: "Termo do Laboratório")
    visit new_admin_usage_term_path

    fill_in "Título", with: "termo do laboratorio"
    fill_in "Texto", with: "Regras."
    click_on "Salvar"

    assert_text "Já existe um termo cadastrado com este título."
    assert_field "Título", with: "termo do laboratorio"
    assert_field "Texto", with: "Regras."
  end
end
