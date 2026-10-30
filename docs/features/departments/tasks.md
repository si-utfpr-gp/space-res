# Cadastro de departamentos — Tarefas

Issue: #58 · [spec.md](spec.md) · [plan.md](plan.md)

Legenda: `[ ]` pendente · `[~]` em andamento · `[x]` concluída

## T1 — Modelo `Department` e tabela `departments`

- [x] Status
- **Objetivo:** departamentos têm nome obrigatório, normalizado e único pela comparação de campi, com
  mensagens próprias.
- **Requisitos:** RN1–RN5 · CA2, CA3, CA6
- **Passos:** testes de modelo (normalização, validações, restrições do banco) → migration
  `CreateDepartments` → `app/models/department.rb` → factory `:department` → modelo, atributos e erros
  em `models.pt-BR.yml` e `errors.pt-BR.yml`.
- **Verificação:** `bin/rails test test/models/department` e diff do `db/schema.rb` só com
  `departments`.
- **Depende de:** —

## T2 — Listagem e atalho na área administrativa

- [x] Status
- **Objetivo:** admin vê os departamentos em ordem alfabética em `/admin/departments`, com título,
  subtítulo, trilha e lista vazia, e chega lá pelo card de `/admin`.
- **Requisitos:** RF1, RF6, RF7 · CA1
- **Passos:** testes de integração → `resources :departments, except: :show` →
  `Admin::DepartmentsController#index` e `set_breadcrumbs` → `index`, `_table` e `_department` → card
  em `_registrations` → textos em `views.pt-BR.yml`. Durante a verificação visual, entrou o
  `fill="currentColor"` do ícone `:users`. `Department.sorted` ordena no banco (`order(:name)`), como
  pedido na revisão da PR #73.
- **Verificação:** `bin/rails test test/controllers/admin`
- **Depende de:** T1

## T3 — Cadastro e edição

- [x] Status
- **Objetivo:** admin cadastra e edita departamentos; dados inválidos voltam ao formulário com erro e
  422; id inexistente responde 404.
- **Requisitos:** RF2, RF3, RF5, RF7 · CA1–CA3
- **Passos:** testes de integração → `new`, `create`, `edit`, `update` e `set_department` → `_form`,
  `new` e `edit` → textos e placeholder.
- **Verificação:** `bin/rails test test/controllers/admin/departments_controller_test.rb`
- **Depende de:** T2

## T4 — Exclusão

- [x] Status
- **Objetivo:** admin exclui um departamento depois de confirmar e vê a mensagem.
- **Requisitos:** RF4, RN6 · CA1
- **Passos:** testes de integração → `destroy` → botão Excluir com `data-turbo-confirm` → textos.
- **Verificação:** `bin/rails test test/controllers/admin/departments_controller_test.rb`
- **Depende de:** T2

## T5 — Controle de acesso

- [x] Status
- **Objetivo:** visitante vai para o login e usuário comum recebe 403 nas seis ações, sem alterar
  dados e sem ver a trilha.
- **Requisitos:** Regras de acesso · CA4
- **Passos:** `test/controllers/admin/departments_controller_access_test.rb`, conferido contra falha.
- **Verificação:** `bin/rails test test/controllers/admin/departments_controller_access_test.rb`
- **Depende de:** T3, T4

## T6 — Populate

- [x] Status
- **Objetivo:** o populate apaga os departamentos e cria os 25 de Guarapuava.
- **Requisitos:** RF9 · CA5
- **Passos:** teste do populator → constante `DEPARTMENTS`, `reset_records` e `setup_departments`.
- **Verificação:** `bin/rails test test/lib`
- **Depende de:** T1

## T7 — Testes de sistema

- [x] Status
- **Objetivo:** comprovar no navegador o fluxo completo, com confirmação e toast, e a listagem em
  320 px com o nome mais longo.
- **Requisitos:** RF1–RF5, RF8 · CA1, CA3
- **Passos:** `manage_departments_test.rb` e `manage_departments_on_phone_test.rb`.
- **Verificação:** `bin/rails test test/system/admin/departments`
- **Depende de:** T3, T4

## T8 — Verificação final

- [x] Status
- **Objetivo:** evidência de todos os critérios e nenhuma regressão.
- **Requisitos:** CA1–CA6 · Definition of Done
- **Passos:** suíte completa, system tests, RuboCop, ERB Lint, Brakeman, `bin/ci`, revisão do diff,
  evidências nesta página.
- **Verificação:** comandos da seção "Comandos de verificação" do plano.
- **Depende de:** T1–T7

## Evidências (2026-10-27)

| CA | Evidência |
| --- | --- |
| CA1 | `test/controllers/admin/departments_controller_test.rb` (listagem em ordem alfabética, lista vazia, título, subtítulo e trilha nas três páginas, cadastro, edição, exclusão com confirmação e toast, 404); `test/models/department/department_sorted_test.rb`; `test/controllers/admin/home_controller_test.rb` (atalho); `test/system/admin/departments/manage_departments_test.rb` (fluxo no navegador, confirmação aceita e recusada); `manage_departments_on_phone_test.rb` (320 × 640 com o nome mais longo e cadastro pelo celular) |
| CA2 | `test/models/department/department_validations_test.rb` (nome vazio e só com espaços, com a mensagem própria); `departments_controller_test.rb` (422 com "Informe o nome do departamento.") |
| CA3 | `department_validations_test.rb` (shoulda `case_insensitive`, maiúsculas acentuadas, sem acento e cedilha, sem espaços, com pontuação, renomear para outro departamento; o próprio departamento pode trocar maiúsculas e acentos); `department_normalize_test.rb`; `departments_controller_test.rb` (duplicata no cadastro e na edição); system test (erro com "departamento de educacao") |
| CA4 | `test/controllers/admin/departments_controller_access_test.rb` — visitante vai para `/login` e usuário comum recebe 403 nas seis ações, sem alterar dados, antes de buscar o departamento e sem ver a trilha |
| CA5 | `test/lib/tasks/db/populate/populator_test.rb` — o populate apaga os departamentos existentes e cria os 25 de Guarapuava |
| CA6 | todos os anteriores, mais `department_constraints_test.rb` |

| Comando | Resultado |
| --- | --- |
| `bin/rails test` | 172 runs, 885 assertions, 0 failures, 0 errors |
| `bin/rails test:system` | 20 runs, 59 assertions, 0 failures, 0 errors |
| `bin/rubocop` | 125 files inspected, no offenses detected |
| `bundle exec erb_lint --lint-all` | No errors were found in ERB files |
| `bundle exec brakeman --no-pager --exit-on-warn --exit-on-error` | 0 errors, 0 security warnings |
| `bin/ci` | todas as etapas passaram |

### Observações

- **Teste de acesso conferido contra falha:** com `skip_before_action :require_admin_area_access`
  adicionado temporariamente ao controller, o teste falhou (200 e 404 em vez de 403). O controller foi
  restaurado e o teste voltou a passar.
- **Migration:** `db:rollback` devolveu o `db/schema.rb` ao estado do `main` e `db:migrate` reaplicou a
  tabela. O diff do `schema.rb` contém só a tabela `departments` e a versão.
- **Telas:** conferidas por screenshot em 1400 e 320 px (`/admin`, listagem com os 25 departamentos e
  cadastro com erro). Elas mostraram o ícone preto, corrigido nesta Issue.
- `bin/rails db:populate` não foi rodado no banco de desenvolvimento. O teste do populator cobre o CA5.
