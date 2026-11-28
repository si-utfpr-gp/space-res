class Admin::Campi::SpacesController < Admin::Campi::BaseController
  before_action :set_space, only: [ :show, :edit, :update, :destroy ]
  before_action :set_form_options, only: [ :new, :create, :edit, :update ]

  def index
    @filters = Admin::SpaceFiltersForm.new(campus: @campus, **filter_params)
    @spaces = Admin::CampusSpacesQuery.new(campus: @campus, filters: @filters).call
    @campus_has_spaces = @campus.spaces.exists?
  end

  def show
  end

  def new
    @space = @campus.spaces.new
  end

  def create
    @space = @campus.spaces.new(space_params)

    if @space.save
      redirect_to admin_campus_spaces_path(@campus), success: t(".success")
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
  end

  def update
    if @space.update(space_params)
      redirect_to admin_campus_spaces_path(@campus), success: t(".success"), status: :see_other
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @space.destroy!
    redirect_to admin_campus_spaces_path(@campus), success: t(".success"), status: :see_other
  end

  private

    def set_space
      @space = @campus.spaces.find(params.expect(:id))
    end

    # Lazy relations: only queried when a form is rendered, not on a successful redirect.
    def set_form_options
      @buildings = @campus.buildings.ordered_by_name
      @departments = Department.sorted
      @usage_terms = UsageTerm.ordered_by_title
    end

    # The campus comes from the URL and never changes. The status only changes through the
    # unavailability and deactivation actions.
    def space_params
      params.expect(space: [ :building_id, :department_id, :usage_term_id, :name, :description, :requires_approval ])
    end

    # Filters sent in any other shape (a plain value, a list) are ignored instead of failing.
    def filter_params
      filters = params[:filters]
      return {} unless filters.is_a?(ActionController::Parameters)

      filters.permit(:name, :building, :status).to_h.symbolize_keys
    end

    def campus_section
      :spaces
    end

    # Uses the saved name, so a rejected edit keeps the trail pointing to the space as it is.
    def set_breadcrumbs
      super
      add_breadcrumb t("admin.campi.spaces.index.breadcrumb"), admin_campus_spaces_path(@campus)

      case action_name
      when "new", "create"
        add_breadcrumb t("admin.campi.spaces.new.breadcrumb")
      when "show"
        add_breadcrumb @space.name_in_database
      when "edit", "update"
        add_breadcrumb @space.name_in_database, admin_campus_space_path(@campus, @space)
        add_breadcrumb t("admin.campi.spaces.edit.breadcrumb")
      end
    end
end
