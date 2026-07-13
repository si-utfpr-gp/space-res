class Users::ReservationsController < Users::BaseController
  before_action :load_form, only: [ :new, :create, :previous ]

  def new; end

  def create
    if @form.update(form_params)
      handle_form_success
    else
      render :new, status: :unprocessable_entity
    end
  end

  def previous
    @form.move_to_previous_step
    session[:reservation_form] = @form.to_session
    redirect_to new_users_reservation_path
  end

  private

  def load_form
    @form = Reservations::ReservationForm.new(
      user: Current.user,
      attributes: session[:reservation_form] || {}
    )
  end

  def form_params
    return {} if @form.current_form.nil?
    params.expect(@form.current_step => @form.current_form.params)
  rescue ActionController::ParameterMissing
    {}
  end

  def handle_form_success
    @form.move_to_next_step
    session[:reservation_form] = @form.to_session

    if @form.completed?
      render :new
    else
      redirect_to new_users_reservation_path
    end
  end
end
