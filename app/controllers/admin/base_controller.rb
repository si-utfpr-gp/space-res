class Admin::BaseController < Users::BaseController
  before_action :require_super_admin

  private

    def require_super_admin
      raise ActionController::RoutingError, "Not Found" unless Current.user.super_admin?
    end
end
