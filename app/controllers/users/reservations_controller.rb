class Users::ReservationsController < Users::BaseController
  before_action :load_form, only: [ :new, :step, :update, :create ]

  def index
    redirect_to new_users_reservation_path
  end
  def new
    redirect_to step_path(@form.earliest_incomplete_step)
  end

  def step
    if (prerequisite = @form.prerequisite_for(current_step))
      redirect_to step_path(prerequisite)
    else
      render :new
    end
  end

  def update
    return head :not_found unless Reservations::ReservationForm::EDITABLE_STEPS.include?(current_step)

    if (prerequisite = @form.prerequisite_for(current_step))
      redirect_to step_path(prerequisite)
    elsif @form.update_step(current_step, form_params)
      session[:reservation_form] = @form.to_session
      redirect_to step_path(@form.next_step)
    else
      session[:reservation_form] = @form.to_session
      render :new, status: :unprocessable_entity
    end
  end

  def create
    if (prerequisite = @form.prerequisite_for(:confirmation))
      redirect_to step_path(prerequisite)
    else
      redirect_to new_users_reservation_confirmation_path
    end
  end

  private

  def load_form
    @form = Reservations::ReservationForm.new(
      user: Current.user,
      current_step: params[:step],
      attributes: session[:reservation_form] || {}
    )
  end

  def form_params
    params.expect(current_step => @form.current_form.params)
  rescue ActionController::ParameterMissing
    {}
  end

  def current_step
    params[:step].to_sym
  end

  def step_path(step)
    public_send("new_users_reservation_#{step}_path")
  end
end
