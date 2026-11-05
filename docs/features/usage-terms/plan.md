# Cadastro de termos de uso — Plano técnico

Issue: #60 · Especificação: [spec.md](spec.md)

Status: aprovado em 2026-11-02; revisado em 2026-11-03 com o retorno do professor (unicidade padrão
do Rails, sem tratamento de concorrência, e texto com Action Text).

## Abordagem técnica

O cadastro repete o de departamentos ([plano de departamentos](../departments/plan.md)): mesma estrutura
de controller, views, textos e testes. Trilha, cabeçalho, toast, estado vazio e `.btn-delete` já existem e
são reaproveitados. As diferenças são a página do termo (`show`) e o texto com o editor do Action Text.

1. **Action Text.** `bin/rails action_text:install` (as gems `actiontext`, `action_text-trix` e
   `image_processing` já estão no `Gemfile.lock`; o Active Storage já está instalado). O instalador cria a
   migration `CreateActionTextTables` (`action_text_rich_texts`), fixa `trix` e `@rails/actiontext` no
   importmap e os importa em `application.js`, e cria `actiontext.css` e as views
   `layouts/action_text/contents/_content` e `active_storage/blobs/_blob`. O fixture gerado
   (`test/fixtures/action_text/rich_texts.yml`) foi removido: o projeto usa FactoryBot.
2. **Tabela.** A migration `CreateUsageTerms` cria `usage_terms` com `title` (`string`, `null: false`),
   `timestamps` e índice único em `LOWER(title)` (`index_usage_terms_on_lower_title`), como o professor
   definiu. O texto fica em `action_text_rich_texts`, sem coluna em `usage_terms`.
3. **Modelo.** `UsageTerm`:
   - `has_rich_text :content` (RF2, RF3, RN5).
   - `normalizes :title, with: ->(title) { title.squish }` (RN2).
   - `validates :title, presence: true, uniqueness: { case_sensitive: false }` (RN1, RN3, RN6, RN7).
   - `validates :content, presence: true` (RN4). O rich text é vazio quando não tem texto, então
     `presence` recusa um editor só com linhas em branco (`<div><br></div>`).
   - `scope :ordered_by_title, -> { order(:title) }` (RF1). O nome diz o critério, como o professor pediu
     na revisão de 2026-10-30 (`sorted` → `ordered_by_name`).
   - Nenhuma associação nesta Issue além do rich text: `has_many :spaces` e o bloqueio de exclusão entram
     na #61.
4. **Rotas.** Dentro de `namespace :admin`, `resources :usage_terms`, com as sete ações. É o primeiro
   cadastro com `show`.
5. **Controller.** `Admin::UsageTermsController < Admin::BaseController`, no formato de
   `Admin::DepartmentsController`:
   - `index`: `UsageTerm.ordered_by_title`.
   - `show`: só renderiza (`set_usage_term`).
   - `create`: sucesso → `redirect_to admin_usage_term_path(@usage_term), success: t(".success")` (RF2);
     falha → `render :new, status: :unprocessable_content`.
   - `update`: sucesso → `redirect_to admin_usage_term_path(@usage_term), success: t(".success"),
     status: :see_other` (RF4); falha → `render :edit, status: :unprocessable_content`.
   - `destroy`: `@usage_term.destroy!` e `redirect_to admin_usage_terms_path` com `success` e
     `status: :see_other` (RF5, RN9). A #61 troca por `restrict_with_error`, como campi.
   - `set_usage_term` com `UsageTerm.find(params.expect(:id))` (404); `usage_term_params` com
     `params.expect(usage_term: [ :title, :content ])`.
   - `set_breadcrumbs` (RF8): Termos de uso; mais Novo (`new`, `create`); o título do termo (`show`); ou o
     título do termo, com link para a página dele, e Editar (`edit`, `update`). A trilha usa
     `@usage_term.title_in_database`: depois de uma edição recusada, ela mostra o título gravado, não o
     valor inválido digitado.
