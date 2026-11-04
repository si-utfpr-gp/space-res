require "test_helper"
require "support/helpers/breadcrumb_assertions"

class Admin::UsageTermsControllerAccessTest < ActionDispatch::IntegrationTest
  include BreadcrumbAssertions

  setup do
    @usage_term = create(:usage_term, title: "Termo da quadra", content: "Regras da quadra.")
  end

  test "redirects visitors to sign in on every action" do
    each_usage_terms_request do |method, path, params|
      public_send(method, path, params: params)

      assert_redirected_to new_session_path, "#{method.upcase} #{path}"
    end

    assert_usage_terms_unchanged
  end

  test "denies regular users with forbidden on every action" do
    sign_in create(:user)

    each_usage_terms_request do |method, path, params|
      public_send(method, path, params: params)

      assert_response :forbidden, "#{method.upcase} #{path}"
    end

    assert_usage_terms_unchanged
  end

  test "hides the admin breadcrumbs and the term from regular users" do
    sign_in create(:user)

    get admin_usage_term_path(@usage_term)

    assert_response :forbidden
    assert_no_breadcrumbs
    assert_no_match "Regras da quadra.", response.body
  end

  test "denies regular users before looking up the usage term" do
    sign_in create(:user)

    get admin_usage_term_path(id: 0)

    assert_response :forbidden
  end

  private

    def each_usage_terms_request(&)
      params = { usage_term: { title: "Termo do laboratório", content: "Outras regras." } }

      [
        [ :get, admin_usage_terms_path, {} ],
        [ :get, admin_usage_term_path(@usage_term), {} ],
        [ :get, new_admin_usage_term_path, {} ],
        [ :post, admin_usage_terms_path, params ],
        [ :get, edit_admin_usage_term_path(@usage_term), {} ],
        [ :patch, admin_usage_term_path(@usage_term), params ],
        [ :delete, admin_usage_term_path(@usage_term), {} ]
      ].each(&)
    end

    def assert_usage_terms_unchanged
      assert_equal [ [ "Termo da quadra", "Regras da quadra." ] ], UsageTerm.all.map { |term| [ term.title, term.content.to_plain_text ] }
    end
end
