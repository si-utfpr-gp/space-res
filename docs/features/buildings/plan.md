# Cadastro de blocos — Plano técnico

Issue: #57 · Especificação: [spec.md](spec.md)

Status: aprovado e implementado em 2026-10-22.

## Abordagem técnica

1. **Tabela.** A migration `CreateBuildings` cria `buildings` com
   `t.references :campus, null: false, foreign_key: true, index: false`, `name` (`string`,
   `null: false`), `timestamps` e o índice único em `[ :campus_id, :name ]`, como define a Issue. Com a
   regra de inflexão de campi, `foreign_key: true` aponta para a tabela `campi`. O índice próprio de
   `campus_id` fica de fora (`index: false`) porque o índice composto já começa por `campus_id` e
   atende as buscas por campus.
2. **Modelo `Building`.** `belongs_to :campus`; `normalizes :name, with: ->(name) { name.squish }`
   (RN3); `validates :name, presence: true, normalized_uniqueness: { scope: :campus_id }` (RN2, RN4–RN7).
   O `belongs_to` já exige um campus existente (RN1), com a mensagem própria "Selecione o campus.".
   O escopo `Building.sorted` (`eager_load(:campus).order("campi.name", :name)`) ordena por campus e
   nome e já carrega o campus de cada bloco, sem N+1 na listagem.
3. **Escopo no validador.** `NormalizedUniquenessValidator` ganha a opção `scope`, como o
   `uniqueness` do Rails: só compara com os registros que têm os mesmos valores nas colunas do escopo
   (`Array(options[:scope]).index_with { |column| record.read_attribute(column) }`). Sem a opção, o
   comportamento de campi não muda. Com `campus_id` vazio, não há comparação, e só aparece o erro de
   campus obrigatório.
4. **Campus com blocos (RN9).** `Campus` ganha `has_many :buildings, dependent: :restrict_with_error`.
   A exclusão de um campus com blocos devolve `false` e grava o erro em `base`. A mensagem fica em
   `activerecord.errors.models.campus.restrict_dependent_destroy.has_many`, com `%{record}` (o nome
   traduzido da associação, "blocos"), e assim serve também para a futura associação com espaços. A
   chave estrangeira do banco é a segunda barreira: apagar o campus sem passar pelo modelo também
   falha.
5. **`Admin::CampiController#destroy`.** Troca o `destroy!` por `if @campus.destroy`. Na falha,
   volta para a listagem de campi com `alert:` e a mensagem do modelo, que o toast já mostra em
   vermelho.
6. **Rotas.** `resources :buildings, except: :show` no namespace `admin`.
7. **`Admin::BuildingsController`.** Mesmo formato do de campi: `index` (`Building.sorted`), `new`,
   `create`, `edit`, `update` e `destroy`, com `set_building` (`Building.find`, 404 para id
   inexistente), `building_params` (`params.expect(building: [ :campus_id, :name ])`) e
   `set_breadcrumbs` (Blocos, mais Novo ou Editar). Um `before_action :set_campi` nas ações de
   formulário guarda `Campus.order(:name)` para a lista de seleção. A relação é preguiçosa: depois de
   salvar com sucesso, o redirect não chega a consultar os campi.
8. **Campo de seleção no form builder (RF3).** `TailwindFormBuilder#input` passa a aceitar
   `type: :select`, com a coleção em `collection:`:

   ```erb
   <%= f.input :campus_id, type: :select, collection: campi, prompt: t(".campus_prompt") %>
   ```

   - O builder renderiza o novo `Form::Input::SelectComponent`, subclasse de
     `Form::Input::BaseComponent`. Ele herda o template (rótulo, campo, dica) e troca só o campo, que
     vira `collection_select` com `value_method: :id` e `text_method: :name` por padrão. `prompt` e
     `include_blank` vão para as opções do select; o resto vai para o HTML, como no `input`.
   - O select usa as mesmas classes do input, mais `min-h-11` (44 px de área de toque) e `bg-white`.
     Para isso, as classes do campo saem do método `input` para um método privado do componente base,
     sem mudar o HTML gerado.
   - **Erro do `belongs_to`.** O Rails grava o erro de campus obrigatório em `campus`, não em
     `campus_id`. O componente de select também mostra os erros da associação `belongs_to` cuja chave
     estrangeira é o atributo do campo (descoberta por reflexão). O componente base passa a ler os
     erros por um método privado, que a subclasse estende.
   - **Por que não sobrescrever `f.select`.** O `TailwindFormBuilder` é o builder padrão, e o
     formulário de reserva (`users/reservations/_schedule_form`) usa `f.select` com rótulo e erros
     próprios. Mudar o `select` do Rails mexeria nessa tela, fora do escopo. A reserva pode migrar para
     `f.input type: :select` depois.
