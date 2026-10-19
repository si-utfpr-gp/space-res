# Cadastro de campi — Plano técnico

Issue: #56 · Especificação: [spec.md](spec.md)

Status: aprovado em 2026-10-19. Implementado em 2026-10-19.

## Abordagem técnica

1. **Plural `campus` → `campi`.** `config/initializers/inflections.rb` ganha
   `inflect.irregular "campus", "campi"`. Sem a regra, o Rails pluraliza "campus" como "campus". Com
   ela, o modelo `Campus` usa a tabela `campi`, a rota `resources :campi` usa o controller
   `Admin::CampiController` e os helpers ficam `admin_campi_path`, `new_admin_campus_path`,
   `edit_admin_campus_path` e `admin_campus_path`.
2. **Tabela.** A migration `CreateCampi` cria `campi` com `name` (`string`, `null: false`),
   `timestamps` e índice único em `name`, como define a Issue.
3. **Modelo.** `Campus` normaliza o nome com `normalizes :name, with: ->(name) { name.squish }` (RN2)
   e valida `presence` (RN1) e `normalized_uniqueness` (RN3–RN6).
4. **Validador de unicidade.** `NormalizedUniquenessValidator` (`app/validators/`) busca os nomes dos
   outros registros (`where.not(id: record.id).pluck`) e compara em Ruby uma forma padronizada de cada
   nome: decomposição Unicode (`unicode_normalize(:nfkd)`), remoção das marcas de acento
   (`gsub(/\p{Mn}/, "")`), minúsculas (`downcase(:fold)`) e remoção de tudo que não é letra ou número
   (`gsub(/[^\p{Alnum}]/, "")`). "Campo Mourão", "CAMPO MOURÃO", "Campo Mourao", "campomourao" e
   "Campo-Mourão." viram "campomourao" (testado). O valor gravado não muda (RN5). O erro usa a chave
   padrão `:taken`, com texto próprio do campus. Motivo de comparar em Ruby: no SQLite, `LOWER()` e
   `COLLATE NOCASE` só tratam letras sem acento (testado: `LOWER('CAMPO MOURÃO')` resulta em
   `'campo mourÃo'`) e não removem acentos nem espaços, então o `uniqueness: { case_sensitive: false }`
   do Rails não cumpriria RN3 nem RN4. Não precisa de gem. O validador não tem opção de escopo agora.
   A Issue de blocos pode acrescentá-la quando precisar.
5. **Rotas.** Dentro de `namespace :admin`, `resources :campi, except: :show`. Não há página de
   detalhes (fora do escopo).
6. **Controller.** `Admin::CampiController < Admin::BaseController`, com `index`, `new`, `create`,
   `edit`, `update` e `destroy`, no formato do scaffold do Rails 8.1:
   - `index`: `Campus.order(:name)`.
   - `create` e `update`: sucesso → `redirect_to admin_campi_path, success: t(".success")` (no
     `update`, com `status: :see_other`, como o scaffold); falha →
     `render :new`/`:edit, status: :unprocessable_content`.
   - `destroy`: `@campus.destroy!` e `redirect_to admin_campi_path, success: t(".success"),
     status: :see_other`.
   - `set_campus` usa `Campus.find(params.expect(:id))`; um id inexistente vira 404.
   - `campus_params` usa `params.expect(campus: [ :name ])`.
7. **Views** (`app/views/admin/campi/`):
   - `index`: título "Campi"; barra de ações com "Voltar" (para `/admin`) à esquerda e "Novo campus"
     à direita; tabela com a coluna Nome e as ações Editar e Excluir; mensagem de lista vazia. Cada
     linha tem `id` com `dom_id(campus)`.
   - Excluir é um `button_to` com `method: :delete` e `data-turbo-confirm` "Excluir o campus
     %{name}?" (RF4).
   - `new` e `edit`: título e o partial `_form` (`locals: (campus:)`), com `f.input :name`, "Salvar" e
     "Cancelar".
