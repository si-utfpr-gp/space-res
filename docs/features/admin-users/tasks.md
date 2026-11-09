# Gestão de usuários pelo admin — Tarefas

Issue: #59 · [spec.md](spec.md) · [plan.md](plan.md)

Legenda: `[ ]` pendente · `[~]` em andamento · `[x]` concluída

## T1 — Departamento no modelo `User`

- [x] Status
- **Objetivo:** um usuário tem um departamento opcional, que precisa existir quando informado; o banco
  recusa departamento inexistente; usuários podem ser ordenados por nome.
- **Requisitos:** RN1, RN3, RN6 · CA2, CA6
- **Passos:** testes de modelo (`belong_to(:department).optional`, departamento inexistente,
  `ordered_by_name`, chave estrangeira) → migration `AddDepartmentToUsers` → `app/models/user.rb` → trait
  `:with_department` na factory → textos em `models.pt-BR.yml` e `errors.pt-BR.yml`. O teste de
  departamento inexistente (`department_id: 0`) pegou que `if: :department_id?` pula a validação para
  zero; a condição virou `unless: -> { department_id.nil? }`.
- **Verificação:** `bin/rails test test/models/user`, `db:migrate:down` e `db:migrate` de novo, e diff do
  `db/schema.rb` só com `department_id`, índice e chave estrangeira.
- **Depende de:** —

## T2 — Exclusão de departamento com usuários

- [x] Status
- **Objetivo:** excluir um departamento com usuários vinculados é recusado com mensagem; sem usuários,
  continua sendo excluído.
- **Requisitos:** RF4, RN5, RN6 · CA3, CA6
- **Passos:** testes de modelo e de integração → `has_many :users, dependent: :restrict_with_error` →
  ramo de recusa em `Admin::DepartmentsController#destroy` → mensagem em `errors.pt-BR.yml`.
- **Verificação:** `bin/rails test test/models/department test/controllers/admin/departments_controller_test.rb`
- **Depende de:** T1

## T3 — Listagem e atalho na área administrativa

- [x] Status
- **Objetivo:** admin vê os usuários em ordem de nome em `/admin/users`, com e-mail, departamento ou
  "Sem departamento" e selo "Administrador", com título, subtítulo e trilha, e chega lá pelo card de
  `/admin`.
- **Requisitos:** RF1, RF5, RF6, RF7 · CA1, CA4
- **Passos:** testes de integração → `resources :users, only: [ :index, :edit, :update ]` →
  `Admin::UsersController#index` e `set_breadcrumbs` → `index`, `_table` e `_user` → card em
  `_registrations` e `fill="currentColor"` no ícone `:person` → textos em `views.pt-BR.yml`.
- **Verificação:** `bin/rails test test/controllers/admin/users_controller_test.rb test/controllers/admin/home_controller_test.rb`
- **Depende de:** T1

## T4 — Edição do departamento

- [x] Status
- **Objetivo:** admin define, troca e remove o departamento de um usuário; nada além do departamento
  muda, mesmo em envio direto.
- **Requisitos:** RF2, RF3, RN2–RN4 · CA2, CA4
- **Passos:** testes de integração (definir, trocar, remover, campos ignorados, departamento inexistente,
  404, trilha) → `edit`, `update`, `set_user`, `set_departments`, `user_params` → `edit` e `_form` →
  textos.
- **Verificação:** `bin/rails test test/controllers/admin/users_controller_test.rb`
- **Depende de:** T3

## T5 — Controle de acesso

- [x] Status
- **Objetivo:** visitantes vão para a autenticação e usuários comuns recebem 403 em toda ação, sem
  alteração nos dados nem trilha administrativa.
- **Requisitos:** Regras de acesso · CA5, CA6
- **Passos:** `test/controllers/admin/users_controller_access_test.rb`, no formato do de departamentos.
- **Verificação:** `bin/rails test test/controllers/admin/users_controller_access_test.rb`
- **Depende de:** T4

## T6 — Populate

- [x] Status
- **Objetivo:** o banco local tem o "User Demo" na Coordenação de TSI e o "Admin Demo" sem departamento;
  popular duas vezes seguidas funciona.
- **Requisitos:** RF8
- **Passos:** teste do populator → ordem de `reset_records` e de `call` → `setup_users` com o
  departamento.
- **Verificação:** `bin/rails test test/lib` e `bin/rails db:populate` duas vezes.
- **Depende de:** T1

