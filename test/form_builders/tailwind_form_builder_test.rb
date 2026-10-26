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

  private

    def render_campus_select(building)
      @rendered = form_with(model: building, url: "/admin/buildings") do |form|
        form.select :campus_id, Campus.order(:name).pluck(:name, :id), { prompt: "Selecione o campus" }
      end
    end
end
