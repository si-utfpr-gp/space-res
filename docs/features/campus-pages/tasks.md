# Área administrativa organizada por campus — Tarefas

Issue: #99 · [spec.md](spec.md) · [plan.md](plan.md)

Legenda: `[ ]` pendente · `[~]` em andamento · `[x]` concluída

As tarefas seguem a ordem em que o código pode mudar sem quebrar o que já foi feito. Entre a T4 e a
T6, os links da visão geral apontam para rotas aninhadas que só ganham controller na T5 e na T6. Os
testes de cada tarefa rodam separados, e a suíte completa roda na T9.

## T1 — Comparação de nomes em `ComparableName`

- [x] Status
- **Objetivo:** a chave que ignora maiúsculas, acentos, espaços e pontuação fica num Value Object,
  usado pelo validador de unicidade e, na T7, pela busca por nome.
- **Requisitos:** RN7 · plano, item 5 e P4
- **Passos:** teste de `ComparableName` → `app/value_objects/comparable_name.rb` →
  `NormalizedUniquenessValidator` passa a usá-lo.
- **Verificação:** `bin/rails test test/value_objects test/models/campus test/models/building
  test/models/department`
- **Depende de:** —

## T2 — Acesso ao campus e escopos de ordem

- [x] Status
- **Objetivo:** existe um ponto único que decide quem administra um campus, e os escopos que a
  entrada, o menu e a visão geral usam.
- **Requisitos:** RN1, regras de acesso · plano, itens 2 e 4, P3
- **Passos:** testes → `AdminPolicy#manage_campus?` → `can_manage_campus?` em `Users::BaseController`
  → `deny_access`, `require_campus_access` e `selectable_campi` em `Admin::BaseController` →
  `Campus.ordered_by_name`, `Building.ordered_by_name` e `Space.counts_by_status`.
- **Verificação:** `bin/rails test test/policies test/models test/controllers/admin`
- **Depende de:** —

## T3 — Menu lateral do campus

- [x] Status
- **Objetivo:** as páginas de um campus podem trocar o menu lateral pelo menu do campus, com o
  seletor, sem mudar o menu das outras páginas.
- **Requisitos:** RF5, RF6, D4 · plano, item 9
- **Passos:** `_sidebar` com `yield(:sidebar_navigation)` e a parcial `_main_navigation` → layout
  `admin/campus` → `Admin::CampusMenuComponent` com teste de componente (seções, seção atual, seletor
  com a mesma seção e campus único sem seletor) → textos em `components.admin.campus_menu`.
- **Verificação:** `bin/rails test test/components test/controllers/users test/controllers/admin` e
  `bin/rails test test/system/users`
- **Depende de:** T2

## T4 — Entrada e página do campus

- [x] Status
- **Objetivo:** a entrada mostra os cartões dos campi e os cadastros gerais, e a página do campus
  mostra a visão geral, com o menu do campus.
- **Requisitos:** RF1–RF4, RF12, RF13, RN6, RN9 · CA1, CA2
- **Passos:** testes → rotas (`resources :campi, except: :index`, com `buildings` e `spaces`
  aninhados em `module: :campi`) → `Admin::CampusSummariesQuery` → `HomeController` e views da
  entrada → `CampiController` (`show`, redirecionamentos, `layout` e `require_campus_access`) →
  `Admin::CampusOverviewPresenter` → views da página do campus → mensagem da exclusão de campus →
  textos.
- **Verificação:** `bin/rails test test/queries test/presenters test/controllers/admin/home_controller_test.rb
  test/controllers/admin/home_controller_access_test.rb test/controllers/admin/campi_controller_test.rb
  test/controllers/admin/campi_controller_access_test.rb`
- **Depende de:** T2, T3

## T5 — Blocos dentro do campus

- [x] Status
- **Objetivo:** blocos são listados, cadastrados, editados e excluídos na página do campus, sem o
  campo Campus, e o campus de um bloco não muda.
- **Requisitos:** RF11, RN1–RN3, RN5 · CA3, CA6, CA7
- **Passos:** `git mv` do controller, das views e dos testes para `campi/` →
  `Admin::Campi::BaseController` → controller com `@campus.buildings` → `attr_readonly :campus_id`
  e saída do callback, do helper e dos textos do aviso e da contagem → teste de modelo do campus fixo
  no lugar do de troca de campus → `Building.sorted` sai (testes de modelo e do populate) → rotas
  antigas de blocos saem.
- **Verificação:** `bin/rails test test/models/building test/lib test/controllers/admin/campi`
- **Depende de:** T4

## T6 — Espaços dentro do campus

- [x] Status
- **Objetivo:** espaços são listados, cadastrados, editados, vistos, marcados como indisponíveis,
  desativados e excluídos na página do campus, sem o campo Campus, e o formulário lista só os blocos
  do campus.
- **Requisitos:** RF7, RF9, RF10, RN1, RN2, RN4, RN5 · CA3, CA4, CA6
- **Passos:** `git mv` dos controllers, das views e dos testes para `campi/` → controllers com
  `@campus.spaces` → formulário sem Campus, com a linha do campus e o `select` de blocos →
  `attr_readonly :campus_id` em `Space` → mensagem "Selecione um bloco deste campus." → saem
  `filtered_select_controller.js`, `Campus.having_buildings_ordered_by_name` e
  `SpacePresenter#location` → rotas antigas de espaços saem.
- **Verificação:** `bin/rails test test/models/space test/models/campus test/presenters
  test/controllers/admin/campi test/form_builders`
- **Depende de:** T5

## T7 — Filtros da listagem de espaços

- [x] Status
- **Objetivo:** a listagem de espaços filtra por nome, bloco e situação, com a contagem anunciada e
  os filtros no endereço.