6. **Views** (`app/views/admin/usage_terms/`):
   - `index`, `_table` e `_usage_term`, copiadas de departamentos. A linha mostra só o título, com
     `break-words`, como link para a página do termo, e três botões: Ver, Editar e Excluir, só com ícone
     no celular e com `min-w-11` (44 px de toque). No celular, as células usam `px-3` e os botões quebram
     de linha (`flex-wrap`): com os três lado a lado, um título com "responsabilidade" deixava a tabela
     com 343 px numa tela de 320 px.
   - `show`: título do termo no cabeçalho (`head_title`), subtítulo fixo, uma linha de ações (Editar e
     Excluir, como o botão "Novo" da listagem) e um cartão com o texto. O texto usa
     `<%= @usage_term.content %>`, que renderiza o rich text dentro de `.trix-content` com o sanitizador
     do Action Text (RF3). O cartão tem `break-words` para endereços longos (RF9).
   - `new`, `edit` e `_form`: `f.input :title` e `f.input :content, type: :rich_textarea, class:
     "min-h-64", placeholder: t("helpers.placeholder.usage_term.content")`. `Form::Input::BaseComponent`
     passa a aceitar `type: :rich_textarea`, como já aceitava `:textarea`, e mantém rótulo, borda,
     mensagem de erro e o wrapper `.usage_term_content`. O placeholder vai como texto porque o
     `rich_textarea` não traduz `placeholder: true`. Cancelar volta para a listagem no cadastro e para a
     página do termo na edição.
   - `actiontext.css` fica dentro de `@layer components`: assim as classes do Tailwind no editor (borda
     vermelha de erro, `px-3`, `min-h-64`) vencem os padrões do Trix, e o Trix continua vencendo o reset
     do preflight. O arquivo devolve o que o preflight remove (marcadores de lista e negrito dos títulos),
     faz os links do texto seguirem o tamanho do texto e separa os blocos.
     No celular, a barra de ferramentas mantém o padrão do Trix: rola para o lado dentro dela, sem rolar
     a página (RF9). Fazer a barra quebrar de linha impediu o clique em Salvar no system test de 320 px,
     e a mudança foi desfeita.
   - Barra do editor em português: os rótulos ficam em `views.pt-BR.yml`, em `shared.rich_text_editor`,
     com as mesmas chaves do `Trix.config.lang`. O `layouts/shared/_head.html.erb` grava esses textos em
     JSON na meta `rich-text-editor-lang`, e `app/javascript/trix_locale.js`, importado logo depois do
     `trix`, copia esses textos para o `Trix.config.lang` (`Object.assign`, no próprio objeto). Isso
     funciona porque o Trix registra os elementos no próximo ciclo (`setTimeout`) e monta a barra a
     partir desse objeto. A meta fica em todos os layouts porque, com o Turbo, o módulo só roda na
     primeira carga. O botão de anexo continua, com o rótulo "Anexar arquivos".
7. **Atalho (RF7).** `admin/home/partials/_registrations.html.erb` ganha o item Termos de uso, depois de
   Departamentos.
8. **Ícones.** O card e a lista vazia usam `:file_with_lines`, que já existe e não é usado em nenhuma
   tela. O SVG dele não tem `fill="currentColor"` e ficaria preto no card azul, como aconteceu com
   `:users`; o atributo é acrescentado. O botão Ver precisa de um ícone novo, `:eye` (Font Awesome Free,
   como os outros).
9. **Populate (RF10).** `Db::Populator` apaga `UsageTerm` em `reset_records` e cria o termo de exemplo em
   `setup_usage_terms` (`UsageTerm.create_with(content:).find_or_create_by!(title:)`), depois dos
   departamentos. Título e texto ficam em constantes, como `DEPARTMENTS`; o texto é HTML, como o editor
   grava.

### Termo de exemplo

Título: **Termo de uso do laboratório de informática**

```html
<div>Ao reservar o laboratório de informática, o responsável pela reserva declara que leu e aceita as regras abaixo.</div>
<ol>
<li>O uso é permitido somente no horário reservado. O responsável deve chegar no início da reserva e liberar o espaço no horário de término.</li>
<li>É proibido consumir alimentos e bebidas dentro do laboratório.</li>
<li>Os computadores não podem ser desconectados, abertos nem ter os cabos trocados. Programas só podem ser instalados com autorização da Coordenadoria de Tecnologia da Informação.</li>
<li>Ao final do uso, o responsável deve desligar os computadores, o projetor e o ar-condicionado, apagar as luzes e fechar as janelas.</li>
</ol>
<div>O responsável responde pelos danos causados ao espaço e aos equipamentos durante a reserva. Problemas encontrados no início do uso devem ser informados ao Setor de Gestão de Espaços Acadêmicos antes de começar a atividade.</div>
```

Um parágrafo, uma lista numerada de quatro regras e outro parágrafo.

### Fluxo de uma requisição ao cadastro

```text
PATCH /admin/usage_terms/:id
  └─ Admin::UsageTermsController (herda Admin::BaseController < Users::BaseController)
       1. require_authentication     → visitante: redirect /login, nada gravado           (acesso)
       2. require_admin_area_access  → usuário comum: 403, nada gravado                   (acesso)
       3. set_usage_term             → id inexistente: 404                                (acesso)
       4. update                     → válido: redirect /admin/usage_terms/:id + mensagem (RF4)
                                       inválido: 422 com erro (RF6)
```

