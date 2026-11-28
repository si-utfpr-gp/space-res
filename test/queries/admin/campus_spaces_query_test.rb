require "test_helper"

class Admin::CampusSpacesQueryTest < ActiveSupport::TestCase
  setup do
    @campus = create(:campus, name: "Guarapuava")
    @bloco_b = create(:building, campus: @campus, name: "Bloco B")
    @bloco_c = create(:building, campus: @campus, name: "Bloco C")
    @sala = create(:space, campus: @campus, building: @bloco_b, name: "Sala B102")
    @laboratorio = create(:space, campus: @campus, building: @bloco_c, name: "Laboratório de Informática C3")
    @reforma = create(:space, :unavailable, campus: @campus, building: @bloco_b, name: "Laboratório de Física")
    @planetario = create(:space, campus: @campus, name: "Planetário")
    @antigo = create(:space, :deactivated, campus: @campus, name: "Auditório antigo")
    create(:space, name: "Sala de outro campus")
  end

  test "lists only the spaces of the campus, by building and then name, the ones without building last" do
    assert_equal [ @reforma, @sala, @laboratorio, @antigo, @planetario ], spaces
  end

  test "preloads what the listing shows" do
    space = spaces.first

    assert space.association(:campus).loaded?
    assert space.association(:building).loaded?
    assert space.association(:department).loaded?
  end

  test "finds the name ignoring case and accents" do
    assert_equal [ @reforma, @laboratorio ], spaces(name: "LABORATORIO")
    assert_equal [ @planetario ], spaces(name: "planetário")
  end

  test "finds a part of the name written with other spaces and punctuation" do
    assert_equal [ @sala ], spaces(name: "b 102")
    assert_equal [ @laboratorio ], spaces(name: "informática-c3")
  end

  test "filters by building" do
    assert_equal [ @reforma, @sala ], spaces(building: @bloco_b.id.to_s)
  end

  test "filters the spaces without building" do
    assert_equal [ @antigo, @planetario ], spaces(building: "none")
  end

  test "filters by status" do
    assert_equal [ @reforma ], spaces(status: "unavailable")
    assert_equal [ @antigo ], spaces(status: "deactivated")
  end

  test "combines the filters" do
    assert_equal [ @laboratorio ], spaces(name: "laboratorio", status: "available")
    assert_equal [], spaces(name: "planetario", building: @bloco_b.id.to_s)
  end

  test "ignores unknown values" do
    other_building = create(:building, name: "Bloco A")

    assert_equal spaces, spaces(building: other_building.id.to_s, status: "archived")
  end

  private

    def spaces(**filters)
      Admin::CampusSpacesQuery.new(campus: @campus, filters: Admin::SpaceFiltersForm.new(campus: @campus, **filters)).call
    end
end