9. **Views** (`app/views/admin/buildings/`), no padrão de campi:
   - `index`: título e subtítulo; "Novo bloco" abaixo do cabeçalho; `if` que só escolhe entre `_table`
     e `shared/_empty_state`.
   - `_table` e `_building`: colunas Nome, Campus e Ações, com `dom_id(building)` em cada linha. No
     celular, a coluna Campus some (`hidden sm:table-cell`) e o campus aparece numa segunda linha, em
     texto menor, abaixo do nome (`sm:hidden`). Assim a tabela cabe em 320 px (RF10). Editar e Excluir
     iguais aos de campi; a confirmação é "Excluir o bloco %{name} do campus %{campus}?", porque o
     mesmo nome pode existir em campi diferentes.
   - `new`, `edit` e `_form` (`locals: (building:, campi:)`): Campus e Nome, com placeholder
     "Ex.: Bloco R", Salvar e Cancelar.
10. **Ícone.** `IconsHelper::ICONS` ganha `:building_office`, do Heroicons 24 outline, como pede a
    skill de frontend. Ele aparece no card da área administrativa e na lista vazia.
11. **Atalho (RF8).** O partial `admin/home/partials/_registrations` ganha o item Blocos.
12. **Populate (RF11).** `Db::Populator` apaga `Building` antes de `Campus` em `reset_records` e cria
    "Bloco B", "Bloco C" e "Bloco R" no campus Guarapuava em `setup_buildings`.
13. **Documentação de campi.** A RN7 de `docs/features/campi/spec.md` ganha uma nota: substituída
    pela RN9 da #57.

### Fluxo da exclusão de um campus

```text
DELETE /admin/campi/:id
  └─ Admin::CampiController#destroy
       @campus.destroy
         ├─ sem blocos → campus apagado → redirect /admin/campi + success   (RN9)
         └─ com blocos → restrict_with_error: erro em base, nada apagado
                         → redirect /admin/campi + alert com o motivo       (RF7, RN9)
```

## Arquivos afetados

| Arquivo | Mudança |
| --- | --- |
| `db/migrate/<timestamp>_create_buildings.rb` | Novo: tabela `buildings`, FK para `campi`, índice único `(campus_id, name)` |
| `db/schema.rb` | Regenerado pela migration |
| `app/models/building.rb` | Novo: associação, normalização, validações e escopo `sorted` |
| `app/models/campus.rb` | `has_many :buildings, dependent: :restrict_with_error` |
| `app/validators/normalized_uniqueness_validator.rb` | Opção `scope` |
| `config/routes.rb` | `resources :buildings, except: :show` no namespace `admin` |
| `app/controllers/admin/buildings_controller.rb` | Novo: CRUD |
| `app/controllers/admin/campi_controller.rb` | `destroy` trata a exclusão recusada |
| `app/form_builders/tailwind_form_builder.rb` | `input` com `type: :select` renderiza o componente de select |
| `app/components/form/input/base_component.rb` | Classes do campo e leitura dos erros em métodos privados |
| `app/components/form/input/select_component.rb` | Novo: select com o visual dos inputs e erros do `belongs_to` |
| `app/views/admin/buildings/*` | Novos: `index`, `_table`, `_building`, `new`, `edit`, `_form` |
| `app/views/admin/home/partials/_registrations.html.erb` | Card de Blocos |
| `app/helpers/icons_helper.rb` | Ícone `:building_office` |
| `config/locales/pt-BR/models.pt-BR.yml` | Modelo `building` e atributos; `campus.buildings` |
| `config/locales/pt-BR/errors.pt-BR.yml` | Mensagens do bloco e da exclusão de campus com blocos |
| `config/locales/pt-BR/views.pt-BR.yml` | Chaves `admin.buildings.*`, `admin.home.index.buildings*` e placeholder |
| `lib/tasks/db/populate/populator.rb` | Apaga blocos e cria os blocos B, C e R |
| `test/factories/buildings.rb` | Nova factory `:building` |
| `docs/features/campi/spec.md` | Nota na RN7 |

### Textos (pt-BR)

