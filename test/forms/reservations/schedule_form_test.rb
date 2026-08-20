require "test_helper"

class Reservations::ScheduleFormTest < ActiveSupport::TestCase
  test "requires type, event date, and a time slot for a single reservation" do
    form = Reservations::ScheduleForm.new(tipo_reserva: "unica", datas: [ "" ], horarios: [ "" ])

    assert_not form.valid?
    assert form.errors.added?(:datas, :blank)
    assert form.errors.added?(:horarios, :blank)
  end

  test "accepts a complete single reservation" do
    form = Reservations::ScheduleForm.new(
      tipo_reserva: "unica", datas: [ "2026-09-01" ], horarios: [ "M1" ]
    )

    assert form.valid?
  end

  test "requires date range, frequency, weekdays, and time slots for a recurring reservation" do
    form = Reservations::ScheduleForm.new(
      tipo_reserva: "recorrente", dias: [ "" ], horarios: [ "" ]
    )

    assert_not form.valid?
    assert form.errors.added?(:data_inicio, :blank)
    assert form.errors.added?(:data_fim, :blank)
    assert form.errors.added?(:frequencia, :blank)
    assert form.errors.added?(:dias, :blank)
    assert form.errors.added?(:horarios, :blank)
  end

  test "accepts a complete recurring reservation" do
    form = Reservations::ScheduleForm.new(
      tipo_reserva: "recorrente",
      data_inicio: "2026-09-01",
      data_fim: "2026-12-01",
      frequencia: "weekly",
      dias: [ "monday" ],
      horarios: [ "N1" ]
    )

    assert form.valid?
  end
end
