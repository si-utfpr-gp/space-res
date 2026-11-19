require "test_helper"
require Rails.root.join("lib/tasks/db/populate/populator")

class Db::PopulatorTest < ActiveSupport::TestCase
  test "creates a local administrator and keeps the demo user regular" do
    assert_output(/Database populated/) { Db::Populator.new.call }

    assert User.find_by!(email_address: "admin@utfpr.edu.br").admin?
    assert_not User.find_by!(email_address: "demo@utfpr.edu.br").admin?
  end

  test "replaces the campi with the Guarapuava campus" do
    create(:campus, name: "Pato Branco")

    assert_output(/Database populated/) { Db::Populator.new.call }

    assert_equal [ "Guarapuava" ], Campus.pluck(:name)
  end

  test "replaces the buildings with blocks B, C and R of the Guarapuava campus" do
    create(:building, campus: create(:campus, name: "Pato Branco"), name: "Bloco A")

    assert_output(/Database populated/) { Db::Populator.new.call }

    assert_equal [ [ "Guarapuava", "Bloco B" ], [ "Guarapuava", "Bloco C" ], [ "Guarapuava", "Bloco R" ] ],
                 Building.sorted.map { |building| [ building.campus.name, building.name ] }
  end

  test "replaces the departments with the 25 Guarapuava departments" do
    create(:department, name: "Departamento de Física")

    assert_output(/Database populated/) { Db::Populator.new.call }

    assert_equal 25, Department.count
    assert_not Department.exists?(name: "Departamento de Física")
    assert Department.exists?(name: "Departamento Acadêmico de Engenharia")
    assert Department.exists?(name: "Núcleo de Acompanhamento Psicopedagógico e Assistência Estudantil")
    assert Department.exists?(name: "Biblioteca")
  end

  test "links the demo user to the TSI course coordination and keeps the admin without department" do
    assert_output(/Database populated/) { Db::Populator.new.call }

    assert_equal "Coordenação do Curso de Tecnologia em Sistemas para a Internet",
                 User.find_by!(email_address: "demo@utfpr.edu.br").department.name
    assert_nil User.find_by!(email_address: "admin@utfpr.edu.br").department
  end

  test "replaces departments that have users" do
    create(:user, department: create(:department, name: "Departamento de Física"))

    assert_output(/Database populated/) { Db::Populator.new.call }

    assert_not Department.exists?(name: "Departamento de Física")
  end

  test "runs twice in a row" do
    assert_output(/Database populated/) { Db::Populator.new.call }
    assert_output(/Database populated/) { Db::Populator.new.call }

    assert_equal 2, User.count
    assert_equal 25, Department.count
  end

  test "replaces the usage terms with the computer lab example" do
    create(:usage_term, title: "Termo da quadra")

    assert_output(/Database populated/) { Db::Populator.new.call }

    usage_term = UsageTerm.sole
    assert_equal "Termo de uso do laboratório de informática", usage_term.title
    assert_equal 4, usage_term.content.body.fragment.find_all("ol li").size
    assert_match "2. É proibido consumir alimentos e bebidas dentro do laboratório.", usage_term.content.to_plain_text
  end

  test "replaces the spaces with examples with and without building" do
    create(:space, :with_building, name: "Sala antiga")

    assert_output(/Database populated/) { Db::Populator.new.call }

    assert_equal [ [ "Bloco B", "Sala B101" ], [ "Bloco B", "Sala B102" ], [ "Bloco B", "Sala B103" ],
                   [ "Bloco C", "Laboratório de Informática C3" ],
                   [ "Bloco R", "Auditório" ], [ nil, "Planetário" ], [ nil, "Quadra poliesportiva" ] ],
                 Space.ordered_by_campus_building_and_name.map { |space| [ space.building&.name, space.name ] }
    assert_equal [ "Guarapuava" ], Space.all.map { |space| space.campus.name }.uniq
  end

  test "creates example spaces with and without approval, department and usage term, one unavailable and one deactivated" do
    assert_output(/Database populated/) { Db::Populator.new.call }

    lab = Space.find_by!(name: "Laboratório de Informática C3")
    assert lab.requires_approval?
    assert_equal "Coordenadoria de Tecnologia da Informação", lab.department.name
    assert_equal "Termo de uso do laboratório de informática", lab.usage_term.title

    auditorium = Space.find_by!(name: "Auditório")
    assert auditorium.requires_approval?
    assert_nil auditorium.department

    room = Space.find_by!(name: "Sala B101")
    assert_equal [ false, nil, nil ], [ room.requires_approval, room.department, room.usage_term ]

    assert_equal [ [ "Sala B102", "Sala em reforma" ] ], Space.unavailable.pluck(:name, :unavailability_reason)
    assert_equal [ "Sala B103" ], Space.deactivated.pluck(:name)
  end

  test "runs twice in a row with the spaces in place" do
    assert_output(/Database populated/) { Db::Populator.new.call }
    assert_output(/Database populated/) { Db::Populator.new.call }

    assert_equal 7, Space.count
  end
end
