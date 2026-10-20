# Cadastro de campi — Tarefas

Issue: #56 · [spec.md](spec.md) · [plan.md](plan.md)

Legenda: `[ ]` pendente · `[~]` em andamento · `[x]` concluída

## T1 — Modelo `Campus` e tabela `campi`

- [x] Status
- **Objetivo:** campi têm nome obrigatório, normalizado e único comparando só letras e números, sem
  diferenciar maiúsculas nem acentos, com mensagens de erro próprias.
- **Requisitos:** RN1–RN6 · CA2, CA3, CA7
- **Passos:** testes de modelo (inflexão, normalização, validações, restrições do banco) → regra
  irregular em `inflections.rb` → migration `CreateCampi` → `NormalizedUniquenessValidator` →
  `app/models/campus.rb` → factory `:campus` → modelo e atributos em `models.pt-BR.yml`.
- **Verificação:** `bin/rails test test/models/campus` e diff do `db/schema.rb` só com `campi`.
- **Depende de:** —

## T2 — Mensagens no layout logado

- [x] Status
- **Objetivo:** as páginas da área logada exibem as mensagens flash como toast.
- **Requisitos:** RF7 · CA1
- **Passos:** teste de integração (aviso "já conectado" aparece no Dashboard) →
  `Flash::ToastMessageComponent` em `layouts/users/application.html.erb`.
- **Verificação:** `bin/rails test test/controllers/users/home_controller_test.rb`
- **Depende de:** —

## T3 — Listagem e atalho na área administrativa

- [x] Status
- **Objetivo:** admin vê os campi em ordem alfabética em `/admin/campi`, com mensagem de lista vazia,
  e chega lá pelo card "Campi" de `/admin`.
- **Requisitos:** RF1, RF6 · CA1
- **Passos:** testes de integração → `resources :campi, except: :show` → `Admin::CampiController#index`
  → `index` e `_campus` → partial `_registrations` em `admin/home` → textos em `views.pt-BR.yml`.
- **Verificação:** `bin/rails test test/controllers/admin`
- **Depende de:** T1

## T4 — Cadastro e edição

- [x] Status
- **Objetivo:** admin cadastra e edita campi; dados inválidos voltam ao formulário com erro e 422.
- **Requisitos:** RF2, RF3, RF5 · CA1, CA2, CA3
- **Passos:** testes de integração → `new`, `create`, `edit`, `update` e `set_campus` (404) → `_form`,
  `new` e `edit` → textos.
- **Verificação:** `bin/rails test test/controllers/admin/campi_controller_test.rb`
- **Depende de:** T2, T3

## T5 — Exclusão

- [x] Status
- **Objetivo:** admin exclui um campus depois de confirmar e vê a mensagem.
- **Requisitos:** RF4 · CA1
- **Passos:** testes de integração → `destroy` → botão Excluir com `data-turbo-confirm` → textos.
- **Verificação:** `bin/rails test test/controllers/admin/campi_controller_test.rb`
- **Depende de:** T3

## T6 — Controle de acesso do cadastro

- [x] Status
- **Objetivo:** visitante vai para o login e usuário comum recebe 403 nas seis ações, sem alterar
  dados.
- **Requisitos:** Regras de acesso · CA4, CA5
- **Passos:** `test/controllers/admin/campi_controller_access_test.rb`.
- **Verificação:** `bin/rails test test/controllers/admin/campi_controller_access_test.rb`
- **Depende de:** T4, T5

## T7 — Fluxo completo no navegador

- [x] Status
- **Objetivo:** comprovar cadastro, edição e exclusão com confirmação e toast no navegador.
- **Requisitos:** RF2–RF4, RF7 · CA1
- **Passos:** `test/system/admin/campi/manage_campi_test.rb`.
- **Verificação:** `bin/rails test test/system/admin/campi/manage_campi_test.rb`
- **Depende de:** T2, T4, T5

## T8 — Campus local no populate

