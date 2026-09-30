require "test_helper"

# namespace :admin { root "home#dashboard" }
class Admin::HomeControllerAccessTest < ActionDispatch::IntegrationTest
  context "unauthenticated user" do
    should "be redirected to the login page" do
      get admin_root_url
      assert_redirected_to new_session_path
    end
  end

  context "common user" do
    should "not find the admin area" do
      sign_in create(:user)

      get admin_root_url
      assert_response :not_found
    end
  end

  context "super admin" do
    should "access the admin area" do
      sign_in create(:user, :super_admin)

      get admin_root_url
      assert_response :success
      assert_select "h1", text: I18n.t("admin.home.dashboard.title")
    end
  end
end
