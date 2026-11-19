# Cadastro de espaços — Plano técnico

Issue: #61 · Especificação: [spec.md](spec.md)

Status: aprovado pelo desenvolvedor em 2026-11-12. Revisado em 2026-11-17 para as três situações do
espaço (D2, D8–D10), a pedido do desenvolvedor depois da resposta do professor. Revisado de novo em
2026-11-18 com os três ajustes que o professor pediu na revisão da PR #88: descrição obrigatória
(D11), `Admin::SpacePresenter` e o campo Bloco com `grouped_collection_select`.

## Abordagem técnica

O cadastro segue o de termos de uso ([plano](../usage-terms/plan.md)), que já tem listagem, página
própria (`show`), formulário e exclusão. Trilha, cabeçalho, toast, estado vazio, `.btn-delete` e o
`select` do form builder são reaproveitados. As partes novas são: a escolha de bloco filtrada pelo
campus (D1), o campo de marcação no form builder, a situação do espaço (disponível, indisponível ou
desativado; D2, D8–D10), as exclusões recusadas nos quatro cadastros vizinhos (D3) e os espaços que
acompanham a troca de campus do bloco (D4).

1. **Tabela.** A migration `CreateSpaces` cria `spaces`:

   | Coluna | Tipo | Regra |
   | --- | --- | --- |
   | `campus_id` | `integer` | `null: false`, chave estrangeira para `campi` |
   | `building_id` | `integer` | opcional, chave estrangeira para `buildings` |
   | `department_id` | `integer` | opcional, chave estrangeira para `departments` |
   | `usage_term_id` | `integer` | opcional, chave estrangeira para `usage_terms` |
   | `name` | `string` | `null: false` |
   | `description` | `text` | `null: false` (RN15, D11) |
   | `requires_approval` | `boolean` | `null: false`, padrão `false` |
   | `status` | `string` | `null: false`, padrão `"available"` (D2, D8; não está na Issue) |
   | `unavailability_reason` | `string` | opcional; preenchido só enquanto o espaço está indisponível (RN13) |

   Duas restrições `CHECK`, segunda barreira para as regras do modelo:
   - `spaces_status_known`: `status IN ('available', 'unavailable', 'deactivated')`.
   - `spaces_unavailability_reason_matches_status`:
     `(status = 'unavailable') = (unavailability_reason IS NOT NULL)`. Há motivo se, e só se, o espaço
     está indisponível.

   As duas são SQL padrão e valem também no PostgreSQL.

   Índices únicos, com `LOWER(name)` por causa da D5 (a Issue previa `name` puro):
   - `index_spaces_on_building_id_and_lower_name`: (`building_id`, `LOWER(name)`). No SQLite, linhas com
     `building_id` nulo não colidem neste índice, então ele só vale para espaços com bloco (RN4).
   - `index_spaces_on_campus_id_and_lower_name_without_building`: (`campus_id`, `LOWER(name)`), parcial,
     `WHERE building_id IS NULL` (RN5).

   Índices simples em `campus_id`, `department_id` e `usage_term_id`, para as consultas das exclusões
   recusadas. As chaves estrangeiras não usam `ON DELETE`: a exclusão do cadastro vizinho é recusada
   antes, no modelo, e o banco recusa como segunda barreira.
