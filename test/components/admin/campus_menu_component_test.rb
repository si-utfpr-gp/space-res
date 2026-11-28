require "test_helper"

class Admin::CampusMenuComponentTest < ViewComponent::TestCase
  include Rails.application.routes.url_helpers

  setup do
    @guarapuava = create(:campus, name: "Guarapuava")
    @pato_branco = create(:campus, name: "Pato Branco")
  end

  test "links back to the administrative area" do
    render_menu(section: :overview)

    assert_selector "nav[aria-label='Menu do campus'] a[href='#{admin_root_path}']", text: "Área administrativa"
  end

  test "links to the sections of the campus" do
    render_menu(section: :overview)

    assert_selector "a[href='#{admin_campus_path(@guarapuava)}']", text: "Visão geral"
    assert_selector "a[href='#{admin_campus_spaces_path(@guarapuava)}']", text: "Espaços"
    assert_selector "a[href='#{admin_campus_buildings_path(@guarapuava)}']", text: "Blocos"
  end

  test "marks the current section" do
    render_menu(section: :spaces)

    assert_selector "a.active[aria-current='page']", count: 1, text: "Espaços"
  end

  test "lists the campi in the selector, marking the current one" do
    render_menu(section: :overview)

    assert_selector "details#campus_selector summary", text: /Guarapuava\s+Trocar de campus/
    # The closed <details> hides the list until the summary is pressed.
    assert_selector "details#campus_selector li", count: 2, visible: :all
    assert_selector "details#campus_selector a[aria-current='true']", count: 1, text: "Guarapuava", visible: :all
  end

  test "opens another campus on the same section" do
    render_menu(section: :spaces)

    assert_selector "details#campus_selector a[href='#{admin_campus_spaces_path(@pato_branco)}']", text: "Pato Branco", visible: :all
  end

  test "opens another campus on the overview from the overview" do
    render_menu(section: :overview)

    assert_selector "details#campus_selector a[href='#{admin_campus_path(@pato_branco)}']", text: "Pato Branco", visible: :all
  end

  test "shows only the name of the campus when it is the only one" do
    @pato_branco.destroy!

    render_menu(section: :buildings)

    assert_no_selector "details"
    assert_selector "p", text: "Guarapuava"
  end

  test "links to the dashboard and the reservations" do
    render_menu(section: :overview)

    assert_selector "a[href='#{users_root_path}']", text: "Dashboard"
    assert_selector "a[href='#{users_reservations_path}']", text: "Minhas reservas"
  end

  test "refuses an unknown section" do
    assert_raises(ArgumentError) { render_menu(section: :rooms) }
  end

  private

    def render_menu(section:)
      render_inline(Admin::CampusMenuComponent.new(campus: @guarapuava, campi: Campus.ordered_by_name, section: section))
    end
end
