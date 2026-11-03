# Cadastro de termos de uso — Plano técnico

Issue: #60 · Especificação: [spec.md](spec.md)

Status: aprovado em 2026-11-02.

## Abordagem técnica

O cadastro repete o de departamentos ([plano de departamentos](../departments/plan.md)): mesma estrutura
de controller, views, textos e testes. Trilha, cabeçalho, toast, estado vazio e `.btn-delete` já existem e
são reaproveitados. As diferenças são a página do termo (`show`), o campo de texto longo e o tratamento de
cadastros simultâneos.

1. **Tabela.** A migration `CreateUsageTerms` cria `usage_terms` com `title` (`string`, `null: false`),
   `content` (`text`, `null: false`), `timestamps` e índice único em `title`, como define a Issue.
2. **Modelo.** `UsageTerm`:
   - `normalizes :title, with: ->(title) { title.squish }` (RN2).
   - `normalizes :content, with: ->(content) { content.gsub(/\r\n?/, "\n").strip }` (RN5): o navegador
     envia as quebras do `textarea` como `\r\n`; o texto é gravado com `\n` e sem espaços e linhas em
     branco nas pontas. O meio do texto não muda.
   - `validates :title, presence: true, normalized_uniqueness: true` (RN1, RN3, RN6, RN7), o mesmo
     validador de campi, blocos e departamentos, sem escopo.
   - `validates :content, presence: true` (RN4). `presence` já recusa texto só com espaços e quebras.
   - `scope :ordered_by_title, -> { order(:title) }` (RF1). O nome diz o critério, como o professor pediu
     na revisão de 2026-10-30 (`sorted` → `ordered_by_name`).
   - Nenhuma associação nesta Issue: `has_many :spaces` e o bloqueio de exclusão entram na #61.
   - **Cadastros simultâneos** (veja [Race condition no título](#race-condition-no-título)): `save`
     captura `ActiveRecord::RecordNotUnique`, adiciona o erro `:taken` ao título e devolve `false`.
3. **Rotas.** Dentro de `namespace :admin`, `resources :usage_terms`, com as sete ações. É o primeiro
   cadastro com `show`.
4. **Controller.** `Admin::UsageTermsController < Admin::BaseController`, no formato de
   `Admin::DepartmentsController`:
   - `index`: `UsageTerm.ordered_by_title`.
   - `show`: só renderiza (`set_usage_term`).
   - `create`: sucesso → `redirect_to admin_usage_term_path(@usage_term), success: t(".success")` (RF2);
     falha → `render :new, status: :unprocessable_content`.
   - `update`: sucesso → `redirect_to admin_usage_term_path(@usage_term), success: t(".success"),
     status: :see_other` (RF4); falha → `render :edit, status: :unprocessable_content`.
   - `destroy`: `@usage_term.destroy!` e `redirect_to admin_usage_terms_path` com `success` e
     `status: :see_other` (RF5, RN9). A #61 troca por `restrict_with_error`, como campi.
   - `set_usage_term` com `UsageTerm.find(params.expect(:id))` (404); `usage_term_params` com
     `params.expect(usage_term: [ :title, :content ])`.
   - `set_breadcrumbs` (RF8): Termos de uso; mais Novo (`new`, `create`); o título do termo (`show`); ou o
     título do termo, com link para a página dele, e Editar (`edit`, `update`). A trilha usa
     `@usage_term.title_in_database`: depois de uma edição recusada, ela mostra o título gravado, não o
     valor inválido digitado.
5. **Views** (`app/views/admin/usage_terms/`):
   - `index`, `_table` e `_usage_term`, copiadas de departamentos. A linha mostra só o título, com
     `break-words`, como link para a página do termo, e três botões: Ver, Editar e Excluir, só com ícone
     no celular e com `min-w-11` (44 px de toque). No celular, as células usam `px-3` e os botões quebram
     de linha (`flex-wrap`): com os três lado a lado, um título com "responsabilidade" deixava a tabela
     com 343 px numa tela de 320 px.
   - `show`: título do termo no cabeçalho (`head_title`), subtítulo fixo, uma linha de ações (Editar e
     Excluir, como o botão "Novo" da listagem) e um cartão com o texto. O texto usa
     `simple_format(h(@usage_term.content))`: `h` escapa o HTML digitado (RF3, cenário com `<script>`), e
     `simple_format` cria um `<p>` por parágrafo e um `<br>` por quebra simples. O cartão tem
     `break-words` para endereços longos (RF9).
   - `new`, `edit` e `_form`: `f.input :title` e `f.input :content, type: :textarea, rows: 12`, que o
     `TailwindFormBuilder` já aceita. Cancelar volta para a listagem no cadastro e para a página do termo
     na edição.
6. **Atalho (RF7).** `admin/home/partials/_registrations.html.erb` ganha o item Termos de uso, depois de
   Departamentos.
7. **Ícones.** O card e a lista vazia usam `:file_with_lines`, que já existe e não é usado em nenhuma
   tela. O SVG dele não tem `fill="currentColor"` e ficaria preto no card azul, como aconteceu com
   `:users`; o atributo é acrescentado. O botão Ver precisa de um ícone novo, `:eye` (Font Awesome Free,
   como os outros).
8. **Populate (RF10).** `Db::Populator` apaga `UsageTerm` em `reset_records` e cria o termo de exemplo em
   `setup_usage_terms` (`UsageTerm.create_with(content:).find_or_create_by!(title:)`), depois dos
   departamentos. Título e texto ficam em constantes, como `DEPARTMENTS`.

### Termo de exemplo

Título: **Termo de uso do laboratório de informática**

```text
Ao reservar o laboratório de informática, o responsável pela reserva declara que leu e aceita as regras abaixo.

1. O uso é permitido somente no horário reservado. O responsável deve chegar no início da reserva e liberar o espaço no horário de término.
2. É proibido consumir alimentos e bebidas dentro do laboratório.
3. Os computadores não podem ser desconectados, abertos nem ter os cabos trocados. Programas só podem ser instalados com autorização da Coordenadoria de Tecnologia da Informação.
4. Ao final do uso, o responsável deve desligar os computadores, o projetor e o ar-condicionado, apagar as luzes e fechar as janelas.

O responsável responde pelos danos causados ao espaço e aos equipamentos durante a reserva. Problemas encontrados no início do uso devem ser informados ao Setor de Gestão de Espaços Acadêmicos antes de começar a atividade.
```

São três parágrafos, e o do meio tem quatro linhas separadas por quebras simples. Assim o exemplo mostra
as duas formatações do RF3.

### Fluxo de uma requisição ao cadastro

```text
PATCH /admin/usage_terms/:id
  └─ Admin::UsageTermsController (herda Admin::BaseController < Users::BaseController)
       1. require_authentication     → visitante: redirect /login, nada gravado           (acesso)
       2. require_admin_area_access  → usuário comum: 403, nada gravado                   (acesso)
       3. set_usage_term             → id inexistente: 404                                (acesso)
       4. update                     → válido: redirect /admin/usage_terms/:id + mensagem (RF4)
                                       inválido ou título gravado por outro: 422 com erro (RF6)
```

## Race condition no título

O professor pediu atenção a race conditions. A unicidade do título é verificada em duas camadas, e elas
não cobrem a mesma coisa:

| Camada | O que garante | O que não garante |
| --- | --- | --- |
| `NormalizedUniquenessValidator` | Títulos iguais depois de ignorar maiúsculas, acentos, espaços e pontuação (RN3). | Roda antes do `INSERT`: duas requisições ao mesmo tempo podem passar as duas pela verificação. |
| Índice único em `title` | Nunca existem duas linhas com o título exatamente igual. | Não compara sem acentos nem sem maiúsculas. |

Dois cenários com dois administradores salvando ao mesmo tempo:

1. **Mesmo título exato.** Os dois passam pelo validador. O segundo `INSERT` bate no índice único, e o
   Rails levanta `ActiveRecord::RecordNotUnique`. Hoje, em campi, blocos e departamentos, isso vira um
   HTTP 500. **Nesta Issue:** `UsageTerm#save` captura a exceção e transforma em erro de validação
   (`errors.add(:title, :taken)`). O administrador vê o formulário com "Já existe um termo cadastrado com
   este título.", como no caso comum. Como `update` chama `save`, a edição fica coberta também.
2. **Títulos equivalentes, mas não idênticos** ("Termo do Laboratório" e "termo do laboratorio"). Os dois
   passam pelo validador, e o índice não os vê como iguais: os dois são gravados. Fechar esse caso exige
   uma coluna com o título normalizado (`title_key`) e índice único nela, o que muda os dados definidos
   pela Issue e o padrão dos outros cadastros. **Fica como risco aceito**: só administradores cadastram,
   o volume é pequeno, e o efeito é um termo duplicado que o próprio administrador exclui. Vai nos
   "Pontos para o revisor" da PR.

Campi, blocos e departamentos têm o cenário 1 com HTTP 500. Corrigi-los está fora desta Issue; sugiro uma
Issue própria, que pode reaproveitar a mesma solução.

## Arquivos afetados

| Arquivo | Mudança |
| --- | --- |
| `db/migrate/<timestamp>_create_usage_terms.rb` | Novo: tabela `usage_terms`, `title` e `content` `null: false`, índice único em `title` |
| `db/schema.rb` | Regenerado pela migration |
| `app/models/usage_term.rb` | Novo: normalizações, validações, `ordered_by_title` e `save` com `RecordNotUnique` |
| `config/routes.rb` | `resources :usage_terms` no namespace `admin` |
| `app/controllers/admin/usage_terms_controller.rb` | Novo: CRUD com `show` e trilha |
| `app/views/admin/usage_terms/*` | Novos: `index`, `_table`, `_usage_term`, `show`, `new`, `edit`, `_form` |
| `app/views/admin/home/partials/_registrations.html.erb` | Card de Termos de uso |
| `app/helpers/icons_helper.rb` | Ícone `:eye`; `fill="currentColor"` no `:file_with_lines` |
| `config/locales/pt-BR/models.pt-BR.yml` | Modelo `usage_term` (Termo de uso/Termos de uso) e atributos |
| `config/locales/pt-BR/errors.pt-BR.yml` | Mensagens de título vazio e repetido e de texto vazio |
| `config/locales/pt-BR/views.pt-BR.yml` | Chaves `admin.usage_terms.*`, `admin.home.index.usage_terms*`, `actions.show` e placeholders |
| `lib/tasks/db/populate/populator.rb` | Constantes do termo, `reset_records` e `setup_usage_terms` |
| `test/factories/usage_terms.rb` | Nova factory `:usage_term` |

### Textos (pt-BR)

| Chave | Texto |
| --- | --- |
| `activerecord.models.usage_term.one` / `.other` | Termo de uso / Termos de uso |
| `activerecord.attributes.usage_term.title` | Título |
| `activerecord.attributes.usage_term.content` | Texto |
| `helpers.placeholder.usage_term.title` | Ex.: Termo de uso do laboratório de informática |
| `helpers.placeholder.usage_term.content` | Escreva as regras de uso e as responsabilidades de quem reserva o espaço. |
| `admin.home.index.usage_terms` | Termos de uso |
| `admin.home.index.usage_terms_description` | Cadastre os termos de uso e responsabilidade dos espaços |
| `admin.usage_terms.index.title` / `.breadcrumb` | Termos de uso |
| `admin.usage_terms.index.subtitle` | Gerencie os termos de uso e responsabilidade que os espaços podem exigir. |
| `admin.usage_terms.index.new` | Novo termo |
| `admin.usage_terms.index.empty` | Nenhum termo de uso cadastrado. |
| `admin.usage_terms.index.actions` | Ações |
| `admin.usage_terms.confirm_destroy` | Excluir o termo %{title}? (usada na listagem e na página do termo) |
| `admin.usage_terms.show.subtitle` | Termo de uso e responsabilidade dos espaços. |
| `admin.usage_terms.new.title` / `.breadcrumb` | Novo termo de uso / Novo |
| `admin.usage_terms.new.subtitle` | Preencha o título e o texto do novo termo. |
| `admin.usage_terms.edit.title` / `.breadcrumb` | Editar termo de uso / Editar |
| `admin.usage_terms.edit.subtitle` | Altere o título ou o texto. A alteração vale para todos os espaços que usam o termo. |
| `admin.usage_terms.create.success` | Termo de uso cadastrado com sucesso. |
| `admin.usage_terms.update.success` | Termo de uso atualizado com sucesso. |
| `admin.usage_terms.destroy.success` | Termo de uso excluído com sucesso. |
| `actions.show` | Ver |
| `activerecord.errors.models.usage_term.attributes.title.blank` | Informe o título do termo. |
| `activerecord.errors.models.usage_term.attributes.title.taken` | Já existe um termo cadastrado com este título. |
| `activerecord.errors.models.usage_term.attributes.content.blank` | Informe o texto do termo. |

Editar, Excluir, Salvar e Cancelar reaproveitam `actions.*`. O subtítulo da edição lembra a RN8.

## Banco de dados e compatibilidade

- Tabela nova, sem dados existentes e sem backfill. A migration é reversível (`create_table` e
  `add_index` dentro de `change`).
- O índice único garante só a igualdade exata do título; a unicidade normalizada (RN3) fica no validador,
  como nos outros cadastros. Veja a [race condition](#race-condition-no-título).
- `content` é `text`, sem limite de tamanho, como a Issue define.
- Vou conferir que o diff do `schema.rb` tem só a tabela `usage_terms`.
- **Produção:** nenhum termo é criado automaticamente (fora do escopo).

## Estratégia de testes

| Arquivo | Tipo | O que verifica | CA |
| --- | --- | --- | --- |
| `test/models/usage_term/usage_term_normalize_test.rb` | Modelo | Espaços do título normalizados com grafia e acentos preservados; texto com `\r\n` gravado com `\n`; espaços e linhas em branco das pontas removidos; parágrafos do meio iguais | CA3, CA4 |
| `test/models/usage_term/usage_term_validations_test.rb` | Modelo | `validate_presence_of` de `title` e `content` e `validate_uniqueness_of(:title).case_insensitive` (shoulda); texto só com espaços e quebras recusado; título repetido sem acento, sem cedilha, sem espaços e com pontuação recusado com a mensagem própria; o próprio termo pode trocar maiúsculas e acentos; renomear para outro termo é recusado | CA2, CA3, CA7 |
| `test/models/usage_term/usage_term_constraints_test.rb` | Modelo | O banco recusa título nulo, texto nulo e título exato repetido, sem validação | CA7 |
| `test/models/usage_term/usage_term_concurrent_save_test.rb` | Modelo | Com o validador de unicidade desligado por Mocha (simula a outra requisição passando junto), `save` e `update` de um título exato repetido devolvem `false` com o erro `:taken`, sem levantar exceção e sem gravar | CA3 |
| `test/models/usage_term/usage_term_ordered_by_title_test.rb` | Modelo | `ordered_by_title` ordena pelo título | CA1 |
| `test/controllers/admin/usage_terms_controller_test.rb` | Integração | Listagem em ordem e lista vazia; título, subtítulo e trilha nas quatro páginas, inclusive após erro (trilha com o título gravado); página do termo com um `<p>` por parágrafo, `<br>` nas quebras simples e HTML escapado; cadastro e edição redirecionam para a página do termo com toast; exclusão redireciona para a listagem; 422 para título vazio, texto vazio e título repetido, com os valores digitados mantidos; confirmação nos botões de excluir; 404 na página e na edição de termo inexistente | CA1–CA4 |
| `test/controllers/admin/usage_terms_controller_access_test.rb` | Integração | Visitante → `/login` e usuário comum → 403 nas sete ações, sem alterar dados; 403 antes de buscar o termo; o 403 não mostra a trilha | CA5 |
| `test/controllers/admin/home_controller_test.rb` | Integração | Atalho para `/admin/usage_terms` | CA1 |
| `test/lib/tasks/db/populate/populator_test.rb` | Unidade | O populate apaga os termos existentes e cria o termo de exemplo, com três parágrafos | CA6 |
| `test/system/admin/usage_terms/manage_usage_terms_test.rb` | Sistema | Cadastro com parágrafos e ida para a página do termo; edição pela página do termo; exclusão pela listagem e pela página do termo, com confirmação aceita e recusada e toast; erro de título repetido | CA1, CA3, CA4 |
| `test/system/admin/usage_terms/manage_usage_terms_on_phone_test.rb` | Sistema | Em 320 × 640, a listagem e a página do termo cabem na tela com um título longo e um endereço longo no texto; Ver, Editar e Excluir com pelo menos 44 px; cadastro pelo celular | CA1 |

- As respostas HTML verificam `assert_no_match(/translation missing/i, response.body)`.
- Sem teste de inflexão: `usage_term` → `usage_terms` é a regra padrão do Rails.
- A factory usa `sequence(:title)` e um texto de dois parágrafos com Faker.

## Autorização e segurança

- Todas as ações herdam `require_authentication` e `require_admin_area_access`. Os testes de acesso
  cobrem as sete ações, incluindo envios diretos de POST, PATCH e DELETE.
- `params.expect(usage_term: [ :title, :content ])` libera só os dois campos.
- CSRF continua ativo; `button_to` envia o token na exclusão.
- **XSS no texto.** O texto é a primeira entrada longa e livre do sistema. `simple_format` sozinho
  sanitiza, mas deixa passar marcações como `<b>` e `<a>`; com `h` antes, todo HTML vira texto (RF3). O
  teste de integração confere `&lt;script&gt;` no corpo da página.
- Título exibido com o escape padrão do ERB; a confirmação de exclusão interpola o título num atributo
  `data-turbo-confirm`, também escapado.
- Vou rodar `bundle exec brakeman --no-pager` na verificação.

## Riscos e trade-offs

- **Regra mais rígida que a Issue (RN3).** Segue a decisão de campi, blocos e departamentos, mantida
  pelo professor em 2026-10-23. Vai nos "Pontos para o revisor" da PR.
- **Títulos equivalentes salvos ao mesmo tempo.** Risco aceito, explicado em
  [Race condition no título](#race-condition-no-título).
- **`save` sobrescrito no modelo.** Assim, cadastro, edição e qualquer outro chamador ficam cobertos sem
  repetir `rescue` no controller. `save!` continua levantando a exceção, como o Rails faz por padrão.
- **Página do termo.** É o primeiro `show` do admin. A tela segue o cabeçalho e os botões das outras;
  depois de salvar, o administrador para nela, e não na listagem como nos outros cadastros, por decisão
  da spec (RF2, RF4).
- **Ordenação com acentos e minúsculas (RF1).** `order(:title)` usa a comparação binária do SQLite:
  títulos que começam com minúscula ou letra acentuada ("termo…", "Área…") vão para o fim da listagem.
  É o mesmo comportamento de departamentos, aceito pelo professor na revisão da PR #73. Vai nos "Pontos
  para o revisor" da PR.
- **`rescue` só do índice do título.** `save` reconhece a violação pelo nome da coluna (SQLite) ou do
  índice (PostgreSQL) na mensagem e levanta de novo qualquer outra, como a de uma chave primária ou de um
  índice único que a #61 venha a criar.
- **Texto sem limite.** Um texto muito longo só deixa a página do termo comprida. Não há limite na Issue.

## Comandos de verificação

```bash
bin/rails db:migrate
bin/rails test test/models/usage_term test/controllers/admin test/lib
bin/rails test
bin/rails test:system test/system/admin/usage_terms
bin/rubocop
bundle exec erb_lint --lint-all
bundle exec brakeman --no-pager
```