| Chave | Texto |
| --- | --- |
| `activerecord.models.building.one` / `.other` | Bloco / Blocos |
| `activerecord.attributes.building.campus` / `.campus_id` | Campus |
| `activerecord.attributes.building.name` | Nome (pelo `defaults` existente) |
| `activerecord.attributes.campus.buildings` | Blocos |
| `helpers.placeholder.building.name` | Ex.: Bloco R |
| `admin.home.index.buildings` | Blocos |
| `admin.home.index.buildings_description` | Cadastre os blocos de cada campus |
| `admin.buildings.index.title` / `.breadcrumb` | Blocos |
| `admin.buildings.index.subtitle` | Gerencie os blocos de cada campus, que organizam os espaços. |
| `admin.buildings.index.new` | Novo bloco |
| `admin.buildings.index.empty` | Nenhum bloco cadastrado. |
| `admin.buildings.index.actions` | Ações |
| `admin.buildings.index.confirm_destroy` | Excluir o bloco %{name} do campus %{campus}? |
| `admin.buildings.new.title` / `.breadcrumb` | Novo bloco / Novo |
| `admin.buildings.new.subtitle` | Preencha as informações do novo bloco. |
| `admin.buildings.edit.title` / `.breadcrumb` | Editar bloco / Editar |
| `admin.buildings.edit.subtitle` | Altere as informações do bloco. |
| `admin.buildings.form.campus_prompt` | Selecione o campus |
| `admin.buildings.create.success` | Bloco cadastrado com sucesso. |
| `admin.buildings.update.success` | Bloco atualizado com sucesso. |
| `admin.buildings.destroy.success` | Bloco excluído com sucesso. |
| `activerecord.errors.models.building.attributes.campus.required` | Selecione o campus. |
| `activerecord.errors.models.building.attributes.name.blank` | Informe o nome do bloco. |
| `activerecord.errors.models.building.attributes.name.taken` | Já existe um bloco com este nome neste campus. |
| `activerecord.errors.models.campus.restrict_dependent_destroy.has_many` | Não é possível excluir o campus porque ele tem %{record} cadastrados. |

## Banco de dados e compatibilidade

- Tabela nova, sem backfill. A migration é reversível (`create_table` e `add_index` em `change`).
- O índice único garante só a igualdade exata de `(campus_id, name)`. A comparação sem maiúsculas,
  acentos, espaços e pontuação (RN4) fica no validador, como em campi.
- A chave estrangeira impede apagar um campus com blocos mesmo sem passar pelo modelo. O adaptador
  SQLite do Rails liga `PRAGMA foreign_keys`; um teste de restrição do banco confirma.
- Depois da migration, confiro que o diff do `schema.rb` tem só a tabela `buildings` e a chave
  estrangeira. Se o banco de desenvolvimento tiver diferenças da `main`, peço autorização antes de
  recriá-lo, porque isso apaga os dados locais.
- **Produção:** nenhum bloco é criado automaticamente. O administrador cadastra pela tela.

## Estratégia de testes

| Arquivo | Tipo | O que verifica | CA |
| --- | --- | --- | --- |
| `test/models/building/building_associations_test.rb` | Modelo | `belong_to(:campus)` | CA2 |
| `test/models/building/building_normalize_test.rb` | Modelo | `"  Bloco   A "` vira `"Bloco A"` | CA3 |
| `test/models/building/building_validations_test.rb` | Modelo | Matchers: presença do nome e unicidade `case_insensitive` no mesmo campus (o `scoped_to` do shoulda só reconhece o `UniquenessValidator` do Rails). Testes: sem campus e com campus inexistente → "Selecione o campus."; nome vazio → "Informe o nome do bloco."; mesmo nome sem acento, sem espaços e com pontuação no mesmo campus recusado; mesmo nome em outro campus aceito; o próprio bloco troca maiúsculas; renomear para o nome de outro bloco do campus e trocar para um campus com o mesmo nome recusados | CA2, CA3, CA8 |
| `test/models/building/building_constraints_test.rb` | Modelo | O banco recusa nome nulo, campus nulo, campus inexistente e `(campus_id, name)` repetido; aceita o mesmo nome em campi diferentes; recusa apagar um campus com blocos sem passar pelo modelo | CA2, CA3, CA4 |
| `test/models/building/building_sorted_test.rb` | Modelo | `sorted` ordena por campus e nome e carrega o campus | CA5 |
| `test/models/campus/campus_associations_test.rb` | Modelo | `have_many(:buildings).dependent(:restrict_with_error)`; campus com blocos não é apagado e tem a mensagem; campus sem blocos é apagado | CA4, CA8 |
| `test/form_builders/tailwind_form_builder_test.rb` | View | `f.input type: :select`: rótulo ligado ao campo, opções na ordem da coleção, prompt, valor selecionado, classes de 44 px, erro do `belongs_to` junto ao campo | CA2 |
| `test/controllers/admin/buildings_controller_test.rb` | Integração | Listagem ordenada com o campus de cada bloco e lista vazia; título, subtítulo e trilha nas três páginas, inclusive após erro; formulário com os campi em ordem e o prompt; cadastro, edição (inclusive troca de campus) e exclusão com redirect e mensagem; 422 sem campus, sem nome e com nome repetido, mantendo o campus escolhido; confirmação no botão de excluir; 404 para bloco inexistente | CA1–CA3, CA5 |
| `test/controllers/admin/buildings_controller_access_test.rb` | Integração | Visitante → `/login` e usuário comum → 403 nas seis ações, sem alterar dados; o 403 não mostra a trilha | CA6 |
| `test/controllers/admin/campi_controller_test.rb` | Integração | Excluir campus com blocos: nada apagado, redirect e alerta com o motivo | CA4 |
| `test/controllers/admin/home_controller_test.rb` | Integração | Atalho para `/admin/buildings` | CA1 |
| `test/lib/tasks/db/populate/populator_test.rb` | Unidade | Cria os blocos B, C e R em Guarapuava e apaga os blocos anteriores | CA7 |
| `test/system/admin/buildings/manage_buildings_test.rb` | Sistema | Admin cadastra escolhendo o campus, edita e exclui pelo navegador, aceitando a confirmação; recusar a confirmação mantém o bloco; erro de nome repetido no formulário | CA1–CA3 |
| `test/system/admin/buildings/manage_buildings_on_phone_test.rb` | Sistema | Em 320 × 640, a tabela cabe na tela com nome, campus, Editar e Excluir, e o cadastro funciona | CA1, CA5 |
| `test/system/admin/campi/manage_campi_test.rb` | Sistema | Excluir campus com blocos mostra o alerta e mantém o campus | CA4 |

