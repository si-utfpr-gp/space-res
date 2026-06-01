require "json"

module Db
  class Populator
    def call
      reset_records
      setup_users
      puts "Database populated"
    end

    private

      def reset_records
        [ User ].each(&:destroy_all)
      end

      def seed_plans
        Rake::Task["db:seed"].reenable
        Rake::Task["db:seed"].invoke
      end

      def setup_users
        User.create_with(name: "User Demo", password: "123456", password_confirmation: "123456")
            .find_or_create_by!(email_address: "demo@utfpr.edu.br")
      end
  end
end
