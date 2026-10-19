# Acesso à área administrativa — Plano técnico

Issue: #55 · Especificação: [spec.md](spec.md)

Status: aprovado em 2026-10-16.

## Abordagem técnica

1. **Perfil no banco.** Uma migration adiciona `users.admin` (`boolean`, `default: false`,
   `null: false`). O modelo valida `inclusion: { in: [ true, false ] }`, então um perfil vazio vira
   erro de validação (e não só exceção do banco). O predicado `admin?` vem do Active Record.
2. **Decisão de autorização em um Policy Object.** `AdminPolicy` (`app/policies/`) recebe o
   usuário e expõe `access_area?`. Hoje é `user.admin?`. Esse é o único lugar que decide quem entra na
   área, como pede a skill `rails-domain-and-queries` ("Use a Policy Object for authorization").
3. **Ponte para controllers e views.** `Users::BaseController` ganha o método privado
   `can_access_admin_area?` (exposto com `helper_method`), que delega para a policy. O controller
   administrativo e o menu lateral usam o mesmo método.
4. **Namespace administrativo.** `Admin::BaseController < Users::BaseController` herda autenticação,
   layout `users/application` e flash types, e adiciona `before_action :require_admin_area_access`.
   Qualquer controller futuro em `Admin::` herda a restrição (regra "páginas futuras herdam a
   restrição").
5. **Acesso negado.** Sem permissão, o before_action faz
   `render "shared/forbidden", status: :forbidden`, o que interrompe a cadeia. A página fica dentro do
   layout logado, com mensagem i18n e link para o Dashboard.
6. **Rota.** `namespace :admin { root "home#index" }` gera `admin_root_path` em `/admin`, atendido por
   `Admin::HomeController#index` (página simples com título e descrição).
7. **Menu lateral.** O array de itens de `_sidebar.html.erb` recebe o item "Área administrativa"
   (ícone `:shield_check`) somente quando `can_access_admin_area?`.
8. **Populate.** `Db::Populator#setup_users` também cria `admin@utfpr.edu.br` com `admin: true`. O
   `demo@utfpr.edu.br` continua comum.

### Fluxo de uma requisição a `/admin`

```text
GET /admin
  └─ Admin::HomeController (herda Admin::BaseController < Users::BaseController)
       1. require_authentication     → visitante: redirect /login            (RF4)
       2. require_admin_area_access  → AdminPolicy#access_area? falso: 403     (RF3)
       3. index                      → página administrativa                 (RF2)
```

A ordem é garantida: o `before_action :require_authentication` é registrado no
`include Authentication` de `Users::BaseController`, antes do callback da subclasse.

## Arquivos afetados

| Arquivo | Mudança |
| --- | --- |
| `db/migrate/<timestamp>_add_admin_to_users.rb` | Novo: `add_column :users, :admin, :boolean, default: false, null: false` |
| `db/schema.rb` | Regenerado pela migration (não editar à mão) |
| `app/models/user.rb` | `validates :admin, inclusion: { in: [ true, false ] }` |
| `app/policies/admin_policy.rb` | Novo: `initialize(user)` e `access_area?` |
| `app/controllers/users/base_controller.rb` | `helper_method :can_access_admin_area?` + método privado delegando à policy |
| `app/controllers/admin/base_controller.rb` | Novo: herda `Users::BaseController`, `before_action :require_admin_area_access` |
| `app/controllers/admin/home_controller.rb` | Novo: action `index` vazia |
| `config/routes.rb` | `namespace :admin do root "home#index" end` |
| `app/views/admin/home/index.html.erb` | Novo: título e descrição |
| `app/views/shared/forbidden.html.erb` | Novo: "Acesso negado", mensagem e link para o Dashboard |
| `app/views/layouts/users/partials/_sidebar.html.erb` | Item condicional "Área administrativa" |
| `app/helpers/icons_helper.rb` | Novo ícone `:shield_check` (Heroicons 24 outline) |
| `config/locales/pt-BR/views.pt-BR.yml` | Chaves `users.home.layouts.sidebar.admin`, `admin.home.index.*`, `shared.forbidden.*` |
| `config/locales/pt-BR/models.pt-BR.yml` | Atributo `user.admin: Administrador` |
| `lib/tasks/db/populate/populator.rb` | Cria o administrador local |
| `test/factories/users.rb` | Trait `:admin` |

### Textos (pt-BR)

| Chave | Texto |
| --- | --- |
| `users.home.layouts.sidebar.admin` | Área administrativa |
| `admin.home.index.title` | Área administrativa |
| `admin.home.index.description` | Os cadastros e configurações do sistema ficarão disponíveis aqui. |
| `shared.forbidden.title` | Acesso negado |
| `shared.forbidden.message` | Você não tem permissão para acessar esta página. |
| `shared.forbidden.back` | Voltar ao Dashboard |
| `activerecord.attributes.user.admin` | Administrador |

## Banco de dados e compatibilidade

- `add_column` com `default: false` e `null: false` é suportado pelo SQLite. Usuários existentes
  ficam com `admin = false`, sem backfill.
- A migration é reversível (`add_column` dentro de `change`).
- **Produção:** o primeiro administrador é definido manualmente depois do deploy, por exemplo:
  `bin/kamal console` e então `User.find_by!(email_address: "...").update!(admin: true)`. Vou deixar
  esse passo descrito no PR.

## Estratégia de testes

| Arquivo | Tipo | O que verifica | CA |
| --- | --- | --- | --- |
| `test/models/user/user_admin_test.rb` | Modelo | Usuário novo não é admin; `admin: nil` é inválido com mensagem i18n | CA1 |
| `test/policies/admin_policy_test.rb` | Unidade | `access_area?` verdadeiro para admin e falso para comum | CA3, CA4 |
| `test/controllers/admin/home_controller_access_test.rb` | Integração | Visitante → redirect `/login`; comum → 403 com "Acesso negado" e link para o Dashboard; admin → 200 com o título | CA2–CA5 |
| `test/controllers/users/home_controller_test.rb` | Integração | Admin vê `a[href="/admin"]` no menu lateral; comum não vê | CA6 |
| `test/lib/tasks/db/populate/populator_test.rb` | Unidade | Após o populate, `admin@` é admin e `demo@` é comum | CA7 |

- As respostas HTML também verificam `assert_no_match(/translation missing/i, response.body)`, como
  os testes existentes, porque `raise_on_missing_translations` está desligado no ambiente de teste.
- **Sem system test novo:** o atalho é um link comum, sem JavaScript, e a skill
  `rails-testing-standards` reserva system tests para comportamento que depende do navegador. Vou
  rodar os system tests existentes (`test/system/users/dashboard/hello_test.rb` e o de login) para
  garantir que o layout não quebrou.

## Autorização e segurança

- A proteção está no servidor (before_action herdado). O item do menu é só conveniência.
- O 403 não revela nada da área: a página negada é genérica.
- Nenhum `params.permit` do sistema inclui `admin`. Hoje o único formulário de usuário é o login
  (`email_address`, `password`), então não existe caminho de atribuição em massa.
- Um usuário que perde o perfil de admin perde o acesso na próxima requisição: a policy lê o valor
  atual a cada request.
- Vou rodar `bin/brakeman --no-pager` na verificação.

## Riscos e trade-offs

- **Policy Object para uma regra de uma linha.** Poderíamos chamar `Current.user.admin?` direto, que
  é mais simples. Sigo a skill do professor porque a decisão fica num lugar só, e as Issues #56–#63
  vão reaproveitar essa base.
- **Conflito com a skill de frontend sobre `<h1>`.** A skill proíbe `<h1>` no corpo porque "o layout
  já renderiza `yield(:head_title)`", mas o layout `users/application` não renderiza isso. Sigo o
  padrão do Dashboard (`provide :title` + `<h1>` no corpo) para manter a consistência visual.
- **Chaves i18n.** A skill sugere `web.<role>.<resource>`, mas o projeto usa a hierarquia das views
  (`users.home...`, `users.reservations...`). Sigo o projeto, com lazy lookup (`t(".title")`).
- **Ícone novo.** Os ícones atuais são de estilos misturados. O novo `:shield_check` segue o padrão
  Heroicons 24 outline exigido pela skill.
- **`app/policies/` é um diretório novo.** Em desenvolvimento, pode ser preciso reiniciar o
  `bin/dev` para o autoload enxergá-lo.

## Comandos de verificação

```bash
bin/rails db:migrate
bin/rails test test/models/user test/policies test/controllers/admin test/controllers/users/home_controller_test.rb test/lib
bin/rails test
bin/rails test test/system/users/dashboard/hello_test.rb test/system/sessions/login/user_login_test.rb
bin/rubocop
bundle exec erb_lint --lint-all
bin/brakeman --no-pager
bin/ci
```

- `bin/rails db:populate` **apaga e recria os usuários do banco de desenvolvimento**. Só vou rodá-lo
  com a sua autorização. O teste automatizado do populator cobre o CA7 sem tocar no banco de
  desenvolvimento.
