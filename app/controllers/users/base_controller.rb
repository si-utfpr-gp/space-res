class Users::BaseController < ActionController::Base
  include Authentication

  layout "application"
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  # allow_browser versions: :modern

  add_flash_types :success, :warning
end
