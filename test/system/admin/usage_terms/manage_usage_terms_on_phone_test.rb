require "application_system_test_case"

class ManageUsageTermsOnPhoneTest < ApplicationSystemTestCase
  LONG_TITLE = "Termo de uso e responsabilidade do Laboratório de Informática e Desenvolvimento de Software".freeze
  LONG_ADDRESS = "https://www.utfpr.edu.br/campus/guarapuava/documentos/regulamento-de-uso-dos-laboratorios-de-informatica".freeze
  MIN_TOUCH_TARGET = 44

  setup do
    sign_in_as create(:user, :admin)
    page.current_window.resize_to(320, 640)
  end

  teardown do
    page.current_window.resize_to(1400, 1400)
  end

  # 320 CSS px is the width WCAG 1.4.10 (Reflow) requires to work without horizontal scrolling.
  test "fits a long title in the list on a 320px wide screen" do
    create(:usage_term, title: LONG_TITLE)
    visit admin_usage_terms_path

    within("tbody tr", text: LONG_TITLE) do
      [ find_link("Ver"), find_link("Editar"), find_button("Excluir") ].each do |action|
        assert_operator action.rect.width, :>=, MIN_TOUCH_TARGET
        assert_operator action.rect.height, :>=, MIN_TOUCH_TARGET
      end
    end
    assert_operator page.evaluate_script("document.querySelector('table').getBoundingClientRect().right"),
                    :<=, page.evaluate_script("window.innerWidth")
    assert_no_horizontal_scroll
  end

  test "fits a long title and a long address on the term page on a 320px wide screen" do
    usage_term = create(:usage_term, title: LONG_TITLE, content: "Leia o regulamento em #{LONG_ADDRESS} antes de reservar.")
    visit admin_usage_term_path(usage_term)

    assert_selector "h1", text: LONG_TITLE
    assert_text LONG_ADDRESS
    assert_no_horizontal_scroll
  end

  test "admin creates a usage term on a phone" do
    visit admin_usage_terms_path
    click_on "Novo termo"
    fill_in "Título", with: "Termo da quadra"
    fill_in_rich_textarea "Texto", with: "Use calçado adequado."
    assert_no_horizontal_scroll
    click_on "Salvar"

    assert_flash_message "Termo de uso cadastrado com sucesso."
    assert_selector "h1", text: "Termo da quadra"
    assert_no_horizontal_scroll
  end

  private

    def assert_no_horizontal_scroll
      assert_operator page.evaluate_script("document.documentElement.scrollWidth"),
                      :<=, page.evaluate_script("window.innerWidth")
    end
end
