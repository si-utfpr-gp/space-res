require "test_helper"
require "support/helpers/breadcrumb_assertions"

class Admin::SpacesControllerTest < ActionDispatch::IntegrationTest
  include BreadcrumbAssertions

  setup do
    sign_in create(:user, :admin)
    @guarapuava = create(:campus, name: "Guarapuava")
    @bloco_b = create(:building, campus: @guarapuava, name: "Bloco B")
  end

  # Listing

  test "lists spaces ordered by campus, building and name, with the spaces without building last" do
    bloco_c = create(:building, campus: @guarapuava, name: "Bloco C")
    create(:space, campus: @guarapuava, name: "Planetário")
    create(:space, campus: @guarapuava, building: bloco_c, name: "Sala 1")
    create(:space, campus: @guarapuava, building: @bloco_b, name: "Sala 2")
    create(:space, campus: @guarapuava, building: @bloco_b, name: "Sala 1")

    get admin_spaces_path

    assert_response :success
    assert_equal [ [ "Sala 1", "Guarapuava · Bloco B" ], [ "Sala 2", "Guarapuava · Bloco B" ],
                   [ "Sala 1", "Guarapuava · Bloco C" ], [ "Planetário", "Guarapuava · Sem bloco" ] ],
                 listed_spaces
    assert_select "a[href='#{new_admin_space_path}']", text: "Novo espaço"
    assert_no_match(/translation missing/i, response.body)
  end

  test "shows the location, the department and the approval of each space" do
    department = create(:department, name: "Biblioteca")
    lab = create(:space, :requiring_approval, campus: @guarapuava, building: @bloco_b, department: department, name: "Laboratório")
    quadra = create(:space, campus: @guarapuava, name: "Quadra")

    get admin_spaces_path

    assert_select "##{dom_id(lab)}" do
      assert_select "td:nth-child(2)", text: "Guarapuava · Bloco B"
      assert_select "td:nth-child(3)", text: "Biblioteca"
      assert_select "td:nth-child(4)", text: "Precisa de aprovação"
      assert_select "td:first-child li", text: "Guarapuava · Bloco B"
      assert_select "td:first-child li", text: "Biblioteca"
      assert_select "td:first-child li", text: "Precisa de aprovação"
    end
    assert_select "##{dom_id(quadra)}" do
      assert_select "td:nth-child(2)", text: "Guarapuava · Sem bloco"
      assert_select "td:nth-child(3)", text: "Sem departamento"
      assert_select "td:nth-child(4)", text: "Não precisa de aprovação"
    end
  end

  test "marks unavailable and deactivated spaces in the list, in text" do
    available = create(:space, campus: @guarapuava, name: "Sala 1")
    unavailable = create(:space, :unavailable, campus: @guarapuava, name: "Sala 2")
    deactivated = create(:space, :deactivated, campus: @guarapuava, name: "Sala 3")

    get admin_spaces_path

    assert_select "##{dom_id(unavailable)} td:first-child span", text: "Indisponível"
    assert_select "##{dom_id(deactivated)} td:first-child span", text: "Desativado"
    assert_select "##{dom_id(available)} td:first-child span", count: 0
  end

  test "links each space to its page, its edit form and its deletion" do
    space = create(:space, campus: @guarapuava, name: "Sala 1")

    get admin_spaces_path

    assert_select "##{dom_id(space)}" do
      assert_select "td:first-child a[href='#{admin_space_path(space)}']", text: "Sala 1"
      assert_select "a[href='#{admin_space_path(space)}']", text: "Ver"
      assert_select "a[href='#{edit_admin_space_path(space)}']", text: "Editar"
      assert_select "form[action='#{admin_space_path(space)}'][data-turbo-confirm^='Excluir o espaço Sala 1?']" do
        assert_select "input[name='_method'][value='delete']"
        assert_select "button", text: "Excluir"
      end
    end
  end

  test "shows the list title, subtitle and breadcrumbs" do
    get admin_spaces_path

    assert_select "main h1", count: 1, text: "Espaços"
    assert_select "header p", text: "Gerencie as salas, os laboratórios e os outros espaços que podem ser reservados."
    assert_breadcrumbs({ "Dashboard" => users_root_path, "Área administrativa" => admin_root_path }, current: "Espaços")
  end

  test "shows a message when there are no spaces and keeps the new space action" do
    get admin_spaces_path

    assert_response :success
    assert_select "p", text: "Nenhum espaço cadastrado."
    assert_select "table", count: 0
    assert_select "a[href='#{new_admin_space_path}']", text: "Novo espaço"
  end

  test "does not run one query per space to list them" do
    3.times { create(:space, :with_building, department: create(:department)) }

    assert_no_queries_match(/FROM "(campi|buildings|departments)" WHERE/) { get admin_spaces_path }
  end

  # Space page

  test "shows a space with all its data, breadcrumbs and actions" do
    department = create(:department, name: "Biblioteca")
    usage_term = create(:usage_term, title: "Termo do laboratório")
    space = create(:space, :requiring_approval, campus: @guarapuava, building: @bloco_b, department: department,
                   usage_term: usage_term, name: "Laboratório B3", description: "20 computadores.\n1º andar.")

    get admin_space_path(space)

    assert_response :success
    assert_select "main h1", count: 1, text: "Laboratório B3"
    assert_select "header p", text: "Dados do espaço e de como ele é reservado."
    assert_breadcrumbs(spaces_breadcrumbs, current: "Laboratório B3")
    assert_select "#space_details" do
      assert_select "#space_status", text: /Disponível/
      assert_select "dd", text: "Guarapuava"
      assert_select "dd", text: "Bloco B"
      assert_select "dd", text: "Biblioteca"
      assert_select "#space_approval", text: "Sim. As reservas são liberadas pelos usuários do departamento Biblioteca."
      assert_select "#space_usage_term a[href='#{admin_usage_term_path(usage_term)}']", text: "Termo do laboratório"
    end
    assert_equal "20 computadores.\n1º andar.", css_select("#space_description").first.text
    assert_select "#space_description.whitespace-pre-line"
    assert_select "a[href='#{edit_admin_space_path(space)}']", text: "Editar"
    assert_select "form[action='#{admin_space_path(space)}'][data-turbo-confirm^='Excluir o espaço Laboratório B3?']" do
      assert_select "button", text: "Excluir"
    end
    assert_no_match(/translation missing/i, response.body)
  end

  test "tells that only administrators release the reservations of a space without department" do
    space = create(:space, :requiring_approval, campus: @guarapuava, name: "Auditório")

    get admin_space_path(space)

    assert_select "#space_approval",
                  text: "Sim. Como o espaço não tem departamento responsável, só os administradores liberam as reservas."
  end

  test "tells that the reservations of a space without approval are confirmed without release" do
    space = create(:space, campus: @guarapuava, name: "Sala 1")

    get admin_space_path(space)

    assert_select "#space_approval", text: "Não. As reservas são confirmadas sem liberação."
  end

  test "shows the placeholders of a space without building, department and usage term" do
    space = create(:space, campus: @guarapuava, name: "Quadra")

    get admin_space_path(space)

    assert_select "#space_details dd", text: "Sem bloco"
    assert_select "#space_details dd", text: "Sem departamento"
    assert_select "#space_usage_term", text: "Sem termo de uso"
  end

  test "shows HTML typed in the name and in the description as text" do
    space = create(:space, campus: @guarapuava, name: "<b>Sala</b>", description: "<script>alert(1)</script>")

    get admin_space_path(space)

    assert_select "main h1", text: "<b>Sala</b>"
    assert_select "#space_description", text: "<script>alert(1)</script>"
    assert_select "#space_description script", count: 0
  end

  test "responds not found for a space that does not exist" do
    get admin_space_path(id: 0)
    assert_response :not_found

    get edit_admin_space_path(id: 0)
    assert_response :not_found
  end

  # Registration

  test "shows the new space form with the fields in the order of the task" do
    pato_branco = create(:campus, name: "Pato Branco")
    bloco_v = create(:building, campus: pato_branco, name: "Bloco V")
    department = create(:department, name: "Biblioteca")
    usage_term = create(:usage_term, title: "Termo do laboratório")

    get new_admin_space_path

    assert_response :success
    assert_select "main h1", count: 1, text: "Novo espaço"
    assert_select "header p", text: "Preencha as informações do novo espaço."
    assert_breadcrumbs(spaces_breadcrumbs, current: "Novo")
    assert_select "form[action='#{admin_spaces_path}']" do
      assert_equal %w[ space[campus_id] space[building_id] space[name] space[description] space[department_id]
                       space[requires_approval] space[usage_term_id] ],
                   css_select("select, input[type='text'], textarea, input[type='checkbox']").map { |field| field["name"] }
      assert_select "select[name='space[campus_id]']" do
        assert_select "option:nth-child(1)[value='']", text: "Selecione o campus"
        assert_select "option:nth-child(2)[value='#{@guarapuava.id}']", text: "Guarapuava"
        assert_select "option:nth-child(3)[value='#{pato_branco.id}']", text: "Pato Branco"
      end
      assert_select "select[name='space[building_id]']" do
        assert_select "> option[value='']", text: "Sem bloco"
        assert_select "optgroup[label='Guarapuava'][data-filter-key='#{@guarapuava.id}'] option[value='#{@bloco_b.id}']", text: "Bloco B"
        assert_select "optgroup[label='Pato Branco'][data-filter-key='#{pato_branco.id}'] option[value='#{bloco_v.id}']", text: "Bloco V"
      end
      assert_select "input[name='space[name]'][placeholder='Ex.: Laboratório de Informática B3']"
      assert_select "textarea[name='space[description]']"
      assert_select "select[name='space[department_id]']" do
        assert_select "option[value='']", text: "Sem departamento"
        assert_select "option[value='#{department.id}']", text: "Biblioteca"
      end
      assert_select "input[type='checkbox'][name='space[requires_approval]']:not([checked])"
      assert_select "label[for='space_requires_approval']", text: "A reserva precisa de aprovação"
      assert_select ".space_requires_approval p", text: /Sem departamento, só os administradores/
      assert_select "select[name='space[usage_term_id]']" do
        assert_select "option[value='']", text: "Sem termo de uso"
        assert_select "option[value='#{usage_term.id}']", text: "Termo do laboratório"
      end
      assert_select "a[href='#{admin_spaces_path}']", text: "Cancelar"
    end
    assert_no_match(/translation missing/i, response.body)
  end

  test "shows quotes and HTML typed in campus and building names as text in the building select" do
    campus = create(:campus, name: %(Campus "Centro"))
    create(:building, campus: campus, name: "<script>alert(1)</script>")

    get new_admin_space_path

    assert_select "select[name='space[building_id]']" do
      assert_select %(optgroup[label='Campus "Centro"'] option), text: "<script>alert(1)</script>"
      assert_select "script", count: 0
    end
  end

  test "creates a space in a building and shows a confirmation on the list" do
    department = create(:department, name: "Biblioteca")
    usage_term = create(:usage_term)

    assert_difference("Space.count", 1) do
      post admin_spaces_path, params: { space: {
        campus_id: @guarapuava.id, building_id: @bloco_b.id, name: "  Laboratório   B3 ", description: "20 computadores.",
        department_id: department.id, requires_approval: "1", usage_term_id: usage_term.id
      } }
    end

    space = Space.last
    assert_redirected_to admin_spaces_path
    assert_equal [ @guarapuava, @bloco_b, "Laboratório B3", "20 computadores.", department, true, usage_term, true ],
                 [ space.campus, space.building, space.name, space.description, space.department, space.requires_approval,
                   space.usage_term, space.available? ]
    follow_redirect!
    assert_success_toast "Espaço cadastrado com sucesso."
    assert_equal [ [ "Laboratório B3", "Guarapuava · Bloco B" ] ], listed_spaces
  end

  test "creates a space without building, department, approval and usage term" do
    assert_difference("Space.count", 1) do
      post admin_spaces_path, params: { space: {
        campus_id: @guarapuava.id, building_id: "", name: "Quadra poliesportiva", description: "Quadra coberta.",
        department_id: "", requires_approval: "0", usage_term_id: ""
      } }
    end

    space = Space.last
    assert_redirected_to admin_spaces_path
    assert_equal [ nil, nil, false, nil ], [ space.building, space.department, space.requires_approval, space.usage_term ]
  end

  test "ignores a forged status or reason when creating and updating a space" do
    post admin_spaces_path, params: { space: { campus_id: @guarapuava.id, name: "Sala 1", description: "Térreo",
                                               status: "deactivated", unavailability_reason: "Sala em reforma" } }
    space = Space.last
    assert_equal [ "available", nil ], [ space.status, space.unavailability_reason ]

    space.deactivate
    patch admin_space_path(space), params: { space: { name: "Sala 2", status: "available" } }

    assert_equal [ "Sala 2", "deactivated" ], [ space.reload.name, space.status ]
  end

  test "rejects a space without a campus and keeps what was typed" do
    assert_no_difference("Space.count") do
      post admin_spaces_path, params: { space: { campus_id: "", name: "Sala 1", description: "Térreo", requires_approval: "1" } }
    end

    assert_response :unprocessable_content
    assert_select "main h1", text: "Novo espaço"
    assert_breadcrumbs(spaces_breadcrumbs, current: "Novo")
    assert_field_error :campus_id, "Selecione o campus."
    assert_select "input[name='space[name]'][value='Sala 1']"
    assert_select "textarea[name='space[description]']", text: "Térreo"
    assert_select "input[type='checkbox'][name='space[requires_approval]'][checked]"
  end

  test "rejects a space without a name and keeps the chosen campus and building" do
    assert_no_difference("Space.count") do
      post admin_spaces_path, params: { space: { campus_id: @guarapuava.id, building_id: @bloco_b.id, name: "  " } }
    end

    assert_response :unprocessable_content
    assert_field_error :name, "Informe o nome do espaço."
    assert_select "select[name='space[campus_id]'] option[selected][value='#{@guarapuava.id}']"
    assert_select "select[name='space[building_id]'] option[selected][value='#{@bloco_b.id}']"
  end

  test "rejects a space without a description and keeps what was typed" do
    assert_no_difference("Space.count") do
      post admin_spaces_path, params: { space: { campus_id: @guarapuava.id, building_id: @bloco_b.id, name: "Sala 1",
                                                 description: "  " } }
    end

    assert_response :unprocessable_content
    assert_field_error :description, "Informe a descrição do espaço."
    assert_select "input[name='space[name]'][value='Sala 1']"
    assert_select "select[name='space[building_id]'] option[selected][value='#{@bloco_b.id}']"
  end

  test "rejects a building of another campus" do
    pato_branco = create(:campus, name: "Pato Branco")

    assert_no_difference("Space.count") do
      post admin_spaces_path, params: { space: { campus_id: pato_branco.id, building_id: @bloco_b.id, name: "Sala 1" } }
    end

    assert_response :unprocessable_content
    assert_field_error :building_id, "Selecione um bloco do campus escolhido."
  end

  test "rejects a building, a department and a usage term that do not exist" do
    assert_no_difference("Space.count") do
      post admin_spaces_path, params: { space: { campus_id: @guarapuava.id, name: "Sala 1", building_id: 0, department_id: 0, usage_term_id: 0 } }
    end

    assert_response :unprocessable_content
    assert_field_error :building_id, "Selecione um bloco do campus escolhido."
    assert_field_error :department_id, "Selecione um departamento cadastrado."
    assert_field_error :usage_term_id, "Selecione um termo de uso cadastrado."
  end

  test "rejects a blank approval flag sent directly" do
    assert_no_difference("Space.count") do
      post admin_spaces_path, params: { space: { campus_id: @guarapuava.id, name: "Sala 1", requires_approval: "" } }
    end

    assert_response :unprocessable_content
    assert_field_error :requires_approval, "Informe se a reserva precisa de aprovação."
  end

  test "rejects a name already taken in the building and accepts it in another building" do
    create(:space, campus: @guarapuava, building: @bloco_b, name: "Sala 101")
    bloco_c = create(:building, campus: @guarapuava, name: "Bloco C")

    assert_no_difference("Space.count") do
      post admin_spaces_path, params: { space: { campus_id: @guarapuava.id, building_id: @bloco_b.id, name: "sala 101" } }
    end
    assert_response :unprocessable_content
    assert_field_error :name, "Já existe um espaço com este nome neste bloco."

    assert_difference("Space.count", 1) do
      post admin_spaces_path, params: { space: { campus_id: @guarapuava.id, building_id: bloco_c.id, name: "Sala 101",
                                                 description: "Térreo" } }
    end
  end

  test "rejects a name already taken among the spaces without building of the campus" do
    create(:space, campus: @guarapuava, name: "Planetário")

    assert_no_difference("Space.count") do
      post admin_spaces_path, params: { space: { campus_id: @guarapuava.id, building_id: "", name: "PLANETário" } }
    end

    assert_response :unprocessable_content
    assert_field_error :name, "Já existe um espaço sem bloco com este nome neste campus."
  end

  # Editing

  test "shows the edit form with the current values" do
    department = create(:department, name: "Biblioteca")
    space = create(:space, :requiring_approval, campus: @guarapuava, building: @bloco_b, department: department,
                   name: "Laboratório B3", description: "20 computadores.")

    get edit_admin_space_path(space)

    assert_response :success
    assert_select "main h1", count: 1, text: "Editar espaço"
    assert_select "header p", text: "Altere as informações do espaço."
    assert_breadcrumbs(spaces_breadcrumbs.merge("Laboratório B3" => admin_space_path(space)), current: "Editar")
    assert_select "form[action='#{admin_space_path(space)}']" do
      assert_select "select[name='space[campus_id]'] option[selected][value='#{@guarapuava.id}']"
      assert_select "select[name='space[building_id]'] option[selected][value='#{@bloco_b.id}']"
      assert_select "input[name='space[name]'][value='Laboratório B3']"
      assert_select "textarea[name='space[description]']", text: "20 computadores."
      assert_select "select[name='space[department_id]'] option[selected][value='#{department.id}']"
      assert_select "input[type='checkbox'][name='space[requires_approval]'][checked]"
      assert_select "a[href='#{admin_space_path(space)}']", text: "Cancelar"
    end
    assert_no_match(/translation missing/i, response.body)
  end

  test "updates a space and shows a confirmation on the list" do
    department = create(:department, name: "Biblioteca")
    space = create(:space, campus: @guarapuava, building: @bloco_b, name: "Sala 1")

    patch admin_space_path(space), params: { space: { name: "Sala 2", building_id: "", department_id: department.id, requires_approval: "1" } }

    assert_response :see_other
    assert_redirected_to admin_spaces_path
    space.reload
    assert_equal [ "Sala 2", nil, department, true ], [ space.name, space.building, space.department, space.requires_approval ]
    follow_redirect!
    assert_success_toast "Espaço atualizado com sucesso."
  end

  test "keeps the status and the reason of a space when it is edited" do
    unavailable = create(:space, :unavailable, campus: @guarapuava, name: "Sala 1")
    deactivated = create(:space, :deactivated, campus: @guarapuava, name: "Sala 2")

    patch admin_space_path(unavailable), params: { space: { name: "Sala 3" } }
    patch admin_space_path(deactivated), params: { space: { name: "Sala 4" } }

    assert_equal [ "Sala 3", "unavailable", "Sala em reforma" ],
                 [ unavailable.reload.name, unavailable.status, unavailable.unavailability_reason ]
    assert_equal [ "Sala 4", "deactivated" ], [ deactivated.reload.name, deactivated.status ]
  end

  test "rejects renaming a space to a name taken in its building and keeps the saved name in the breadcrumbs" do
    create(:space, campus: @guarapuava, building: @bloco_b, name: "Sala 101")
    space = create(:space, campus: @guarapuava, building: @bloco_b, name: "Sala 102")

    patch admin_space_path(space), params: { space: { name: "sala 101" } }

    assert_response :unprocessable_content
    assert_select "input[name='space[name]'][value='sala 101']"
    assert_breadcrumbs(spaces_breadcrumbs.merge("Sala 102" => admin_space_path(space)), current: "Editar")
    assert_field_error :name, "Já existe um espaço com este nome neste bloco."
    assert_equal "Sala 102", space.reload.name
  end

  test "rejects moving a space to a campus that is not the campus of its building" do
    pato_branco = create(:campus, name: "Pato Branco")
    space = create(:space, campus: @guarapuava, building: @bloco_b, name: "Sala 1")

    patch admin_space_path(space), params: { space: { campus_id: pato_branco.id } }

    assert_response :unprocessable_content
    assert_field_error :building_id, "Selecione um bloco do campus escolhido."
    assert_equal @guarapuava, space.reload.campus
  end

  # Deletion

  test "deletes a space in any status and shows a confirmation on the list" do
    spaces = [ create(:space, campus: @guarapuava, name: "Sala 1"), create(:space, :unavailable, campus: @guarapuava, name: "Sala 2"),
               create(:space, :deactivated, campus: @guarapuava, name: "Sala 3") ]

    assert_difference("Space.count", -3) do
      spaces.each { |space| delete admin_space_path(space) }
    end

    assert_response :see_other
    assert_redirected_to admin_spaces_path
    follow_redirect!
    assert_success_toast "Espaço excluído com sucesso."
    assert_select "p", text: "Nenhum espaço cadastrado."
  end

  test "reminds that the deletion cannot be undone and that the space can be deactivated instead" do
    space = create(:space, campus: @guarapuava, name: "Sala 1")

    get admin_space_path(space)

    assert_select "form[action='#{admin_space_path(space)}']" \
                  "[data-turbo-confirm='Excluir o espaço Sala 1? A exclusão não pode ser desfeita. " \
                  "Para só tirar o espaço de uso, desative-o na página do espaço.']"
  end

  # Status on the space page

  test "offers to mark an available space as unavailable or to deactivate it, with a confirmation" do
    space = create(:space, campus: @guarapuava, name: "Sala 1")

    get admin_space_path(space)

    assert_select "#space_status", text: /O espaço aparece na reserva e pode ser reservado./
    assert_select "#space_unavailability_reason", count: 0
    assert_select "a[href='#{new_admin_space_unavailability_path(space)}']", text: "Marcar como indisponível"
    assert_select "form[action='#{admin_space_deactivation_path(space)}']" \
                  "[data-turbo-confirm='Desativar o espaço Sala 1? Ele deixará de aparecer na reserva. " \
                  "Para impedir as reservas só por um tempo, use \"Marcar como indisponível\".']" do
      assert_select "input[name='_method']", count: 0
      assert_select "button", text: "Desativar"
    end
    assert_select "form[action='#{admin_space_unavailability_path(space)}']", count: 0
    assert_select "button", text: "Reativar", count: 0
    assert_no_match(/translation missing/i, response.body)
  end

  test "shows the reason of an unavailable space and offers to change it, end it or deactivate the space" do
    space = create(:space, :unavailable, campus: @guarapuava, name: "Sala 1")

    get admin_space_path(space)

    assert_select "#space_status", text: /Indisponível/
    assert_select "#space_status", text: /mas não pode ser reservado/
    assert_select "#space_unavailability_reason", text: /Motivo:\s+Sala em reforma/
    assert_select "#space_status a[href='#{edit_admin_space_unavailability_path(space)}']", text: "Alterar motivo"
    assert_select "form[action='#{admin_space_unavailability_path(space)}']" do
      assert_select "input[name='_method'][value='delete']"
      assert_select "button", text: "Tornar disponível"
    end
    assert_select "form[action='#{admin_space_deactivation_path(space)}'] button", text: "Desativar"
    assert_select "a", text: "Marcar como indisponível", count: 0
    assert_no_match(/translation missing/i, response.body)
  end

  test "offers only to reactivate a deactivated space" do
    space = create(:space, :deactivated, campus: @guarapuava, name: "Sala 1")

    get admin_space_path(space)

    assert_select "#space_status", text: /Desativado/
    assert_select "#space_status", text: /O espaço não aparece na reserva. O cadastro continua guardado./
    assert_select "form[action='#{admin_space_deactivation_path(space)}']" do
      assert_select "input[name='_method'][value='delete']"
      assert_select "button", text: "Reativar"
    end
    assert_select "button", text: "Desativar", count: 0
    assert_select "button", text: "Tornar disponível", count: 0
    assert_select "a", text: "Marcar como indisponível", count: 0
    assert_no_match(/translation missing/i, response.body)
  end

  private

    def spaces_breadcrumbs
      { "Dashboard" => users_root_path, "Área administrativa" => admin_root_path, "Espaços" => admin_spaces_path }
    end

    def listed_spaces
      css_select("tbody tr").map do |row|
        [ row.at_css("td:first-child a").text.strip, row.at_css("td:nth-child(2)").text.strip ]
      end
    end

    # The form builder renders each field and its errors inside a wrapper named after the field.
    def assert_field_error(attribute, message)
      assert_select ".space_#{attribute} p.text-red-600", text: message
    end

    def assert_success_toast(message)
      assert_select "[data-controller='ui--toast'][data-ui--toast-message-type-value='success']" \
                    "[data-ui--toast-message-text-value='#{message}']"
    end
end