2. **Modelo `Space`.**
   - `belongs_to :campus`; `belongs_to :building`, `:department` e `:usage_term` com `optional: true`.
   - `normalizes :name, with: ->(name) { name.squish }` (RN3).
   - `validates :name, presence: true` (RN3) e `validates :description, presence: true` (RN15).
   - Unicidade (RN4, RN5, D5), padrão do Rails, em duas validações que não se sobrepõem:
     `uniqueness: { case_sensitive: false, scope: :building_id }` quando há bloco, e
     `uniqueness: { case_sensitive: false, scope: :campus_id, conditions: -> { where(building_id: nil) } }`
     quando não há, cada uma com a sua mensagem.
   - `validates :building`, `:department` e `:usage_term` com `presence: true` quando o identificador
     foi informado e mudou: `optional: true` não confere se o registro existe (RN2, RN6, RN7). É o
     mesmo recurso usado em `User#department` na PR #85.
   - `validates :requires_approval, inclusion: { in: [ true, false ] }`: um valor em branco enviado
     direto vira erro de validação, não erro do banco (achado da revisão independente).
   - `validate :building_belongs_to_campus` (RN2): com bloco e campus presentes e
     `building.campus_id != campus_id`, erro em `:building`.
   - `scope :ordered_by_campus_building_and_name` (RF1): carrega campus e bloco, ordena por
     `campi.name`, depois blocos antes de "sem bloco" (`buildings.name IS NULL`), `buildings.name` e
     `spaces.name`. O nome diz o critério, como o professor pediu.
   - `enum :status, { available:, unavailable:, deactivated: }`, com os valores gravados como texto
     (D8). O enum já dá os predicados (`unavailable?`) e os escopos (`Space.not_deactivated`) de que a
     tela de reserva vai precisar; nenhum escopo novo nesta Issue.
   - `normalizes :unavailability_reason` com `squish.presence`, e
     `validates :unavailability_reason, presence: true, length: { maximum: 100 }, if: :unavailable?`
     (RN13). O limite fica em `Space::UNAVAILABILITY_REASON_MAX_LENGTH`, usado também no `maxlength`
     do campo.
   - `before_save :forget_unavailability_reason, unless: :unavailable?`: o motivo é apagado sempre que
     o espaço deixa de estar indisponível, por qualquer caminho (RN13).
   - Mudanças de situação com nomes do domínio (RN12–RN14, RF14), cada uma a partir de situações
     certas:
     - `mark_unavailable(reason)`: de disponível para indisponível, com o motivo;
     - `change_unavailability_reason(reason)`: só em indisponível;
     - `end_unavailability`: de indisponível para disponível;
     - `deactivate`: de disponível ou indisponível para desativado;
     - `reactivate`: de desativado para disponível.

     As duas que recebem o motivo usam `update` e devolvem `false` com o erro no campo. Todas passam
     por `change_status_from`, que relê o espaço com `with_lock` e levanta `Space::StatusConflict` se a
     situação gravada não for uma das esperadas. A releitura e a mudança ficam na mesma transação (no
     SQLite, imediata; no PostgreSQL, com `FOR UPDATE`). Assim, uma página aberta antes da mudança de
     outro administrador, ou uma ação repetida, não desfaz nada nem bate na restrição `CHECK`.
3. **Cadastros vizinhos (RN10, D3).** `Campus`, `Building`, `Department` e `UsageTerm` ganham
   `has_many :spaces, dependent: :restrict_with_error`. As mensagens `restrict_dependent_destroy` passam
   a trazer o próximo passo (ver Textos). Os controllers de blocos, departamentos e termos trocam
   `destroy!` pelo formato que campi já usa: `if destroy` → sucesso; senão →
   `redirect_to <listagem>, alert: errors.full_messages.to_sentence, status: :see_other`.
4. **Troca de campus do bloco (RN11, D4).** Em `Building`:
   `after_update :move_spaces_to_new_campus, if: :saved_change_to_campus_id?`, que faz
   `spaces.update_all(campus_id: campus_id)`. O callback roda dentro da transação do `save`: se
   falhar, o bloco também não muda. `update_all` basta porque a unicidade dos espaços com bloco é por
   bloco, e o bloco não muda. `Admin::BuildingsController#update` usa a mensagem
   `success_with_spaces` (com a contagem) quando o campus mudou e o bloco tem espaços. O `_form` de
   blocos, na edição de um bloco com espaços, mostra o aviso como `hint:` do campo Campus (RF15).
5. **Rotas.** Em `namespace :admin`, `resources :spaces`, com dois recursos singulares aninhados em
   `scope module: :spaces` (D9):
   - `resource :unavailability, only: [ :new, :create, :edit, :update, :destroy ]`: marcar como
     indisponível, alterar o motivo e tornar disponível.
   - `resource :deactivation, only: [ :create, :destroy ]`: desativar e reativar.
