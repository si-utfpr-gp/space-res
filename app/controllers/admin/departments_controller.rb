class Admin::DepartmentsController < Admin::BaseController
  before_action :set_department, only: [ :edit, :update, :destroy ]

  def index
    @departments = Department.sorted
  end

  def new
    @department = Department.new
  end

  def create
    @department = Department.new(department_params)

    if @department.save
      redirect_to admin_departments_path, success: t(".success")
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
  end

  def update
    if @department.update(department_params)
      redirect_to admin_departments_path, success: t(".success"), status: :see_other
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @department.destroy!
    redirect_to admin_departments_path, success: t(".success"), status: :see_other
  end

  private

    def set_department
      @department = Department.find(params.expect(:id))
    end

    def department_params
      params.expect(department: [ :name ])
    end

    def set_breadcrumbs
      add_breadcrumb t("admin.departments.index.breadcrumb"), admin_departments_path
      add_breadcrumb t("admin.departments.new.breadcrumb") if action_name.in?(%w[ new create ])
      add_breadcrumb t("admin.departments.edit.breadcrumb") if action_name.in?(%w[ edit update ])
    end
end
