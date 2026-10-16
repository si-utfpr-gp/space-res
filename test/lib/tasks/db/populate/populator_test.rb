require "test_helper"
require Rails.root.join("lib/tasks/db/populate/populator")

class Db::PopulatorTest < ActiveSupport::TestCase
  test "creates a local administrator and keeps the demo user regular" do
    assert_output(/Database populated/) { Db::Populator.new.call }

    assert User.find_by!(email_address: "admin@utfpr.edu.br").admin?
    assert_not User.find_by!(email_address: "demo@utfpr.edu.br").admin?
  end
end
