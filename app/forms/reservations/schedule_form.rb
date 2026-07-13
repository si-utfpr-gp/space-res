class Reservations::ScheduleForm < BaseForm
  attr_accessor :tipo_reserva, :datas

  def attributes
    { tipo_reserva: tipo_reserva, datas: datas }
  end

  def params
    [ :tipo_reserva, datas: [] ]
  end

  def tipo_reserva_options
    [
      [ I18n.t("reservations.tipo_reserva.unica"), "unica" ],
      [ I18n.t("reservations.tipo_reserva.recorrente"), "recorrente" ]
    ]
  end
end