8. **Mensagens na área logada (RF7).** `layouts/users/application.html.erb` passa a renderizar
   `Flash::ToastMessageComponent`, como os layouts `application` e `session` já fazem. As mensagens
   `success` e `warning` já estão habilitadas em `Users::BaseController`.
9. **Atalho na área administrativa (RF6).** `admin/home/index` ganha a seção "Cadastros", com um card
   para Campi no estilo das "Ações rápidas" do Dashboard. O card fica no partial
   `admin/home/partials/_registrations.html.erb`, com uma lista de itens que as próximas Issues
   (blocos, departamentos...) só precisam aumentar.
10. **Populate (RF8).** `Db::Populator` apaga `Campus` junto com `User` em `reset_records` e cria
    Guarapuava em um novo `setup_campi` (`Campus.find_or_create_by!(name: "Guarapuava")`).

### Fluxo de uma requisição ao cadastro

```text
PATCH /admin/campi/:id
  └─ Admin::CampiController (herda Admin::BaseController < Users::BaseController)
       1. require_authentication     → visitante: redirect /login, nada gravado       (acesso)
       2. require_admin_area_access  → usuário comum: 403, nada gravado               (acesso)
       3. set_campus                 → id inexistente: 404                            (acesso)
       4. update                     → válido: redirect /admin/campi + mensagem       (RF3, RF7)
                                       inválido: 422 com o formulário e o erro       (RF5)
```

A verificação de permissão roda antes de buscar o campus, então um usuário comum recebe 403 mesmo
para um id que não existe, sem saber se ele existe.

## Arquivos afetados

| Arquivo | Mudança |
| --- | --- |
| `config/initializers/inflections.rb` | Regra irregular `campus` → `campi` |
| `db/migrate/<timestamp>_create_campi.rb` | Novo: tabela `campi`, `name` `null: false`, índice único |
| `db/schema.rb` | Regenerado pela migration |
| `app/models/campus.rb` | Novo: normalização e validações |
| `app/validators/normalized_uniqueness_validator.rb` | Novo: unicidade comparando só letras e números, sem maiúsculas nem acentos |
| `config/locales/pt-BR/errors.pt-BR.yml` | Mensagens de nome vazio e repetido do campus |
| `config/routes.rb` | `resources :campi, except: :show` no namespace `admin` |
| `app/controllers/admin/campi_controller.rb` | Novo: CRUD |
| `app/views/admin/campi/index.html.erb` | Novo: listagem |
| `app/views/admin/campi/_campus.html.erb` | Novo: linha da tabela com as ações |
| `app/views/admin/campi/new.html.erb`, `edit.html.erb` | Novos: título e formulário |
| `app/views/admin/campi/_form.html.erb` | Novo: campo Nome, Salvar e Cancelar |
| `app/views/admin/home/index.html.erb` | Renderiza a seção "Cadastros"; descrição atualizada |
| `app/views/admin/home/partials/_registrations.html.erb` | Novo: card de Campi |
| `app/views/layouts/users/application.html.erb` | Renderiza `Flash::ToastMessageComponent` |
| `config/locales/pt-BR/models.pt-BR.yml` | Modelo `campus` (Campus/Campi) e atributos |
| `config/locales/pt-BR/views.pt-BR.yml` | Chaves `admin.campi.*` e `admin.home.index.*` |
| `lib/tasks/db/populate/populator.rb` | Apaga campi e cria Guarapuava |
| `test/factories/campi.rb` | Nova factory `:campus` |

Os ícones já existem: `:add`, `:pen`, `:trash` e `:location_dot` (card de Campi). Nenhum ícone novo.

### Textos (pt-BR)

