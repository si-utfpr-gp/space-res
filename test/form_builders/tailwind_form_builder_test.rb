require "test_helper"

class TailwindFormBuilderTest < ActionView::TestCase
  setup do
    @guarapuava = create(:campus, name: "Guarapuava")
    @pato_branco = create(:campus, name: "Pato Branco")
  end

  test "renders a labeled select with the prompt and the choices in order" do
    render_campus_select(Building.new)

    assert_select "label[for='building_campus_id']", text: "Campus"
    assert_select "select#building_campus_id[name='building[campus_id]']" do
      assert_select "option", count: 3
      assert_select "option:nth-child(1)[value='']", text: "Selecione o campus"
      assert_select "option:nth-child(2)[value='#{@guarapuava.id}']", text: "Guarapuava"
      assert_select "option:nth-child(3)[value='#{@pato_branco.id}']", text: "Pato Branco"
    end
  end

  test "gives the select the input style and a 44px touch target" do
    render_campus_select(Building.new)

    assert_select "select.w-full.rounded-md.text-base.min-h-11"
  end

  test "selects the current value" do
    render_campus_select(Building.new(campus: @pato_branco))

    assert_select "option[selected][value='#{@pato_branco.id}']", text: "Pato Branco"
  end

  test "shows the error of the belongs_to association next to the select" do
    building = Building.new
    building.validate

    render_campus_select(building)

    assert_select "select.border-red-500"
    assert_select "select + p", text: "Selecione o campus."
  end

  test "takes Rails' select options and html options, plus a custom label" do
    @rendered = form_with(model: Building.new, url: "/admin/buildings") do |form|
      form.select :campus_id, [ [ "Guarapuava", @guarapuava.id ] ], { include_blank: true },
                  label: "Campus do bloco", data: { action: "change->campus#pick" }
    end

    assert_select "label[for='building_campus_id']", text: "Campus do bloco"
    assert_select "select[data-action='change->campus#pick']" do
      assert_select "option:nth-child(1)[value='']", text: ""
    end
  end

  test "renders a checkbox with a label that toggles it" do
    render_approval_checkbox(Space.new)

    assert_select "input[type='hidden'][name='space[requires_approval]'][value='0']"
    assert_select "input#space_requires_approval[type='checkbox'][name='space[requires_approval]'][value='1']"
    assert_select "input#space_requires_approval[checked]", count: 0
    assert_select "label[for='space_requires_approval']", text: "A reserva precisa de aprovação"
  end

  test "checks the checkbox when the attribute is true" do
    render_approval_checkbox(Space.new(requires_approval: true))

    assert_select "input#space_requires_approval[type='checkbox'][checked]"
  end

  test "gives the checkbox a 44px touch target and a visible focus" do
    render_approval_checkbox(Space.new)

    assert_select "label.min-h-11[for='space_requires_approval']"
    assert_select "input[type='checkbox'].focus\\:ring-2"
  end

  test "shows the hint and the errors of the checkbox" do
    space = Space.new
    space.errors.add(:requires_approval, "Escolha um departamento antes.")

    render_approval_checkbox(space, hint: "Quem libera as reservas.")

    assert_select ".space_requires_approval p.text-gray-500", text: "Quem libera as reservas."
    assert_select ".space_requires_approval p.text-red-600", text: "Escolha um departamento antes."
  end

  test "takes Rails' checkbox values and html options, plus a custom label, under both method names" do
    @rendered = form_with(model: Space.new, url: "/admin/spaces") do |form|
      form.check_box :requires_approval, { label: "Exige liberação", data: { action: "change->space#toggle" } }, "yes", "no"
    end

    assert_select "input[type='hidden'][value='no']"
    assert_select "input[type='checkbox'][value='yes'][data-action='change->space#toggle']"
    assert_select "label[for='space_requires_approval']", text: "Exige liberação"
  end

  private

    def render_campus_select(building)
      @rendered = form_with(model: building, url: "/admin/buildings") do |form|
        form.select :campus_id, Campus.order(:name).pluck(:name, :id), { prompt: "Selecione o campus" }
      end
    end

    def render_approval_checkbox(space, **options)
      @rendered = form_with(model: space, url: "/admin/spaces") do |form|
        form.checkbox :requires_approval, options
      end
    end
end
