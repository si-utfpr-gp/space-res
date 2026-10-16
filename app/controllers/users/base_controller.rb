class Users::BaseController < ActionController::Base
  include Authentication

  layout "users/application"
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  # allow_browser versions: :modern

  add_flash_types :success, :warning

  helper_method :admin_area_access?

  private

    def admin_area_access?
      AdminAreaPolicy.new(Current.user).access?
    end
end
