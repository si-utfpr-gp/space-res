require "application_system_test_case"

class UserLoginTest < ApplicationSystemTestCase
  setup do
    @user = create(:user)
  end

  test "see hello message" do
    sign_in_as(@user)
    visit users_root_path

    assert_selector "h1", text: "Olá #{@user.name}"
  end
end