| Chave | Texto |
| --- | --- |
| `activerecord.models.campus.one` / `.other` | Campus / Campi |
| `activerecord.attributes.campus.name` | Nome (pelo `defaults` existente) |
| `admin.home.index.description` | Gerencie os cadastros e as configurações do sistema. |
| `admin.home.index.registrations` | Cadastros |
| `admin.home.index.campi` | Campi |
| `admin.home.index.campi_description` | Cadastre os campi da UTFPR |
| `admin.campi.index.title` | Campi |
| `admin.campi.index.new` | Novo campus |
| `admin.campi.index.empty` | Nenhum campus cadastrado. |
| `admin.campi.index.actions` | Ações |
| `admin.campi.index.confirm_destroy` | Excluir o campus %{name}? |
| `admin.campi.new.title` | Novo campus |
| `admin.campi.edit.title` | Editar campus |
| `admin.campi.create.success` | Campus cadastrado com sucesso. |
| `admin.campi.update.success` | Campus atualizado com sucesso. |
| `admin.campi.destroy.success` | Campus excluído com sucesso. |
| `activerecord.errors.models.campus.attributes.name.blank` | Informe o nome do campus. |
| `activerecord.errors.models.campus.attributes.name.taken` | Já existe um campus cadastrado com este nome. |