## T7 — Testes de sistema

- [x] Status
- **Objetivo:** o fluxo funciona no navegador, no computador e num celular de 320 px.
- **Requisitos:** RF1–RF3, RF7 · CA1, CA2
- **Passos:** `test/system/admin/users/manage_users_test.rb` e `manage_users_on_phone_test.rb`, no formato
  dos de departamentos; conferência visual em 1400, 390 e 320 px. O primeiro teste de 320 px falhou
  porque `app/assets/builds/tailwind.css` local era de 2026-11-05 e não tinha `break-all`; depois de
  `bin/rails tailwindcss:build`, passou. O arquivo é gerado e não vai para o Git.
- **Verificação:** `bin/rails test:system test/system/admin/users test/system/admin/departments`
- **Depende de:** T4

## T8 — Verificação final

- [x] Status
- **Objetivo:** todos os critérios com evidência, linters e CI local verdes, revisão independente da
  mudança (migration e controle de acesso).
- **Requisitos:** CA1–CA6
- **Passos:** `bin/ci`, `bundle exec erb_lint --lint-all`, testes de sistema, revisão com o `reviewer`,
  evidências neste arquivo.
- **Verificação:** saídas dos comandos registradas abaixo.
- **Depende de:** T1–T7

## Evidências (2026-11-09)

| Critério | Evidência |
| --- | --- |
| CA1 — listagem com nome, e-mail e departamento | `users_controller_test.rb` (ordem, e-mail, "Sem departamento", selo, título e trilha), `home_controller_test.rb` (card), `manage_users_test.rb` e `manage_users_on_phone_test.rb` (320 px sem rolagem lateral) |
| CA2 — definir, trocar e remover | `users_controller_test.rb` (definir, trocar, remover, salvar sem mudar, o próprio admin, departamento inexistente → 422), `user_department_test.rb`, `manage_users_test.rb` |
| CA3 — exclusão recusada com mensagem | `department_associations_test.rb`, `departments_controller_test.rb` (alerta e, depois de desvincular o último usuário, exclusão aceita), `manage_users_test.rb`, `user_constraints_test.rb` (chave estrangeira) |
| CA4 — perfil admin inalterável | `users_controller_test.rb` (`admin`, nome, e-mail e senha forjados ignorados; admin não perde o perfil), formulário sem campo `admin` |
| CA5 — 403 e autenticação | `users_controller_access_test.rb` (visitante, usuário comum, usuário comum em si mesmo, sem trilha, 403 antes do 404) |
| CA6 — testes automatizados | todos os acima; `populator_test.rb` para o RF8 |

Comandos executados:

- `bin/rails db:migrate`, `db:migrate:down VERSION=20261109141609` e `db:migrate`: diff do `db/schema.rb`
  só com `department_id`, índice e `add_foreign_key "users", "departments"`.
- `bin/rails db:populate` duas vezes: "User Demo" na Coordenação de TSI, "Admin Demo" sem departamento.
- `bin/rubocop`, `bundle exec erb_lint --lint-all` e `bin/ci` (Brakeman sem avisos; 249 testes, 0 falhas),
  antes dos ajustes da revisão. Depois deles: `bin/rubocop` e `erb_lint` sem ofensas, `bin/rails test`
  com 252 testes e 0 falhas, e `bin/rails test test/system/admin/users test/system/admin/departments` com
  9 testes e 0 falhas.
- `bin/rails test test/system/admin test/system/users`: 37 testes, 0 falhas.
- Conferência visual em 1400, 390 e 320 px da listagem, da edição e do card.

### Revisão independente

O `reviewer` não achou problema de acesso, atribuição em massa, corrida ou migration (testou `admin`
forjado, `department_id` com texto, zero e número enorme, e a migration de ida e volta com usuário e sessão
no banco). Ajustes feitos a partir dela:

- Erros de nome e e-mail aparecem no formulário (antes, um usuário com dado antigo inválido dava 422 sem
  mensagem).
- A validação do departamento só roda quando ele muda; um teste garante que salvar sem mudar não consulta
  `departments` (o teste falha com a condição anterior).
- Testes de 404 no `PATCH` e de exclusão depois de desvincular o último usuário.
- Constante `DEMO_USER_DEPARTMENT` no populator.
- Mantido: ordem por bytes do SQLite para nomes com acento (ver Riscos no plano).