- [x] Status
- **Objetivo:** o populate apaga os campi e cria Guarapuava.
- **Requisitos:** RF8 · CA6
- **Passos:** teste do populator → `reset_records` e `setup_campi`.
- **Verificação:** `bin/rails test test/lib`
- **Depende de:** T1

## T9 — Verificação final

- [x] Status
- **Objetivo:** evidência de todos os critérios e nenhuma regressão.
- **Requisitos:** CA1–CA7 · Definition of Done
- **Passos:** suíte completa, system tests, RuboCop, ERB Lint, Brakeman, `bin/ci`, revisão do diff,
  evidências nesta página.
- **Verificação:** todos os comandos da seção "Comandos de verificação" do plano sem falhas.
- **Depende de:** T1–T8

## T10 — Trilha de navegação

- [x] Status
- **Objetivo:** a área logada monta a trilha a partir do Dashboard; a área administrativa e o cadastro
  de campi acrescentam seus itens; o 403 não mostra a trilha.
- **Requisitos:** RF9 · Regras de acesso
- **Passos:** testes de integração → concern `Breadcrumbs` → `default_breadcrumbs` em
  `Users::BaseController` e `Admin::BaseController` → `set_breadcrumbs` em `Admin::CampiController` →
  `clear_breadcrumbs` no 403 → textos.
- **Verificação:** `bin/rails test test/controllers`
- **Depende de:** T3–T6

## T11 — Cabeçalho da página no layout

- [x] Status
- **Objetivo:** o layout logado renderiza trilha, título e subtítulo; as views deixam de escrever
  `<h1>`.
- **Requisitos:** RF9
- **Passos:** testes de integração (um `<h1>` no conteúdo, subtítulo) → `Page::HeaderComponent` e
  `Page::BreadcrumbsComponent` → layout → `head_subtitle` nas views de campi e de `/admin` → Dashboard
  e 403 sem `<h1>` próprio.
- **Verificação:** `bin/rails test test/controllers`
- **Depende de:** T10

## T12 — Listagem e formulário mobile first

- [x] Status
- **Objetivo:** listagem sem rolagem horizontal em 320 px, formulário com a largura toda, `if` da
  listagem só com partials e inputs sem zoom no iOS.
- **Requisitos:** RF1–RF3, RF10
- **Passos:** system test em 320 × 640 → `_table` e `shared/_empty_state` → botões só com ícone no
  celular e `.btn-delete` → formulário sem `max-w-xl`, com placeholder e botões empilhados no
  celular → padding do `main` → fonte do `Form::Input::BaseComponent`.
- **Verificação:** `bin/rails test test/system/admin/campi` e screenshots em 1400, 390 e 320 px
- **Depende de:** T11

## T13 — Verificação da revisão do layout

- [x] Status
- **Objetivo:** evidência de RF9 e RF10 e nenhuma regressão.
- **Requisitos:** RF9, RF10 · Definition of Done
- **Passos:** suíte completa, system tests, RuboCop, ERB Lint, Brakeman, `bin/ci`, evidências nesta
  página.
- **Verificação:** comandos da seção "Comandos de verificação" do plano.
- **Depende de:** T10–T12

## Evidências (2026-10-19)