6. **Controller.** `Admin::SpacesController < Admin::BaseController`, no formato de
   `Admin::UsageTermsController`:
   - `index`: `Space.ordered_by_campus_building_and_name.includes(:department)`.
   - `show`: só renderiza.
   - `create` e `update`: sucesso → `redirect_to admin_spaces_path, success:` (RF3); falha →
     `render :new`/`:edit` com `:unprocessable_content`.
   - `destroy`: `destroy!` e volta para a listagem (RN9).
   - `space_params`: `campus_id`, `building_id`, `department_id`, `usage_term_id`, `name`,
     `description`, `requires_approval`. `status` e `unavailability_reason` ficam de fora: só mudam
     pelas ações de situação.
   - `set_form_options` (só nas ações que mostram o formulário): campi por nome, os campi que têm blocos
     (`Campus.having_buildings_ordered_by_name`, que já carrega os blocos em ordem de nome),
     departamentos (`Department.sorted`) e termos (`UsageTerm.ordered_by_title`).
   - `set_breadcrumbs`: Espaços › Novo, nome do espaço, ou nome do espaço › Editar, com
     `name_in_database`, como nos termos.

   **Controllers de situação** em `app/controllers/admin/spaces/`:
   - `Admin::Spaces::BaseController < Admin::BaseController`: busca o espaço por `space_id` (depois da
     checagem de acesso herdada, então o 403 vem antes do 404) e monta a trilha até o nome do espaço.
     `rescue_from Space::StatusConflict` volta para a página do espaço com o aviso "Nada foi alterado:
     o espaço está …" (`warning:`, `303`).
   - `UnavailabilitiesController`: `new` (só para espaço disponível) e `edit` (só para indisponível)
     mostram o formulário do motivo; nas outras situações, voltam com o mesmo aviso. `create` chama
     `mark_unavailable` e `update` chama `change_unavailability_reason`, com
     `params.expect(space: [ :unavailability_reason ])`, e voltam para a página do espaço com toast,
     ou mostram o formulário com `422`; `destroy` chama `end_unavailability`. A trilha termina em
     Indisponibilidade.
   - `DeactivationsController`: `create` chama `deactivate`, `destroy` chama `reactivate`; os dois
     voltam para a página do espaço com toast e `303`.
7. **Campo de marcação (RF6).** `TailwindFormBuilder` ganha o campo de marcação com a assinatura do
   Rails, mais `label:` e `hint:`, como foi feito com `select`. Ele renderiza
   `Form::Input::CheckboxComponent < Form::Input::BaseComponent`, com template próprio: caixa e rótulo
   lado a lado (o `for` do rótulo aponta para a caixa), área de toque de 44 px, foco visível, dica e
   erro embaixo. O componente chama o helper da view, não o do builder, para não entrar em recursão
   (mesmo cuidado do `SelectComponent`). No Rails 8.1 o nome canônico é `checkbox`, com `check_box`
   como alias (conferido no código do Action View 8.1.4.1); o builder sobrescreve os dois.

   Na revisão da PR #88, o builder ganhou também o `grouped_collection_select`, com a assinatura do
   Rails. Ele transforma a coleção nos grupos de opções e renderiza o `select` estilizado. Com
   `group_filter_key: :metodo` nas opções, cada `<optgroup>` leva `data-filter-key` com esse valor do
   grupo. O `grouped_collection_select` do próprio Rails não aceita atributos no grupo nem nas opções,
   que o filtro do campo Bloco precisa.
