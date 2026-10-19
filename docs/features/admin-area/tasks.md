# Acesso à área administrativa — Tarefas

Issue: #55 · [spec.md](spec.md) · [plan.md](plan.md)

Legenda: `[ ]` pendente · `[~]` em andamento · `[x]` concluída

## T1 — Perfil de administrador no usuário

- [x] Status
- **Objetivo:** usuários têm `admin` (`false` por padrão, nunca vazio).
- **Requisitos:** RF1 · CA1
- **Passos:** teste de modelo → migration `AddAdminToUsers` → validação de inclusão → trait `:admin`
  na factory → atributo traduzido em `models.pt-BR.yml`.
- **Verificação:** `bin/rails test test/models/user`
- **Depende de:** —

## T2 — Policy de acesso à área administrativa

- [x] Status
- **Objetivo:** `AdminPolicy#access_area?` concentra a decisão de acesso.
- **Requisitos:** regra "verificação no servidor" · base para CA3/CA4
- **Passos:** teste da policy → `app/policies/admin_policy.rb`.
- **Verificação:** `bin/rails test test/policies`
- **Depende de:** T1

## T3 — Área `/admin` protegida

- [x] Status
- **Objetivo:** admin acessa `/admin`; comum recebe 403 com página no layout; visitante vai para o
  login.
- **Requisitos:** RF2, RF3, RF4 · CA2, CA3, CA4, CA5
- **Passos:** teste de integração → rota `namespace :admin` → `helper_method :can_access_admin_area?` em
  `Users::BaseController` → `Admin::BaseController` e `Admin::HomeController` → views
  `admin/home/index` e `shared/forbidden` → textos em `views.pt-BR.yml`.
- **Verificação:** `bin/rails test test/controllers/admin`
- **Depende de:** T2

## T4 — Atalho no menu lateral

- [x] Status
- **Objetivo:** "Área administrativa" aparece no menu lateral só para admins.
- **Requisitos:** RF5 · CA6
- **Passos:** teste de integração → ícone `:shield_check` → item condicional em `_sidebar.html.erb` →
  texto em `views.pt-BR.yml`.
- **Verificação:** `bin/rails test test/controllers/users/home_controller_test.rb`
- **Depende de:** T3

## T5 — Administrador local no populate

- [x] Status
- **Objetivo:** o populate cria `admin@utfpr.edu.br` (admin) e mantém `demo@utfpr.edu.br` comum.
- **Requisitos:** RF6 · CA7
- **Passos:** teste do populator → `setup_users` cria o admin.
- **Verificação:** `bin/rails test test/lib`
- **Depende de:** T1

## T6 — Verificação final

- [x] Status
- **Objetivo:** evidência de todos os critérios e nenhuma regressão.
- **Requisitos:** CA8 · Definition of Done
- **Passos:** suíte completa, system tests existentes, RuboCop, ERB Lint, Brakeman, `bin/ci`, revisão
  do diff.
- **Verificação:** todos os comandos da seção "Comandos de verificação" do plano sem falhas.
- **Depende de:** T1–T5

## Evidências (2026-10-16)

| CA | Evidência |
| --- | --- |
| CA1 | `test/models/user/user_admin_test.rb` (padrão `false`, `nil` inválido) |
| CA2 | `test/controllers/admin/home_controller_access_test.rb` — admin recebe 200 |
| CA3, CA4 | mesmo arquivo — usuário comum recebe 403 com "Acesso negado"; `test/policies/admin_policy_test.rb` |
| CA5 | mesmo arquivo — visitante é redirecionado para `/login` |
| CA6 | `test/controllers/users/home_controller_test.rb` — link só para admin |
| CA7 | `test/lib/tasks/db/populate/populator_test.rb` |
| CA8 | todos os anteriores |

| Comando | Resultado |
| --- | --- |
| `bin/rails test` | 45 runs, 184 assertions, 0 failures, 0 errors |
| `bin/rails test:system` | 3 runs, 4 assertions, 0 failures, 0 errors |
| `bin/rubocop` | 79 files inspected, no offenses |
| `bundle exec erb_lint --lint-all` | No errors |
| `bin/brakeman --no-pager` | No warnings |
| `bin/ci` | todas as etapas passaram |

### Observação de ambiente

O banco de desenvolvimento local tinha duas migrations do branch `feat/departments-db`
(`20261006212436`, `20261006212502`) sem arquivo neste branch. Rodar `db:migrate` em desenvolvimento
gravou a tabela `departments` no `db/schema.rb`. O schema foi regenerado a partir de um banco de teste
limpo (`RAILS_ENV=test bin/rails db:drop db:create db:schema:load db:migrate`) e contém só a coluna
`admin`.
