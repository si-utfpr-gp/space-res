class Admin::UsersController < Admin::BaseController
  before_action :set_user, only: [ :edit, :update ]
  before_action :set_departments, only: [ :edit, :update ]

  def index
    @users = User.includes(:department).ordered_by_name
  end

  def edit
  end

  def update
    if @user.update(user_params)
      redirect_to admin_users_path, success: t(".success"), status: :see_other
    else
      render :edit, status: :unprocessable_content
    end
  end

  private

    def set_user
      @user = User.find(params.expect(:id))
    end

    # Lazy relation: only queried when the form is rendered, not on a successful redirect.
    def set_departments
      @departments = Department.sorted
    end

    # Only the department: the admin flag, name, e-mail and password are never changed from here.
    def user_params
      params.expect(user: [ :department_id ])
    end

    def set_breadcrumbs
      add_breadcrumb t("admin.users.index.breadcrumb"), admin_users_path
      add_breadcrumb t("admin.users.edit.breadcrumb") if action_name.in?(%w[ edit update ])
    end
end
