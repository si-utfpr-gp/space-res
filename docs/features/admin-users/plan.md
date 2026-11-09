# Gestão de usuários pelo admin — Plano técnico

Issue: #59 · Especificação: [spec.md](spec.md)

Status: aprovado em 2026-11-09; condição da validação do departamento revisada na implementação (item 2).

## Abordagem técnica

A gestão de usuários segue o formato dos cadastros de campi e departamentos: mesmo controller base,
views, trilha, toast e testes. A diferença é que só há `index`, `edit` e `update`: não se cria nem exclui
usuário.

1. **Coluna.** A migration `AddDepartmentToUsers` faz
   `add_reference :users, :department, foreign_key: true`: coluna `department_id` opcional (`NULL`
   permitido), índice e chave estrangeira para `departments`, como define a Issue. A chave estrangeira não
   tem `on_delete`: o banco recusa apagar um departamento referenciado.
2. **Modelo `User`.**
   - `belongs_to :department, optional: true` (RN1).
   - `validates :department, presence: true, if: -> { department_id_changed? && !department_id.nil? }`
     (RN3): com `optional: true` o Rails não confere se o departamento existe; esta validação recusa um
     id inexistente com a mensagem própria, em vez de deixar a chave estrangeira levantar exceção (HTTP
     500). A condição não usa `if: :department_id?`, como estava no rascunho: o método `?` do Rails
     devolve `false` para o número `0`, e um envio com `department_id: 0` pularia a validação (achado do
     teste de modelo). Só confere quando o departamento muda, para não consultar `departments` em todo
     `save` de usuário; a chave estrangeira já garante o vínculo que existe (revisão, 2026-11-09).
   - `scope :ordered_by_name, -> { order(:name) }` (RF1), nome que diz o critério, como pediu o
     professor.
3. **Modelo `Department`.** `has_many :users, dependent: :restrict_with_error` (RN5), como
   `Campus has_many :buildings`. A #61 acrescenta `has_many :spaces` da mesma forma.
4. **Rotas.** Dentro de `namespace :admin`, `resources :users, only: [ :index, :edit, :update ]`.
5. **Controller `Admin::UsersController < Admin::BaseController`.**
   - `index`: `User.includes(:department).ordered_by_name` (sem N+1 na coluna de departamento).
   - `edit`/`update`: `set_user` com `User.find(params.expect(:id))` (404 para id inexistente) e
     `set_departments` com `Department.sorted` para o select, só nas ações que mostram o formulário.
   - `update`: sucesso → `redirect_to admin_users_path, success: t(".success"), status: :see_other`;
     falha → `render :edit, status: :unprocessable_content`.
   - `user_params`: `params.expect(user: [ :department_id ])`. Só o departamento é permitido (RN2):
     `admin`, `name`, `email_address` e `password` enviados no mesmo formulário são descartados pelo
     strong parameters.
   - `set_breadcrumbs`: Usuários, mais Editar (`edit`, `update`).
6. **`Admin::DepartmentsController#destroy`.** Passa a tratar a recusa como `Admin::CampiController`:
   `if @department.destroy` → sucesso; senão `redirect_to admin_departments_path, alert:
   @department.errors.full_messages.to_sentence, status: :see_other` (RF4).
7. **Views** (`app/views/admin/users/`):
   - `index`: título, subtítulo e `_table`. Sem botão de novo e sem lista vazia: o próprio administrador
     está sempre na lista.
   - `_table` e `_user`: colunas Nome, Departamento e Ações. Na coluna Nome vão o nome, o selo
     "Administrador" (só leitura, quando `user.admin?`) e o e-mail embaixo, com `break-words`/`break-all`
     para e-mails longos. No celular, a coluna Departamento fica escondida e o departamento aparece
     embaixo do e-mail, para caber em 320 px sem rolagem horizontal (RF7). O botão Editar repete o dos
     outros cadastros: só ícone no celular, com texto a partir de `sm`.
   - `edit` e `_form`: nome e e-mail em uma lista de definição (`<dl>`), só leitura, com o erro de cada
     um embaixo (`f.full_error`): um usuário com dado antigo inválido, como um e-mail gravado à mão fora
     do formato, não pode ser salvo, e o administrador vê o motivo em vez de um 422 sem mensagem. E
     `f.select :department_id, departments.pluck(:name, :id), { include_blank: t(".no_department") },
     hint: t(".department_hint")`. A opção em branco é "Sem departamento" e grava `NULL` (RF3). Salvar e
     Cancelar como nos outros formulários.
8. **Atalho (RF5).** `admin/home/partials/_registrations.html.erb` ganha o item Usuários, depois de Termos
   de uso, com o ícone `:person`, que já existe e não é usado em nenhuma tela. O SVG dele não tem
   `fill="currentColor"` e ficaria preto no card azul, como aconteceu com `:users` nos departamentos; o
   atributo é acrescentado.