Editar, Excluir, Salvar, Cancelar e Voltar reaproveitam `actions.*`. As mensagens de erro ficam em
`errors.pt-BR.yml` e valem só para o campus: as mensagens padrão do `rails-i18n` ("não pode ficar em
branco", "já está em uso") continuam nos outros formulários.

## Banco de dados e compatibilidade

- Tabela nova, sem dados existentes e sem backfill. A migration é reversível (`create_table` e
  `add_index` dentro de `change`).
- O índice único garante só a igualdade exata do nome. A unicidade padronizada (RN3 e RN4) fica no
  validador do modelo, como a Issue já previa ("validada no modelo").
- O banco de desenvolvimento foi recriado a partir do `schema.rb` do `main` antes de começar. Assim,
  o `schema.rb` gerado pela migration deve mudar só com a tabela `campi`. Vou conferir o diff.
- **Produção:** nenhum campus é criado automaticamente (fora do escopo). O administrador cadastra pela
  tela.

## Estratégia de testes

| Arquivo | Tipo | O que verifica | CA |
| --- | --- | --- | --- |
| `test/models/campus/campus_inflection_test.rb` | Modelo | `campus` ↔ `campi`, tabela `campi`, nome traduzido (Campus/Campi) | CA7 |
| `test/models/campus/campus_normalize_test.rb` | Modelo | `"  Pato   Branco "` vira `"Pato Branco"` | CA3 |
| `test/models/campus/campus_validations_test.rb` | Modelo | Nome vazio e só com espaços recusados com "Informe o nome do campus."; duplicata exata, com maiúsculas diferentes, com maiúsculas acentuadas, sem acento, sem cedilha, sem espaços, com pontuação e com espaços extras recusada com a mensagem de nome repetido; o próprio campus pode trocar maiúsculas e acentos; editar para o nome de outro campus é recusado; nomes diferentes são aceitos | CA2, CA3, CA7 |
| `test/models/campus/campus_constraints_test.rb` | Modelo | O banco recusa nome nulo e nome exato repetido, mesmo sem validação | CA7 |
| `test/controllers/admin/campi_controller_test.rb` | Integração | Admin: listagem em ordem alfabética e lista vazia; cadastro, edição e exclusão com redirect e mensagem no layout; formulário com erro e 422 para nome vazio e duplicado; confirmação no botão de excluir; 404 para campus inexistente | CA1–CA3 |
| `test/controllers/admin/campi_controller_access_test.rb` | Integração | Visitante → `/login` e usuário comum → 403 nas seis ações, sem alterar dados | CA4, CA5 |
| `test/controllers/admin/home_controller_test.rb` | Integração | A página inicial de `/admin` tem o atalho para `/admin/campi` | CA1 |
| `test/controllers/users/home_controller_test.rb` | Integração | O layout logado exibe uma mensagem existente: usuário logado que abre `/login` vê o aviso no Dashboard (RF7) | CA1 |
| `test/lib/tasks/db/populate/populator_test.rb` | Unidade | Após o populate, existe o campus Guarapuava | CA6 |
| `test/system/admin/campi/manage_campi_test.rb` | Sistema | Admin cadastra, edita e exclui pelo navegador, aceitando a confirmação, e vê as mensagens; recusar a confirmação mantém o campus | CA1 |

- O validador é testado pelo `Campus`, seu único uso por enquanto.
- As respostas HTML também verificam `assert_no_match(/translation missing/i, response.body)`, como
  os testes existentes.
- **System test novo:** a confirmação de exclusão e o toast dependem de JavaScript, então só um teste
  no navegador comprova o fluxo completo do CA1.

## Autorização e segurança

- Todas as ações herdam `require_authentication` e `require_admin_area_access`. Os testes de acesso
  cobrem as seis ações, incluindo envios diretos de POST, PATCH e DELETE.
- `params.expect(campus: [ :name ])` libera só o nome.
- A proteção CSRF continua ativa. `button_to` envia o token na exclusão.
- O nome é exibido com escape padrão do ERB. O toast passa a mensagem por `sanitize_text`, e as
  mensagens deste cadastro não interpolam o nome.
- Vou rodar `bin/brakeman --no-pager` na verificação.

## Riscos e trade-offs

- **Regra mais rígida que a Issue.** A Issue cita só maiúsculas e minúsculas. Ignorar acentos,
  espaços e pontuação (RN4) foi decisão do desenvolvedor em 2026-10-19 e vai nos "Pontos para o
  revisor" da PR, para o professor confirmar. Se ele preferir a regra da Issue, basta tirar do
  validador a remoção de acentos e de caracteres que não são letras ou números, e ajustar os testes
  da RN4.
- **Validador carrega todos os nomes.** Para comparar em Ruby, ele lê os nomes da tabela a cada
  validação. Para campi (dezenas no máximo), o custo é desprezível. Se uma tabela futura crescer
  muito, revisamos.
- **Unicidade padronizada não é garantida pelo banco.** Dois envios exatamente simultâneos de
  "Campo Mourão" e "Campo Mourao" passariam. Numa tela usada só por administradores, o risco é
  desprezível. A Issue define índice único só em `name`.
- **Nomes sem letras nem números.** Um nome só com pontuação (por exemplo, "---") vira uma forma
  padronizada vazia, então dois nomes assim são tratados como iguais. É um caso sem uso real e não
  cria duplicata.
- **Ordenação do SQLite.** `order(:name)` compara byte a byte: nomes com inicial minúscula ou
  acentuada aparecem depois do "Z". Nomes de campi começam com maiúscula sem acento, então a lista sai
  em ordem alfabética na prática.
- **`:unprocessable_content`.** O Rack 3.2 marca `:unprocessable_entity` como obsoleto e emite aviso
  (testado). O código novo usa `:unprocessable_content`. O de reservas não muda (fora do escopo).
- **Toast em toda a área logada.** Além do cadastro, o aviso existente "você já está conectado"
  (quando um usuário logado abre `/login`) passa a aparecer no Dashboard. É o comportamento esperado
  do RF7.
- **`<h1>` no corpo e chaves i18n por view.** Sigo o padrão do projeto, como no plano da #55.
- **Trabalho anterior.** A PR #46 (fechada) tinha `Campus`, a regra de inflexão, a normalização e a
  factory. Reaproveito essas ideias reescrevendo no padrão atual, sem trazer `Building` (fora do
  escopo).

## Comandos de verificação

```bash
bin/rails db:migrate
bin/rails test test/models/campus test/controllers/admin test/lib
bin/rails test
bin/rails test test/system/admin/campi/manage_campi_test.rb
bin/rails test:system
bin/rubocop
bundle exec erb_lint --lint-all
bin/brakeman --no-pager
bin/ci
```

- `bin/rails db:populate` apaga e recria os usuários e os campi do banco de desenvolvimento. Vou
  rodá-lo só com a sua autorização. O teste do populator cobre o CA6 sem tocar nesse banco.
