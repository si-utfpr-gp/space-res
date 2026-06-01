require "test_helper"

# resource :session, only: %i[ new create destroy ]
class Auth::SessionsControllerAccessTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user)
  end

  context "unauthenticated user" do
    should "access the routes" do
      get new_session_url
      assert_response :success

      post session_url, params: { email_address: @user.email_address, password: "password" }
      assert_redirected_to users_root_path
    end
  end

  context "authenticated user" do
    should "be redirect to users_root_path" do
      sign_in @user

      get new_session_url
      assert_redirected_to users_root_path

      post session_url, params: { email_address: "", password: "" }
      assert_redirected_to users_root_path
    end
  end
end
