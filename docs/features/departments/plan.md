# Cadastro de departamentos — Plano técnico

Issue: #58 · Especificação: [spec.md](spec.md)

Status: aprovado em 2026-10-27. Ordenação da listagem revisada na revisão da PR #73 (item 2 e
[Riscos](#riscos-e-trade-offs)).

## Abordagem técnica

O cadastro repete o de campi ([plano de campi](../campi/plan.md)): mesma estrutura de controller, views,
textos e testes. Trilha, cabeçalho, toast, estado vazio e `.btn-delete` já existem e são reaproveitados
sem mudança.

1. **Tabela.** A migration `CreateDepartments` cria `departments` com `name` (`string`, `null: false`),
   `timestamps` e índice único em `name`, como define a Issue.
2. **Modelo.** `Department` normaliza o nome com `normalizes :name, with: ->(name) { name.squish }`
   (RN2) e valida `presence` (RN1) e `normalized_uniqueness` (RN3–RN5), o mesmo validador de campi e
   blocos, sem escopo. Nenhuma associação nesta Issue: `has_many :users` e `has_many :spaces` entram na
   #59 e na #61, junto com o bloqueio de exclusão.
   - **Ordenação (RF1).** `scope :sorted, -> { order(:name) }`: a ordenação fica no banco. A
     implementação chegou a ordenar em Ruby sem acentos, porque o SQLite compara bytes e põe
     "Coordenadoria de Tecnologia da Informação" antes de "Coordenação de Gestão de Recursos Humanos".
     Na revisão da PR #73, o professor pediu a ordenação do banco: a ordem exata não é necessária, e o
     PostgreSQL, se adotado em produção, já ignora os acentos.
3. **Rotas.** Dentro de `namespace :admin`, `resources :departments, except: :show`.
4. **Controller.** `Admin::DepartmentsController < Admin::BaseController`, no formato de
   `Admin::CampiController`:
   - `index`: `Department.sorted`.
   - `create` e `update`: sucesso → `redirect_to admin_departments_path, success: t(".success")` (no
     `update`, com `status: :see_other`); falha → `render :new`/`:edit, status: :unprocessable_content`.
   - `destroy`: `@department.destroy!` e redirect com `success` e `status: :see_other`. Como a exclusão
     é livre (RN6), não há o ramo de erro de campi; a #59 e a #61 o acrescentam quando criarem os
     vínculos.
   - `set_department` com `Department.find(params.expect(:id))` (404 para id inexistente);
     `department_params` com `params.expect(department: [ :name ])`.
   - `set_breadcrumbs`: Departamentos, mais Novo (`new`, `create`) ou Editar (`edit`, `update`).
5. **Views** (`app/views/admin/departments/`), copiadas de campi: `index` (botão "Novo departamento" e
   `if` que só escolhe entre `_table` e `shared/_empty_state`), `_table`, `_department` (linha com
   `dom_id`, `break-words` no nome e botões só com ícone no celular), `new`, `edit` e `_form` com
   `f.input :name`, placeholder, Salvar e Cancelar.
6. **Atalho (RF6).** `admin/home/partials/_registrations.html.erb` ganha o item Departamentos, depois de
   Blocos.
7. **Ícone.** O card e a lista vazia usam o ícone `:users` (grupo de pessoas), que já existe e não é
   usado em nenhuma tela. Nenhum ícone novo. O SVG dele não tinha `fill="currentColor"`, como os
   outros ícones de preenchimento, e aparecia preto no card azul; o atributo foi acrescentado.
8. **Populate (RF9).** `Db::Populator` ganha a constante `DEPARTMENTS` com os 25 nomes, apaga
   `Department` em `reset_records` e cria os departamentos em `setup_departments`
   (`Department.find_or_create_by!`), depois dos blocos. Como a lista é longa, fica numa constante, como
   na PR #51, em vez de um array dentro do método, como em `setup_buildings`.

### Lista do populate

Os 21 da PR #51, mais os 4 acrescentados em 2026-10-27 (marcados com *):

- Departamento Acadêmico de Engenharia
- Departamento Acadêmico de Exatas *
- Coordenação do Curso de Engenharia Civil
- Coordenação do Curso de Engenharia Mecânica
- Coordenação do Curso de Engenharia Mecatrônica
- Coordenação do Curso de Tecnologia em Sistemas para a Internet
- Coordenação do Curso de Arquitetura e Urbanismo
- Diretoria de Graduação e Educação Profissional
- Secretaria de Gestão Acadêmica *
- Departamento de Registros Acadêmicos
- Departamento de Educação
- Diretoria de Relações Empresariais e Comunitárias
- Departamento de Extensão
- Departamento de Estágios e Cursos de Qualificação Profissional
- Departamento de Relações Interinstitucionais *
- Departamento de Apoio e Projetos Tecnológicos *
- Diretoria de Pesquisa e Pós-Graduação
- Núcleo de Acompanhamento Psicopedagógico e Assistência Estudantil
- Núcleo de Apoio ao Ensino
- Setor de Gestão de Espaços Acadêmicos
- Assessoria de Comunicação
- Diretoria de Planejamento e Administração
- Coordenadoria de Tecnologia da Informação
- Coordenação de Gestão de Recursos Humanos
- Biblioteca

### Fluxo de uma requisição ao cadastro

```text
PATCH /admin/departments/:id
  └─ Admin::DepartmentsController (herda Admin::BaseController < Users::BaseController)
       1. require_authentication     → visitante: redirect /login, nada gravado       (acesso)
       2. require_admin_area_access  → usuário comum: 403, nada gravado               (acesso)
       3. set_department             → id inexistente: 404                            (acesso)
       4. update                     → válido: redirect /admin/departments + mensagem (RF3)
                                       inválido: 422 com o formulário e o erro       (RF5)
```

## Arquivos afetados

| Arquivo | Mudança |
| --- | --- |
| `db/migrate/<timestamp>_create_departments.rb` | Novo: tabela `departments`, `name` `null: false`, índice único |
| `db/schema.rb` | Regenerado pela migration |
| `app/models/department.rb` | Novo: normalização, validações e `sorted` |
| `config/routes.rb` | `resources :departments, except: :show` no namespace `admin` |
| `app/controllers/admin/departments_controller.rb` | Novo: CRUD e trilha |
| `app/views/admin/departments/*` | Novos: `index`, `_table`, `_department`, `new`, `edit`, `_form` |
| `app/views/admin/home/partials/_registrations.html.erb` | Card de Departamentos |
| `config/locales/pt-BR/models.pt-BR.yml` | Modelo `department` (Departamento/Departamentos) e atributos |
| `config/locales/pt-BR/errors.pt-BR.yml` | Mensagens de nome vazio e repetido |
| `config/locales/pt-BR/views.pt-BR.yml` | Chaves `admin.departments.*`, `admin.home.index.departments*` e placeholder |
| `app/helpers/icons_helper.rb` | `fill="currentColor"` no ícone `:users`, que aparecia preto no card azul |
| `lib/tasks/db/populate/populator.rb` | Constante `DEPARTMENTS`, `reset_records` e `setup_departments` |
| `test/factories/departments.rb` | Nova factory `:department` |

### Textos (pt-BR)

| Chave | Texto |
| --- | --- |
| `activerecord.models.department.one` / `.other` | Departamento / Departamentos |
| `activerecord.attributes.department.name` | Nome (pelo `defaults` existente) |
| `helpers.placeholder.department.name` | Ex.: Departamento Acadêmico de Engenharia |
| `admin.home.index.departments` | Departamentos |
| `admin.home.index.departments_description` | Cadastre os departamentos responsáveis pelos espaços |
| `admin.departments.index.title` / `.breadcrumb` | Departamentos |
| `admin.departments.index.subtitle` | Gerencie os departamentos que respondem pelos espaços e liberam as reservas. |
| `admin.departments.index.new` | Novo departamento |
| `admin.departments.index.empty` | Nenhum departamento cadastrado. |
| `admin.departments.index.actions` | Ações |
| `admin.departments.index.confirm_destroy` | Excluir o departamento %{name}? |
| `admin.departments.new.title` / `.breadcrumb` | Novo departamento / Novo |
| `admin.departments.new.subtitle` | Preencha as informações do novo departamento. |
| `admin.departments.edit.title` / `.breadcrumb` | Editar departamento / Editar |
| `admin.departments.edit.subtitle` | Altere as informações do departamento. |
| `admin.departments.create.success` | Departamento cadastrado com sucesso. |
| `admin.departments.update.success` | Departamento atualizado com sucesso. |
| `admin.departments.destroy.success` | Departamento excluído com sucesso. |
| `activerecord.errors.models.department.attributes.name.blank` | Informe o nome do departamento. |
| `activerecord.errors.models.department.attributes.name.taken` | Já existe um departamento cadastrado com este nome. |

Editar, Excluir, Salvar e Cancelar reaproveitam `actions.*`.

## Banco de dados e compatibilidade

- Tabela nova, sem dados existentes e sem backfill. A migration é reversível (`create_table` e
  `add_index` dentro de `change`).
- O índice único garante só a igualdade exata do nome; a unicidade padronizada (RN3) fica no validador,
  como em campi.
- O banco de desenvolvimento não tem mais as migrations do branch `feat/departments-db`
  (`db:migrate:status` conferido em 2026-10-27), então o `schema.rb` deve mudar só com a tabela
  `departments`. Vou conferir o diff.
- **Produção:** nenhum departamento é criado automaticamente (fora do escopo).

## Estratégia de testes

| Arquivo | Tipo | O que verifica | CA |
| --- | --- | --- | --- |
| `test/models/department/department_normalize_test.rb` | Modelo | Espaços normalizados; grafia e acentos preservados | CA3 |
| `test/models/department/department_validations_test.rb` | Modelo | `validate_presence_of` e `validate_uniqueness_of(...).case_insensitive` (shoulda); nome repetido sem acento, sem cedilha, sem espaços e com pontuação recusado com a mensagem própria; o próprio departamento pode trocar maiúsculas e acentos; renomear para outro departamento é recusado | CA2, CA3, CA6 |
| `test/models/department/department_constraints_test.rb` | Modelo | O banco recusa nome nulo e nome exato repetido, sem validação | CA6 |
| `test/models/department/department_sorted_test.rb` | Modelo | `sorted` ordena pelo nome | CA1 |
| `test/controllers/admin/departments_controller_test.rb` | Integração | Listagem em ordem alfabética e lista vazia; título, subtítulo e trilha nas três páginas, inclusive após erro; cadastro, edição e exclusão com redirect e toast; 422 para nome vazio e repetido; confirmação no botão de excluir; 404 para departamento inexistente | CA1–CA3 |
| `test/controllers/admin/departments_controller_access_test.rb` | Integração | Visitante → `/login` e usuário comum → 403 nas seis ações, sem alterar dados; 403 antes de buscar o departamento; o 403 não mostra a trilha | CA4 |
| `test/controllers/admin/home_controller_test.rb` | Integração | Atalho para `/admin/departments` | CA1 |
| `test/lib/tasks/db/populate/populator_test.rb` | Unidade | O populate apaga os departamentos existentes e cria os 25 de Guarapuava | CA5 |
| `test/system/admin/departments/manage_departments_test.rb` | Sistema | Cadastro, edição e exclusão no navegador, com confirmação aceita e recusada e toast; erro de nome repetido | CA1, CA3 |
| `test/system/admin/departments/manage_departments_on_phone_test.rb` | Sistema | Em 320 × 640, a tabela cabe na tela com o nome mais longo da lista, Editar e Excluir; cadastro pelo celular | CA1 |

- As respostas HTML verificam `assert_no_match(/translation missing/i, response.body)`.
- Sem teste de inflexão: `department` → `departments` é a regra padrão do Rails. O nome traduzido do
  modelo aparece nas mensagens e nos títulos já testados.

## Autorização e segurança

- Todas as ações herdam `require_authentication` e `require_admin_area_access`. Os testes de acesso
  cobrem as seis ações, incluindo envios diretos de POST, PATCH e DELETE.
- `params.expect(department: [ :name ])` libera só o nome.
- CSRF continua ativo; `button_to` envia o token na exclusão.
- O nome é exibido com o escape padrão do ERB. A confirmação de exclusão interpola o nome num atributo
  `data-turbo-confirm`, também escapado, como em campi.
- Vou rodar `bundle exec brakeman --no-pager` na verificação.

## Riscos e trade-offs

- **Regra mais rígida que a Issue (RN3).** Segue a decisão de campi e de blocos, mantida pelo professor
  em 2026-10-23. Vai nos "Pontos para o revisor" da PR.
- **Lista do populate.** Mistura departamentos, coordenações, diretorias, setores e a Biblioteca, porque
  o que importa é ser a unidade responsável por espaços (justificativa da PR #51). Os nomes vêm de
  pesquisa no site da UTFPR e podem não estar completos; servem só ao ambiente local.
- **Acentos na ordenação.** No SQLite, nomes que só diferem num caractere acentuado podem sair fora da
  ordem do dicionário ("Coordenadoria" antes de "Coordenação"). Aceito pelo professor na revisão da
  PR #73. Campi e blocos seguem a mesma regra e ficam como estão, sem Issue de acompanhamento.
- **Exclusão sem bloqueio.** Enquanto não houver usuários nem espaços ligados, apagar um departamento
  não tem efeito em outras tabelas. A #59 e a #61 trocam o `destroy!` pelo tratamento de
  `restrict_with_error`.
- **Ícone `:users`.** Se a #59 (gestão de usuários) quiser o mesmo ícone, ela pode usar `:person` ou
  `:user_plus`, que já existem.

## Comandos de verificação

```bash
bin/rails db:migrate
bin/rails test test/models/department test/controllers/admin test/lib
bin/rails test
bin/rails test test/system/admin/departments
bin/rails test:system
bin/rubocop
bundle exec erb_lint --lint-all
bundle exec brakeman --no-pager
bin/ci
```

- `bin/rails db:populate` apaga e recria os dados do banco de desenvolvimento. Vou rodá-lo só com a sua
  autorização. O teste do populator cobre o CA5 sem tocar nesse banco.
