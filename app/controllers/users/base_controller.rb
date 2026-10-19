class Users::BaseController < ActionController::Base
  include Authentication

  layout "users/application"
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  # allow_browser versions: :modern

  add_flash_types :success, :warning

  helper_method :can_access_admin_area?

  private

    def can_access_admin_area?
      AdminPolicy.new(Current.user).access_area?
    end
end