- **Requisitos:** RF8, RN7, RN8 · CA5
- **Passos:** testes → `Admin::SpaceFiltersForm` → `Admin::CampusSpacesQuery` → `index` e views
  (`_filters`, frame, contagem, estados vazios) → Stimulus `ui--filter-form` → textos.
- **Verificação:** `bin/rails test test/forms test/queries test/controllers/admin/campi`
- **Depende de:** T1, T6

## T8 — Endereços antigos e limpeza

- [x] Status
- **Objetivo:** os endereços antigos respondem 404, e não sobra texto, rota ou teste do modelo
  antigo.
- **Requisitos:** RF14, D3 · CA3
- **Passos:** `legacy_routes_test.rb` → busca por `admin_buildings_path`, `admin_spaces_path`,
  `admin_campi_path`, `admin.buildings.`, `admin.spaces.` e `admin.campi.index` sem uso → chaves
  órfãs removidas.
- **Verificação:** `bin/rails test` e `bin/rails test test/controllers/admin/legacy_routes_test.rb`
- **Depende de:** T7

## T9 — Testes de sistema e verificação

- [x] Status
- **Objetivo:** os fluxos funcionam no navegador, em tela grande e em 320 px, e cada critério de
  aceitação tem evidência.
- **Requisitos:** CA1–CA9, checklist de usabilidade
- **Passos:** testes de sistema de `test/system/admin/campi/` (campus, blocos, espaços, filtros e as
  versões de celular), movendo os de `admin/buildings`, `admin/spaces` e `admin/campi` → verificação
  manual em 1400, 390 e 320 px → `bin/rails test`, `bin/rails test test/system/admin
  test/system/users`, `bin/rubocop`, `bundle exec erb_lint --lint-all`, `bundle exec brakeman
  --no-pager`, `bin/importmap audit` → revisão independente → evidências abaixo.
- **Depende de:** T8

## Evidências

Verificação de 2026-11-28, no branch `feat/admin-area-by-campus`:

- `bin/rails test`: 504 testes, 0 falhas.
- `bin/rails test test/system/admin test/system/users`: 74 testes, 0 falhas.
  `bin/rails test test/system/sessions`: 2 testes, 0 falhas.
- `bin/rubocop`: 195 arquivos, nenhuma ofensa. `bundle exec erb_lint --lint-all`: nenhum erro.
- `bundle exec brakeman --no-pager`: nenhum aviso. `bin/importmap audit`: nenhum pacote vulnerável.
- Verificação visual em 1400, 390 e 320 px da entrada, da página do campus, da listagem de espaços
  (sem filtro, filtrada e sem resultados), dos blocos, do formulário de espaço e do menu do campus
  com o seletor aberto: nenhuma página com rolagem horizontal.
- Revisão independente: nenhum bug no comportamento entregue. Os ajustes que ela pediu estão em
  "Ajustes durante a implementação", no [plano](plan.md).

| Critério | Evidência |
|---|---|
| CA1 | `test/controllers/admin/home_controller_test.rb` (cartões em ordem, resumo, aviso de indisponíveis, cadastros gerais) · `test/queries/admin/campus_summaries_query_test.rb` · sistema: `manage_campus_test.rb` ("shows the counts of each campus on the entry…") e `manage_campus_on_phone_test.rb` |
| CA2 | `test/controllers/admin/campi_controller_test.rb` (visão geral, menu, resumos, indisponíveis) · `test/components/admin/campus_menu_component_test.rb` · `test/presenters/admin/campus_overview_presenter_test.rb` · sistema: `manage_campus_test.rb` (seletor, seções, campus único) |
| CA3 | `test/controllers/admin/campi/buildings_controller_test.rb` e `spaces_controller_test.rb` (listagem, cadastro, edição e exclusão sem o campo Campus) · `test/controllers/admin/legacy_routes_test.rb` · sistema: `manage_buildings_test.rb` e `manage_spaces_test.rb` |
| CA4 | `spaces_controller_test.rb` ("rejects a building of another campus…", "rejects moving a space to a building of another campus") · sistema: `manage_spaces_test.rb` ("the form shows the campus and offers only its buildings") |
| CA5 | `test/controllers/admin/campi/spaces_filters_test.rb` · `test/forms/admin/space_filters_form_test.rb` · `test/queries/admin/campus_spaces_query_test.rb` · `test/value_objects/comparable_name_test.rb` · sistema: `filter_spaces_test.rb` (frame sem recarregar, filtros no endereço, foco, recarga, limpar) |
| CA6 | `test/models/building/building_campus_readonly_test.rb` e `test/models/space/space_campus_readonly_test.rb` · `buildings_controller_test.rb` ("ignores a campus sent with a new building", "keeps the building and its spaces in their campus when another campus is sent") · `spaces_controller_test.rb` ("ignores a campus sent when creating a space", "keeps the campus of a space when another campus is sent") · testes de acesso com `manage_campus?` negado |
| CA7 | Saíram o callback de movimentação, as chaves `campus_change_hint` e `success_with_spaces` e o `filtered_select_controller.js` (busca sem resultados em `app`, `config`, `lib` e `test`) · `building_campus_readonly_test.rb` ("leaves the spaces of the building in its campus") |
| CA8 | Sistema: `manage_campus_on_phone_test.rb`, `manage_buildings_on_phone_test.rb` e `manage_spaces_on_phone_test.rb` (320 px, sem rolagem horizontal, alvos de toque de 44 px) · verificação visual acima |
| CA9 | Todos os testes acima, mais os de acesso: `campi_controller_access_test.rb`, `campi/buildings_controller_access_test.rb`, `campi/spaces_controller_access_test.rb` e `test/policies/admin_policy_test.rb` |
