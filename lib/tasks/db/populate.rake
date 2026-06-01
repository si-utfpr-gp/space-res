require Rails.root.join("lib/tasks/db/populate/populator")

namespace :db do
  desc "Erase and fill database"

  task populate: :environment do
    Db::Populator.new.call
  end
end
