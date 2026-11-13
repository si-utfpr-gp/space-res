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

    DEMO_USER_DEPARTMENT = "Coordenação do Curso de Tecnologia em Sistemas para a Internet".freeze

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

    # building, department and usage_term hold names; a missing key means the space has none.
    SPACES = [
      { building: "Bloco B", name: "Sala B101", description: "Sala de aula com 40 carteiras e projetor, no térreo." },
      { building: "Bloco B", name: "Sala B102", description: "Sala de aula com 35 carteiras, no térreo.",
        status: :unavailable, unavailability_reason: "Sala em reforma" },
      { building: "Bloco B", name: "Sala B103", description: "Sala unificada com a Sala B101.", status: :deactivated },
      { building: "Bloco C", name: "Laboratório de Informática C3", requires_approval: true,
        department: "Coordenadoria de Tecnologia da Informação", usage_term: USAGE_TERM_TITLE,
        description: "Laboratório com 20 computadores e projetor, no 1º andar." },
      { building: "Bloco R", name: "Auditório", requires_approval: true,
        description: "Auditório com 120 lugares, palco e sistema de som." },
      { name: "Quadra poliesportiva", requires_approval: true, department: "Departamento de Educação",
        description: "Quadra coberta, ao lado do estacionamento." },
      { name: "Planetário", description: "Cúpula com 30 lugares, na entrada do campus." }
    ].freeze

    def call
      reset_records
      setup_campi
      setup_buildings
      setup_departments
      setup_users
      setup_usage_terms
      setup_spaces
      puts "Database populated"
    end

    private

      def reset_records
        # Spaces first, and users before departments: records in use cannot be destroyed.
        [ Space, Building, Campus, User, Department, UsageTerm ].each(&:destroy_all)
      end

      def seed_plans
        Rake::Task["db:seed"].reenable
        Rake::Task["db:seed"].invoke
      end

      def setup_users
        department = Department.find_by!(name: DEMO_USER_DEPARTMENT)
        User.create_with(name: "User Demo", password: "123456", password_confirmation: "123456", department: department)
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

      def setup_spaces
        campus = Campus.find_by!(name: "Guarapuava")

        SPACES.each do |space|
          campus.spaces.create!(
            space.except(:building, :department, :usage_term).merge(
              building: space[:building] && campus.buildings.find_by!(name: space[:building]),
              department: space[:department] && Department.find_by!(name: space[:department]),
              usage_term: space[:usage_term] && UsageTerm.find_by!(title: space[:usage_term])
            )
          )
        end
      end
  end
end
