require "test_helper"

class Reservations::ReservationFormTest < ActiveSupport::TestCase
  test "defines the semantic step order" do
    assert_equal %i[space schedule confirmation], Reservations::ReservationForm::STEPS
  end

  test "finds the earliest incomplete step" do
    assert_equal :space, build_form.earliest_incomplete_step
    assert_equal :schedule, build_form(attributes: { space: space_attributes }).earliest_incomplete_step

    form = build_form(attributes: complete_attributes)

    assert_equal :confirmation, form.earliest_incomplete_step
    assert_predicate form, :completed?
  end

  test "finds the first invalid prerequisite for a requested step" do
    assert_nil build_form.prerequisite_for(:space)
    assert_equal :space, build_form.prerequisite_for(:schedule)
    assert_equal :space, build_form.prerequisite_for(:confirmation)

    form = build_form(attributes: { space: space_attributes })

    assert_nil form.prerequisite_for(:schedule)
    assert_equal :schedule, form.prerequisite_for(:confirmation)
    assert_nil build_form(attributes: complete_attributes).prerequisite_for(:confirmation)
  end

  test "updates and hydrates the current form" do
    form = build_form(current_step: :schedule, attributes: { space: space_attributes })

    assert form.update_step(:schedule, schedule_attributes)
    assert_instance_of Reservations::ScheduleForm, form.current_form
    assert_equal "unica", form.current_form.tipo_reserva
    assert_equal [ "2026-09-01" ], form.current_form.datas
    assert_equal [ "M1" ], form.current_form.horarios
  end

  test "changing an earlier step clears downstream data" do
    form = build_form(current_step: :space, attributes: complete_attributes)

    assert form.update_step(:space, { space_id: "2" })
    assert_equal({ space: { space_id: "2" } }, form.to_session)
    assert_equal :schedule, form.earliest_incomplete_step
  end

  test "resubmitting an unchanged earlier step preserves downstream data" do
    form = build_form(current_step: :space, attributes: complete_attributes)

    assert form.update_step(:space, space_attributes)
    assert_equal complete_attributes, form.to_session
  end

  test "serializes only editable step data without exposing internal state" do
    form = build_form(
      current_step: :schedule,
      attributes: complete_attributes.merge(current_step: :confirmation, ignored: "value")
    )
    session_data = form.to_session

    assert_equal complete_attributes, session_data
    assert_not session_data.key?(:current_step)
    assert_not session_data.key?(:ignored)
    assert_not_same session_data, form.to_session
  end

  test "exposes confirmation data through hydrated forms" do
    form = build_form(attributes: complete_attributes)

    assert_equal "Sala 101", form.selected_space[:name]
    assert_instance_of Reservations::ScheduleForm, form.schedule
    assert_equal "unica", form.schedule.tipo_reserva
    assert_equal [ "2026-09-01" ], form.schedule.datas
    assert_equal [ "M1" ], form.schedule.horarios
  end

  test "reports navigation and completion state" do
    space_form = build_form(current_step: :space, attributes: complete_attributes)
    schedule_form = build_form(current_step: :schedule, attributes: complete_attributes)
    confirmation_form = build_form(current_step: :confirmation, attributes: complete_attributes)

    assert_nil space_form.previous_step
    assert_equal :schedule, space_form.next_step
    assert_not space_form.final_step?

    assert_equal :space, schedule_form.previous_step
    assert_equal :confirmation, schedule_form.next_step
    assert_predicate schedule_form, :final_step?

    assert_equal :schedule, confirmation_form.previous_step
    assert confirmation_form.step_complete?(:space)
    assert confirmation_form.step_complete?(:schedule)
    assert confirmation_form.step_complete?(:confirmation)
  end

  private

  def build_form(current_step: nil, attributes: {})
    Reservations::ReservationForm.new(user: Object.new, current_step: current_step, attributes: attributes)
  end

  def complete_attributes
    { space: space_attributes, schedule: schedule_attributes }
  end

  def space_attributes
    { space_id: "1" }
  end

  def schedule_attributes
    { tipo_reserva: "unica", datas: [ "2026-09-01" ], horarios: [ "M1" ] }
  end
end
