require "test_helper"

class Admin::SpacePresenterTest < ActiveSupport::TestCase
  setup do
    @campus = create(:campus, name: "Guarapuava")
    @building = create(:building, campus: @campus, name: "Bloco B")
    @department = create(:department, name: "Biblioteca")
  end

  test "shows the building of a space" do
    assert_equal "Bloco B", present(building: @building).building_name
  end

  test "shows a placeholder for a space without building" do
    assert_equal "Sem bloco", present(building: nil).building_name
  end

  test "shows the department, or a placeholder when there is none" do
    assert_equal "Biblioteca", present(department: @department).department_name
    assert_equal "Sem departamento", present(department: nil).department_name
  end

  test "labels whether the reservations need approval" do
    assert_equal "Precisa de aprovação", present(requires_approval: true).approval_label
    assert_equal "Não precisa de aprovação", present(requires_approval: false).approval_label
  end

  test "describes who releases the reservations" do
    assert_equal "Não. As reservas são confirmadas sem liberação.",
                 present(requires_approval: false, department: @department).approval_description
    assert_equal "Sim. As reservas são liberadas pelos usuários do departamento Biblioteca.",
                 present(requires_approval: true, department: @department).approval_description
    assert_equal "Sim. Como o espaço não tem departamento responsável, só os administradores liberam as reservas.",
                 present(requires_approval: true, department: nil).approval_description
  end

  test "labels each status" do
    assert_equal [ "Disponível", "Indisponível", "Desativado" ],
                 [ build(:space), build(:space, :unavailable), build(:space, :deactivated) ].map { |space| Admin::SpacePresenter.new(space).status_label }
  end

  private

    def present(**attributes)
      Admin::SpacePresenter.new(build(:space, campus: @campus, **attributes))
    end
end
