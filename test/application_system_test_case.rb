require "test_helper"
require "support/helpers/capybara_custom_assertions"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  include CapybaraCustomAssertions
  Capybara.default_max_wait_time = 10

  options = { screen_size: [ 1400, 1400 ] }
  options[:using] = :headless_chrome unless ENV["LAUNCH_BROWSER"]

  driven_by :selenium, **options do |driver_options|
    driver_options.add_preference(:credentials_enable_service, false)
    driver_options.add_preference(:profile, { password_manager_leak_detection: false }) # not show dialog when password is weak
  end

  def sign_in_as(user)
    session = user.sessions.create!
    Current.session = session
    request = ActionDispatch::Request.new(Rails.application.env_config)
    cookies = request.cookie_jar
    cookies.signed[:session_id] = { value: session.id, httponly: true, same_site: :lax }
  end

  def sign_out
    Current.session&.destroy!
    request = ActionDispatch::Request.new(Rails.application.env_config)
    cookies = request.cookie_jar
    cookies.delete(:session_id)
  end

  def teardown
    super
    sign_out
  end
end