8. **Escolha do bloco (RF4, D1).**
   - O servidor monta o campo com
     `f.grouped_collection_select :building_id, campi_with_buildings, :buildings, :name, :id, :name`,
     com "Sem bloco" e `group_filter_key: :id`: um `<optgroup>` por campus, com `data-filter-key` com o
     campus. É o que funciona sem JavaScript.
   - Um controller Stimulus novo, `ui/filtered_select_controller.js`, liga o campo Campus (origem) ao
     campo Bloco (alvo). Ao conectar, guarda as opções originais. Sem campus escolhido, mantém a lista
     agrupada. Com campus, reconstrói o campo só com "Sem bloco" e os blocos do grupo daquele campus; se o
     bloco escolhido for de outro campus, volta para "Sem bloco". As opções são removidas e
     recolocadas, em vez de escondidas: o Safari do iPhone não esconde `<option>`. Antes de o Turbo
     guardar a página em cache (`turbo:before-cache`), a lista completa é recolocada, para o filtro
     funcionar ao voltar pelo navegador.
   - `Space#building_belongs_to_campus` continua valendo para envios diretos.
9. **Views** em `app/views/admin/spaces/`:
   - `index`, `_table`, `_space`: colunas Nome, Localização (campus e bloco, ou "Sem bloco"),
     Departamento, Aprovação e Ações (ver, editar, excluir). Ao lado do nome, o selo "Indisponível" ou
     "Desativado" em texto. No celular, só Nome e Ações ficam como colunas; localização, departamento
     e aprovação vão embaixo do nome (RF12), como em blocos e usuários.
   - `show`: ações Editar, as ações da situação e Excluir; dados em `<dl>`, começando pela situação,
     com a frase do que ela significa para a reserva e, se o espaço está indisponível, o motivo e o
     link "Alterar motivo" (área de toque de 44 px); o termo de uso é um link para
     `admin_usage_term_path`; a frase de quem libera as reservas (RF5).
   - `_status_actions`: um `case` pela situação (RF14). "Marcar como indisponível" é link para o
     formulário; "Tornar disponível" e "Reativar" são `button_to` com `DELETE`; "Desativar"
     (`_deactivate_button`) é `button_to` com `POST` e `data-turbo-confirm`.
   - `unavailabilities/new`, `edit` e `_form`: um campo, Motivo, com `maxlength`, exemplo, dica e
     ações Cancelar e Salvar (RF16).
   - `new`, `edit`, `_form`: campos na ordem da tarefa T1. Descrição com `type: :textarea`; a página do
     espaço não precisa mais do texto "Sem descrição.". A dica da
     caixa de aprovação explica a regra de liberação com e sem departamento (RF5).
   - Parciais `_status_badge`, `_unavailability_reason` e `_usage_term`, para as views não terem `if`
     longo. A confirmação de exclusão traz o nome do espaço e o lembrete da desativação (RF7).
   - `Admin::SpacePresenter` (`app/presenters/admin/space_presenter.rb`), no lugar do
     `Admin::SpacesHelper` da primeira versão, que misturava apresentação, a regra de quem libera e as
     opções do formulário (revisão da PR #88): `location`, `building_name`, `department_name`,
     `approval_label`, `status_label` e `approval_description`, que devolve a frase da RF5 (três casos:
     sem aprovação, com departamento, sem departamento). A regra de quem libera fica no presenter
     enquanto só a página do espaço a usa; quando o fluxo de liberação existir, ela vai para o modelo.
     As views criam o presenter, e `Admin::Spaces::BaseController` o usa no aviso "Nada foi alterado".
10. **Atalho (RF10).** `admin/home/partials/_registrations.html.erb` ganha o item Espaços, depois de
    Blocos, com um ícone novo em `IconsHelper` (`:door`, desenhado em traço como `:building_office`,
    com `stroke="currentColor"`).
11. **Populate (RF13).** `Db::Populator#setup_spaces`, depois de blocos, departamentos e termos. `Space`
    entra primeiro em `reset_records`, porque os outros cadastros não podem ser apagados com espaços.
    Espaços: no Bloco B, uma sala simples, uma sala indisponível ("Sala em reforma") e uma sala
    desativada (unificada com a primeira); um laboratório de informática no Bloco C,
    com departamento, aprovação e o termo de exemplo; um auditório no Bloco R, com aprovação e sem
    departamento; e a quadra poliesportiva (com departamento e aprovação) e o planetário sem bloco.

### Fluxo de um cadastro

1. `GET /admin/spaces/new` → formulário com Campus em "Selecione o campus" e Bloco agrupado.
2. O administrador escolhe o campus → o Stimulus reduz o campo Bloco aos blocos daquele campus.
3. `POST /admin/spaces` → `Space.new(space_params).save`.
4. Válido → `303` para `/admin/spaces` com toast. Inválido → `422`, formulário com os valores e os
   erros junto aos campos; o Stimulus reaplica o filtro pelo campus que voltou escolhido.

## Arquivos afetados

| Área | Arquivos |
| --- | --- |
| Banco | `db/migrate/*_create_spaces.rb`, `db/schema.rb` |
| Modelos | `app/models/space.rb` (novo); `campus.rb`, `building.rb`, `department.rb`, `usage_term.rb` |
| Controllers | `app/controllers/admin/spaces_controller.rb` e `admin/spaces/{base,unavailabilities,deactivations}_controller.rb` (novos); `buildings_controller.rb`, `departments_controller.rb`, `usage_terms_controller.rb` |
| Rotas | `config/routes.rb` |
| Form builder | `app/form_builders/tailwind_form_builder.rb`; `app/components/form/input/checkbox_component.rb` e `.html.erb` (novos) |
| JavaScript | `app/javascript/controllers/ui/filtered_select_controller.js` (novo) |
| Views | `app/views/admin/spaces/*` (novas); `admin/buildings/_form.html.erb`; `admin/home/partials/_registrations.html.erb` |
| Presenters | `app/presenters/admin/space_presenter.rb` (novo) |
| Helpers | `app/helpers/admin/buildings_helper.rb` (novo); `app/helpers/icons_helper.rb` |
| Textos | `config/locales/pt-BR/models.pt-BR.yml`, `errors.pt-BR.yml`, `views.pt-BR.yml` |
| Populate | `lib/tasks/db/populate/populator.rb` |
| Testes | ver Estratégia de testes |

### Textos (pt-BR)

- **Modelo:** Espaço / Espaços; atributos Campus, Bloco, Nome, Descrição, Departamento responsável,
  Termo de uso, "A reserva precisa de aprovação", Situação, Motivo.
- **Erros de `Space`:** as mensagens das RN1–RN7, RN13 e RN15 da especificação.
- **Exclusões recusadas (D3):** as mensagens usam `%{record}`, o nome do que está vinculado.
  - Campus: "Não é possível excluir o campus porque ele tem blocos (ou espaços) cadastrados. Mova-os
    para outro campus ou exclua-os antes." Substitui o texto da RN9 de blocos.
  - Bloco: "Não é possível excluir o bloco porque ele tem espaços cadastrados. Mova os espaços para
    outro bloco ou exclua-os antes."
  - Departamento: "Não é possível excluir o departamento porque ele tem usuários (ou espaços)
    vinculados. Troque ou remova o departamento desses usuários (ou espaços) antes." Substitui o texto
    da PR #85, que só dava o motivo.
  - Termo de uso: "Não é possível excluir o termo porque ele é usado por espaços. Troque ou remova o
    termo de uso desses espaços antes."
- **Blocos:** aviso do campo Campus ("Este bloco tem N espaços. Ao trocar o campus, eles passam para o
  novo campus.") e confirmação ("Bloco atualizado com sucesso. N espaços passaram para o campus X."),
  as duas com singular e plural.
- **Views de espaços:** títulos, subtítulos, trilha, "Novo espaço", lista vazia, "Sem bloco", "Sem
  departamento", "Sem termo de uso", as três situações e o que cada uma significa para a reserva, as
  ações de situação, o formulário do motivo, os toasts, as confirmações de exclusão e desativação e
  as três frases de quem libera a reserva.

## Banco de dados e compatibilidade

- Só uma tabela nova; nenhuma tabela existente muda. A migration é reversível (`create_table`).
- `status`, `unavailability_reason`, as restrições `CHECK` e os índices com `LOWER(name)` são
  diferenças em relação ao "Dados do modelo" da Issue, vindas das decisões D2, D5 e D8. Vão nos
  "Pontos para o revisor" da PR.
- A revisão de 2026-11-17 alterou a própria migration `CreateSpaces`, que ainda não saiu da máquina
  do desenvolvedor, em vez de criar outra só para trocar `active` por `status`. O banco de
  desenvolvimento local precisa refazer a tabela:
  `bin/rails db:migrate:redo VERSION=20261112133836` (apaga os espaços locais) e, se quiser os
  exemplos de volta, `bin/rails db:populate`. O banco de teste é recriado sozinho a partir do
  `schema.rb`.
- A revisão da PR #88 (2026-11-18) também alterou a `CreateSpaces` no lugar, para `description` ficar
  `null: false`, porque a tabela ainda não está na `main`. Quem já rodou a migration refaz a tabela com
  o mesmo comando.
- Campus e bloco iguais são garantidos na aplicação (validação em `Space` e callback em `Building`),
  não no banco. Uma chave estrangeira composta (`building_id`, `campus_id`) foi considerada e
  descartada: exigiria um índice único novo em `buildings` e não é o padrão do projeto.

## Estratégia de testes

| Arquivo | Tipo | O que verifica | CA |
| --- | --- | --- | --- |
| `test/models/space/space_associations_test.rb` | Modelo | `belong_to` campus (obrigatório) e bloco, departamento e termo (opcionais), com shoulda | CA2 |
| `test/models/space/space_normalize_test.rb` | Modelo | Espaços do nome e do motivo normalizados; motivo em branco vira nulo | CA1, CA11 |
| `test/models/space/space_status_test.rb` | Modelo | Enum com valores em texto (shoulda); motivo obrigatório e com até 100 caracteres só no indisponível (shoulda); marcar, alterar o motivo, tornar disponível, desativar e reativar; cada mudança fora das situações de partida levanta `StatusConflict` sem mudar nada; uma cópia carregada antes de outra mudança não a desfaz; motivo apagado ao sair de indisponível; editar mantém a situação | CA11 |
| `test/models/space/space_validations_test.rb` | Modelo | Presença do nome e da descrição (shoulda); unicidade no bloco e entre espaços sem bloco, sem diferenciar maiúsculas; mesmo nome em blocos diferentes e entre espaço com e sem bloco aceito; bloco de outro campus recusado; bloco, departamento e termo inexistentes recusados; mensagens próprias | CA2–CA5 |
| `test/models/space/space_constraints_test.rb` | Modelo | O banco recusa nome, descrição, campus, aprovação e situação nulos, situação desconhecida, indisponível sem motivo e motivo fora de indisponível, nome repetido no bloco e nome repetido sem bloco no campus, sem validação | CA4, CA5, CA11 |
| `test/models/space/space_ordered_by_campus_building_and_name_test.rb` | Modelo | Ordem por campus, bloco e nome, com "sem bloco" depois dos blocos | CA7 |
| `test/models/{campus,building,department,usage_term}/*_associations_test.rb` | Modelo | `have_many(:spaces).dependent(:restrict_with_error)`; a exclusão com espaços (inclusive desativados) falha com a mensagem; sem espaços, passa | CA6 |
| `test/models/campus/campus_having_buildings_ordered_by_name_test.rb` | Modelo | Campi e blocos em ordem de nome, sem os campi sem blocos, com os blocos carregados | CA2, CA3 |
| `test/models/building/building_campus_change_test.rb` | Modelo | Trocar o campus do bloco move os espaços dele e não mexe nos espaços sem bloco; troca recusada (nome repetido no destino) não move nada | CA12 |
| `test/controllers/admin/spaces_controller_test.rb` | Integração | Listagem em ordem, com localização, departamento, aprovação e selos Indisponível e Desativado; lista vazia; título, subtítulo e trilha em todas as páginas; página do espaço com todos os dados, a situação, a frase de quem libera e o link do termo; ações de situação certas para cada situação, com a confirmação da desativação; formulário com os campos na ordem, bloco agrupado e caixa desmarcada; cadastro e edição com toast; 422 com valores mantidos para cada regra; situação e motivo forjados no envio são ignorados; editar mantém situação e motivo; exclusão em qualquer situação e confirmação; 404 | CA1–CA5, CA7, CA11 |
| `test/controllers/admin/spaces/unavailabilities_controller_test.rb` | Integração | Formulário do motivo (título, trilha, dica, limite, exemplo, Cancelar); marcar, alterar e tornar disponível com toast; motivo em branco ou longo → 422 sem mudar a situação nem o motivo salvo; envio sem o campo → 400; cada ação e formulário na situação errada → aviso com a situação atual, sem mudança; 404 | CA11 |
| `test/controllers/admin/spaces/deactivations_controller_test.rb` | Integração | Desativar (inclusive um indisponível, apagando o motivo) e reativar, com toast e a página atualizada; dados mantidos; repetir a desativação ou reativar um espaço não desativado → aviso, sem mudança; 404 | CA11 |
| `test/controllers/admin/spaces_controller_access_test.rb` | Integração | Visitante → `/login` e usuário comum → 403 nas catorze ações, sem alterar dados; 403 antes de procurar o espaço | CA8 |
| `test/controllers/admin/{campi,buildings,departments,usage_terms}_controller_test.rb` | Integração | Exclusão com espaços recusada, com a mensagem e o próximo passo, e nada apagado; blocos: aviso no formulário e confirmação com a contagem ao trocar o campus | CA6, CA12 |
| `test/controllers/admin/home_controller_test.rb` | Integração | Atalho para `/admin/spaces` | CA1 |
| `test/form_builders/tailwind_form_builder_test.rb` | Unidade | Caixa com rótulo ligado, valor marcado e desmarcado, dica, erro e área de toque; `grouped_collection_select` com um grupo por registro, valor escolhido, `data-filter-key` no grupo e as opções do Rails | CA1 |
| `test/presenters/admin/space_presenter_test.rb` | Unidade | Localização com e sem bloco, departamento ou "Sem departamento", aprovação, as três frases de quem libera e as três situações | CA7 |
| `test/lib/tasks/db/populate/populator_test.rb` | Unidade | O populate cria espaços com e sem bloco, um indisponível com motivo e um desativado, e roda duas vezes sem erro | CA9 |
| `test/system/admin/spaces/manage_spaces_test.rb` | Sistema | Cadastro escolhendo o campus e vendo o campo Bloco reduzido; troca de campus limpa o bloco; cadastro sem bloco; edição; marcar como indisponível (com erro de motivo vazio), alterar o motivo e tornar disponível; cancelar o formulário do motivo; desativar com confirmação aceita e recusada, e reativar; exclusão com confirmação aceita e recusada; uso só pelo teclado no formulário | CA1–CA3, CA11 |
| `test/system/admin/spaces/manage_spaces_on_phone_test.rb` | Sistema | Em 320 × 640, listagem e página do espaço sem rolagem horizontal, ações com 44 px (inclusive "Alterar motivo"), cadastro e indisponibilidade pelo celular | CA1, CA7, CA11 |

- Factory `:space` com `campus`, nome em sequência, descrição do Faker e traits `:with_building` (bloco do mesmo campus),
  `:requiring_approval`, `:unavailable` (com o motivo "Sala em reforma") e `:deactivated`.
- As respostas HTML verificam `assert_no_match(/translation missing/i, response.body)`.
- A verificação de uso da especificação (T1–T7, heurísticas e WCAG) é feita na aplicação rodando, em
  1400, 390 e 320 px, e registrada em `tasks.md`.

## Autorização e segurança

- Todas as ações passam por `Admin::BaseController#require_admin_area_access`; nada de novo em
  autenticação.
- `status` e `unavailability_reason` não entram em `space_params`. As mudanças de situação são
  `POST` e `DELETE` com token CSRF (`button_to` e formulário), nunca `GET`.
- O motivo é texto puro, escapado pelo ERB. Ele vai aparecer para os solicitantes na tela de reserva.
- A descrição é texto puro, escapado pelo ERB.
- Os identificadores de campus, bloco, departamento e termo são validados no servidor; a lista
  filtrada pelo JavaScript é só conveniência.

## Riscos e trade-offs

- **Branch empilhada na PR #85.** As duas Issues mexem em `Department`,
  `Admin::DepartmentsController#destroy`, nos erros de departamento, no populate, no atalho da área
  administrativa e nas rotas, e o banco local já tem a migration da #85. Por isso `feat/spaces` parte
  de `feat/admin-users`, não da `main`. A #85 entrou na `main` por squash em 2026-11-13; antes de
  abrir a PR desta Issue, a branch é refeita com
  `git rebase --onto origin/main feat/admin-users feat/spaces`.
- **Cadastros simultâneos.** O adaptador de SQLite do Rails 8.1 abre as transações de escrita em modo
  imediato (`default_transaction_mode: :immediate`), e o `save` valida dentro da transação. Assim, dois
  administradores salvando o mesmo nome, ou um trocando o campus de um bloco enquanto outro cadastra
  um espaço nele, são atendidos um depois do outro, e o segundo já vê o resultado do primeiro. Os
  índices únicos ficam como segunda barreira. Não há tratamento além disso, como o professor definiu
  para o admin (termos de uso).
- **Teste de `BaseForm`.** `test/forms/base_form_test.rb` afirmava que não existia a constante `Space`.
  Com o modelo novo, a afirmação passou a usar o formulário de horários, que continua sem constante.
- **`LOWER()` do SQLite só converte ASCII.** "Área" e "área" contam como nomes diferentes, na validação
  e no índice. Mesmo comportamento dos termos de uso. O professor manteve o padrão do Rails porque o
  banco vai migrar para PostgreSQL (D5).
- **Ordenação por bytes.** Nomes que começam com minúscula ou acento vão para o fim, como nos outros
  cadastros.
- **Issue #63.** A tela de reserva precisará esconder os espaços desativados e mostrar os indisponíveis
  com o motivo, sem deixar reservá-los. A #63 está fechada como concluída, mas a lista fixa continua no
  código. O professor não respondeu a essa observação na mensagem de 2026-11-13; perguntar de novo.
- **Página desatualizada e requisições simultâneas.** Dois administradores na mesma página: se um
  desativa e o outro depois clica em "Tornar disponível", "Alterar motivo" ou "Marcar como
  indisponível", nada muda, e o segundo vê o aviso com a situação atual. Como a situação é relida com
  `with_lock` dentro da transação da mudança, isso vale também para duas requisições ao mesmo tempo
  (achado da revisão independente de 2026-11-17).
- **Troca de campus do bloco.** Na revisão da PR #88, o professor indicou que não permitiria a troca e
  que o `update_all` esconde uma mudança importante: move os espaços sem passar pelas validações e
  callbacks deles. O comportamento fica como está nesta PR e sai na Issue própria.
- **Tamanho.** É a maior Issue de cadastro até aqui (form builder, JavaScript, quatro cadastros
  vizinhos). As tarefas são fatiadas para cada commit ficar verificável sozinho.

## Comandos de verificação

```bash
bin/rails db:migrate
bin/rails db:migrate:down VERSION=<versão> && bin/rails db:migrate
bin/rails test test/models/space test/models/building test/models/campus test/controllers/admin test/controllers/admin/spaces test/form_builders test/presenters test/lib
bin/rails test
bin/rails test:system test/system/admin/spaces test/system/admin/buildings
bin/rubocop
bundle exec erb_lint --lint-all
bundle exec brakeman --no-pager
```

Por envolver migration, a implementação passa por uma revisão independente antes de ser dada como
concluída.
