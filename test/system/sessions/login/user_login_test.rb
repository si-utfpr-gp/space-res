require "application_system_test_case"

class UserLoginTest < ApplicationSystemTestCase
  setup do
    @user = create(:user)
    visit new_session_path
  end

  test "user can log in" do
    fill_in :email_address, with: @user.email_address
    fill_in :password, with: "password"
    click_on I18n.t("sessions.actions.sign_in")

    assert_current_path users_root_path
  end

  test "user cannot log in with invalid credentials" do
    fill_in :email_address, with: @user.email_address
    fill_in :password, with: "wrongpassword"
    click_on I18n.t("sessions.actions.sign_in")

    assert_flash_message I18n.t("sessions.flash.error")

    assert_current_path new_session_path
  end
end
