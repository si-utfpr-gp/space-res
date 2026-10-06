require "json"

module Db
  class Populator
    DEPARTMENTS = [
      "Departamento Acadêmico de Engenharia",
      "Coordenação do Curso de Engenharia Civil",
      "Coordenação do Curso de Engenharia Mecânica",
      "Coordenação do Curso de Engenharia Mecatrônica",
      "Coordenação do Curso de Tecnologia em Sistemas para a Internet",
      "Coordenação do Curso de Arquitetura e Urbanismo",
      "Diretoria de Graduação e Educação Profissional",
      "Diretoria de Relações Empresariais e Comunitárias",
      "Diretoria de Pesquisa e Pós-Graduação",
      "Departamento de Registros Acadêmicos",
      "Departamento de Educação",
      "Núcleo de Acompanhamento Psicopedagógico e Assistência Estudantil",
      "Núcleo de Apoio ao Ensino",
      "Setor de Gestão de Espaços Acadêmicos",
      "Assessoria de Comunicação",
      "Departamento de Extensão",
      "Departamento de Estágios e Cursos de Qualificação Profissional",
      "Diretoria de Planejamento e Administração",
      "Coordenadoria de Tecnologia da Informação",
      "Coordenação de Gestão de Recursos Humanos",
      "Biblioteca"
    ].freeze

    def call
      reset_records
      setup_users
      setup_departments
      puts "Database populated"
    end

    private

      def reset_records
        [ User, Department ].each(&:destroy_all)
      end

      def seed_plans
        Rake::Task["db:seed"].reenable
        Rake::Task["db:seed"].invoke
      end

      def setup_users
        User.create_with(name: "User Demo", password: "123456", password_confirmation: "123456")
            .find_or_create_by!(email_address: "demo@utfpr.edu.br")
      end

      def setup_departments
        DEPARTMENTS.each { |name| Department.find_or_create_by!(name: name) }
      end
  end
end
