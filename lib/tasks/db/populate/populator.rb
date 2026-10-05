require "json"

module Db
  class Populator
    CAMPI = {
      "Guarapuava" => [ "Bloco A", "Bloco B", "Bloco C", "Bloco D", "Bloco E" ],
      "Pato Branco" => [ "Bloco A", "Bloco B" ]
    }.freeze

    def call
      reset_records
      setup_users
      setup_campi
      puts "Database populated"
    end

    private

      def reset_records
        [ Building, Campus, User ].each(&:destroy_all)
      end

      def seed_plans
        Rake::Task["db:seed"].reenable
        Rake::Task["db:seed"].invoke
      end

      def setup_users
        User.create_with(name: "User Demo", password: "123456", password_confirmation: "123456")
            .find_or_create_by!(email_address: "demo@utfpr.edu.br")
      end

      def setup_campi
        CAMPI.each do |campus_name, building_names|
          campus = Campus.find_or_create_by!(name: campus_name)
          building_names.each { |name| campus.buildings.find_or_create_by!(name: name) }
        end
      end
  end
end
