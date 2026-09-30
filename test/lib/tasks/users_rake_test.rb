require "test_helper"
require "rake"

class UsersRakeTest < ActiveSupport::TestCase
  setup do
    Rails.application.load_tasks unless Rake::Task.task_defined?("users:grant_super_admin")
    @task = Rake::Task["users:grant_super_admin"]
    @task.reenable
  end

  test "grants super admin access to an existing user" do
    user = create(:user)

    assert_output(/is now a super admin/) { @task.invoke(user.email_address) }
    assert user.reload.super_admin?
  end

  test "finds the user regardless of e-mail case and spaces" do
    user = create(:user, email_address: "admin@utfpr.edu.br")

    capture_io { @task.invoke("  Admin@UTFPR.edu.br ") }
    assert user.reload.super_admin?
  end

  test "aborts when the user does not exist" do
    error = assert_raises(SystemExit) do
      capture_io { @task.invoke("missing@utfpr.edu.br") }
    end

    assert_equal "User not found: missing@utfpr.edu.br", error.message
  end
end
