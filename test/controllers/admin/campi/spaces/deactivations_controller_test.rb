require "test_helper"

class Admin::Campi::Spaces::DeactivationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in create(:user, :admin)
    @campus = create(:campus, name: "Guarapuava")
  end

  test "deactivates a space and shows the new status on its page" do
    space = create(:space, campus: @campus, name: "Sala 1")

    post admin_campus_space_deactivation_path(@campus, space)

    assert_response :see_other
    assert_redirected_to admin_campus_space_path(@campus, space)
    assert space.reload.deactivated?
    follow_redirect!
    assert_success_toast "Espaço desativado. Ele deixa de aparecer na reserva."
    assert_select "#space_status", text: /Desativado/
    assert_select "form[action='#{admin_campus_space_deactivation_path(@campus, space)}'] button", text: "Reativar"
  end

  test "deactivates an unavailable space and forgets the reason" do
    space = create(:space, :unavailable, campus: @campus)

    post admin_campus_space_deactivation_path(@campus, space)

    assert_equal [ "deactivated", nil ], [ space.reload.status, space.unavailability_reason ]
  end

  test "keeps all the data of a space when it is deactivated" do
    department = create(:department)
    space = create(:space, :requiring_approval, :with_building, campus: @campus, department: department, name: "Laboratório",
                   description: "20 computadores.")

    post admin_campus_space_deactivation_path(@campus, space)

    space.reload
    assert_equal [ department, "Laboratório", "20 computadores.", true ],
                 [ space.department, space.name, space.description, space.requires_approval ]
    assert space.building.present?
  end

  test "reactivates a deactivated space as available" do
    space = create(:space, :deactivated, campus: @campus)

    delete admin_campus_space_deactivation_path(@campus, space)

    assert_response :see_other
    assert_redirected_to admin_campus_space_path(@campus, space)
    assert space.reload.available?
    follow_redirect!
    assert_success_toast "Espaço reativado. Ele volta a aparecer na reserva e pode ser reservado."
    assert_select "#space_status", text: /Disponível/
  end

  test "repeating the deactivation changes nothing and says the space is already deactivated" do
    deactivated = create(:space, :deactivated, campus: @campus)

    post admin_campus_space_deactivation_path(@campus, deactivated)

    assert_response :see_other
    assert_redirected_to admin_campus_space_path(@campus, deactivated)
    assert deactivated.reload.deactivated?
    follow_redirect!
    assert_warning_toast "Nada foi alterado: o espaço está desativado."
  end

  test "does not reactivate a space that is not deactivated, and says why" do
    unavailable = create(:space, :unavailable, campus: @campus)

    delete admin_campus_space_deactivation_path(@campus, unavailable)

    assert_redirected_to admin_campus_space_path(@campus, unavailable)
    assert_equal [ "unavailable", "Sala em reforma" ], [ unavailable.reload.status, unavailable.unavailability_reason ]
    follow_redirect!
    assert_warning_toast "Nada foi alterado: o espaço está indisponível."
  end

  test "does not find a space of another campus through this campus" do
    other_campus = create(:campus, name: "Pato Branco")
    available = create(:space, campus: other_campus, name: "Sala 1")
    deactivated = create(:space, :deactivated, campus: other_campus, name: "Sala 2")

    post admin_campus_space_deactivation_path(@campus, available)
    assert_response :not_found

    delete admin_campus_space_deactivation_path(@campus, deactivated)
    assert_response :not_found

    assert available.reload.available?
    assert deactivated.reload.deactivated?
  end

  test "responds not found for a space that does not exist" do
    post admin_campus_space_deactivation_path(@campus, space_id: 0)
    assert_response :not_found

    delete admin_campus_space_deactivation_path(@campus, space_id: 0)
    assert_response :not_found
  end

  private

    def assert_success_toast(message)
      assert_select "[data-controller='ui--toast'][data-ui--toast-message-type-value='success']" \
                    "[data-ui--toast-message-text-value='#{message}']"
    end

    def assert_warning_toast(message)
      assert_select "[data-controller='ui--toast'][data-ui--toast-message-type-value='warning']" \
                    "[data-ui--toast-message-text-value='#{message}']"
    end
end
