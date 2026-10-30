require "test_helper"

class DepartmentSortedTest < ActiveSupport::TestCase
  test "orders by name" do
    [ "Núcleo de Apoio ao Ensino", "Biblioteca", "Coordenação de Gestão de Recursos Humanos" ]
      .each { |name| create(:department, name: name) }

    assert_equal [ "Biblioteca", "Coordenação de Gestão de Recursos Humanos", "Núcleo de Apoio ao Ensino" ],
                 Department.sorted.map(&:name)
  end
end
