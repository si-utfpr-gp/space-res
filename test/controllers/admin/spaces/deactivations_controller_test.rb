require "test_helper"

class Admin::Spaces::DeactivationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in create(:user, :admin)
  end

  test "deactivates a space and shows the new status on its page" do
    space = create(:space, name: "Sala 1")

    post admin_space_deactivation_path(space)

    assert_response :see_other
    assert_redirected_to admin_space_path(space)
    assert space.reload.deactivated?
    follow_redirect!
    assert_success_toast "Espaço desativado. Ele deixa de aparecer na reserva."
    assert_select "#space_status", text: /Desativado/
    assert_select "form[action='#{admin_space_deactivation_path(space)}'] button", text: "Reativar"
  end

  test "deactivates an unavailable space and forgets the reason" do
    space = create(:space, :unavailable)

    post admin_space_deactivation_path(space)

    assert_equal [ "deactivated", nil ], [ space.reload.status, space.unavailability_reason ]
  end

  test "keeps all the data of a space when it is deactivated" do
    department = create(:department)
    space = create(:space, :requiring_approval, :with_building, department: department, name: "Laboratório",
                   description: "20 computadores.")

    post admin_space_deactivation_path(space)

    space.reload
    assert_equal [ department, "Laboratório", "20 computadores.", true ],
                 [ space.department, space.name, space.description, space.requires_approval ]
    assert space.building.present?
  end

  test "reactivates a deactivated space as available" do
    space = create(:space, :deactivated)

    delete admin_space_deactivation_path(space)

    assert_response :see_other
    assert_redirected_to admin_space_path(space)
    assert space.reload.available?
    follow_redirect!
    assert_success_toast "Espaço reativado. Ele volta a aparecer na reserva e pode ser reservado."
    assert_select "#space_status", text: /Disponível/
  end

  test "repeating the deactivation changes nothing and says the space is already deactivated" do
    deactivated = create(:space, :deactivated)

    post admin_space_deactivation_path(deactivated)

    assert_response :see_other
    assert_redirected_to admin_space_path(deactivated)
    assert deactivated.reload.deactivated?
    follow_redirect!
    assert_warning_toast "Nada foi alterado: o espaço está desativado."
  end

  test "does not reactivate a space that is not deactivated, and says why" do
    unavailable = create(:space, :unavailable)

    delete admin_space_deactivation_path(unavailable)

    assert_redirected_to admin_space_path(unavailable)
    assert_equal [ "unavailable", "Sala em reforma" ], [ unavailable.reload.status, unavailable.unavailability_reason ]
    follow_redirect!
    assert_warning_toast "Nada foi alterado: o espaço está indisponível."
  end

  test "responds not found for a space that does not exist" do
    post admin_space_deactivation_path(space_id: 0)
    assert_response :not_found

    delete admin_space_deactivation_path(space_id: 0)
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
