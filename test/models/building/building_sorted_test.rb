require "test_helper"

class BuildingSortedTest < ActiveSupport::TestCase
  test "orders by campus name and then by building name" do
    pato_branco = create(:campus, name: "Pato Branco")
    guarapuava = create(:campus, name: "Guarapuava")
    create(:building, campus: pato_branco, name: "Bloco A")
    create(:building, campus: guarapuava, name: "Bloco R")
    create(:building, campus: guarapuava, name: "Bloco B")

    assert_equal [ [ "Guarapuava", "Bloco B" ], [ "Guarapuava", "Bloco R" ], [ "Pato Branco", "Bloco A" ] ],
                 Building.sorted.map { |building| [ building.campus.name, building.name ] }
  end

  test "loads the campus of each building" do
    create(:building)

    assert Building.sorted.first.association(:campus).loaded?
  end
end
