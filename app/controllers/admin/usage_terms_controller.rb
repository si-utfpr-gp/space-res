class Admin::UsageTermsController < Admin::BaseController
  before_action :set_usage_term, only: [ :show, :edit, :update, :destroy ]

  def index
    @usage_terms = UsageTerm.ordered_by_title
  end

  def show
  end

  def new
    @usage_term = UsageTerm.new
  end

  def create
    @usage_term = UsageTerm.new(usage_term_params)

    if @usage_term.save
      redirect_to admin_usage_term_path(@usage_term), success: t(".success")
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
  end

  def update
    if @usage_term.update(usage_term_params)
      redirect_to admin_usage_term_path(@usage_term), success: t(".success"), status: :see_other
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @usage_term.destroy!
    redirect_to admin_usage_terms_path, success: t(".success"), status: :see_other
  end

  private

    def set_usage_term
      @usage_term = UsageTerm.find(params.expect(:id))
    end

    def usage_term_params
      params.expect(usage_term: [ :title, :content ])
    end

    # Uses the saved title, so a rejected edit keeps the trail pointing to the term as it is.
    def set_breadcrumbs
      add_breadcrumb t("admin.usage_terms.index.breadcrumb"), admin_usage_terms_path

      case action_name
      when "new", "create"
        add_breadcrumb t("admin.usage_terms.new.breadcrumb")
      when "show"
        add_breadcrumb @usage_term.title_in_database
      when "edit", "update"
        add_breadcrumb @usage_term.title_in_database, admin_usage_term_path(@usage_term)
        add_breadcrumb t("admin.usage_terms.edit.breadcrumb")
      end
    end
end