9. **Populate (RF8).**
   - `reset_records` passa a apagar `User` antes de `Department`. Com o bloqueio de exclusão, a ordem
     atual (`Department` antes de `User`) deixaria os departamentos com usuário vinculado no banco.
   - `call` cria os departamentos antes dos usuários, e `setup_users` vincula o "User Demo" à
     "Coordenação do Curso de Tecnologia em Sistemas para a Internet" com `create_with(..., department:)`.

### Fluxo de uma edição

```
PATCH /admin/users/:id  { user: { department_id: "7", admin: "1" } }
  Authentication          → visitante: redirect para /login
  require_admin_area_access → usuário comum: 403, nada gravado
  set_user                → id inexistente: 404
  user_params             → { department_id: "7" }   (admin descartado)
  @user.update            → BEGIN IMMEDIATE
                             validates :department (SELECT departments WHERE id = 7)
                             UPDATE users SET department_id = 7   (chave estrangeira confere)
                            COMMIT
  sucesso → redirect /admin/users com toast · falha → 422 com erro no campo Departamento
```

## Operações simultâneas (RN6)

Duas operações podem disputar o mesmo departamento: um administrador vincula um usuário a ele enquanto
outro o exclui. Três camadas impedem que sobre um usuário vinculado a um departamento inexistente:

1. **Validações dentro da transação.** No Rails, `save` roda as validações dentro da transação, e
   `restrict_with_error` é um `before_destroy`, também dentro da transação da exclusão.
2. **Transações `IMMEDIATE` no SQLite.** O adaptador do Rails 8.1 abre as transações com
   `default_transaction_mode: :immediate` (conferido em `sqlite3_adapter.rb`, linha 162): cada transação
   pega o lock de escrita já no `BEGIN`. A edição e a exclusão rodam uma depois da outra, e a segunda
   enxerga o resultado da primeira: se a exclusão vier antes, a validação da RN3 recusa o vínculo; se o
   vínculo vier antes, o `restrict_with_error` recusa a exclusão (RN5).
3. **Chave estrangeira.** O adaptador liga `PRAGMA foreign_keys` (linha 112). Se as camadas anteriores
   falharem, por exemplo num banco que não serializa as escritas, o banco recusa o estado inválido com
   `ActiveRecord::InvalidForeignKey` (HTTP 500), mas não grava um vínculo órfão.

Não há tratamento de `InvalidForeignKey` no controller: no SQLite a exceção não acontece pelo caminho da
tela, e um `rescue` sem cenário reproduzível seria código sem teste. Se o projeto trocar de banco, isso
volta a ser avaliado (ver Riscos).

## Arquivos afetados

**Novos**

- `db/migrate/<timestamp>_add_department_to_users.rb`
- `app/controllers/admin/users_controller.rb`
- `app/views/admin/users/index.html.erb`, `_table.html.erb`, `_user.html.erb`, `edit.html.erb`,
  `_form.html.erb`
- `test/models/user/user_department_test.rb`, `test/models/user/user_constraints_test.rb`,
  `test/models/user/user_ordered_by_name_test.rb`
- `test/models/department/department_associations_test.rb`
- `test/controllers/admin/users_controller_test.rb`, `test/controllers/admin/users_controller_access_test.rb`
- `test/system/admin/users/manage_users_test.rb`, `test/system/admin/users/manage_users_on_phone_test.rb`

**Alterados**

- `db/schema.rb` (gerado pela migration)
- `app/models/user.rb`, `app/models/department.rb`
- `app/controllers/admin/departments_controller.rb` (`destroy`)
- `config/routes.rb`
- `app/views/admin/home/partials/_registrations.html.erb`
- `app/helpers/icons_helper.rb` (`fill="currentColor"` no `:person`)
- `config/locales/pt-BR/models.pt-BR.yml`, `errors.pt-BR.yml`, `views.pt-BR.yml`
- `lib/tasks/db/populate/populator.rb`
- `test/factories/users.rb` (trait `:with_department`)
- `test/models/user/user_associations_test.rb`
- `test/controllers/admin/departments_controller_test.rb`, `test/controllers/admin/home_controller_test.rb`
- `test/lib/tasks/db/populate/populator_test.rb`

### Textos (pt-BR)

- **Modelo:** `user.department` e `user.department_id` → "Departamento"; `department.users` →
  "Usuários".
- **Erros:**
  - `user.attributes.department.blank` → "Selecione um departamento cadastrado."
  - `department.restrict_dependent_destroy.has_many` → "Não é possível excluir o departamento porque
    ele tem %{record} vinculados." (`%{record}` vira "usuários"; na #61, "espaços").
