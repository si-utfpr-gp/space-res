class Admin::BuildingsController < Admin::BaseController
  before_action :set_building, only: [ :edit, :update, :destroy ]
  before_action :set_campi, only: [ :new, :create, :edit, :update ]

  def index
    @buildings = Building.sorted
  end

  def new
    @building = Building.new
  end

  def create
    @building = Building.new(building_params)

    if @building.save
      redirect_to admin_buildings_path, success: t(".success")
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
  end

  def update
    if @building.update(building_params)
      redirect_to admin_buildings_path, success: t(".success"), status: :see_other
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @building.destroy!
    redirect_to admin_buildings_path, success: t(".success"), status: :see_other
  end

  private

    def set_building
      @building = Building.find(params.expect(:id))
    end

    # Lazy relation: only queried when a form is rendered, not on a successful redirect.
    def set_campi
      @campi = Campus.order(:name)
    end

    def building_params
      params.expect(building: [ :campus_id, :name ])
    end

    def set_breadcrumbs
      add_breadcrumb t("admin.buildings.index.breadcrumb"), admin_buildings_path
      add_breadcrumb t("admin.buildings.new.breadcrumb") if action_name.in?(%w[ new create ])
      add_breadcrumb t("admin.buildings.edit.breadcrumb") if action_name.in?(%w[ edit update ])
    end
end
