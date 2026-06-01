require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
  def test_full_title_without_param
    assert_equal I18n.t("app.name"), full_title
  end

  def test_full_title_with_param
    assert_equal "Home | #{I18n.t('app.name')}", full_title("Home")
  end

  def test_full_title_with_nil_param
    assert_equal I18n.t("app.name"), full_title(nil)
  end
end
