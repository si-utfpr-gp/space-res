require "application_system_test_case"

class ManageCampusOnPhoneTest < ApplicationSystemTestCase
  MIN_TOUCH_TARGET = 44

  setup do
    sign_in_as create(:user, :admin)
    page.current_window.resize_to(320, 640)
  end

  teardown do
    page.current_window.resize_to(1400, 1400)
  end

  # 320 CSS px is the width WCAG 1.4.10 (Reflow) requires to work without horizontal scrolling.
  test "fits the entry with a long campus name on a 320px wide screen" do
    create(:space, :unavailable, campus: create(:campus, name: "Campus Avançado de Campo Mourão do Paraná"))
    visit admin_root_path

    within("article[id^='campus_']") do
      assert_text "1 espaço indisponível"
      assert_operator find_link("Gerenciar Campus Avançado de Campo Mourão do Paraná").rect.height, :>=, MIN_TOUCH_TARGET
    end
    assert_no_horizontal_scroll
  end

  test "fits the campus page on a 320px wide screen with comfortable buttons" do
    campus = create(:campus, name: "Campo Mourão")
    create(:space, :unavailable, campus:, name: "Sala 1")
    visit admin_campus_path(campus)

    assert_selector "h1", text: "Campus Campo Mourão"
    [ find_link("Editar campus"), find_button("Excluir campus") ].each do |action|
      assert_operator action.rect.height, :>=, MIN_TOUCH_TARGET
    end
    assert_selector "#unavailable_spaces"
    assert_no_horizontal_scroll
  end

  test "admin creates a campus on a phone" do
    visit admin_root_path
    click_on "Cadastrar campus"
    fill_in "Nome", with: "Pato Branco"
    click_on "Salvar"

    assert_flash_message "Campus cadastrado com sucesso."
    assert_selector "article[id^='campus_']", text: "Pato Branco"
    assert_no_horizontal_scroll
  end

  test "admin opens the menu and switches campus with the selector" do
    guarapuava = create(:campus, name: "Guarapuava")
    pato_branco = create(:campus, name: "Pato Branco")
    visit admin_campus_spaces_path(guarapuava)

    click_on "Menu de navegação", enable_aria_label: true
    within("nav[aria-label='Menu do campus']") do
      summary = find("#campus_selector summary")
      assert_operator summary.rect.height, :>=, MIN_TOUCH_TARGET
      summary.click
      within("#campus_selector") { click_on "Pato Branco" }
    end

    assert_current_path admin_campus_spaces_path(pato_branco)
    assert_text "campus Pato Branco"
  end

  private

    def assert_no_horizontal_scroll
      assert_operator page.evaluate_script("document.documentElement.scrollWidth"),
                      :<=, page.evaluate_script("window.innerWidth")
    end
end