| CA | Evidência |
| --- | --- |
| CA1 | `test/controllers/admin/campi_controller_test.rb` (listagem em ordem alfabética, lista vazia, cadastro, edição, exclusão com confirmação e mensagens); `test/controllers/admin/home_controller_test.rb` (atalho); `test/controllers/users/home_controller_test.rb` (toast no layout); `test/system/admin/campi/manage_campi_test.rb` (fluxo no navegador, confirmação aceita e recusada) |
| CA2 | `test/models/campus/campus_validations_test.rb` (nome vazio e só com espaços); `campi_controller_test.rb` (422 com "não pode ficar em branco") |
| CA3 | `campus_validations_test.rb` (nome exato, maiúsculas, maiúsculas acentuadas, sem acento, sem cedilha, sem espaços, com pontuação, espaços extras, renomear para outro campus; o próprio campus pode trocar maiúsculas e acentos); `campus_normalize_test.rb`; `campi_controller_test.rb` (duplicata no cadastro e na edição); system test (erro com "campo mourao") |
| CA4 | `test/controllers/admin/campi_controller_access_test.rb` — usuário comum recebe 403 nas seis ações, sem alterar dados, e antes de buscar o campus |
| CA5 | mesmo arquivo — visitante é redirecionado para `/login` nas seis ações, sem alterar dados |
| CA6 | `test/lib/tasks/db/populate/populator_test.rb` — após o populate, existe só Guarapuava |
| CA7 | todos os anteriores, mais `campus_constraints_test.rb` e `campus_inflection_test.rb` |

| Comando | Resultado |
| --- | --- |
| `bin/rails test` | 84 runs, 345 assertions, 0 failures, 0 errors |
| `bin/rails test:system` | 6 runs, 13 assertions, 0 failures, 0 errors |
| `bin/rubocop` | 92 files inspected, no offenses |
| `bundle exec erb_lint --lint-all` | No errors |
| `bin/brakeman --no-pager` | No warnings |
| `bin/ci` | todas as etapas passaram |

### Observações

- **Testes de acesso conferidos contra falha:** com `skip_before_action :require_admin_area_access`
  adicionado temporariamente ao controller, o teste de acesso falhou (404 em vez de 403). O controller
  foi restaurado e o teste voltou a passar.
- **Migration:** `db:rollback` devolveu o `db/schema.rb` ao estado do `main` e `db:migrate` reaplicou
  a tabela. O diff do `schema.rb` contém só a tabela `campi` e a versão.
- **Telas:** conferidas por screenshot (listagem, formulário com erro e atalho em `/admin`).
- `bin/rails db:populate` não foi rodado no banco de desenvolvimento. O teste do populator cobre o CA6.

## Evidências da revisão do layout (2026-10-20)

| Requisito | Evidência |
| --- | --- |
| RF9 | `campi_controller_test.rb` (um `<h1>`, subtítulo e trilha em ordem na listagem, no cadastro e na edição, também após erro 422); `home_controller_test.rb` de `/admin` (título, subtítulo e trilha); `users/home_controller_test.rb` (Dashboard sem trilha e com um `<h1>`); `home_controller_access_test.rb` e `campi_controller_access_test.rb` (403 sem trilha) |
| RF10 | `test/system/admin/campi/manage_campi_on_phone_test.rb` (em 320 × 640, a tabela cabe na tela com Editar e Excluir, e o cadastro funciona) |

| Comando | Resultado |
| --- | --- |
| `bin/rails test` | 88 runs, 419 assertions, 0 failures, 0 errors |
| `bin/rails test:system` | 8 runs, 19 assertions, 0 failures, 0 errors |
| `bin/rubocop` | 97 files inspected, no offenses |
| `bundle exec erb_lint --lint-all` | No errors |
| `bundle exec brakeman --no-pager --exit-on-warn --exit-on-error` | 0 errors, 0 security warnings |
| `bin/ci` | todas as etapas passaram, menos Brakeman: `bin/brakeman` usa `--ensure-latest`, que consulta o rubygems.org e quebrou sem rede (`undefined method 'date' for nil`) antes da análise |

### Observações

- **Testes conferidos contra falha:** sem `clear_breadcrumbs`, os dois testes de 403 sem trilha
  falharam. Com o `_campus.html.erb` da primeira versão, o teste em 320 px falhou (tabela até 334 px
  numa tela de 320 px). Em 390 e 360 px a versão antiga cabia, porque o navegador espreme a coluna do
  nome. Por isso o teste usa 320 px, a largura do critério de reflow da WCAG (1.4.10).
- **Telas:** conferidas por screenshot em 1400, 390 e 320 px (listagem, lista vazia, cadastro com
  erro, edição e `/admin`).
