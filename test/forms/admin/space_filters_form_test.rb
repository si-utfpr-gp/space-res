require "test_helper"

class Admin::SpaceFiltersFormTest < ActiveSupport::TestCase
  setup do
    @campus = create(:campus, name: "Guarapuava")
    @bloco_r = create(:building, campus: @campus, name: "Bloco R")
    @bloco_b = create(:building, campus: @campus, name: "Bloco B")
  end

  test "applies no filter by default" do
    filters = Admin::SpaceFiltersForm.new(campus: @campus)

    assert_nil filters.name
    assert_nil filters.building
    assert_nil filters.status
    assert_not filters.applied?
  end

  test "keeps the name without extra spaces" do
    assert_equal "Sala B", Admin::SpaceFiltersForm.new(campus: @campus, name: "  Sala   B ").name
  end

  test "ignores a name made only of spaces" do
    filters = Admin::SpaceFiltersForm.new(campus: @campus, name: "   ")

    assert_nil filters.name
    assert_not filters.applied?
  end

  test "ignores a name made only of punctuation, which would match every space" do
    filters = Admin::SpaceFiltersForm.new(campus: @campus, name: " --- ")

    assert_nil filters.name
    assert_not filters.applied?
  end

  test "keeps a building of the campus" do
    filters = Admin::SpaceFiltersForm.new(campus: @campus, building: @bloco_b.id.to_s)

    assert_equal @bloco_b.id.to_s, filters.building
    assert_not filters.without_building?
    assert filters.applied?
  end

  test "keeps the choice of spaces without building" do
    filters = Admin::SpaceFiltersForm.new(campus: @campus, building: "none")

    assert_equal "none", filters.building
    assert filters.without_building?
  end

  test "ignores a building of another campus or one that does not exist" do
    other = create(:building, name: "Bloco A")

    assert_nil Admin::SpaceFiltersForm.new(campus: @campus, building: other.id.to_s).building
    assert_nil Admin::SpaceFiltersForm.new(campus: @campus, building: "0").building
  end

  test "keeps a known status and ignores an unknown one" do
    assert_equal "unavailable", Admin::SpaceFiltersForm.new(campus: @campus, status: "unavailable").status
    assert_nil Admin::SpaceFiltersForm.new(campus: @campus, status: "archived").status
  end

  test "offers spaces without building and the buildings of the campus by name" do
    create(:building, name: "Bloco A")

    assert_equal [ [ "Sem bloco", "none" ], [ "Bloco B", @bloco_b.id.to_s ], [ "Bloco R", @bloco_r.id.to_s ] ],
                 Admin::SpaceFiltersForm.new(campus: @campus).building_options
  end

  test "offers the three statuses" do
    assert_equal [ [ "Disponível", "available" ], [ "Indisponível", "unavailable" ], [ "Desativado", "deactivated" ] ],
                 Admin::SpaceFiltersForm.new(campus: @campus).status_options
  end

  test "names its fields in Portuguese" do
    assert_equal [ "Nome", "Bloco", "Situação" ],
                 [ :name, :building, :status ].map { |attribute| Admin::SpaceFiltersForm.human_attribute_name(attribute) }
  end
end