## Unicidade do título

Decisão do professor em 2026-11-03: no admin, a concorrência não é um problema, e a unicidade padrão do
Rails basta. A primeira versão desta PR usava o `NormalizedUniquenessValidator` (que carrega todos os
títulos com `pluck` e compara em Ruby) e um `UsageTerm#save` que convertia `RecordNotUnique` em erro de
validação. As duas coisas saíram:

| Camada | O que garante |
| --- | --- |
| `uniqueness: { case_sensitive: false }` | Consulta só o título informado (`LOWER(title) = LOWER(?)`), sem carregar os outros. |
| Índice único em `LOWER(title)` | A mesma regra no banco: nunca há dois títulos iguais sem diferenciar maiúsculas. |

As duas camadas usam o `LOWER()` do SQLite, que só converte letras ASCII; "Á" e "á" contam como
diferentes nas duas, então elas não se contradizem. Dois administradores salvando o mesmo título ao
mesmo tempo podem passar pela validação; o índice recusa o segundo, que recebe HTTP 500. É o mesmo
comportamento de campi, blocos e departamentos, aceito pelo professor para o admin. Ajustar os nomes
desses cadastros fica para uma PR separada, como ele indicou.

## Arquivos afetados

| Arquivo | Mudança |
| --- | --- |
| `db/migrate/<timestamp>_create_usage_terms.rb` | Novo: tabela `usage_terms`, `title` `null: false`, índice único em `LOWER(title)` |
| `db/migrate/<timestamp>_create_action_text_tables.action_text.rb` | Novo, do instalador: tabela `action_text_rich_texts` |
| `db/schema.rb` | Regenerado pelas migrations |
| `app/models/usage_term.rb` | Novo: `has_rich_text :content`, normalização e validações do título, `ordered_by_title` |
| `app/javascript/application.js`, `config/importmap.rb` | Do instalador: `trix` e `@rails/actiontext` |
| `app/assets/stylesheets/actiontext.css` | Do instalador, dentro de `@layer components`, com marcadores de lista, títulos em negrito, links no tamanho do texto e espaço entre blocos |
| `app/views/layouts/action_text/contents/_content.html.erb`, `app/views/active_storage/blobs/_blob.html.erb` | Do instalador, sem mudança |
| `app/components/form/input/base_component.rb` | Aceita `type: :rich_textarea` |
| `config/routes.rb` | `resources :usage_terms` no namespace `admin` |
| `app/controllers/admin/usage_terms_controller.rb` | Novo: CRUD com `show` e trilha |
| `app/views/admin/usage_terms/*` | Novos: `index`, `_table`, `_usage_term`, `show` (rich text), `new`, `edit`, `_form` (editor do Action Text) |
| `app/views/admin/home/partials/_registrations.html.erb` | Card de Termos de uso |
| `app/helpers/icons_helper.rb` | Ícone `:eye`; `fill="currentColor"` no `:file_with_lines` |
| `config/locales/pt-BR/models.pt-BR.yml` | Modelo `usage_term` (Termo de uso/Termos de uso) e atributos |
| `config/locales/pt-BR/errors.pt-BR.yml` | Mensagens de título vazio e repetido e de texto vazio |
| `config/locales/pt-BR/views.pt-BR.yml` | Chaves `admin.usage_terms.*`, `admin.home.index.usage_terms*`, `actions.show` e placeholders |
| `lib/tasks/db/populate/populator.rb` | Constantes do termo, `reset_records` e `setup_usage_terms` |
| `test/factories/usage_terms.rb` | Nova factory `:usage_term` |

### Textos (pt-BR)

