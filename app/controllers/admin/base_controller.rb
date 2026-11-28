class Admin::BaseController < Users::BaseController
  before_action :require_admin_area_access
  helper_method :selectable_campi

  private

    def default_breadcrumbs
      super
      add_breadcrumb t("admin.home.index.breadcrumb"), admin_root_path
    end

    def require_admin_area_access
      deny_access unless can_access_admin_area?
    end

    # Runs after @campus is loaded, so an administrator gets not found for a missing campus.
    def require_campus_access
      deny_access unless can_manage_campus?(@campus)
    end

    # The application layout, without the campus menu: access to the campus was not granted.
    def deny_access
      clear_breadcrumbs
      render "shared/forbidden", status: :forbidden, layout: "users/application"
    end

    # The campi the campus selector offers.
    def selectable_campi
      @selectable_campi ||= Campus.ordered_by_name
    end
end
