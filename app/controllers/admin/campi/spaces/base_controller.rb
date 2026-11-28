# Actions on the status of one space, nested under it.
class Admin::Campi::Spaces::BaseController < Admin::Campi::BaseController
  before_action :set_space
  rescue_from Space::StatusConflict, with: :report_status_unchanged

  private

    def set_space
      @space = @campus.spaces.find(params.expect(:space_id))
    end

    # The space page shows the current status and the actions that fit it.
    def report_status_unchanged
      redirect_to admin_campus_space_path(@campus, @space), status: :see_other,
                  warning: t("admin.campi.spaces.status_unchanged", status: Admin::SpacePresenter.new(@space).status_label.downcase)
    end

    def campus_section
      :spaces
    end

    def set_breadcrumbs
      super
      add_breadcrumb t("admin.campi.spaces.index.breadcrumb"), admin_campus_spaces_path(@campus)
      add_breadcrumb @space.name_in_database, admin_campus_space_path(@campus, @space)
    end
end
