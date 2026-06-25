class Users::ReservationsController < Users::BaseController
  def new
    session[:reservation] ||= {}
    @step = params[:step]&.to_i || 1
    @spaces = Space.where(status: true)
  end

  def create
    @step = params[:step].to_i
    session[:reservation] ||= {}

    case @step
    when 1
      session[:reservation]["space_id"] = params[:space_id]
      redirect_to new_users_reservation_path(step: 2)

    when 2
      session[:reservation]["tipo_reserva"] = params[:tipo_reserva]
      session[:reservation]["datas"] = params[:datas]
      redirect_to new_users_reservation_path(step: 3)

    when 3
      @reservation = Reservation.new(
        space_id:     session[:reservation]["space_id"],
        tipo_reserva: session[:reservation]["tipo_reserva"],
        status:       "draft",
        user:         Current.user
      )
      
      if @reservation.save
        session.delete(:reservation)
        redirect_to users_root_path, notice: t("reservations.created")
      else
        redirect_to new_users_reservation_path(step: 1)
      end
    end
  end
end