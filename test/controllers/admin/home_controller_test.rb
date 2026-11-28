require "test_helper"
require "support/helpers/breadcrumb_assertions"

class Admin::HomeControllerTest < ActionDispatch::IntegrationTest
  include BreadcrumbAssertions

  setup do
    sign_in create(:user, :admin)
  end

  test "shows the title, subtitle and breadcrumbs" do
    get admin_root_path

    assert_select "main h1", count: 1, text: "Área administrativa"
    assert_select "header p", text: "Escolha o campus que você quer gerenciar."
    assert_breadcrumbs({ "Dashboard" => users_root_path }, current: "Área administrativa")
    assert_no_match(/translation missing/i, response.body)
  end

  test "shows a card for each campus in alphabetical order" do
    create(:campus, name: "Pato Branco")
    create(:campus, name: "Guarapuava")

    get admin_root_path

    assert_equal [ "Guarapuava", "Pato Branco" ], css_select("article h3").map { |title| title.text.strip }
  end

  test "summarizes the spaces and buildings of each campus" do
    campus = create(:campus, name: "Guarapuava")
    create_list(:building, 3, campus: campus)
    create_list(:space, 5, campus: campus)
    create(:space, :unavailable, campus: campus)
    create(:space, :deactivated, campus: campus)

    get admin_root_path

    assert_select "##{dom_id(campus)}" do
      assert_select "dl div", text: /Espaços\s+7/
      assert_select "dl div", text: /Blocos\s+3/
      assert_select "p", text: "1 espaço indisponível"
      assert_select "a[href='#{admin_campus_path(campus)}']", text: "Gerenciar Guarapuava"
    end
  end

  test "counts the unavailable spaces in the plural" do
    campus = create(:campus)
    create_list(:space, 2, :unavailable, campus: campus)

    get admin_root_path

    assert_select "##{dom_id(campus)} p", text: "2 espaços indisponíveis"
  end

  test "shows no unavailable notice for a campus without registrations" do
    campus = create(:campus, name: "Pato Branco")

    get admin_root_path

    assert_select "##{dom_id(campus)}" do
      assert_select "dl div", text: /Espaços\s+0/
      assert_select "dl div", text: /Blocos\s+0/
      assert_select "p", text: /indispon/, count: 0
    end
  end

  test "links to the new campus form" do
    get admin_root_path

    assert_select "main a[href='#{new_admin_campus_path}']", text: "Cadastrar campus"
  end

  test "tells when there are no campi" do
    get admin_root_path

    assert_select "#campi_title + a, section p", text: "Nenhum campus cadastrado."
    assert_select "article", count: 0
    assert_select "main a[href='#{new_admin_campus_path}']", text: "Cadastrar campus"
  end

  test "links to the general registrations" do
    get admin_root_path

    assert_select "h2", text: "Cadastros gerais"
    assert_select "section p", text: "Valem para todos os campi. Só o administrador geral vê esta seção."
    assert_select "main a[href='#{admin_users_path}']", text: /Usuários/
    assert_select "main a[href='#{admin_departments_path}']", text: /Departamentos/
    assert_select "main a[href='#{admin_usage_terms_path}']", text: /Termos de uso/
  end

  test "keeps the main menu in the sidebar" do
    get admin_root_path

    assert_select "aside nav[aria-label='Menu do campus']", count: 0
    assert_select "aside a[href='#{admin_root_path}']", text: /Área administrativa/
  end
end
