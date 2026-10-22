# Cadastro de blocos — Tarefas

Issue: #57 · [spec.md](spec.md) · [plan.md](plan.md)

Legenda: `[ ]` pendente · `[~]` em andamento · `[x]` concluída

## T1 — Modelo `Building` e tabela `buildings`

- [x] Status
- **Objetivo:** blocos pertencem a um campus e têm nome obrigatório, normalizado e único dentro do
  campus pela comparação de campi, com mensagens próprias; a listagem tem um escopo ordenado que
  carrega o campus.
- **Requisitos:** RN1–RN7, RF1 · CA2, CA3, CA5, CA8
- **Passos:** testes de modelo (associação, normalização, validações, restrições do banco, escopo
  `sorted`) → migration `CreateBuildings` → opção `scope` no `NormalizedUniquenessValidator` →
  `app/models/building.rb` → factory `:building` → modelo, atributos e erros em `models.pt-BR.yml` e
  `errors.pt-BR.yml`.
- **Verificação:** `bin/rails test test/models` (blocos e campi) e diff do `db/schema.rb` só com
  `buildings`.
- **Depende de:** —

## T2 — Campus com blocos não pode ser excluído

- [x] Status
- **Objetivo:** excluir um campus com blocos não apaga nada e mostra o motivo; campus sem blocos
  continua sendo excluído.
- **Requisitos:** RF7, RN9 · CA4, CA8
- **Passos:** teste de modelo do campus e teste de integração da exclusão recusada →
  `has_many :buildings, dependent: :restrict_with_error` → mensagem em `errors.pt-BR.yml` →
  `Admin::CampiController#destroy` com `alert:` na falha.
- **Verificação:** `bin/rails test test/models/campus test/controllers/admin/campi_controller_test.rb`
- **Depende de:** T1

## T3 — Campo de seleção no form builder

- [x] Status
- **Objetivo:** `f.input :attr, type: :select, collection:` renderiza um select com o visual dos
  inputs, rótulo, prompt, 44 px de altura e os erros do atributo e do `belongs_to`.
- **Requisitos:** RF3 · CA2
- **Passos:** teste em `test/form_builders/tailwind_form_builder_test.rb` → métodos privados de
  classes e erros no `Form::Input::BaseComponent` → `Form::Input::SelectComponent` →
  `TailwindFormBuilder#input` escolhe o componente pelo tipo.
- **Verificação:** `bin/rails test test/form_builders` e os testes de campi e login continuam passando.
- **Depende de:** T1 (o teste usa `Building`)

## T4 — Listagem e atalho na área administrativa

- [x] Status
- **Objetivo:** admin vê os blocos ordenados por campus e nome em `/admin/buildings`, com o campus de
  cada bloco, mensagem de lista vazia, título, subtítulo e trilha, e chega lá pelo card "Blocos" de
  `/admin`.
- **Requisitos:** RF1, RF8, RF9, RF10 · CA1, CA5
- **Passos:** testes de integração → `resources :buildings, except: :show` →
  `Admin::BuildingsController#index` e `set_breadcrumbs` → `index`, `_table` e `_building` → ícone
  `:building_office` → card no `_registrations` → textos em `views.pt-BR.yml`.
- **Verificação:** `bin/rails test test/controllers/admin`
- **Depende de:** T1

## T5 — Cadastro e edição

- [x] Status
- **Objetivo:** admin cadastra e edita blocos escolhendo o campus, com mensagem de confirmação; dados
  inválidos voltam com o erro junto ao campo e o campus escolhido.
- **Requisitos:** RF2–RF4, RF6, RF9 · CA1–CA3
- **Passos:** testes de integração → `new`, `create`, `edit`, `update`, `set_campi` e
  `building_params` → `new`, `edit` e `_form` → textos.
- **Verificação:** `bin/rails test test/controllers/admin/buildings_controller_test.rb`
- **Depende de:** T3, T4

## T6 — Exclusão de bloco

- [x] Status
- **Objetivo:** admin exclui um bloco depois de confirmar, com mensagem de confirmação; bloco
  inexistente responde 404.
- **Requisitos:** RF5, RN8 · CA1
- **Passos:** testes de integração → `destroy` e `set_building` → botão Excluir com
  `data-turbo-confirm` no `_building`.
- **Verificação:** `bin/rails test test/controllers/admin/buildings_controller_test.rb`
- **Depende de:** T4

## T7 — Controle de acesso

- [x] Status
- **Objetivo:** visitante vai para o login e usuário comum recebe 403 nas seis ações, sem alterar
  dados e sem ver a trilha da área administrativa.
- **Requisitos:** Regras de acesso · CA6, CA8
- **Passos:** `test/controllers/admin/buildings_controller_access_test.rb` (a proteção vem do
  `Admin::BaseController`).
- **Verificação:** `bin/rails test test/controllers/admin/buildings_controller_access_test.rb`
- **Depende de:** T5, T6

## T8 — Populate

- [x] Status
- **Objetivo:** popular o banco local cria "Bloco B", "Bloco C" e "Bloco R" em Guarapuava e apaga os
  blocos anteriores.
- **Requisitos:** RF11 · CA7
- **Passos:** teste do populator → `reset_records` com `Building` antes de `Campus` →
  `setup_buildings`.
- **Verificação:** `bin/rails test test/lib`
- **Depende de:** T1

## T9 — Testes de sistema

- [x] Status
- **Objetivo:** os fluxos com JavaScript (confirmação, toast, select) e o celular funcionam no
  navegador.
- **Requisitos:** RF1–RF7, RF10 · CA1–CA5
- **Passos:** `manage_buildings_test.rb`, `manage_buildings_on_phone_test.rb` e o caso de campus com
  blocos em `manage_campi_test.rb` → conferência visual em 1400, 390 e 320 px.
- **Verificação:** `bin/rails test test/system/admin`
- **Depende de:** T2, T5, T6

## T10 — Documentação e verificação final

- [x] Status
- **Objetivo:** documentação sincronizada e todos os testes e linters passando.
- **Requisitos:** todos · CA8
- **Passos:** nota na RN7 de `docs/features/campi/spec.md` → status dos documentos →
  `bin/rails test`, `bin/rails test:system`, `bin/rubocop`, `bundle exec erb_lint --lint-all`,
  `bin/brakeman --no-pager`, `bin/ci`.
- **Verificação:** saída dos comandos acima.
- **Depende de:** T1–T9
