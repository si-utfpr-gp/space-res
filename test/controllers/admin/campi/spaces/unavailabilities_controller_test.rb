require "test_helper"
require "support/helpers/breadcrumb_assertions"

class Admin::Campi::Spaces::UnavailabilitiesControllerTest < ActionDispatch::IntegrationTest
  include BreadcrumbAssertions

  setup do
    sign_in create(:user, :admin)
    @campus = create(:campus, name: "Guarapuava")
    @space = create(:space, campus: @campus, name: "Sala 101")
  end

  # Marking as unavailable

  test "shows the reason form with title, breadcrumbs, hint and the limit of characters" do
    get new_admin_campus_space_unavailability_path(@campus, @space)

    assert_response :success
    assert_select "main h1", text: "Marcar como indisponível"
    assert_select "header p", text: "O espaço Sala 101 vai continuar aparecendo na reserva, mas não poderá ser reservado."
    assert_breadcrumbs(space_breadcrumbs, current: "Indisponibilidade")
    assert_select "form[action='#{admin_campus_space_unavailability_path(@campus, @space)}'][method='post']" do
      assert_select "input[name='_method']", count: 0
      assert_select "label[for='space_unavailability_reason']", text: "Motivo"
      assert_select "input#space_unavailability_reason[maxlength='100'][placeholder='Ex.: Sala em reforma'][autofocus]"
      assert_select "input#space_unavailability_reason[value]", count: 0
      assert_select "p", text: "Aparece para quem tenta reservar o espaço. Até 100 caracteres."
      assert_select "a[href='#{admin_campus_space_path(@campus, @space)}']", text: "Cancelar"
    end
    assert_select "aside nav[aria-label='Menu do campus'] a.active[aria-current='page']", text: /Espaços/
    assert_no_match(/translation missing/i, response.body)
  end

  test "marks the space as unavailable and shows the reason on its page" do
    post admin_campus_space_unavailability_path(@campus, @space), params: { space: { unavailability_reason: "  Sala   em reforma " } }

    assert_redirected_to admin_campus_space_path(@campus, @space)
    @space.reload
    assert_equal [ "unavailable", "Sala em reforma" ], [ @space.status, @space.unavailability_reason ]
    follow_redirect!
    assert_success_toast "Espaço marcado como indisponível. Ele continua aparecendo na reserva, mas não pode ser reservado."
    assert_select "#space_status", text: /Indisponível/
    assert_select "#space_unavailability_reason", text: /Sala em reforma/
  end

  test "refuses a blank reason and keeps the space available" do
    post admin_campus_space_unavailability_path(@campus, @space), params: { space: { unavailability_reason: "   " } }

    assert_response :unprocessable_content
    assert_select "main h1", text: "Marcar como indisponível"
    assert_breadcrumbs(space_breadcrumbs, current: "Indisponibilidade")
    assert_field_error "Informe o motivo da indisponibilidade."
    assert @space.reload.available?
    assert_no_match(/translation missing/i, response.body)
  end

  test "refuses a reason longer than 100 characters and keeps what was typed" do
    reason = "a" * 101

    post admin_campus_space_unavailability_path(@campus, @space), params: { space: { unavailability_reason: reason } }

    assert_response :unprocessable_content
    assert_select "input#space_unavailability_reason[value='#{reason}']"
    assert_field_error "O motivo deve ter no máximo 100 caracteres."
    assert @space.reload.available?
  end

  test "rejects a request without the reason field" do
    post admin_campus_space_unavailability_path(@campus, @space)

    assert_response :bad_request
    assert @space.reload.available?
  end

  # Changing the reason

  test "shows the reason form filled with the current reason" do
    @space.mark_unavailable("Sala em reforma")

    get edit_admin_campus_space_unavailability_path(@campus, @space)

    assert_response :success
    assert_select "main h1", text: "Alterar motivo"
    assert_select "header p", text: "O novo motivo aparece para quem tenta reservar o espaço Sala 101."
    assert_breadcrumbs(space_breadcrumbs, current: "Indisponibilidade")
    assert_select "form[action='#{admin_campus_space_unavailability_path(@campus, @space)}']" do
      assert_select "input[name='_method'][value='patch']"
      assert_select "input#space_unavailability_reason[value='Sala em reforma']"
    end
    assert_no_match(/translation missing/i, response.body)
  end

  test "changes the reason of an unavailable space" do
    @space.mark_unavailable("Sala em reforma")

    patch admin_campus_space_unavailability_path(@campus, @space), params: { space: { unavailability_reason: "Sala em reforma até março" } }

    assert_response :see_other
    assert_redirected_to admin_campus_space_path(@campus, @space)
    assert_equal [ "unavailable", "Sala em reforma até março" ], [ @space.reload.status, @space.unavailability_reason ]
    follow_redirect!
    assert_success_toast "Motivo da indisponibilidade alterado."
  end

  test "refuses a blank new reason and keeps the saved one" do
    @space.mark_unavailable("Sala em reforma")

    patch admin_campus_space_unavailability_path(@campus, @space), params: { space: { unavailability_reason: "" } }

    assert_response :unprocessable_content
    assert_select "main h1", text: "Alterar motivo"
    assert_field_error "Informe o motivo da indisponibilidade."
    assert_equal "Sala em reforma", @space.reload.unavailability_reason
  end

  # Ending the unavailability

  test "makes an unavailable space available again and forgets the reason" do
    @space.mark_unavailable("Sala em reforma")

    delete admin_campus_space_unavailability_path(@campus, @space)

    assert_response :see_other
    assert_redirected_to admin_campus_space_path(@campus, @space)
    assert_equal [ "available", nil ], [ @space.reload.status, @space.unavailability_reason ]
    follow_redirect!
    assert_success_toast "Espaço disponível de novo. Ele pode voltar a ser reservado."
    assert_select "#space_status", text: /Disponível/
    assert_select "#space_unavailability_reason", count: 0
  end

  # Repeated actions and pages opened before another change

  test "does not mark as unavailable a space that is no longer available, and says why" do
    unavailable = create(:space, :unavailable, campus: @campus)
    deactivated = create(:space, :deactivated, campus: @campus)

    post admin_campus_space_unavailability_path(@campus, unavailable), params: { space: { unavailability_reason: "Outro motivo" } }
    assert_redirected_to admin_campus_space_path(@campus, unavailable)
    assert_equal "Sala em reforma", unavailable.reload.unavailability_reason
    follow_redirect!
    assert_warning_toast "Nada foi alterado: o espaço está indisponível."

    post admin_campus_space_unavailability_path(@campus, deactivated), params: { space: { unavailability_reason: "Outro motivo" } }
    assert_redirected_to admin_campus_space_path(@campus, deactivated)
    assert deactivated.reload.deactivated?
    follow_redirect!
    assert_warning_toast "Nada foi alterado: o espaço está desativado."
  end

  test "does not change the reason of a space that is no longer unavailable" do
    deactivated = create(:space, :deactivated, campus: @campus)

    patch admin_campus_space_unavailability_path(@campus, @space), params: { space: { unavailability_reason: "Sala em reforma" } }
    assert_redirected_to admin_campus_space_path(@campus, @space)
    assert_equal [ "available", nil ], [ @space.reload.status, @space.unavailability_reason ]
    follow_redirect!
    assert_warning_toast "Nada foi alterado: o espaço está disponível."

    patch admin_campus_space_unavailability_path(@campus, deactivated), params: { space: { unavailability_reason: "Sala em reforma" } }
    assert deactivated.reload.deactivated?
  end

  test "does not make available a space that is not unavailable" do
    deactivated = create(:space, :deactivated, campus: @campus)

    delete admin_campus_space_unavailability_path(@campus, deactivated)
    assert_response :see_other
    assert_redirected_to admin_campus_space_path(@campus, deactivated)
    assert deactivated.reload.deactivated?
    follow_redirect!
    assert_warning_toast "Nada foi alterado: o espaço está desativado."

    delete admin_campus_space_unavailability_path(@campus, @space)
    assert @space.reload.available?
    follow_redirect!
    assert_warning_toast "Nada foi alterado: o espaço está disponível."
  end

  test "opens the reason forms only for the status they change" do
    get new_admin_campus_space_unavailability_path(@campus, create(:space, :deactivated, campus: @campus))
    assert_response :see_other
    follow_redirect!
    assert_warning_toast "Nada foi alterado: o espaço está desativado."

    get edit_admin_campus_space_unavailability_path(@campus, @space)
    assert_redirected_to admin_campus_space_path(@campus, @space)
    follow_redirect!
    assert_warning_toast "Nada foi alterado: o espaço está disponível."
  end

  test "does not find a space of another campus through this campus" do
    other = create(:space, campus: create(:campus, name: "Pato Branco"), name: "Sala 1")
    unavailable = create(:space, :unavailable, campus: other.campus, name: "Sala 2")
    reason_params = { space: { unavailability_reason: "Outro motivo" } }

    get new_admin_campus_space_unavailability_path(@campus, other)
    assert_response :not_found

    post admin_campus_space_unavailability_path(@campus, other), params: reason_params
    assert_response :not_found

    get edit_admin_campus_space_unavailability_path(@campus, unavailable)
    assert_response :not_found

    patch admin_campus_space_unavailability_path(@campus, unavailable), params: reason_params
    assert_response :not_found

    delete admin_campus_space_unavailability_path(@campus, unavailable)
    assert_response :not_found

    assert_equal [ "available", nil ], [ other.reload.status, other.unavailability_reason ]
    assert_equal [ "unavailable", "Sala em reforma" ], [ unavailable.reload.status, unavailable.unavailability_reason ]
  end

  test "responds not found for a space that does not exist" do
    get new_admin_campus_space_unavailability_path(@campus, space_id: 0)
    assert_response :not_found

    post admin_campus_space_unavailability_path(@campus, space_id: 0), params: { space: { unavailability_reason: "Sala em reforma" } }
    assert_response :not_found

    delete admin_campus_space_unavailability_path(@campus, space_id: 0)
    assert_response :not_found
  end

  private

    def space_breadcrumbs
      { "Dashboard" => users_root_path, "Área administrativa" => admin_root_path, "Guarapuava" => admin_campus_path(@campus),
        "Espaços" => admin_campus_spaces_path(@campus), "Sala 101" => admin_campus_space_path(@campus, @space) }
    end

    def assert_field_error(message)
      assert_select ".space_unavailability_reason p.text-red-600", text: message
    end

    def assert_success_toast(message)
      assert_select "[data-controller='ui--toast'][data-ui--toast-message-type-value='success']" \
                    "[data-ui--toast-message-text-value='#{message}']"
    end

    def assert_warning_toast(message)
      assert_select "[data-controller='ui--toast'][data-ui--toast-message-type-value='warning']" \
                    "[data-ui--toast-message-text-value='#{message}']"
    end
end
