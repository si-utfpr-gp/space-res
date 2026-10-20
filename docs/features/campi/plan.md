# Cadastro de campi — Plano técnico

Issue: #56 · Especificação: [spec.md](spec.md)

Status: aprovado em 2026-10-19. Implementado em 2026-10-19. Layout revisado em 2026-10-20 (seção
[Revisão do layout](#revisão-do-layout-2026-10-20)).

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
   - `index`: título e subtítulo; "Novo campus" à direita, abaixo do cabeçalho; tabela com a coluna
     Nome e as ações Editar e Excluir; mensagem de lista vazia. Cada linha tem `id` com
     `dom_id(campus)`. O "Voltar" da primeira versão deu lugar à trilha de navegação (2026-10-20).
   - Excluir é um `button_to` com `method: :delete` e `data-turbo-confirm` "Excluir o campus
     %{name}?" (RF4).
   - `new` e `edit`: título, subtítulo e o partial `_form` (`locals: (campus:)`), com `f.input :name`,
     "Salvar" e "Cancelar".
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
| `app/views/admin/campi/_table.html.erb` | Novo: tabela de campi |
| `app/views/admin/campi/_campus.html.erb` | Novo: linha da tabela com as ações |
| `app/views/admin/campi/new.html.erb`, `edit.html.erb` | Novos: título, subtítulo e formulário |
| `app/views/admin/campi/_form.html.erb` | Novo: campo Nome, Salvar e Cancelar |
| `app/views/shared/_empty_state.html.erb` | Novo: estado de lista vazia, com ícone e mensagem |
| `app/views/admin/home/index.html.erb` | Renderiza a seção "Cadastros"; título e subtítulo pelo layout |
| `app/views/admin/home/partials/_registrations.html.erb` | Novo: card de Campi |
| `app/views/users/home/dashboard.html.erb`, `app/views/shared/forbidden.html.erb` | Deixam o `<h1>` próprio; o layout renderiza o título |
| `app/views/layouts/users/application.html.erb` | Renderiza `Flash::ToastMessageComponent` e `Page::HeaderComponent`; padding do `main` |
| `app/controllers/concerns/breadcrumbs.rb` | Novo: trilha montada na renderização |
| `app/controllers/users/base_controller.rb`, `app/controllers/admin/base_controller.rb` | Trilha base (Dashboard, Área administrativa); trilha limpa no 403 |
| `app/components/page/header_component.*`, `app/components/page/breadcrumbs_component.*` | Novos: cabeçalho da página e trilha |
| `app/components/form/input/base_component.rb` | Fonte do input, do rótulo e do erro, mobile first |
| `app/assets/tailwind/application.css` | Nova variante `.btn-delete` |
| `config/locales/pt-BR/models.pt-BR.yml` | Modelo `campus` (Campus/Campi) e atributos |
| `config/locales/pt-BR/views.pt-BR.yml` | Chaves `admin.campi.*` e `admin.home.index.*` |
| `lib/tasks/db/populate/populator.rb` | Apaga campi e cria Guarapuava |
| `test/factories/campi.rb` | Nova factory `:campus` |

Os ícones já existem: `:add`, `:pen`, `:trash`, `:location_dot` (card de Campi e lista vazia) e
`:chevron_right` (trilha). Nenhum ícone novo.

### Textos (pt-BR)

| Chave | Texto |
| --- | --- |
| `activerecord.models.campus.one` / `.other` | Campus / Campi |
| `activerecord.attributes.campus.name` | Nome (pelo `defaults` existente) |
| `admin.home.index.subtitle` | Gerencie os cadastros e as configurações do sistema. |
| `admin.home.index.breadcrumb` | Área administrativa |
| `users.home.dashboard.breadcrumb` | Dashboard |
| `components.page.breadcrumbs.label` | Trilha de navegação |
| `helpers.placeholder.campus.name` | Ex.: Guarapuava |
| `admin.home.index.registrations` | Cadastros |
| `admin.home.index.campi` | Campi |
| `admin.home.index.campi_description` | Cadastre os campi da UTFPR |
| `admin.campi.index.title` / `.breadcrumb` | Campi |
| `admin.campi.index.subtitle` | Gerencie os campi da UTFPR que organizam os blocos e os espaços. |
| `admin.campi.index.new` | Novo campus |
| `admin.campi.index.empty` | Nenhum campus cadastrado. |
| `admin.campi.index.actions` | Ações |
| `admin.campi.index.confirm_destroy` | Excluir o campus %{name}? |
| `admin.campi.new.title` / `.breadcrumb` | Novo campus / Novo |
| `admin.campi.new.subtitle` | Preencha as informações do novo campus. |
| `admin.campi.edit.title` / `.breadcrumb` | Editar campus / Editar |
| `admin.campi.edit.subtitle` | Altere as informações do campus. |
| `admin.campi.create.success` | Campus cadastrado com sucesso. |
| `admin.campi.update.success` | Campus atualizado com sucesso. |
| `admin.campi.destroy.success` | Campus excluído com sucesso. |
| `activerecord.errors.models.campus.attributes.name.blank` | Informe o nome do campus. |
| `activerecord.errors.models.campus.attributes.name.taken` | Já existe um campus cadastrado com este nome. |

Editar, Excluir, Salvar e Cancelar reaproveitam `actions.*`. As mensagens de erro ficam em
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
| `test/controllers/admin/campi_controller_test.rb` | Integração | Admin: listagem em ordem alfabética e lista vazia; cadastro, edição e exclusão com redirect e mensagem no layout; formulário com erro e 422 para nome vazio e duplicado; confirmação no botão de excluir; 404 para campus inexistente; título único, subtítulo e trilha em ordem na listagem, no cadastro e na edição, inclusive após erro (RF9) | CA1–CA3 |
| `test/controllers/admin/campi_controller_access_test.rb` | Integração | Visitante → `/login` e usuário comum → 403 nas seis ações, sem alterar dados; o 403 não mostra a trilha | CA4, CA5 |
| `test/controllers/admin/home_controller_test.rb` | Integração | A página inicial de `/admin` tem o atalho para `/admin/campi`, título, subtítulo e trilha | CA1 |
| `test/controllers/users/home_controller_test.rb` | Integração | O layout logado exibe uma mensagem existente: usuário logado que abre `/login` vê o aviso no Dashboard (RF7); o Dashboard tem um só título no conteúdo e nenhuma trilha | CA1 |
| `test/lib/tasks/db/populate/populator_test.rb` | Unidade | Após o populate, existe o campus Guarapuava | CA6 |
| `test/system/admin/campi/manage_campi_test.rb` | Sistema | Admin cadastra, edita e exclui pelo navegador, aceitando a confirmação, e vê as mensagens; recusar a confirmação mantém o campus | CA1 |
| `test/system/admin/campi/manage_campi_on_phone_test.rb` | Sistema | Com a janela em 320 × 640, a tabela cabe na tela com Editar e Excluir, e o cadastro funciona (RF10) | CA1 |

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
- **Chaves i18n por view.** Sigo o padrão do projeto, como no plano da #55. O `<h1>` no corpo das
  views saiu na revisão do layout (2026-10-20): agora o layout renderiza o título.
- **Trabalho anterior.** A PR #46 (fechada) tinha `Campus`, a regra de inflexão, a normalização e a
  factory. Reaproveito essas ideias reescrevendo no padrão atual, sem trazer `Building` (fora do
  escopo).

## Revisão do layout (2026-10-20)

Feedback do professor sobre a primeira versão: o layout estava feio; faltava hierarquia visual
(títulos, subtítulos e breadcrumbs); o formulário ocupava metade da página; as páginas precisam
funcionar bem no celular (mobile first); e `if` não deve ter muito código nos blocos. Referências: as
telas do trabalho do Jacson (monografia, figuras 45, 46, 58 e 64) e
`maxiambiental/app/views/courses/index.html.erb`. As regras seguem a skill `rails-frontend-standards`
(seções 5, 7 e 9).

1. **Cabeçalho no layout.** `layouts/users/application` renderiza `Page::HeaderComponent` com
   `content_for(:head_title)`, `content_for(:head_subtitle)` e a trilha: trilha, `<h1>`, subtítulo e
   uma linha divisória. O componente não aparece quando a página não define `head_title` (a reserva,
   por exemplo). As views não escrevem mais `<h1>`. Dashboard, área administrativa e 403 já definiam
   `head_title` e deixam o `<h1>` próprio para não repetir o título.
2. **Trilha.** O concern `Breadcrumbs` monta a trilha quando o layout a pede, durante a renderização:
   primeiro `default_breadcrumbs` (Dashboard em `Users::BaseController`, mais Área administrativa em
   `Admin::BaseController`), depois `set_breadcrumbs` do controller. Assim a raiz vem sempre antes.
   `Admin::CampiController#set_breadcrumbs` acrescenta Campi e, conforme a ação, Novo (`new`,
   `create`) ou Editar (`edit`, `update`), para a trilha continuar certa quando o formulário volta com
   erro. O último item é a página atual, sem link e com `aria-current="page"`. Com um item só (o
   Dashboard), a trilha não aparece. No 403, `Admin::BaseController` limpa a trilha para não mostrar a
   área administrativa a quem não tem acesso.
3. **Listagem.** "Novo campus" fica abaixo do cabeçalho: à direita no desktop, largura total no
   celular. O `if` da listagem só escolhe entre dois partials, `_table` e `shared/_empty_state`, como
   no exemplo do professor. No celular, Editar e Excluir viram botões de 44 px só com ícone, com o
   texto para leitor de tela (`sr-only sm:not-sr-only`) e `title`. A partir de `sm`, o texto aparece.
4. **Formulário.** Ocupa toda a largura do conteúdo (sai o `max-w-xl`), com placeholder
   "Ex.: Guarapuava". No celular, os botões ficam empilhados com largura total e Salvar em cima. A
   partir de `sm`, Cancelar fica à esquerda e Salvar à direita, como nas telas do Jacson.
5. **Espaçamento.** O `main` passa de `p-4 sm:p-8 lg:p-16` para `p-4 sm:p-6 lg:p-10`. As views deixam o
   wrapper `p-2 sm:p-6`, que se somava ao padding do layout.
6. **Input mobile first.** `Form::Input::BaseComponent` usava `text-xs md:text-base`: 12 px no
   celular, e o iOS dá zoom ao focar campos com menos de 16 px. O input passa a `text-base` em
   qualquer tela, e o rótulo e o erro passam de `text-xs md:text-sm` para `text-sm`. No desktop nada
   muda. O login usa o mesmo componente e também ganha a correção.

### Riscos e pendências da revisão

- **Outras páginas.** O padding do `main` muda também no Dashboard e na reserva, e a fonte dos inputs
  muda também no login (só no celular). Conferido nos testes de sistema existentes.
- **Fora do escopo, para outra Issue:** o cabeçalho do layout ainda tem um `<h1>` com "Olá, nome" (o
  teste `test/system/users/dashboard/hello_test.rb` depende dele), então as páginas têm dois `<h1>`; o
  botão de menu do celular não tem área de toque de 44 px nem rótulo acessível; e a reserva usa
  `content_for :page_title`, que o layout não renderiza.
- **320 px.** Na largura mínima, a trilha da edição quebra em duas linhas. Os itens Novo e Editar são
  curtos para isso acontecer só nessa largura.

## Comandos de verificação

```bash
bin/rails db:migrate
bin/rails test test/models/campus test/controllers/admin test/lib
bin/rails test
bin/rails test test/system/admin/campi
bin/rails test:system
bin/rubocop
bundle exec erb_lint --lint-all
bin/brakeman --no-pager
bin/ci
```

- `bin/rails db:populate` apaga e recria os usuários e os campi do banco de desenvolvimento. Vou
  rodá-lo só com a sua autorização. O teste do populator cobre o CA6 sem tocar nesse banco.
