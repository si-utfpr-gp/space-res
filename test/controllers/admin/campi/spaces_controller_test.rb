require "test_helper"
require "support/helpers/breadcrumb_assertions"

class Admin::Campi::SpacesControllerTest < ActionDispatch::IntegrationTest
  include BreadcrumbAssertions

  setup do
    sign_in create(:user, :admin)
    @guarapuava = create(:campus, name: "Guarapuava")
    @pato_branco = create(:campus, name: "Pato Branco")
    @bloco_b = create(:building, campus: @guarapuava, name: "Bloco B")
  end

  # Listing

  test "lists only the spaces of the campus, ordered by building and name, with the spaces without building last" do
    create(:space, campus: @pato_branco, name: "Sala de Pato Branco")
    bloco_c = create(:building, campus: @guarapuava, name: "Bloco C")
    create(:space, campus: @guarapuava, name: "Planetário")
    create(:space, campus: @guarapuava, building: bloco_c, name: "Sala 1")
    create(:space, campus: @guarapuava, building: @bloco_b, name: "Sala 2")
    create(:space, campus: @guarapuava, building: @bloco_b, name: "Sala 1")

    get admin_campus_spaces_path(@guarapuava)

    assert_response :success
    assert_equal [ [ "Sala 1", "Bloco B" ], [ "Sala 2", "Bloco B" ], [ "Sala 1", "Bloco C" ], [ "Planetário", "Sem bloco" ] ],
                 listed_spaces
    assert_select "a[href='#{new_admin_campus_space_path(@guarapuava)}']", text: "Novo espaço"
    assert_no_match(/translation missing/i, response.body)
  end

  test "shows the building, the department and the approval of each space" do
    department = create(:department, name: "Biblioteca")
    lab = create(:space, :requiring_approval, campus: @guarapuava, building: @bloco_b, department: department, name: "Laboratório")
    quadra = create(:space, campus: @guarapuava, name: "Quadra")

    get admin_campus_spaces_path(@guarapuava)

    assert_select "##{dom_id(lab)}" do
      assert_select "td:nth-child(2)", text: "Bloco B"
      assert_select "td:nth-child(3)", text: "Biblioteca"
      assert_select "td:nth-child(4)", text: "Precisa de aprovação"
      assert_select "td:first-child li", text: "Bloco B"
      assert_select "td:first-child li", text: "Biblioteca"
      assert_select "td:first-child li", text: "Precisa de aprovação"
    end
    assert_select "##{dom_id(quadra)}" do
      assert_select "td:nth-child(2)", text: "Sem bloco"
      assert_select "td:nth-child(3)", text: "Sem departamento"
      assert_select "td:nth-child(4)", text: "Não precisa de aprovação"
    end
  end

  test "marks unavailable and deactivated spaces in the list, in text" do
    available = create(:space, campus: @guarapuava, name: "Sala 1")
    unavailable = create(:space, :unavailable, campus: @guarapuava, name: "Sala 2")
    deactivated = create(:space, :deactivated, campus: @guarapuava, name: "Sala 3")

    get admin_campus_spaces_path(@guarapuava)

    assert_select "##{dom_id(unavailable)} td:first-child span", text: "Indisponível"
    assert_select "##{dom_id(deactivated)} td:first-child span", text: "Desativado"
    assert_select "##{dom_id(available)} td:first-child span", count: 0
  end

  test "links each space to its page, its edit form and its deletion" do
    space = create(:space, campus: @guarapuava, name: "Sala 1")

    get admin_campus_spaces_path(@guarapuava)

    assert_select "##{dom_id(space)}" do
      assert_select "td:first-child a[href='#{admin_campus_space_path(@guarapuava, space)}']", text: "Sala 1"
      assert_select "a[href='#{admin_campus_space_path(@guarapuava, space)}']", text: "Ver"
      assert_select "a[href='#{edit_admin_campus_space_path(@guarapuava, space)}']", text: "Editar"
      assert_select "form[action='#{admin_campus_space_path(@guarapuava, space)}'][data-turbo-confirm^='Excluir o espaço Sala 1?']" do
        assert_select "input[name='_method'][value='delete']"
        assert_select "button", text: "Excluir"
      end
    end
  end

  test "shows the list title, subtitle and breadcrumbs" do
    get admin_campus_spaces_path(@guarapuava)

    assert_select "main h1", count: 1, text: "Espaços"
    assert_select "header p",
                  text: "Gerencie as salas, os laboratórios e os outros espaços do campus Guarapuava que podem ser reservados."
    assert_breadcrumbs(campus_breadcrumbs, current: "Espaços")
  end

  test "names the building column Bloco and has no campus column" do
    create(:space, campus: @guarapuava, name: "Sala 1")

    get admin_campus_spaces_path(@guarapuava)

    assert_select "th", text: "Bloco"
    assert_select "th", text: "Localização", count: 0
    assert_select "th", text: "Campus", count: 0
  end

  test "marks the spaces as the current section of the campus menu on the listing, the space pages and the forms" do
    space = create(:space, campus: @guarapuava, name: "Sala 1")

    [ admin_campus_spaces_path(@guarapuava), admin_campus_space_path(@guarapuava, space),
      new_admin_campus_space_path(@guarapuava), edit_admin_campus_space_path(@guarapuava, space) ].each do |path|
      get path

      assert_select "aside nav[aria-label='Menu do campus'] a.active[aria-current='page']", { text: /Espaços/ }, path
    end
  end

  test "shows a message when there are no spaces and keeps the new space action" do
    get admin_campus_spaces_path(@guarapuava)

    assert_response :success
    assert_select "p", text: "Nenhum espaço cadastrado neste campus."
    assert_select "table", count: 0
    assert_select "a[href='#{new_admin_campus_space_path(@guarapuava)}']", text: "Novo espaço"
  end

  test "shows the empty message when only other campi have spaces" do
    create(:space, campus: @pato_branco, name: "Sala 1")

    get admin_campus_spaces_path(@guarapuava)

    assert_select "p", text: "Nenhum espaço cadastrado neste campus."
    assert_select "table", count: 0
  end

  test "does not run one query per space to list them" do
    create(:space, :with_building, campus: @guarapuava, department: create(:department))
    get admin_campus_spaces_path(@guarapuava)
    queries_for_one = count_queries { get admin_campus_spaces_path(@guarapuava) }
    3.times { create(:space, :with_building, campus: @guarapuava, department: create(:department)) }

    assert_equal queries_for_one, count_queries { get admin_campus_spaces_path(@guarapuava) }
  end

  # Space page

  test "shows a space with all its data, breadcrumbs and actions" do
    department = create(:department, name: "Biblioteca")
    usage_term = create(:usage_term, title: "Termo do laboratório")
    space = create(:space, :requiring_approval, campus: @guarapuava, building: @bloco_b, department: department,
                   usage_term: usage_term, name: "Laboratório B3", description: "20 computadores.\n1º andar.")

    get admin_campus_space_path(@guarapuava, space)

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
    assert_select "a[href='#{edit_admin_campus_space_path(@guarapuava, space)}']", text: "Editar"
    assert_select "form[action='#{admin_campus_space_path(@guarapuava, space)}'][data-turbo-confirm^='Excluir o espaço Laboratório B3?']" do
      assert_select "button", text: "Excluir"
    end
    assert_no_match(/translation missing/i, response.body)
  end

  test "tells that only administrators release the reservations of a space without department" do
    space = create(:space, :requiring_approval, campus: @guarapuava, name: "Auditório")

    get admin_campus_space_path(@guarapuava, space)

    assert_select "#space_approval",
                  text: "Sim. Como o espaço não tem departamento responsável, só os administradores liberam as reservas."
  end

  test "tells that the reservations of a space without approval are confirmed without release" do
    space = create(:space, campus: @guarapuava, name: "Sala 1")

    get admin_campus_space_path(@guarapuava, space)

    assert_select "#space_approval", text: "Não. As reservas são confirmadas sem liberação."
  end

  test "shows the placeholders of a space without building, department and usage term" do
    space = create(:space, campus: @guarapuava, name: "Quadra")

    get admin_campus_space_path(@guarapuava, space)

    assert_select "#space_details dd", text: "Sem bloco"
    assert_select "#space_details dd", text: "Sem departamento"
    assert_select "#space_usage_term", text: "Sem termo de uso"
  end

  test "shows HTML typed in the name and in the description as text" do
    space = create(:space, campus: @guarapuava, name: "<b>Sala</b>", description: "<script>alert(1)</script>")

    get admin_campus_space_path(@guarapuava, space)

    assert_select "main h1", text: "<b>Sala</b>"
    assert_select "#space_description", text: "<script>alert(1)</script>"
    assert_select "#space_description script", count: 0
  end

  test "responds not found for a space or a campus that does not exist" do
    [ admin_campus_space_path(@guarapuava, id: 0), edit_admin_campus_space_path(@guarapuava, id: 0),
      admin_campus_spaces_path(campus_id: 0), new_admin_campus_space_path(campus_id: 0) ].each do |path|
      get path

      assert_response :not_found, path
    end
  end

  test "does not find a space of another campus through this campus" do
    space = create(:space, campus: @pato_branco, name: "Sala 1")

    get admin_campus_space_path(@guarapuava, space)
    assert_response :not_found

    get edit_admin_campus_space_path(@guarapuava, space)
    assert_response :not_found

    patch admin_campus_space_path(@guarapuava, space), params: { space: { name: "Sala 2" } }
    assert_response :not_found

    assert_no_difference("Space.count") { delete admin_campus_space_path(@guarapuava, space) }
    assert_response :not_found

    assert_equal [ @pato_branco, "Sala 1" ], [ space.reload.campus, space.name ]
  end

  # Registration

  test "shows the new space form with the campus line and the fields in the order of the task" do
    create(:building, campus: @guarapuava, name: "Bloco A")
    create(:building, campus: @pato_branco, name: "Bloco V")
    department = create(:department, name: "Biblioteca")
    usage_term = create(:usage_term, title: "Termo do laboratório")

    get new_admin_campus_space_path(@guarapuava)

    assert_response :success
    assert_select "main h1", count: 1, text: "Novo espaço"
    assert_select "header p", text: "Preencha as informações do novo espaço do campus Guarapuava."
    assert_breadcrumbs(spaces_breadcrumbs, current: "Novo")
    assert_select "form[action='#{admin_campus_spaces_path(@guarapuava)}']" do
      assert_select "p#space_campus", text: "Campus Guarapuava"
      assert_select "p#space_campus strong", text: "Guarapuava"
      assert_equal %w[ space[building_id] space[name] space[description] space[department_id]
                       space[requires_approval] space[usage_term_id] ],
                   css_select("select, input[type='text'], textarea, input[type='checkbox']").map { |field| field["name"] }
      assert_select "select[name='space[campus_id]']", count: 0
      assert_select "input[name='space[campus_id]']", count: 0
      assert_select "select[name='space[building_id]']" do
        assert_equal [ "Sem bloco", "Bloco A", "Bloco B" ], css_select("select[name='space[building_id]'] > option").map { |option| option.text.strip }
        assert_select "option:nth-child(1)[value='']", text: "Sem bloco"
        assert_select "optgroup", count: 0
        assert_select "option[data-filter-key]", count: 0
        assert_select "option", text: "Bloco V", count: 0
      end
      assert_select "p", text: 'Só aparecem os blocos deste campus. Escolha "Sem bloco" para espaços fora de blocos, como a quadra e o planetário.'
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
      assert_select "a[href='#{admin_campus_spaces_path(@guarapuava)}']", text: "Cancelar"
    end
    assert_select "aside nav[aria-label='Menu do campus'] a.active[aria-current='page']", text: /Espaços/
    assert_no_match(/translation missing/i, response.body)
  end

  test "shows quotes and HTML typed in the campus and building names as text" do
    campus = create(:campus, name: %(Campus "Centro"))
    create(:building, campus: campus, name: "<script>alert(1)</script>")

    get new_admin_campus_space_path(campus)

    assert_select "p#space_campus strong", text: %(Campus "Centro")
    assert_select "select[name='space[building_id]']" do
      assert_select "option", text: "<script>alert(1)</script>"
      assert_select "script", count: 0
    end
  end

  test "creates a space in a building and shows a confirmation on the list" do
    department = create(:department, name: "Biblioteca")
    usage_term = create(:usage_term)

    assert_difference("Space.count", 1) do
      post admin_campus_spaces_path(@guarapuava), params: { space: {
        building_id: @bloco_b.id, name: "  Laboratório   B3 ", description: "20 computadores.",
        department_id: department.id, requires_approval: "1", usage_term_id: usage_term.id
      } }
    end

    space = Space.last
    assert_redirected_to admin_campus_spaces_path(@guarapuava)
    assert_equal [ @guarapuava, @bloco_b, "Laboratório B3", "20 computadores.", department, true, usage_term, true ],
                 [ space.campus, space.building, space.name, space.description, space.department, space.requires_approval,
                   space.usage_term, space.available? ]
    follow_redirect!
    assert_success_toast "Espaço cadastrado com sucesso."
    assert_equal [ [ "Laboratório B3", "Bloco B" ] ], listed_spaces
  end

  test "creates a space without building, department, approval and usage term" do
    assert_difference("Space.count", 1) do
      post admin_campus_spaces_path(@guarapuava), params: { space: {
        building_id: "", name: "Quadra poliesportiva", description: "Quadra coberta.",
        department_id: "", requires_approval: "0", usage_term_id: ""
      } }
    end

    space = Space.last
    assert_redirected_to admin_campus_spaces_path(@guarapuava)
    assert_equal [ nil, nil, false, nil ], [ space.building, space.department, space.requires_approval, space.usage_term ]
  end

  test "ignores a forged status or reason when creating and updating a space" do
    post admin_campus_spaces_path(@guarapuava), params: { space: { name: "Sala 1", description: "Térreo",
                                               status: "deactivated", unavailability_reason: "Sala em reforma" } }
    space = Space.last
    assert_equal [ "available", nil ], [ space.status, space.unavailability_reason ]

    space.deactivate
    patch admin_campus_space_path(@guarapuava, space), params: { space: { name: "Sala 2", status: "available" } }

    assert_equal [ "Sala 2", "deactivated" ], [ space.reload.name, space.status ]
  end

  test "ignores a campus sent when creating a space" do
    assert_difference("@guarapuava.spaces.count", 1) do
      post admin_campus_spaces_path(@guarapuava), params: { space: { campus_id: @pato_branco.id, name: "Sala 1", description: "Térreo" } }
    end

    assert_redirected_to admin_campus_spaces_path(@guarapuava)
    assert_equal @guarapuava, Space.find_by!(name: "Sala 1").campus
    assert_empty @pato_branco.spaces
  end

  test "keeps what was typed when the space is rejected" do
    assert_no_difference("Space.count") do
      post admin_campus_spaces_path(@guarapuava), params: { space: { name: "", description: "Térreo", requires_approval: "1" } }
    end

    assert_response :unprocessable_content
    assert_select "main h1", text: "Novo espaço"
    assert_select "p#space_campus strong", text: "Guarapuava"
    assert_breadcrumbs(spaces_breadcrumbs, current: "Novo")
    assert_select "textarea[name='space[description]']", text: "Térreo"
    assert_select "input[type='checkbox'][name='space[requires_approval]'][checked]"
  end

  test "rejects a space without a name and keeps the chosen building" do
    assert_no_difference("Space.count") do
      post admin_campus_spaces_path(@guarapuava), params: { space: { building_id: @bloco_b.id, name: "  " } }
    end

    assert_response :unprocessable_content
    assert_field_error :name, "Informe o nome do espaço."
    assert_select "select[name='space[building_id]'] option[selected][value='#{@bloco_b.id}']"
  end

  test "rejects a space without a description and keeps what was typed" do
    assert_no_difference("Space.count") do
      post admin_campus_spaces_path(@guarapuava), params: { space: { building_id: @bloco_b.id, name: "Sala 1", description: "  " } }
    end

    assert_response :unprocessable_content
    assert_field_error :description, "Informe a descrição do espaço."
    assert_select "input[name='space[name]'][value='Sala 1']"
    assert_select "select[name='space[building_id]'] option[selected][value='#{@bloco_b.id}']"
  end

  test "rejects a building of another campus, even with the campus of the building sent" do
    bloco_v = create(:building, campus: @pato_branco, name: "Bloco V")

    assert_no_difference("Space.count") do
      post admin_campus_spaces_path(@guarapuava), params: { space: { campus_id: @pato_branco.id, building_id: bloco_v.id, name: "Sala 1" } }
    end

    assert_response :unprocessable_content
    assert_field_error :building_id, "Selecione um bloco deste campus."
    assert_equal [], Space.pluck(:name)
  end

  test "rejects a building, a department and a usage term that do not exist" do
    assert_no_difference("Space.count") do
      post admin_campus_spaces_path(@guarapuava), params: { space: { name: "Sala 1", building_id: 0, department_id: 0, usage_term_id: 0 } }
    end

    assert_response :unprocessable_content
    assert_field_error :building_id, "Selecione um bloco deste campus."
    assert_field_error :department_id, "Selecione um departamento cadastrado."
    assert_field_error :usage_term_id, "Selecione um termo de uso cadastrado."
  end

  test "rejects a blank approval flag sent directly" do
    assert_no_difference("Space.count") do
      post admin_campus_spaces_path(@guarapuava), params: { space: { name: "Sala 1", requires_approval: "" } }
    end

    assert_response :unprocessable_content
    assert_field_error :requires_approval, "Informe se a reserva precisa de aprovação."
  end

  test "rejects a name already taken in the building and accepts it in another building" do
    create(:space, campus: @guarapuava, building: @bloco_b, name: "Sala 101")
    bloco_c = create(:building, campus: @guarapuava, name: "Bloco C")

    assert_no_difference("Space.count") do
      post admin_campus_spaces_path(@guarapuava), params: { space: { building_id: @bloco_b.id, name: "sala 101" } }
    end
    assert_response :unprocessable_content
    assert_field_error :name, "Já existe um espaço com este nome neste bloco."

    assert_difference("Space.count", 1) do
      post admin_campus_spaces_path(@guarapuava), params: { space: { building_id: bloco_c.id, name: "Sala 101", description: "Térreo" } }
    end
  end

  test "rejects a name already taken among the spaces without building of the campus" do
    create(:space, campus: @guarapuava, name: "Planetário")

    assert_no_difference("Space.count") do
      post admin_campus_spaces_path(@guarapuava), params: { space: { building_id: "", name: "PLANETário" } }
    end

    assert_response :unprocessable_content
    assert_field_error :name, "Já existe um espaço sem bloco com este nome neste campus."
  end

  # Editing

  test "shows the edit form with the current values" do
    department = create(:department, name: "Biblioteca")
    space = create(:space, :requiring_approval, campus: @guarapuava, building: @bloco_b, department: department,
                   name: "Laboratório B3", description: "20 computadores.")

    get edit_admin_campus_space_path(@guarapuava, space)

    assert_response :success
    assert_select "main h1", count: 1, text: "Editar espaço"
    assert_select "header p", text: "Altere as informações do espaço do campus Guarapuava."
    assert_breadcrumbs(spaces_breadcrumbs.merge("Laboratório B3" => admin_campus_space_path(@guarapuava, space)), current: "Editar")
    assert_select "form[action='#{admin_campus_space_path(@guarapuava, space)}']" do
      assert_select "p#space_campus strong", text: "Guarapuava"
      assert_select "select[name='space[campus_id]']", count: 0
      assert_select "select[name='space[building_id]'] option[selected][value='#{@bloco_b.id}']"
      assert_select "input[name='space[name]'][value='Laboratório B3']"
      assert_select "textarea[name='space[description]']", text: "20 computadores."
      assert_select "select[name='space[department_id]'] option[selected][value='#{department.id}']"
      assert_select "input[type='checkbox'][name='space[requires_approval]'][checked]"
      assert_select "a[href='#{admin_campus_space_path(@guarapuava, space)}']", text: "Cancelar"
    end
    assert_no_match(/translation missing/i, response.body)
  end

  test "updates a space and shows a confirmation on the list" do
    department = create(:department, name: "Biblioteca")
    space = create(:space, campus: @guarapuava, building: @bloco_b, name: "Sala 1")

    patch admin_campus_space_path(@guarapuava, space), params: { space: { name: "Sala 2", building_id: "", department_id: department.id, requires_approval: "1" } }

    assert_response :see_other
    assert_redirected_to admin_campus_spaces_path(@guarapuava)
    space.reload
    assert_equal [ "Sala 2", nil, department, true ], [ space.name, space.building, space.department, space.requires_approval ]
    follow_redirect!
    assert_success_toast "Espaço atualizado com sucesso."
  end

  test "keeps the status and the reason of a space when it is edited" do
    unavailable = create(:space, :unavailable, campus: @guarapuava, name: "Sala 1")
    deactivated = create(:space, :deactivated, campus: @guarapuava, name: "Sala 2")

    patch admin_campus_space_path(@guarapuava, unavailable), params: { space: { name: "Sala 3" } }
    patch admin_campus_space_path(@guarapuava, deactivated), params: { space: { name: "Sala 4" } }

    assert_equal [ "Sala 3", "unavailable", "Sala em reforma" ],
                 [ unavailable.reload.name, unavailable.status, unavailable.unavailability_reason ]
    assert_equal [ "Sala 4", "deactivated" ], [ deactivated.reload.name, deactivated.status ]
  end

  test "rejects renaming a space to a name taken in its building and keeps the saved name in the breadcrumbs" do
    create(:space, campus: @guarapuava, building: @bloco_b, name: "Sala 101")
    space = create(:space, campus: @guarapuava, building: @bloco_b, name: "Sala 102")

    patch admin_campus_space_path(@guarapuava, space), params: { space: { name: "sala 101" } }

    assert_response :unprocessable_content
    assert_select "input[name='space[name]'][value='sala 101']"
    assert_breadcrumbs(spaces_breadcrumbs.merge("Sala 102" => admin_campus_space_path(@guarapuava, space)), current: "Editar")
    assert_field_error :name, "Já existe um espaço com este nome neste bloco."
    assert_equal "Sala 102", space.reload.name
  end

  test "keeps the campus of a space when another campus is sent" do
    space = create(:space, campus: @guarapuava, building: @bloco_b, name: "Sala 1")

    patch admin_campus_space_path(@guarapuava, space), params: { space: { campus_id: @pato_branco.id, name: "Sala 2" } }

    assert_redirected_to admin_campus_spaces_path(@guarapuava)
    assert_equal [ @guarapuava, @bloco_b, "Sala 2" ], [ space.reload.campus, space.building, space.name ]
  end

  test "rejects moving a space to a building of another campus" do
    bloco_v = create(:building, campus: @pato_branco, name: "Bloco V")
    space = create(:space, campus: @guarapuava, building: @bloco_b, name: "Sala 1")

    patch admin_campus_space_path(@guarapuava, space), params: { space: { building_id: bloco_v.id } }

    assert_response :unprocessable_content
    assert_field_error :building_id, "Selecione um bloco deste campus."
    assert_equal [ @guarapuava, @bloco_b ], [ space.reload.campus, space.building ]
  end

  # Deletion

  test "deletes a space in any status and shows a confirmation on the list" do
    spaces = [ create(:space, campus: @guarapuava, name: "Sala 1"), create(:space, :unavailable, campus: @guarapuava, name: "Sala 2"),
               create(:space, :deactivated, campus: @guarapuava, name: "Sala 3") ]

    assert_difference("Space.count", -3) do
      spaces.each { |space| delete admin_campus_space_path(@guarapuava, space) }
    end

    assert_response :see_other
    assert_redirected_to admin_campus_spaces_path(@guarapuava)
    follow_redirect!
    assert_success_toast "Espaço excluído com sucesso."
    assert_select "p", text: "Nenhum espaço cadastrado neste campus."
  end

  test "reminds that the deletion cannot be undone and that the space can be deactivated instead" do
    space = create(:space, campus: @guarapuava, name: "Sala 1")

    get admin_campus_space_path(@guarapuava, space)

    assert_select "form[action='#{admin_campus_space_path(@guarapuava, space)}']" \
                  "[data-turbo-confirm='Excluir o espaço Sala 1? A exclusão não pode ser desfeita. " \
                  "Para só tirar o espaço de uso, desative-o na página do espaço.']"
  end

  # Status on the space page

  test "offers to mark an available space as unavailable or to deactivate it, with a confirmation" do
    space = create(:space, campus: @guarapuava, name: "Sala 1")

    get admin_campus_space_path(@guarapuava, space)

    assert_select "#space_status", text: /O espaço aparece na reserva e pode ser reservado./
    assert_select "#space_unavailability_reason", count: 0
    assert_select "a[href='#{new_admin_campus_space_unavailability_path(@guarapuava, space)}']", text: "Marcar como indisponível"
    assert_select "form[action='#{admin_campus_space_deactivation_path(@guarapuava, space)}']" \
                  "[data-turbo-confirm='Desativar o espaço Sala 1? Ele deixará de aparecer na reserva. " \
                  "Para impedir as reservas só por um tempo, use \"Marcar como indisponível\".']" do
      assert_select "input[name='_method']", count: 0
      assert_select "button", text: "Desativar"
    end
    assert_select "form[action='#{admin_campus_space_unavailability_path(@guarapuava, space)}']", count: 0
    assert_select "button", text: "Reativar", count: 0
    assert_no_match(/translation missing/i, response.body)
  end

  test "shows the reason of an unavailable space and offers to change it, end it or deactivate the space" do
    space = create(:space, :unavailable, campus: @guarapuava, name: "Sala 1")

    get admin_campus_space_path(@guarapuava, space)

    assert_select "#space_status", text: /Indisponível/
    assert_select "#space_status", text: /mas não pode ser reservado/
    assert_select "#space_unavailability_reason", text: /Motivo:\s+Sala em reforma/
    assert_select "#space_status a[href='#{edit_admin_campus_space_unavailability_path(@guarapuava, space)}']", text: "Alterar motivo"
    assert_select "form[action='#{admin_campus_space_unavailability_path(@guarapuava, space)}']" do
      assert_select "input[name='_method'][value='delete']"
      assert_select "button", text: "Tornar disponível"
    end
    assert_select "form[action='#{admin_campus_space_deactivation_path(@guarapuava, space)}'] button", text: "Desativar"
    assert_select "a", text: "Marcar como indisponível", count: 0
    assert_no_match(/translation missing/i, response.body)
  end

  test "offers only to reactivate a deactivated space" do
    space = create(:space, :deactivated, campus: @guarapuava, name: "Sala 1")

    get admin_campus_space_path(@guarapuava, space)

    assert_select "#space_status", text: /Desativado/
    assert_select "#space_status", text: /O espaço não aparece na reserva. O cadastro continua guardado./
    assert_select "form[action='#{admin_campus_space_deactivation_path(@guarapuava, space)}']" do
      assert_select "input[name='_method'][value='delete']"
      assert_select "button", text: "Reativar"
    end
    assert_select "button", text: "Desativar", count: 0
    assert_select "button", text: "Tornar disponível", count: 0
    assert_select "a", text: "Marcar como indisponível", count: 0
    assert_no_match(/translation missing/i, response.body)
  end

  private

    def campus_breadcrumbs
      { "Dashboard" => users_root_path, "Área administrativa" => admin_root_path, "Guarapuava" => admin_campus_path(@guarapuava) }
    end

    def spaces_breadcrumbs
      campus_breadcrumbs.merge("Espaços" => admin_campus_spaces_path(@guarapuava))
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

    # Counts cached queries too: the query cache outlives a request in tests, and a query run once per
    # space still shows up, cached or not.
    def count_queries(&block)
      count = 0
      counter = ->(*, payload) { count += 1 unless payload[:name] == "SCHEMA" }
      ActiveSupport::Notifications.subscribed(counter, "sql.active_record", &block)
      count
    end
end
