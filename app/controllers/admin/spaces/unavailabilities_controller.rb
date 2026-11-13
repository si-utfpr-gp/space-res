# Temporary unavailability: the space stays listed for reservation, with the reason, but cannot be reserved.
class Admin::Spaces::UnavailabilitiesController < Admin::Spaces::BaseController
  before_action -> { report_status_unchanged unless @space.available? }, only: :new
  before_action -> { report_status_unchanged unless @space.unavailable? }, only: :edit

  def new
  end

  def create
    if @space.mark_unavailable(unavailability_reason)
      redirect_to admin_space_path(@space), success: t(".success")
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
  end

  def update
    if @space.change_unavailability_reason(unavailability_reason)
      redirect_to admin_space_path(@space), success: t(".success"), status: :see_other
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @space.end_unavailability
    redirect_to admin_space_path(@space), success: t(".success"), status: :see_other
  end

  private

    def unavailability_reason
      params.expect(space: [ :unavailability_reason ])[:unavailability_reason]
    end

    def set_breadcrumbs
      super
      add_breadcrumb t("admin.spaces.unavailabilities.breadcrumb")
    end
end