- **Telas:** `admin.users.index` (título "Usuários", subtítulo, cabeçalhos, "Sem departamento", selo
  "Administrador", breadcrumb), `admin.users.edit` (título "Editar usuário", subtítulo, breadcrumb),
  `admin.users._form` ("Sem departamento" e a orientação "Atribua departamento apenas a docentes e
  técnicos."), `admin.users.update.success` ("Usuário atualizado com sucesso."), e
  `admin.home.index.users` e `users_description` para o card.

## Banco de dados e compatibilidade

- A migration é reversível (`add_reference`/`remove_reference`). No SQLite, acrescentar a chave
  estrangeira faz o Rails recriar a tabela `users` (cópia dos dados com `foreign_keys` desligado durante a
  cópia). Os usuários e as sessões existentes ficam intactos e todos começam sem departamento.
- Verificação: `bin/rails db:migrate`, `db:migrate:down` da versão e `db:migrate` de novo, e diff do
  `db/schema.rb` só com `department_id`, o índice e o `add_foreign_key "users", "departments"`.
- Produção: a migration só acrescenta uma coluna opcional; não há dado a migrar.

## Estratégia de testes

- **Modelo `User`:** `should belong_to(:department).optional` (shoulda); departamento inexistente
  recusado com a mensagem da RN3 (teste simples, o matcher não cobre); `ordered_by_name`; o banco recusa
  `department_id` inexistente com `InvalidForeignKey` (`update_column`, sem validação).
- **Modelo `Department`:** `should have_many(:users).dependent(:restrict_with_error)`; `destroy` com
  usuário vinculado devolve `false`, mantém o registro e tem a mensagem da RN5; sem usuários, exclui.
- **Integração `Admin::UsersController`:** listagem em ordem de nome com e-mail, departamento,
  "Sem departamento" e selo; edição mostra nome, e-mail e select preenchido; `update` define, troca e
  remove o departamento; `admin`, `name`, `email_address` e `password` enviados juntos não mudam (CA4);
  departamento inexistente → 422 com a mensagem; usuário inexistente → 404; trilha.
- **Acesso:** visitante redirecionado e usuário comum com 403 em `index`, `edit` e `update`, sem
  alteração; sem trilha administrativa no 403 (mesmo formato de `departments_controller_access_test.rb`).
- **Integração `Admin::DepartmentsController`:** excluir departamento com usuário → redirect com o
  alerta e departamento mantido.
- **Home:** card de Usuários em `/admin`.
- **Populate:** "User Demo" com a Coordenação de TSI; "Admin Demo" sem departamento; rodar duas vezes
  seguidas funciona (garante a nova ordem do `reset_records`).
- **Sistema:** administrador troca e remove o departamento de um usuário pela tela; no celular (320 px),
  listagem sem rolagem horizontal e edição completa.

## Autorização e segurança

- `Admin::UsersController` herda `Admin::BaseController`: autenticação e `require_admin_area_access` em
  toda ação, inclusive em `PATCH` enviado direto.
- Strong parameters só aceitam `department_id`. Isso é o que garante o CA4: não há campo `admin` no
  formulário, e mesmo um envio forjado não o altera. Também não é possível trocar e-mail ou senha de
  outro usuário por aqui.
- A listagem expõe nome e e-mail de todos os usuários, só para administradores.
- Nenhum `html_safe` ou `raw`; os nomes são escapados pelo ERB.

## Riscos e trade-offs

- **Sem paginação.** A listagem traz todos os usuários. Com poucos usuários cadastrados é suficiente; se
  o sistema abrir para todos os alunos, busca e paginação viram uma Issue própria.
- **Vínculo não validado.** O sistema não sabe quem é docente, técnico ou aluno; a regra fica com o
  administrador (orientação no formulário).
- **Outro banco.** Se a produção trocar o SQLite por um banco sem transações serializadas, a corrida da
  RN6 passa a cair na chave estrangeira com HTTP 500, sem corromper dados. Aí vale tratar
  `InvalidForeignKey` ou usar lock no departamento.
- **Ordem com acentos.** `order(:name)` no SQLite compara bytes: "Ângela" e nomes em minúsculas vão
  para o fim da lista. É a mesma decisão do professor para departamentos na PR #73 (ordenar no banco; a
  ordem exata não é necessária, e o PostgreSQL já ignora os acentos).
- **`Department.sorted`.** O select usa o escopo já existente na `main`. O professor pediu nomes que digam o
  critério, mas a decisão de 2026-11-03 foi não renomear código já integrado sem perguntar a ele; este
  plano não o renomeia.

## Comandos de verificação

```bash
bin/rails db:migrate
bin/rails test test/models/user test/models/department test/controllers/admin test/lib
bin/rails test:system test/system/admin/users test/system/admin/departments
bin/rubocop
bundle exec erb_lint --lint-all
bin/ci
```
