# Actions on the status of one space, nested under it.
class Admin::Spaces::BaseController < Admin::BaseController
  before_action :set_space
  rescue_from Space::StatusConflict, with: :report_status_unchanged

  private

    def set_space
      @space = Space.find(params.expect(:space_id))
    end

    # The space page shows the current status and the actions that fit it.
    def report_status_unchanged
      redirect_to admin_space_path(@space), status: :see_other,
                  warning: t("admin.spaces.status_unchanged", status: Admin::SpacePresenter.new(@space).status_label.downcase)
    end

    def set_breadcrumbs
      add_breadcrumb t("admin.spaces.index.breadcrumb"), admin_spaces_path
      add_breadcrumb @space.name_in_database, admin_space_path(@space)
    end
end
