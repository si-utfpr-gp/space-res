class Users::BaseController < ActionController::Base
  include Authentication
  include Breadcrumbs

  layout "users/application"
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  # allow_browser versions: :modern

  add_flash_types :success, :warning

  helper_method :can_access_admin_area?, :can_manage_campus?

  private

    def can_access_admin_area?
      AdminPolicy.new(Current.user).access_area?
    end

    def can_manage_campus?(campus)
      AdminPolicy.new(Current.user).manage_campus?(campus)
    end

    def default_breadcrumbs
      add_breadcrumb t("users.home.dashboard.breadcrumb"), users_root_path
    end
end
