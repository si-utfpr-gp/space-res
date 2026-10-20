class Admin::CampiController < Admin::BaseController
  before_action :set_campus, only: [ :edit, :update, :destroy ]

  def index
    @campi = Campus.order(:name)
  end

  def new
    @campus = Campus.new
  end

  def create
    @campus = Campus.new(campus_params)

    if @campus.save
      redirect_to admin_campi_path, success: t(".success")
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
  end

  def update
    if @campus.update(campus_params)
      redirect_to admin_campi_path, success: t(".success"), status: :see_other
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @campus.destroy!
    redirect_to admin_campi_path, success: t(".success"), status: :see_other
  end

  private

    def set_campus
      @campus = Campus.find(params.expect(:id))
    end

    def campus_params
      params.expect(campus: [ :name ])
    end

    def set_breadcrumbs
      add_breadcrumb t("admin.campi.index.breadcrumb"), admin_campi_path
      add_breadcrumb t("admin.campi.new.breadcrumb") if action_name.in?(%w[ new create ])
      add_breadcrumb t("admin.campi.edit.breadcrumb") if action_name.in?(%w[ edit update ])
    end
end
