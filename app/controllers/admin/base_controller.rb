class Admin::BaseController < Users::BaseController
  before_action :require_admin_area_access

  private

    def require_admin_area_access
      render "shared/forbidden", status: :forbidden unless can_access_admin_area?
    end
end
