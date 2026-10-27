require "test_helper"

class DepartmentSortedTest < ActiveSupport::TestCase
  test "sorts by name ignoring accents and letter case" do
    [
      "Núcleo de Apoio ao Ensino",
      "Coordenadoria de Tecnologia da Informação",
      "biblioteca",
      "Coordenação de Gestão de Recursos Humanos",
      "Área de Convivência"
    ].each { |name| create(:department, name: name) }

    assert_equal [
      "Área de Convivência",
      "biblioteca",
      "Coordenação de Gestão de Recursos Humanos",
      "Coordenadoria de Tecnologia da Informação",
      "Núcleo de Apoio ao Ensino"
    ], Department.sorted.map(&:name)
  end
end