- As respostas HTML também verificam `assert_no_match(/translation missing/i, response.body)`.
- O validador continua testado pelos modelos que o usam: campi sem escopo e blocos com escopo.

## Autorização e segurança

- Todas as ações herdam `require_authentication` e `require_admin_area_access`. Os testes de acesso
  cobrem as seis ações, incluindo envios diretos de POST, PATCH e DELETE.
- `params.expect(building: [ :campus_id, :name ])` libera só o campus e o nome. Um `campus_id`
  forjado para um campus inexistente é recusado pelo `belongs_to`, e a chave estrangeira barra o
  resto.
- Proteção CSRF ativa; `button_to` envia o token na exclusão.
- Nomes exibidos com escape padrão do ERB. A mensagem de exclusão recusada não interpola dados
  digitados pelo usuário (só o nome traduzido da associação) e passa por `sanitize_text` no toast.
- Vou rodar `bin/brakeman --no-pager` na verificação.

## Riscos e trade-offs

- **Regra mais rígida que a Issue.** A RN4 segue a regra de campi, não só maiúsculas e minúsculas.
  Vai para os "Pontos para o revisor" da PR.
- **Escopo no modelo em vez de Query Object.** A listagem é um join simples, sem filtros. Um escopo
  no modelo basta, e o teste do escopo garante o carregamento do campus. Se a listagem ganhar busca
  ou filtros, vira Query Object em `app/queries/`.
- **Reflexão no componente de select.** Descobrir a associação pela chave estrangeira é um pouco
  implícito, mas evita repetir `campus` em todo formulário e serve para os próximos selects
  (departamentos, espaços). Se o atributo não for chave de um `belongs_to`, o componente mostra só os
  erros do próprio atributo.
- **Formulário de reserva.** Continua com o `f.select` do Rails, sem o visual novo (fora do escopo).
- **Troca de campus na edição.** Hoje é livre. Quando existirem espaços, a Issue de espaços decide se
  um bloco com espaços pode mudar de campus.
- **Sem campi cadastrados.** O formulário de bloco abre com o select só com "Selecione o campus" e o
  envio é recusado. Não há aviso extra nem link para cadastrar campus (fora do escopo).
- **Ordenação do SQLite.** Como em campi, `order` compara byte a byte: nomes com inicial minúscula ou
  acentuada vão para o fim. Nomes de campi e de blocos começam com maiúscula sem acento.

## Comandos de verificação

```bash
bin/rails db:migrate
bin/rails test test/models test/form_builders test/controllers/admin test/lib
bin/rails test
bin/rails test test/system/admin
bin/rails test:system
bin/rubocop
bundle exec erb_lint --lint-all
bin/brakeman --no-pager
bin/ci
```

- `bin/rails db:populate` apaga e recria usuários, campi e blocos do banco de desenvolvimento. Vou
  rodá-lo só com a sua autorização. O teste do populator cobre o CA7 sem tocar nesse banco.
