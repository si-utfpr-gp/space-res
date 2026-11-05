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

    USAGE_TERM_TITLE = "Termo de uso do laboratório de informática".freeze
    USAGE_TERM_CONTENT = <<~HTML.freeze
      <div>Ao reservar o laboratório de informática, o responsável pela reserva declara que leu e aceita as regras abaixo.</div>
      <ol>
      <li>O uso é permitido somente no horário reservado. O responsável deve chegar no início da reserva e liberar o espaço no horário de término.</li>
      <li>É proibido consumir alimentos e bebidas dentro do laboratório.</li>
      <li>Os computadores não podem ser desconectados, abertos nem ter os cabos trocados. Programas só podem ser instalados com autorização da Coordenadoria de Tecnologia da Informação.</li>
      <li>Ao final do uso, o responsável deve desligar os computadores, o projetor e o ar-condicionado, apagar as luzes e fechar as janelas.</li>
      </ol>
      <div>O responsável responde pelos danos causados ao espaço e aos equipamentos durante a reserva. Problemas encontrados no início do uso devem ser informados ao Setor de Gestão de Espaços Acadêmicos antes de começar a atividade.</div>
    HTML

    def call
      reset_records
      setup_users
      setup_campi
      setup_buildings
      setup_departments
      setup_usage_terms
      puts "Database populated"
    end

    private

      def reset_records
        [ Building, Campus, Department, UsageTerm, User ].each(&:destroy_all)
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

      def setup_usage_terms
        UsageTerm.create_with(content: USAGE_TERM_CONTENT).find_or_create_by!(title: USAGE_TERM_TITLE)
      end
  end
end