| Chave | Texto |
| --- | --- |
| `activerecord.models.usage_term.one` / `.other` | Termo de uso / Termos de uso |
| `activerecord.attributes.usage_term.title` | Título |
| `activerecord.attributes.usage_term.content` | Texto |
| `helpers.placeholder.usage_term.title` | Ex.: Termo de uso do laboratório de informática |
| `helpers.placeholder.usage_term.content` | Escreva as regras de uso e as responsabilidades de quem reserva o espaço. |
| `admin.home.index.usage_terms` | Termos de uso |
| `admin.home.index.usage_terms_description` | Cadastre os termos de uso e responsabilidade dos espaços |
| `admin.usage_terms.index.title` / `.breadcrumb` | Termos de uso |
| `admin.usage_terms.index.subtitle` | Gerencie os termos de uso e responsabilidade que os espaços podem exigir. |
| `admin.usage_terms.index.new` | Novo termo |
| `admin.usage_terms.index.empty` | Nenhum termo de uso cadastrado. |
| `admin.usage_terms.index.actions` | Ações |
| `admin.usage_terms.confirm_destroy` | Excluir o termo %{title}? (usada na listagem e na página do termo) |
| `admin.usage_terms.show.subtitle` | Termo de uso e responsabilidade dos espaços. |
| `admin.usage_terms.new.title` / `.breadcrumb` | Novo termo de uso / Novo |
| `admin.usage_terms.new.subtitle` | Preencha o título e o texto do novo termo. |
| `admin.usage_terms.edit.title` / `.breadcrumb` | Editar termo de uso / Editar |
| `admin.usage_terms.edit.subtitle` | Altere o título ou o texto. A alteração vale para todos os espaços que usam o termo. |
| `admin.usage_terms.create.success` | Termo de uso cadastrado com sucesso. |
| `admin.usage_terms.update.success` | Termo de uso atualizado com sucesso. |
| `admin.usage_terms.destroy.success` | Termo de uso excluído com sucesso. |
| `actions.show` | Ver |
| `activerecord.errors.models.usage_term.attributes.title.blank` | Informe o título do termo. |
| `activerecord.errors.models.usage_term.attributes.title.taken` | Já existe um termo cadastrado com este título. |
| `activerecord.errors.models.usage_term.attributes.content.blank` | Informe o texto do termo. |

Editar, Excluir, Salvar e Cancelar reaproveitam `actions.*`. O subtítulo da edição lembra a RN8.

## Banco de dados e compatibilidade

- Tabelas novas, sem dados existentes e sem backfill. As migrations são reversíveis (`create_table` e
  `add_index` dentro de `change`).
