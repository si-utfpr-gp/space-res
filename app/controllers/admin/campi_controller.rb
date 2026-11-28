class Admin::CampiController < Admin::BaseController
  # A saved campus shows the campus menu; `layout only:` would leave the other actions without a layout.
  layout -> { @campus&.persisted? ? "admin/campus" : "users/application" }
  before_action :set_campus, :require_campus_access, only: [ :show, :edit, :update, :destroy ]
  helper_method :campus_section

  def show
    @space_counts = @campus.spaces.counts_by_status
    @building_names = @campus.buildings.ordered_by_name.pluck(:name)
    @unavailable_spaces = @campus.spaces.unavailable.ordered_by_campus_building_and_name
  end

  def new
    @campus = Campus.new
  end

  # The new campus shows up as a card on the entry, where its administrators will be defined (#93).
  def create
    @campus = Campus.new(campus_params)

    if @campus.save
      redirect_to admin_root_path, success: t(".success")
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
  end

  def update
    if @campus.update(campus_params)
      redirect_to admin_campus_path(@campus), success: t(".success"), status: :see_other
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    if @campus.destroy
      redirect_to admin_root_path, success: t(".success"), status: :see_other
    else
      redirect_to admin_campus_path(@campus), alert: @campus.errors.full_messages.to_sentence, status: :see_other
    end
  end

  private

    def set_campus
      @campus = Campus.find(params.expect(:id))
    end

    def campus_params
      params.expect(campus: [ :name ])
    end

    def campus_section
      :overview
    end

    # Uses the saved name, so a rejected edit keeps the trail pointing to the campus as it is.
    def set_breadcrumbs
      case action_name
      when "new", "create"
        add_breadcrumb t("admin.campi.new.breadcrumb")
      when "show"
        add_breadcrumb @campus.name
      when "edit", "update"
        add_breadcrumb @campus.name_in_database, admin_campus_path(@campus)
        add_breadcrumb t("admin.campi.edit.breadcrumb")
      end
    end
end
