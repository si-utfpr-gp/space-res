require "json"

module Db
  class Populator
    def call
      reset_records
      setup_users
      setup_campi
      setup_buildings
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
  end
end
