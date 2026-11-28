# Área administrativa organizada por campus — Plano técnico

Issue: #99 · Especificação: [spec.md](spec.md)

Status: aprovado pelo desenvolvedor em 2026-11-27. Os ajustes feitos durante a implementação estão
em "Ajustes durante a implementação", no fim.

## Abordagem técnica

O campus passa a ser um recurso pai nas rotas. Os controllers de blocos e espaços vão para dentro
dele (`Admin::Campi::`), e todos buscam o bloco ou o espaço pela associação do campus do endereço.
Isso resolve, de uma vez, o campus fixo (RN1, RN2) e o isolamento entre campi (RN5). Nenhuma tabela
muda. As partes novas são a entrada com os cartões, a visão geral do campus, o menu lateral do campus
e os filtros da listagem de espaços. O resto é o código atual de blocos e espaços (#57 e #61) mudado
de lugar e sem o campo Campus.

1. **Rotas.** Em `namespace :admin`:

   ```ruby
   resources :campi, except: :index do
     scope module: :campi do
       resources :buildings, except: :show
       resources :spaces do
         scope module: :spaces do
           resource :unavailability, only: [ :new, :create, :edit, :update, :destroy ]
           resource :deactivation, only: [ :create, :destroy ]
         end
       end
     end
   end
   ```

   Os endereços ficam `/admin/campi/:campus_id/buildings`, `/admin/campi/:campus_id/spaces/:id` e
   `/admin/campi/:campus_id/spaces/:space_id/unavailability`, no plural (D8). Os helpers ficam
   `admin_campus_spaces_path(campus)`, `admin_campus_space_path(campus, space)` e assim por diante.
   `resources :buildings` e `resources :spaces` saem do topo de `admin`, e a listagem de campi
   (`index`) deixa de existir (RF14, D3). Departamentos, termos de uso e usuários não mudam.
2. **Acesso ao campus (RN1, D1).**
   - `AdminPolicy#manage_campus?(campus)`: devolve `@user.admin?`. Nesta Issue, o administrador geral
     administra todos os campi. A #93 muda este método para considerar os administradores do campus,
     e ainda precisa separar o que é só do administrador geral (ver Riscos). Segue o padrão de nomes que o professor indicou: `AdminPolicy#access_area?` com
     `can_access_admin_area?`.
   - `Users::BaseController` ganha o helper `can_manage_campus?(campus)`, ao lado de
     `can_access_admin_area?`.
   - `Admin::BaseController` ganha `require_campus_access`, que nega o acesso quando o usuário não
     pode administrar o campus de `@campus`. A resposta de acesso negado (sem trilha, `shared/forbidden`,
     403) passa para um método `deny_access`, usado pelas duas checagens. O controller ganha também
     `selectable_campi` (`Campus.ordered_by_name`), os campi do seletor. A #93 restringe esse método
     aos campi da pessoa (D4 da #89).
   - A ordem dos `before_action` é: área administrativa (herdada), busca do campus e acesso ao campus.
     Assim, o usuário comum recebe 403 mesmo num campus que não existe, e o administrador recebe 404.
3. **`Admin::Campi::BaseController < Admin::BaseController`** (novo), base dos controllers dentro
   do campus:
   - `layout "admin/campus"` (item 9).
   - `set_campus`: `Campus.find(params.expect(:campus_id))`, seguido de `require_campus_access`.
   - `campus_section`: a seção do menu (`:buildings` ou `:spaces`), definida em cada controller e
     exposta à view com `helper_method`.
   - `set_breadcrumbs`: acrescenta o campus, com link para a página dele, depois de Dashboard › Área
     administrativa.
4. **Modelos.**
   - `Building`: sai o callback `move_spaces_to_new_campus` e entra `attr_readonly :campus_id` (RN2).
     Com `load_defaults 8.1`, `raise_on_assign_to_attr_readonly` está ligado (conferido no Rails
     8.1.4.1): escrever o campus de um bloco já gravado levanta `ActiveRecord::ReadonlyAttributeError`.
     Os controllers nunca escrevem o campus, porque ele não está nos parâmetros permitidos. O erro
     também aparece ao reatribuir o mesmo campus (`assign_attributes(campus:)`,
     `campus.buildings << building`), porque o Rails não compara os valores; nenhum código do sistema,
     do populate ou das factories faz isso. O escopo `sorted`,
     usado só pela listagem antiga, dá lugar a `ordered_by_name`, que diz o critério.
   - `Space`: também `attr_readonly :campus_id` (RN2, D5). A validação
     `building_belongs_to_campus` continua valendo para envios diretos (RN4). Ganha
     `Space.counts_by_status`, um `group(:status).count` para a visão geral.
   - `Campus`: ganha o escopo `ordered_by_name`. Sai `having_buildings_ordered_by_name`, que só
     servia ao campo Bloco agrupado por campus.
   - Mensagens de erro: o bloco de outro campus passa a ser "Selecione um bloco deste campus.", e a
     exclusão de campus recusada termina em "Exclua-os antes." (RN4, RN9).
5. **Comparação de nomes (RN7, D7).** O cálculo da chave de comparação sai de
   `NormalizedUniquenessValidator#comparison_key` e vai para um Value Object,
   `ComparableName = Data.define(:key)`, em `app/value_objects/comparable_name.rb`.
   - `ComparableName.from(texto)` monta a chave: só letras e dígitos, sem acentos e em minúsculas
     (NFKD, remove `\p{Mn}`, `downcase(:fold)`, remove `[^\p{Alnum}]`). É o mesmo cálculo de hoje, que
     roda em Ruby porque o `LOWER()` do SQLite só converte ASCII.
   - `#include?(outro)` responde se a chave de um nome contém a de outro.
   - O validador passa a comparar `ComparableName` (a igualdade vem do `Data`), sem mudar o
     comportamento. Os testes atuais de unicidade de campi, blocos e departamentos continuam
     garantindo isso.
6. **Entrada (`Admin::HomeController#index`, RF1–RF3).**
   - `Admin::CampusSummariesQuery#call` (em `app/queries/admin/`) devolve um `CampusSummary` por
     campus, em ordem alfabética, com `campus`, `spaces_count`, `buildings_count` e
     `unavailable_spaces_count`. São quatro consultas, qualquer que seja o número de campi: os campi
     e três `group(:campus_id).count` (espaços, espaços indisponíveis e blocos). Não há N+1.
   - Views: `admin/home/index` renderiza `partials/_campi` (título da seção, "Cadastrar campus", um
     `_campus_card` por campus ou o estado vazio) e `partials/_general_registrations` (Usuários,
     Departamentos e Termos de uso, com as descrições atuais). Sai `partials/_registrations`.
7. **Página do campus (`Admin::CampiController`, RF3, RF4, RF12).**
   - `index` sai; entra `show`. `layout "admin/campus", only: [ :show, :edit, :update ]`.
     `require_campus_access` em `show`, `edit`, `update` e `destroy`. `campus_section` devolve
     `:overview`.
   - `show`: `@space_counts = @campus.spaces.counts_by_status`,
     `@building_names = @campus.buildings.ordered_by_name.pluck(:name)` e
     `@unavailable_spaces = @campus.spaces.unavailable.ordered_by_campus_building_and_name`.
   - `Admin::CampusOverviewPresenter` (`app/presenters/admin/`) monta as frases dos resumos: o total e
     "5 disponíveis, 1 indisponível e 1 desativado" (só as situações com espaços, com singular e
     plural), e o total e "Bloco B, Bloco C e Bloco R" (`to_sentence` em pt-BR).
   - Redirecionamentos: `create` vai para a entrada (D6); `update` vai para a página do campus;
     `destroy` vai para a entrada com sucesso, ou para a página do campus com o `alert` da recusa.
   - Views: `show` com as parciais `_actions` (Editar campus e Excluir campus, com confirmação),
     `_spaces_summary`, `_buildings_summary` e `_unavailable_spaces` (um item por espaço, ou "Nenhum
     espaço indisponível."). Saem `index`, `_table` e `_campus`.
   - Trilha: Área administrativa › Novo campus; Área administrativa › <campus> (página); Área
     administrativa › <campus> › Editar, com `name_in_database` para a edição recusada continuar
     mostrando o nome gravado.
8. **Blocos (`Admin::Campi::BuildingsController`, RF11).** É o `Admin::BuildingsController` atual,
   movido para `app/controllers/admin/campi/` e com as views em `app/views/admin/campi/buildings/`.
   - `index`: `@campus.buildings.ordered_by_name`. `set_building`:
     `@campus.buildings.find(params.expect(:id))`, que dá 404 para um bloco de outro campus (RN5).
   - `create`: `@campus.buildings.new(building_params)`; `building_params` só com `:name`.
   - Saem `set_campi`, `update_success_message`, `Admin::BuildingsHelper#building_campus_change_hint`
     e os textos do aviso e da contagem (CA7).
   - Views: sem a coluna Campus; o formulário só com Nome, em
     `form_with model: [ :admin, campus, building ]`; confirmação "Excluir o bloco <nome>?".
9. **Layout e menu do campus (RF5, RF6, D4).**
   - O conteúdo do `<nav>` de `layouts/users/partials/_sidebar.html.erb` vai para a parcial
     `_main_navigation`. O `<aside>` (classes, alvos do `ui--sidebar`, backdrop) não muda e passa a
     renderizar `yield(:sidebar_navigation)` quando há esse conteúdo; senão, `_main_navigation`. O
     `if` só escolhe entre duas renderizações, como o professor pediu.
   - Layout aninhado `layouts/admin/campus.html.erb`: preenche `:sidebar_navigation` com
     `Admin::CampusMenuComponent` e renderiza `layouts/users/application`. Cabeçalho, toast e botão
     do menu no celular são os mesmos.
   - `Admin::CampusMenuComponent.new(campus:, campi:, section:)` (`app/components/admin/`): o link
     "Área administrativa"; o rótulo "Campus" e o seletor em `<details>`/`<summary>` (funciona sem
     JavaScript e pelo teclado), com os campi e o atual marcado com `aria-current`; com um só
     campus, só o nome. Depois, os itens Visão geral, Espaços e Blocos, com `aria-current="page"` e a
     classe `active` na seção atual, e Dashboard e Minhas reservas separados. Cada campus do seletor
     aponta para a mesma seção dele (D4): `admin_campus_path`, `admin_campus_spaces_path` ou
     `admin_campus_buildings_path`. A seção vem de `campus_section`, não da comparação de endereços,
     então a página de um espaço ou um formulário marcam a seção certa.
10. **Espaços (`Admin::Campi::SpacesController` e `Admin::Campi::Spaces::*`, RF7–RF10).** São os
    controllers atuais, movidos para `app/controllers/admin/campi/`, com as views em
    `app/views/admin/campi/spaces/`.
    - `set_space`: `@campus.spaces.find(...)`, também na base das ações de situação, que passa a
      herdar de `Admin::Campi::BaseController` (RN5).
    - `create`: `@campus.spaces.new(space_params)`; `space_params` sem `campus_id` (RN1).
    - `set_form_options`: `@buildings = @campus.buildings.ordered_by_name`, e os departamentos e
      termos de hoje (RN10).
    - Formulário: sai o campo Campus e entra a linha "Campus <nome>"; o campo Bloco vira um `select`
      simples com "Sem bloco" e os blocos do campus, com a dica nova. Sai o `ui--filtered-select` do
      formulário, e o controller `ui/filtered_select_controller.js` é apagado, porque era o único uso.
      O `grouped_collection_select` do form builder fica como está, sem uso por enquanto; só o
      comentário que cita o controller apagado é ajustado.
    - Todos os links, cancelamentos e redirecionamentos passam a usar os helpers aninhados.
    - `Admin::SpacePresenter#location` deixa de ser usado (a listagem mostra o bloco) e sai.
11. **Filtros da listagem de espaços (RF8, RN7, RN8).**
    - `Admin::SpaceFiltersForm < BaseForm` (`app/forms/admin/`), com `campus`, `name`, `building` e
      `status`. Ele normaliza a entrada: nome com `squish`; situação só se for uma das do enum; bloco só
      se for `"none"` ("Sem bloco") ou o id de um bloco do campus. Qualquer outro valor vira "Todos"
      (RN8). Expõe também as opções dos dois `select` e `any?`, que decide se aparece "Limpar
      filtros".
    - `Admin::CampusSpacesQuery.new(campus:, filters:).call` (`app/queries/admin/`): parte de
      `campus.spaces.ordered_by_campus_building_and_name.includes(:department)`, aplica bloco e
      situação no SQL e o nome em Ruby, com `ComparableName#include?`. Devolve um `Array`. O
      pré-carregamento (bloco e departamento) faz parte do contrato da consulta. A listagem não é
      paginada, então filtrar em Ruby os espaços de um campus custa pouco.
    - Parâmetros: `params.permit(filters: [ :name, :building, :status ])`. Um `filters` malformado
      vira "sem filtro", em vez de erro. O endereço fica, por exemplo,
      `/admin/campi/1/spaces?filters[name]=lab&filters[status]=available`.
    - View: `_filters` (formulário `GET`, `role="search"`, rótulos visíveis), fora do
      `turbo_frame_tag "spaces_results"`. Dentro do frame ficam a contagem, a tabela, "Nenhum espaço
      encontrado com estes filtros." e "Limpar filtros" (com `data-turbo-frame="_top"`, para limpar
      também o formulário). Num campus sem espaços, filtros e tabela dão lugar ao estado vazio
      "Nenhum espaço cadastrado neste campus."
    - O formulário usa `data-turbo-frame="spaces_results"` e `data-turbo-action="advance"`: só a
      tabela é trocada, o foco continua no campo e o endereço guarda os filtros.
    - Controller Stimulus `ui--filter-form` (novo): envia o formulário com `requestSubmit()` ao mudar
      um `select` e 300 ms depois da última tecla no nome; esconde o botão "Filtrar" ao conectar (sem
      JavaScript, o botão envia o formulário); e, depois de `turbo:frame-load`, copia a contagem para
      uma região `aria-live="polite"` fora do frame, que já existe na página. Uma região viva criada
      junto com o conteúdo novo nem sempre é anunciada pelos leitores de tela.
12. **Textos (pt-BR).** As chaves de `admin.buildings.*` e `admin.spaces.*` vão para
    `admin.campi.buildings.*` e `admin.campi.spaces.*`, acompanhando as views. As chaves
    preguiçosas (`t(".title")`) dependem do caminho da view, e o presenter e as parciais passam a usar
    o caminho novo. Entram as chaves da entrada, da página do campus, dos resumos, dos filtros e do
    menu (`components.admin.campus_menu.*`, como as de `components.page.*`). Saem as chaves do aviso
    de troca de campus, da contagem, de `campus_prompt` e dos atalhos antigos.

### Fluxo de um cadastro de espaço

1. `GET /admin/campi/1/spaces/new` → área administrativa e campus 1 conferidos; formulário com
   "Campus Guarapuava" e os blocos de Guarapuava.
2. `POST /admin/campi/1/spaces` → `@campus.spaces.new(space_params).save`. Um `campus_id` no corpo
   é descartado pelos parâmetros permitidos.
3. Válido → `303` para `/admin/campi/1/spaces`, com toast. Inválido → `422`, formulário com os
   valores e os erros, como hoje.

## Arquivos afetados

| Área | Arquivos |
| --- | --- |
| Rotas | `config/routes.rb` |
| Políticas | `app/policies/admin_policy.rb` |
| Controllers | `users/base_controller.rb`, `admin/base_controller.rb`, `admin/home_controller.rb`, `admin/campi_controller.rb`; `admin/campi/base_controller.rb` (novo); `admin/buildings_controller.rb` → `admin/campi/buildings_controller.rb`; `admin/spaces_controller.rb` e `admin/spaces/*` → `admin/campi/spaces_controller.rb` e `admin/campi/spaces/*` |
| Modelos | `building.rb`, `space.rb`, `campus.rb` |
| Value Objects | `app/value_objects/comparable_name.rb` (novo); `app/validators/normalized_uniqueness_validator.rb` |
| Queries | `app/queries/admin/campus_summaries_query.rb`, `app/queries/admin/campus_spaces_query.rb` (novos) |
| Forms | `app/forms/admin/space_filters_form.rb` (novo) |
| Presenters | `app/presenters/admin/campus_overview_presenter.rb` (novo); `admin/space_presenter.rb` |
| Componentes | `app/components/admin/campus_menu_component.rb` e `.html.erb` (novos) |
| Helpers | `app/helpers/admin/buildings_helper.rb` (sai) |
| JavaScript | `app/javascript/controllers/ui/filter_form_controller.js` (novo); `ui/filtered_select_controller.js` (sai) |
| Layouts | `layouts/admin/campus.html.erb` (novo); `layouts/users/partials/_sidebar.html.erb`, `_main_navigation.html.erb` (novo) |
| Views | `admin/home/*`; `admin/campi/*`; `admin/buildings/*` → `admin/campi/buildings/*`; `admin/spaces/*` → `admin/campi/spaces/*` |
| Textos | `config/locales/pt-BR/views.pt-BR.yml`, `errors.pt-BR.yml`, `models.pt-BR.yml` |
| Testes | ver Estratégia de testes |

## Banco de dados e compatibilidade

- Nenhuma migration. Blocos e espaços já têm `campus_id NOT NULL` com chave estrangeira.
- O campus fixo fica garantido na aplicação (`attr_readonly`), não no banco. Um gatilho no banco foi
  descartado: o SQLite e o PostgreSQL escrevem gatilhos de jeitos diferentes, e a migração para
  PostgreSQL está prevista.
- Os endereços antigos (`/admin/campi` em `GET`, `/admin/buildings…` e `/admin/spaces…`) passam a
  responder 404, sem redirecionamento (D3). O sistema ainda não está em uso.
- As consultas novas usam só `group`, `count`, `where` e `order` do Active Record, que valem no
  PostgreSQL.

## Estratégia de testes

| Arquivo | Tipo | O que verifica | CA |
| --- | --- | --- | --- |
| `test/components/admin/campus_menu_component_test.rb` | Componente | Seções e seção atual, seletor com os campi em ordem e o atual marcado, outro campus na mesma seção, campus único sem seletor, seção desconhecida recusada | CA2 |
| `test/policies/admin_policy_test.rb` | Unidade | `manage_campus?` verdadeiro para o administrador e falso para o usuário comum | CA6, CA9 |
| `test/value_objects/comparable_name_test.rb` | Unidade | Chave sem acentos, maiúsculas, espaços e pontuação; `include?`; igualdade por valor | CA5 |
| `test/models/building/building_campus_readonly_test.rb` (no lugar de `building_campus_change_test.rb`) | Modelo | Trocar o campus de um bloco gravado levanta o erro e não muda o bloco nem os espaços; o nome continua editável | CA6, CA7 |
| `test/models/space/space_campus_readonly_test.rb` | Modelo | O mesmo para o espaço | CA6 |
| `test/models/building/building_ordered_by_name_test.rb` (no lugar de `building_sorted_test.rb`), `test/models/campus/campus_ordered_by_name_test.rb` (no lugar de `campus_having_buildings_ordered_by_name_test.rb`) | Modelo | Ordem pelo nome | CA1, CA3 |
| `test/lib/tasks/db/populate/populator_test.rb` | Unidade | Troca `Building.sorted` pelos blocos de Guarapuava em `ordered_by_name`; o populate não muda | — |
| `test/models/space/space_counts_by_status_test.rb` | Modelo | Contagem por situação, só das situações com espaços | CA2 |
| `test/queries/admin/campus_summaries_query_test.rb` | Unidade | Um resumo por campus, em ordem, com zeros para campus vazio; os indisponíveis contados à parte; número fixo de consultas | CA1 |
| `test/queries/admin/campus_spaces_query_test.rb` | Unidade | Só os espaços do campus, em ordem; filtros por nome (acentos e maiúsculas), por bloco, por "Sem bloco" e por situação, combinados | CA5 |
| `test/forms/admin/space_filters_form_test.rb` | Unidade | Normalização; situação desconhecida e bloco de outro campus ignorados; opções dos `select`; `any?` | CA5 |
| `test/presenters/admin/campus_overview_presenter_test.rb` | Unidade | Frases com singular, plural e situações omitidas; nomes dos blocos | CA2 |
| `test/controllers/admin/home_controller_test.rb` | Integração | Título, subtítulo e trilha; cartões em ordem, com contagens e o aviso de indisponíveis; estado vazio; Cadastros gerais; sem os atalhos antigos | CA1 |
| `test/controllers/admin/campi_controller_test.rb` | Integração | Página do campus (resumos, indisponíveis, botões, trilha, menu com a seção marcada e o seletor); cadastro volta para a entrada; edição volta para a página; exclusão com sucesso e recusada com a mensagem nova; 404 | CA2 |
| `test/controllers/admin/campi/buildings_controller_test.rb` (movido) | Integração | Listagem só do campus; cadastro e edição sem o campo Campus; `campus_id` forjado ignorado no cadastro e na edição, sem mexer nos espaços; bloco de outro campus → 404 em editar, atualizar e excluir; sem o aviso e a contagem | CA3, CA6, CA7 |
| `test/controllers/admin/campi/spaces_controller_test.rb` (movido) | Integração | O que já cobre hoje, nos endereços novos; formulário sem Campus, com a linha do campus e só os blocos do campus; `campus_id` forjado ignorado; bloco de outro campus recusado; espaço de outro campus → 404; filtros por parâmetro, com contagem, "Limpar filtros" e valores desconhecidos ignorados | CA3–CA6 |
| `test/controllers/admin/campi/spaces/{unavailabilities,deactivations}_controller_test.rb` (movidos) | Integração | O que já cobrem hoje, nos endereços novos; espaço de outro campus → 404 | CA3 |
| `test/controllers/admin/{campi,campi/buildings,campi/spaces}_controller_access_test.rb` e `home_controller_access_test.rb` | Integração | Visitante → `/login` e usuário comum → 403 em todas as ações, sem alterar dados; 403 antes de procurar o campus | CA9 |
| `test/controllers/admin/campi/spaces_filters_test.rb` | Integração | Campos e opções dos filtros; nome sem acentos, bloco, "Sem bloco", situação e combinação; contagem; "Limpar filtros"; sem resultado; valores desconhecidos e formato inválido ignorados; resposta ao pedido do frame; campus sem espaços sem filtros | CA5 |
| `test/controllers/admin/legacy_routes_test.rb` | Integração | `/admin/campi`, `/admin/buildings` e `/admin/spaces` respondem 404 | CA3 |
| `test/system/admin/campi/manage_campus_test.rb` | Sistema | Da entrada até a página do campus; troca de campus pelo seletor na mesma seção; editar e excluir o campus | CA1, CA2 |
| `test/system/admin/campi/manage_buildings_test.rb`, `manage_spaces_test.rb` (movidos de `admin/buildings` e `admin/spaces`) | Sistema | Os fluxos de hoje dentro do campus; filtros atualizando a tabela sem tirar o foco, com o endereço atualizado e o filtro mantido ao recarregar | CA3–CA5 |
| `test/system/admin/campi/*_on_phone_test.rb` | Sistema | Em 320 × 640: entrada, visão geral, menu e seletor, filtros e formulários sem rolagem lateral, com áreas de toque de 44 px | CA8 |

- As respostas HTML conferem `assert_no_match(/translation missing/i, response.body)`.
- A verificação de uso (checklist da especificação) é feita na aplicação rodando, em 1400, 390 e
  320 px, e registrada em `tasks.md`.

## Autorização e segurança

- Toda ação passa pela checagem da área administrativa e, dentro de um campus, pela do campus
  (`AdminPolicy#manage_campus?`), sempre no servidor.
- Blocos e espaços são sempre buscados pela associação do campus do endereço, então um id de outro
  campus dá 404 em todas as ações (RN5).
- `campus_id` não entra nos parâmetros permitidos, e `attr_readonly` barra a troca em qualquer outro
  caminho (RN2).
- Os filtros só aceitam valores conhecidos; o nome é comparado em Ruby e nunca entra numa consulta
  SQL montada à mão.
- Exclusões continuam em `DELETE` com token CSRF (`button_to`); filtros usam `GET` e não alteram nada.

## Riscos e trade-offs

- **Tamanho da mudança.** Quase todo o código e os testes de blocos e espaços mudam de lugar. As
  tarefas movem cada recurso de uma vez, com os testes, para cada passo ficar verificável sozinho.
  Mover arquivos com `git mv` preserva o histórico.
- **Checagem de campus igual à da área.** Até a #93, `manage_campus?` dá o mesmo resultado que
  `access_area?`. O método entra agora porque a regra é do professor (D1).
- **O que a #93 precisa mudar além de `manage_campus?`** (achado da revisão independente). Para o
  administrador de campus chegar a `/admin`, `access_area?` vai ficar mais amplo. Então a #93 precisa
  de um predicado só do administrador geral para: cadastrar, editar e excluir campi; os cadastros
  gerais (usuários, departamentos e termos de uso, enquanto forem gerais) e a seção deles na entrada.
  Precisa também restringir aos campi da pessoa os cartões da entrada
  (`Admin::CampusSummariesQuery`) e o seletor (`selectable_campi`), de preferência a partir de um
  único escopo da política. Nesta Issue, só o administrador geral acessa a área, então nada disso
  muda o comportamento.
- **Campus excluído durante um cadastro.** Se um campus sem cadastros é excluído entre o carregamento
  do campus e o `save` de um bloco nele, a chave estrangeira recusa a gravação e a requisição falha
  com erro 500. É raro (dois administradores, um campus vazio sendo excluído no mesmo instante) e não
  deixa dado inconsistente. Aceito, como nas Issues anteriores.
- **Filtro de nome em Ruby.** Carrega todos os espaços do campus antes de filtrar pelo nome. Para os
  números de um campus (dezenas de espaços), não pesa. Se a listagem ganhar paginação, o filtro de nome
  vai para o banco, com `unaccent` e `ILIKE` no PostgreSQL.
- **Branch a partir da `main`, sem a PR #98.** Os links da especificação para os protótipos só
  funcionam depois que a #98 entrar. O código não depende dela.
- **Falha do `scan_ruby` na CI.** O Brakeman 8.1.0 está desatualizado e a CI falha em qualquer PR até
  o professor atualizar a gem. A verificação local usa `bundle exec brakeman`.

## Decisões técnicas para aprovar

| # | Decisão | Proposta |
| --- | --- | --- |
| P1 | Onde ficam os controllers de blocos e espaços | Em `Admin::Campi::`, espelhando o endereço, com uma base que busca o campus e confere o acesso. A alternativa (aninhar só as rotas e manter `Admin::SpacesController`) espalharia a busca do campus por vários controllers. |
| P2 | Como fixar o campus | `attr_readonly :campus_id` em `Building` e `Space`, que levanta erro na tentativa. Uma validação com mensagem não teria quem a visse, porque nenhuma tela envia o campus. |
| P3 | Checagem de acesso ao campus já nesta Issue | Sim, `AdminPolicy#manage_campus?`, pelos motivos dos riscos. |
| P4 | Busca por nome sem acentos | Extrair a chave do validador para `ComparableName` e filtrar o nome em Ruby. |
| P5 | Filtros | `GET` com Turbo Frame e o Stimulus `ui--filter-form`, com o botão "Filtrar" para quem não tem JavaScript. |
| P6 | Código que perde o uso | Apagar `filtered_select_controller.js`, `Campus.having_buildings_ordered_by_name`, `Building.sorted`, `Admin::BuildingsHelper` e `Admin::SpacePresenter#location`. Manter o `grouped_collection_select` do form builder, que o professor pediu na #88 e é genérico. |

## Comandos de verificação

```bash
bin/rails test test/policies test/value_objects test/models test/queries test/forms test/presenters
bin/rails test test/controllers/admin
bin/rails test
bin/rails test:system test/system/admin/campi
bin/rubocop
bundle exec erb_lint --lint-all
bundle exec brakeman --no-pager
bin/importmap audit
```

Como a mudança mexe no controle de acesso da área administrativa, a implementação passa por uma
revisão independente antes de ser dada como concluída.

## Ajustes durante a implementação

- **Layout da página do campus.** `layout "admin/campus", only: [...]` deixa as outras ações sem
  layout nenhum, em vez de usar o do controller pai. `Admin::CampiController` escolhe o layout com
  uma lambda: campus gravado → `admin/campus`; cadastro de campus → `users/application`.
- **Acesso negado.** `deny_access` renderiza `shared/forbidden` sempre com `users/application`,
  porque o layout do campus precisa de um campus carregado e o acesso é negado antes da busca.
- **Nome no menu.** O menu do campus mostra `name_in_database`, para uma edição recusada não
  renomear o campus no menu antes de salvar.
- **Largura do menu.** O menu lateral passou de `lg:w-48` para `lg:w-56` em todas as páginas, como
  nos protótipos aprovados, para caber o seletor de campus.
- **Frame dos resultados.** `turbo_frame_tag "spaces_results", target: "_top"`: os links e botões da
  tabela abrem a página inteira; só o formulário de filtros mira o frame.
- **Contagem de consultas nos testes.** O cache de consultas continua entre requisições no mesmo
  teste, então os testes de N+1 contam também as consultas em cache e comparam 1 espaço com 4.
- **Teste do componente.** O menu do campus ganhou teste próprio de componente, além das
  verificações de integração.
- **Busca só com pontuação.** Um nome sem letras nem dígitos ("---") não tem o que comparar e
  encontraria todos os espaços; o formulário de filtros o descarta, como a busca vazia.
- **Revisão independente.** Sem bugs no comportamento atual. Os ajustes vieram dela: os testes de
  acesso negado ao campus para um administrador (página do campus e todas as ações de espaços,
  inclusive o pedido do frame), a busca só com pontuação, o comentário do `attr_readonly` e os riscos
  da #93 acima.
