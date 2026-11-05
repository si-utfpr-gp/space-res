require "test_helper"
require "support/helpers/breadcrumb_assertions"

class Admin::UsageTermsControllerTest < ActionDispatch::IntegrationTest
  include BreadcrumbAssertions

  setup do
    sign_in create(:user, :admin)
  end

  test "lists usage terms in alphabetical order of title" do
    create(:usage_term, title: "Termo do planetário")
    create(:usage_term, title: "Termo da quadra")
    create(:usage_term, title: "Termo do laboratório de informática")

    get admin_usage_terms_path

    assert_response :success
    assert_equal [ "Termo da quadra", "Termo do laboratório de informática", "Termo do planetário" ],
                 listed_usage_term_titles
    assert_select "a[href='#{new_admin_usage_term_path}']", text: "Novo termo"
    assert_no_match(/translation missing/i, response.body)
  end

  test "shows the list title, subtitle and breadcrumbs" do
    get admin_usage_terms_path

    assert_select "main h1", count: 1, text: "Termos de uso"
    assert_select "header p", text: "Gerencie os termos de uso e responsabilidade que os espaços podem exigir."
    assert_breadcrumbs({ "Dashboard" => users_root_path, "Área administrativa" => admin_root_path }, current: "Termos de uso")
  end

  test "shows a message when there are no usage terms" do
    get admin_usage_terms_path

    assert_response :success
    assert_select "p", text: "Nenhum termo de uso cadastrado."
    assert_select "table", count: 0
  end

  test "lists only the title of each usage term, with links to show and edit it" do
    usage_term = create(:usage_term, title: "Termo da quadra", content: "Texto que fica só na página do termo.")

    get admin_usage_terms_path

    assert_select "##{dom_id(usage_term)}" do
      assert_select "td:first-child a[href='#{admin_usage_term_path(usage_term)}']", text: "Termo da quadra"
      assert_select "a[href='#{admin_usage_term_path(usage_term)}']", text: "Ver"
      assert_select "a[href='#{edit_admin_usage_term_path(usage_term)}']", text: "Editar"
    end
    assert_no_match "Texto que fica só na página do termo.", response.body
  end

  test "shows a usage term with its title, subtitle, breadcrumbs and actions" do
    usage_term = create(:usage_term, title: "Termo da quadra")

    get admin_usage_term_path(usage_term)

    assert_response :success
    assert_select "main h1", count: 1, text: "Termo da quadra"
    assert_select "header p", text: "Termo de uso e responsabilidade dos espaços."
    assert_breadcrumbs(usage_terms_breadcrumbs, current: "Termo da quadra")
    assert_select "a[href='#{edit_admin_usage_term_path(usage_term)}']", text: "Editar"
    assert_select "form[action='#{admin_usage_term_path(usage_term)}'][data-turbo-confirm='Excluir o termo Termo da quadra?']" do
      assert_select "input[name='_method'][value='delete']"
      assert_select "button", text: "Excluir"
    end
    assert_no_match(/translation missing/i, response.body)
  end

  test "shows the content with its formatting" do
    usage_term = create(:usage_term, content: "<div>Regras:</div><ol><li><strong>Chegue</strong> no horário.</li><li>Recolha o material.</li></ol>")

    get admin_usage_term_path(usage_term)

    assert_select "#usage_term_content .trix-content" do
      assert_select "div", text: "Regras:"
      assert_select "ol li", count: 2
      assert_select "ol li strong", text: "Chegue"
    end
  end

  test "removes scripts and event handlers from the content" do
    usage_term = create(:usage_term, content: "<div onclick=\"steal()\">Regras</div><script>steal()</script>" \
                                              "<a href=\"javascript:steal()\">link</a>")

    get admin_usage_term_path(usage_term)

    assert_select "#usage_term_content script", count: 0
    assert_select "#usage_term_content [onclick]", count: 0
    assert_select "#usage_term_content a[href^='javascript']", count: 0
    assert_select "#usage_term_content div", text: "Regras"
  end

  test "shows HTML typed in the title as text" do
    usage_term = create(:usage_term, title: "<b>Termo</b> da quadra")

    get admin_usage_term_path(usage_term)

    assert_select "main h1 b", count: 0
    assert_select "main h1", text: "<b>Termo</b> da quadra"
    assert_select "form[data-turbo-confirm='Excluir o termo <b>Termo</b> da quadra?']"
  end

  test "responds not found for a usage term that does not exist" do
    get admin_usage_term_path(id: 0)

    assert_response :not_found
  end

  test "shows the new usage term form" do
    get new_admin_usage_term_path

    assert_response :success
    assert_select "main h1", count: 1, text: "Novo termo de uso"
    assert_select "header p", text: "Preencha o título e o texto do novo termo."
    assert_breadcrumbs(usage_terms_breadcrumbs, current: "Novo")
    assert_select "form[action='#{admin_usage_terms_path}']" do
      assert_select "input[name='usage_term[title]'][placeholder='Ex.: Termo de uso do laboratório de informática']"
      assert_select "input[type='hidden'][name='usage_term[content]']"
      assert_select "label[for='usage_term_content']", text: "Texto"
      assert_select "trix-editor#usage_term_content" \
                    "[placeholder='Escreva as regras de uso e as responsabilidades de quem reserva o espaço.']"
      assert_select "a[href='#{admin_usage_terms_path}']", text: "Cancelar"
    end
    assert_no_match(/translation missing/i, response.body)
  end

  test "creates a usage term and shows it with a confirmation" do
    assert_difference("UsageTerm.count", 1) do
      post admin_usage_terms_path, params: { usage_term: { title: "  Termo   da quadra ", content: "<div>Regra 1.</div><ol><li>Regra 2.</li></ol>" } }
    end

    usage_term = UsageTerm.last
    assert_redirected_to admin_usage_term_path(usage_term)
    assert_equal "Termo da quadra", usage_term.title
    assert_equal "<div>Regra 1.</div><ol><li>Regra 2.</li></ol>", usage_term.content.body.to_html
    follow_redirect!
    assert_success_toast "Termo de uso cadastrado com sucesso."
  end

  test "rejects a usage term without a title and keeps the content typed" do
    assert_no_difference("UsageTerm.count") do
      post admin_usage_terms_path, params: { usage_term: { title: "", content: "<div>Regras da quadra.</div>" } }
    end

    assert_response :unprocessable_content
    assert_select "main h1", text: "Novo termo de uso"
    assert_breadcrumbs(usage_terms_breadcrumbs, current: "Novo")
    assert_field_error :title, "Informe o título do termo."
    assert_select "input[name='usage_term[content]'][value='<div>Regras da quadra.</div>']"
  end

  test "rejects a usage term without a content and keeps the title typed" do
    assert_no_difference("UsageTerm.count") do
      post admin_usage_terms_path, params: { usage_term: { title: "Termo da quadra", content: "<div><br></div>" } }
    end

    assert_response :unprocessable_content
    assert_field_error :content, "Informe o texto do termo."
    assert_select "input[name='usage_term[title]'][value='Termo da quadra']"
  end

  test "rejects a usage term with a title already taken" do
    create(:usage_term, title: "Termo do Laboratório")

    assert_no_difference("UsageTerm.count") do
      post admin_usage_terms_path, params: { usage_term: { title: "termo do laboratório", content: "<div>Regras.</div>" } }
    end

    assert_response :unprocessable_content
    assert_select "input[name='usage_term[title]'][value='termo do laboratório']"
    assert_field_error :title, "Já existe um termo cadastrado com este título."
  end

  test "shows the edit form with the current values" do
    usage_term = create(:usage_term, title: "Termo da quadra", content: "<div>Regra 1.</div><ol><li>Regra 2.</li></ol>")

    get edit_admin_usage_term_path(usage_term)

    assert_response :success
    assert_select "main h1", count: 1, text: "Editar termo de uso"
    assert_select "header p", text: "Altere o título ou o texto. A alteração vale para todos os espaços que usam o termo."
    assert_breadcrumbs(usage_terms_breadcrumbs.merge("Termo da quadra" => admin_usage_term_path(usage_term)), current: "Editar")
    assert_select "form[action='#{admin_usage_term_path(usage_term)}']" do
      assert_select "input[name='usage_term[title]'][value='Termo da quadra']"
      assert_select "input[name='usage_term[content]'][value='<div>Regra 1.</div><ol><li>Regra 2.</li></ol>']"
      assert_select "a[href='#{admin_usage_term_path(usage_term)}']", text: "Cancelar"
    end
    assert_no_match(/translation missing/i, response.body)
  end

  test "updates a usage term and shows it with a confirmation" do
    usage_term = create(:usage_term, title: "Termo da quadra")

    patch admin_usage_term_path(usage_term), params: { usage_term: { title: "Termo da quadra coberta", content: "<div>Novo texto.</div>" } }

    assert_redirected_to admin_usage_term_path(usage_term)
    assert_equal [ "Termo da quadra coberta", "Novo texto." ], [ usage_term.reload.title, usage_term.content.to_plain_text ]
    follow_redirect!
    assert_success_toast "Termo de uso atualizado com sucesso."
    assert_select "#usage_term_content .trix-content div", text: "Novo texto."
  end

  test "rejects renaming a usage term to a title already taken and keeps the saved title in the breadcrumbs" do
    create(:usage_term, title: "Termo do planetário")
    usage_term = create(:usage_term, title: "Termo da quadra")

    patch admin_usage_term_path(usage_term), params: { usage_term: { title: "termo do planetário" } }

    assert_response :unprocessable_content
    assert_select "input[name='usage_term[title]'][value='termo do planetário']"
    assert_select "main h1", text: "Editar termo de uso"
    assert_breadcrumbs(usage_terms_breadcrumbs.merge("Termo da quadra" => admin_usage_term_path(usage_term)), current: "Editar")
    assert_field_error :title, "Já existe um termo cadastrado com este título."
    assert_equal "Termo da quadra", usage_term.reload.title
  end

  test "responds not found when editing a usage term that does not exist" do
    get edit_admin_usage_term_path(id: 0)

    assert_response :not_found
  end

  test "asks for confirmation before deleting a usage term from the list" do
    usage_term = create(:usage_term, title: "Termo da quadra")

    get admin_usage_terms_path

    assert_select "##{dom_id(usage_term)} form[action='#{admin_usage_term_path(usage_term)}']" \
                  "[data-turbo-confirm='Excluir o termo Termo da quadra?']" do
      assert_select "input[name='_method'][value='delete']"
      assert_select "button", text: "Excluir"
    end
  end

  test "deletes a usage term and shows a confirmation on the list" do
    usage_term = create(:usage_term)

    assert_difference("UsageTerm.count", -1) do
      delete admin_usage_term_path(usage_term)
    end

    assert_response :see_other
    assert_redirected_to admin_usage_terms_path
    follow_redirect!
    assert_success_toast "Termo de uso excluído com sucesso."
    assert_select "p", text: "Nenhum termo de uso cadastrado."
  end

  private

    def usage_terms_breadcrumbs
      { "Dashboard" => users_root_path, "Área administrativa" => admin_root_path, "Termos de uso" => admin_usage_terms_path }
    end

    def listed_usage_term_titles
      css_select("tbody tr td:first-child").map { |cell| cell.text.strip }
    end

    # The form builder renders each field and its errors inside a wrapper named after the field.
    def assert_field_error(attribute, message)
      assert_select ".usage_term_#{attribute} p.text-red-600", text: message
    end

    def assert_success_toast(message)
      assert_select "[data-controller='ui--toast'][data-ui--toast-message-type-value='success']" \
                    "[data-ui--toast-message-text-value='#{message}']"
    end
end
