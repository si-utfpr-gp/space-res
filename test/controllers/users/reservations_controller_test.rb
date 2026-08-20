require "test_helper"

class Users::ReservationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in create(:user)
  end

  test "entry point redirects to the earliest incomplete step" do
    get new_users_reservation_path

    assert_redirected_to new_users_reservation_space_path
  end

  test "unknown step is not routable" do
    get "/users/reservations/new/unknown"

    assert_response :not_found
  end

  test "prevents skipping ahead" do
    get new_users_reservation_schedule_path
    assert_redirected_to new_users_reservation_space_path

    get new_users_reservation_confirmation_path
    assert_redirected_to new_users_reservation_space_path
  end

  test "invalid space stays on its URL and renders localized errors" do
    patch users_reservation_step_path(:space), params: { space: { space_id: "" } }

    assert_response :unprocessable_entity
    assert_equal "/users/reservations/new/space", request.path
    assert_select "p", text: "Espaço não pode ficar em branco"
  end

  test "invalid schedule retains entered values and provides a previous link" do
    select_space

    patch users_reservation_step_path(:schedule), params: {
      schedule: { tipo_reserva: "unica", datas: [ "2026-09-01" ], horarios: [ "" ] }
    }

    assert_response :unprocessable_entity
    assert_equal "/users/reservations/new/schedule", request.path
    assert_select "option[value='unica'][selected]"
    assert_select "input[name='schedule[datas][]'][value='2026-09-01']"
    assert_select "p", text: "Horários não pode ficar em branco"
    assert_select "a[href='#{new_users_reservation_space_path}']", text: "Voltar"
    assert_select "form[action*='previous']", count: 0
  end

  test "valid single schedule advances and renders semantic wizard state" do
    select_space
    submit_single_schedule

    assert_redirected_to new_users_reservation_confirmation_path
    follow_redirect!
    assert_response :success
    assert_select "nav[aria-label='Etapas da reserva'] ol"
    assert_select "li[aria-current='step']", count: 1, text: /Confirmação/
    assert_select "a[href='#{new_users_reservation_schedule_path}']", text: "Voltar"
    assert_no_match(/translation missing/i, response.body)
    assert_select "dd", text: "Sala 101"
    assert_select "dd", text: "Reserva única"
    assert_select "dd", text: "M1"
  end

  test "valid recurring schedule advances to confirmation" do
    select_space
    patch users_reservation_step_path(:schedule), params: {
      schedule: {
        tipo_reserva: "recorrente",
        data_inicio: "2026-09-01",
        data_fim: "2026-12-01",
        frequencia: "weekly",
        dias: [ "monday" ],
        horarios: [ "N1" ]
      }
    }

    assert_redirected_to new_users_reservation_confirmation_path
    follow_redirect!
    assert_select "dd", text: "Reserva recorrente"
    assert_select "dd", text: "2026-09-01 – 2026-12-01"
    assert_select "dd", text: "Seg"
  end

  test "changing space clears downstream schedule data" do
    select_space
    submit_single_schedule

    patch users_reservation_step_path(:space), params: { space: { space_id: "2" } }
    assert_redirected_to new_users_reservation_schedule_path

    get new_users_reservation_confirmation_path
    assert_redirected_to new_users_reservation_schedule_path

    get new_users_reservation_path
    assert_redirected_to new_users_reservation_schedule_path
  end

  private

  def select_space
    patch users_reservation_step_path(:space), params: { space: { space_id: "1" } }
    assert_redirected_to new_users_reservation_schedule_path
  end

  def submit_single_schedule
    patch users_reservation_step_path(:schedule), params: {
      schedule: { tipo_reserva: "unica", datas: [ "2026-09-01" ], horarios: [ "M1" ] }
    }
  end
end