- O índice único em `LOWER(title)` aplica no banco a mesma regra da validação (RN3). Veja
  [Unicidade do título](#unicidade-do-título).
- O texto fica em `action_text_rich_texts.body` (`text`), sem limite de tamanho. `has_rich_text` exclui
  o rich text junto com o termo.
- O diff do `schema.rb` tem só `action_text_rich_texts`, `usage_terms` e a versão.
- A migration de `usage_terms` foi alterada no lugar, porque nunca chegou à `main` (o merge da PR #80
  foi desfeito). Quem a rodou localmente faz `bin/rails db:migrate:down VERSION=20261102215619` antes de
  atualizar o branch e `bin/rails db:migrate` depois.
- **Produção:** nenhum termo é criado automaticamente (fora do escopo).

## Estratégia de testes

| Arquivo | Tipo | O que verifica | CA |
| --- | --- | --- | --- |
| `test/models/usage_term/usage_term_normalize_test.rb` | Modelo | Espaços do título normalizados com grafia e acentos preservados | CA3 |
| `test/models/usage_term/usage_term_validations_test.rb` | Modelo | `validate_presence_of` de `title` e `content` e `validate_uniqueness_of(:title).case_insensitive` (shoulda); título só com espaços e texto sem conteúdo (`<div><br></div>`) recusados; título repetido em outra caixa recusado com a mensagem própria; o próprio termo pode trocar maiúsculas e minúsculas; renomear para outro termo é recusado | CA2, CA3, CA7 |
| `test/models/usage_term/usage_term_constraints_test.rb` | Modelo | O banco recusa título nulo e título repetido em outra caixa (índice em `LOWER(title)`), sem validação | CA7 |
| `test/models/usage_term/usage_term_rich_text_test.rb` | Modelo | O texto mantém a formatação (lista e negrito) depois de gravado; excluir o termo exclui o rich text | CA4 |
| `test/models/usage_term/usage_term_ordered_by_title_test.rb` | Modelo | `ordered_by_title` ordena pelo título | CA1 |
| `test/controllers/admin/usage_terms_controller_test.rb` | Integração | Listagem em ordem e lista vazia; título, subtítulo e trilha nas quatro páginas, inclusive após erro (trilha com o título gravado); página do termo com a formatação do texto (lista e negrito) e sem scripts, `onclick` nem links `javascript:`; formulário com o editor (`trix-editor` com placeholder e campo oculto `usage_term[content]`); cadastro e edição redirecionam para a página do termo com toast; exclusão redireciona para a listagem; 422 para título vazio, texto vazio e título repetido, com os valores digitados mantidos; confirmação nos botões de excluir; 404 na página e na edição de termo inexistente | CA1–CA4 |
| `test/controllers/admin/usage_terms_controller_access_test.rb` | Integração | Visitante → `/login` e usuário comum → 403 nas sete ações, sem alterar dados; 403 antes de buscar o termo; o 403 não mostra a trilha | CA5 |
| `test/controllers/admin/home_controller_test.rb` | Integração | Atalho para `/admin/usage_terms` | CA1 |
| `test/lib/tasks/db/populate/populator_test.rb` | Unidade | O populate apaga os termos existentes e cria o termo de exemplo, com a lista de quatro regras | CA6 |
| `test/system/admin/usage_terms/manage_usage_terms_test.rb` | Sistema | Cadastro digitando no editor e usando o botão Negrito da barra, com ida para a página do termo; edição trocando o texto por uma lista numerada; exclusão pela listagem e pela página do termo, com confirmação aceita e recusada e toast; barra do editor em português (14 botões, sem "Bold"); erro de título repetido | CA1, CA3, CA4 |
| `test/system/admin/usage_terms/manage_usage_terms_on_phone_test.rb` | Sistema | Em 320 × 640, a listagem e a página do termo cabem na tela com um título longo e um endereço longo no texto; Ver, Editar e Excluir com pelo menos 44 px; cadastro pelo celular, com o formulário sem rolagem horizontal | CA1 |

- As respostas HTML verificam `assert_no_match(/translation missing/i, response.body)`.
- Sem teste de inflexão: `usage_term` → `usage_terms` é a regra padrão do Rails.
- A factory usa `sequence(:title)` e um texto de dois parágrafos com Faker, cada um num `<div>`, como o
  Trix grava.
- Os system tests usam `fill_in_rich_textarea` (`ActionText::SystemTestHelper`), e o de cadastro digita
  no editor e clica em Negrito, o que comprova que o JavaScript do Trix carregou.

## Autorização e segurança

- Todas as ações herdam `require_authentication` e `require_admin_area_access`. Os testes de acesso
  cobrem as sete ações, incluindo envios diretos de POST, PATCH e DELETE.
- `params.expect(usage_term: [ :title, :content ])` libera só os dois campos.
- CSRF continua ativo; `button_to` envia o token na exclusão.
- **XSS no texto.** O texto é HTML enviado pelo editor, e um envio direto pode trazer qualquer HTML. Na
  exibição, o Action Text passa o conteúdo pelo sanitizador do Rails (lista de tags e atributos
  permitidos): `<script>`, atributos de evento e links `javascript:` saem (RF3). O teste de integração
  envia os três e confere que nenhum chega à página.
- **Anexos.** O editor mantém o botão de anexo padrão, que usa o direct upload do Active Storage, já
  instalado. Não há regra própria para anexos nesta Issue (fora do escopo).
- Título exibido com o escape padrão do ERB; a confirmação de exclusão interpola o título num atributo
  `data-turbo-confirm`, também escapado.
- Vou rodar `bundle exec brakeman --no-pager` na verificação.

## Riscos e trade-offs

- **Unicidade só sem diferenciar maiúsculas (RN3).** Decisão do professor em 2026-11-03. Títulos que
  diferem só em acentos ou pontuação são aceitos como diferentes, e o `LOWER()` do SQLite não converte
  letras acentuadas. Veja [Unicidade do título](#unicidade-do-título).
- **Títulos iguais salvos ao mesmo tempo.** O índice recusa o segundo com HTTP 500. Risco aceito pelo
  professor para o admin.
- **Barra do editor traduzida em JavaScript.** O professor pediu a tradução da barra do Trix em
  2026-11-04, nesta PR. Como o Trix só lê os rótulos do `Trix.config.lang`, a tradução depende do
  módulo `trix_locale.js` rodar logo depois do `import "trix"` e antes de o Trix registrar os elementos.
  Veja o passo 6.
- **Página do termo.** É o primeiro `show` do admin. A tela segue o cabeçalho e os botões das outras;
  depois de salvar, o administrador para nela, e não na listagem como nos outros cadastros, por decisão
  da spec (RF2, RF4).
- **Ordenação com acentos e minúsculas (RF1).** `order(:title)` usa a comparação binária do SQLite:
  títulos que começam com minúscula ou letra acentuada ("termo…", "Área…") vão para o fim da listagem.
  É o mesmo comportamento de departamentos, aceito pelo professor na revisão da PR #73. Vai nos "Pontos
  para o revisor" da PR.
- **Texto sem limite.** Um texto muito longo só deixa a página do termo comprida. Não há limite na Issue.

## Comandos de verificação

```bash
bin/rails db:migrate
bin/rails test test/models/usage_term test/controllers/admin test/lib
bin/rails test
bin/rails test:system test/system/admin/usage_terms
bin/rubocop
bundle exec erb_lint --lint-all
bundle exec brakeman --no-pager
```
