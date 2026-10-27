require "json"

module Db
  class Populator
    DEPARTMENTS = [
      "Departamento Acadêmico de Engenharia",
      "Departamento Acadêmico de Exatas",
      "Coordenação do Curso de Engenharia Civil",
      "Coordenação do Curso de Engenharia Mecânica",
      "Coordenação do Curso de Engenharia Mecatrônica",
      "Coordenação do Curso de Tecnologia em Sistemas para a Internet",
      "Coordenação do Curso de Arquitetura e Urbanismo",
      "Diretoria de Graduação e Educação Profissional",
      "Secretaria de Gestão Acadêmica",
      "Departamento de Registros Acadêmicos",
      "Departamento de Educação",
      "Diretoria de Relações Empresariais e Comunitárias",
      "Departamento de Extensão",
      "Departamento de Estágios e Cursos de Qualificação Profissional",
      "Departamento de Relações Interinstitucionais",
      "Departamento de Apoio e Projetos Tecnológicos",
      "Diretoria de Pesquisa e Pós-Graduação",
      "Núcleo de Acompanhamento Psicopedagógico e Assistência Estudantil",
      "Núcleo de Apoio ao Ensino",
      "Setor de Gestão de Espaços Acadêmicos",
      "Assessoria de Comunicação",
      "Diretoria de Planejamento e Administração",
      "Coordenadoria de Tecnologia da Informação",
      "Coordenação de Gestão de Recursos Humanos",
      "Biblioteca"
    ].freeze

    def call
      reset_records
      setup_users
      setup_campi
      setup_buildings
      setup_departments
      puts "Database populated"
    end

    private

      def reset_records
        [ Building, Campus, Department, User ].each(&:destroy_all)
      end

      def seed_plans
        Rake::Task["db:seed"].reenable
        Rake::Task["db:seed"].invoke
      end

      def setup_users
        User.create_with(name: "User Demo", password: "123456", password_confirmation: "123456")
            .find_or_create_by!(email_address: "demo@utfpr.edu.br")

        User.create_with(name: "Admin Demo", password: "123456", password_confirmation: "123456", admin: true)
            .find_or_create_by!(email_address: "admin@utfpr.edu.br")
      end

      def setup_campi
        Campus.find_or_create_by!(name: "Guarapuava")
      end

      def setup_buildings
        campus = Campus.find_by!(name: "Guarapuava")

        [ "Bloco B", "Bloco C", "Bloco R" ].each do |name|
          campus.buildings.find_or_create_by!(name: name)
        end
      end

      def setup_departments
        DEPARTMENTS.each { |name| Department.find_or_create_by!(name: name) }
      end
  end
end
