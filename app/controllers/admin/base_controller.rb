class Admin::BaseController < Users::BaseController
  before_action :require_admin_area_access

  private

    def default_breadcrumbs
      super
      add_breadcrumb t("admin.home.index.breadcrumb"), admin_root_path
    end

    def require_admin_area_access
      return if can_access_admin_area?

      clear_breadcrumbs
      render "shared/forbidden", status: :forbidden
    end
end
