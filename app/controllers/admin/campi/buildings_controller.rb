class Admin::Campi::BuildingsController < Admin::Campi::BaseController
  before_action :set_building, only: [ :edit, :update, :destroy ]

  def index
    @buildings = @campus.buildings.ordered_by_name
  end

  def new
    @building = @campus.buildings.new
  end

  def create
    @building = @campus.buildings.new(building_params)

    if @building.save
      redirect_to admin_campus_buildings_path(@campus), success: t(".success")
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
  end

  def update
    if @building.update(building_params)
      redirect_to admin_campus_buildings_path(@campus), success: t(".success"), status: :see_other
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    if @building.destroy
      redirect_to admin_campus_buildings_path(@campus), success: t(".success"), status: :see_other
    else
      redirect_to admin_campus_buildings_path(@campus), alert: @building.errors.full_messages.to_sentence, status: :see_other
    end
  end

  private

    def set_building
      @building = @campus.buildings.find(params.expect(:id))
    end

    # The campus comes from the URL and never changes, so it is not a parameter.
    def building_params
      params.expect(building: [ :name ])
    end

    def campus_section
      :buildings
    end

    def set_breadcrumbs
      super
      add_breadcrumb t("admin.campi.buildings.index.breadcrumb"), admin_campus_buildings_path(@campus)
      add_breadcrumb t("admin.campi.buildings.new.breadcrumb") if action_name.in?(%w[ new create ])
      add_breadcrumb t("admin.campi.buildings.edit.breadcrumb") if action_name.in?(%w[ edit update ])
    end
end
