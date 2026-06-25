class Users::ReservationsController < Users::BaseController
  def new
    @reservation = Reservation.new
  end

  def create
    @reservation = Reservation.new(reservation_params)
    if @reservation.save
      redirect_to users_root_path, notice: t("reservations.created")
    else
      render :new, status: :unprocessable_entity
    end
  end
end