require "application_system_test_case"

class ManageSpacesOnPhoneTest < ApplicationSystemTestCase
  LONG_NAME = "Laboratório de Informática e Desenvolvimento de Software para Dispositivos Móveis".freeze
  LONG_DEPARTMENT = "Núcleo de Acompanhamento Psicopedagógico e Assistência Estudantil".freeze
  MIN_TOUCH_TARGET = 44

  setup do
    sign_in_as create(:user, :admin)
    @campus = create(:campus, name: "Guarapuava")
    @building = create(:building, campus: @campus, name: "Bloco B")
    @department = create(:department, name: LONG_DEPARTMENT)
    page.current_window.resize_to(320, 640)
  end

  teardown do
    page.current_window.resize_to(1400, 1400)
  end

  # 320 CSS px is the width WCAG 1.4.10 (Reflow) requires to work without horizontal scrolling.
  test "fits a long name in the list on a 320px wide screen, with the building, department and approval" do
    create(:space, :requiring_approval, :unavailable, campus: @campus, building: @building, department: @department, name: LONG_NAME)
    visit admin_campus_spaces_path(@campus)

    within("tbody tr", text: LONG_NAME) do
      assert_text "Bloco B"
      assert_text LONG_DEPARTMENT
      assert_text "Precisa de aprovação"
      assert_text "Indisponível"
      [ find_link("Ver"), find_link("Editar"), find_button("Excluir") ].each do |action|
        assert_operator action.rect.width, :>=, MIN_TOUCH_TARGET
        assert_operator action.rect.height, :>=, MIN_TOUCH_TARGET
      end
    end
    assert_operator page.evaluate_script("document.querySelector('table').getBoundingClientRect().right"),
                    :<=, page.evaluate_script("window.innerWidth")
    assert_no_horizontal_scroll
  end

  test "fits the filters on a 320px wide screen with comfortable fields" do
    create(:space, campus: @campus, name: "Sala 1")
    visit admin_campus_spaces_path(@campus)

    [ find_field("Bloco"), find_field("Situação") ].each do |field|
      assert_operator field.rect.height, :>=, MIN_TOUCH_TARGET
    end
    assert_no_horizontal_scroll
  end

  test "fits the space page on a 320px wide screen" do
    space = create(:space, :requiring_approval, campus: @campus, building: @building, department: @department, name: LONG_NAME,
                   description: "Reservas pelo endereço https://www.utfpr.edu.br/campus/guarapuava/laboratorios/informatica/reservas")
    visit admin_campus_space_path(@campus, space)

    assert_selector "h1", text: LONG_NAME
    assert_text LONG_DEPARTMENT
    [ find_link("Editar"), find_button("Desativar"), find_button("Excluir") ].each do |action|
      assert_operator action.rect.height, :>=, MIN_TOUCH_TARGET
    end
    assert_no_horizontal_scroll
  end

  test "admin marks a space as unavailable on a phone and finds the actions easy to tap" do
    space = create(:space, campus: @campus, building: @building, name: LONG_NAME)
    visit admin_campus_space_path(@campus, space)

    click_on "Marcar como indisponível"
    fill_in "Motivo", with: "Sala interditada pela Defesa Civil até a conclusão da reforma do telhado do Bloco B"
    assert_no_horizontal_scroll
    click_on "Salvar"

    assert_flash_message "Espaço marcado como indisponível."
    [ find_link("Alterar motivo"), find_button("Tornar disponível"), find_button("Desativar") ].each do |action|
      assert_operator action.rect.height, :>=, MIN_TOUCH_TARGET
    end
    assert_no_horizontal_scroll
  end

  test "admin registers a space on a phone, with a comfortable checkbox" do
    visit admin_campus_spaces_path(@campus)
    click_on "Novo espaço"
    assert_selector "#space_campus", text: "Campus Guarapuava"
    select "Bloco B", from: "Bloco"
    fill_in "Nome", with: "Sala 1"
    fill_in "Descrição", with: "Sala de aula com 40 carteiras."
    select LONG_DEPARTMENT, from: "Departamento responsável"
    assert_operator find("label", text: "A reserva precisa de aprovação").rect.height, :>=, MIN_TOUCH_TARGET
    find("label", text: "A reserva precisa de aprovação").click
    assert_no_horizontal_scroll
    click_on "Salvar"

    assert_flash_message "Espaço cadastrado com sucesso."
    within("tbody tr", text: "Sala 1") { assert_text "Precisa de aprovação" }
    assert_no_horizontal_scroll
  end

  test "admin opens the menu and goes from the spaces to the buildings of the campus" do
    visit admin_campus_spaces_path(@campus)

    click_on "Menu de navegação", enable_aria_label: true
    within("nav[aria-label='Menu do campus']") do
      assert_selector "a[aria-current='page']", text: "Espaços"
      click_on "Blocos"
    end

    assert_current_path admin_campus_buildings_path(@campus)
  end

  private

    def assert_no_horizontal_scroll
      assert_operator page.evaluate_script("document.documentElement.scrollWidth"),
                      :<=, page.evaluate_script("window.innerWidth")
    end
end
