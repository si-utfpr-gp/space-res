# Cadastro de termos de uso — Tarefas

Issue: #60 · [spec.md](spec.md) · [plan.md](plan.md)

Legenda: `[ ]` pendente · `[~]` em andamento · `[x]` concluída

## T1 — Modelo `UsageTerm` e tabela `usage_terms`

- [x] Status
- **Objetivo:** termos têm título obrigatório, normalizado e único sem diferenciar maiúsculas, e texto
  obrigatório, com mensagens próprias.
- **Requisitos:** RN1–RN7 · CA2, CA3, CA7
- **Passos:** testes de modelo (normalização, validações, restrições do banco, `ordered_by_title`) →
  migration `CreateUsageTerms` → `app/models/usage_term.rb` → factory `:usage_term` → modelo, atributos
  e erros em `models.pt-BR.yml` e `errors.pt-BR.yml`. Revisado em 2026-11-03: `uniqueness: {
  case_sensitive: false }` no lugar do `NormalizedUniquenessValidator` e índice único em `LOWER(title)`.
- **Verificação:** `bin/rails test test/models/usage_term`, `db:migrate:down` e `db:migrate` de novo, e
  diff do `db/schema.rb` só com `action_text_rich_texts` e `usage_terms`.
- **Depende de:** —

## T2 — Texto com Action Text

- [x] Status
- **Objetivo:** o texto do termo é escrito no editor do Action Text e exibido com a formatação,
  sanitizado. Substitui a tarefa de cadastros simultâneos, retirada por decisão do professor em
  2026-11-03.
- **Requisitos:** RF2, RF3, RF9, RN4, RN5 · CA2, CA4
- **Passos:** `bin/rails action_text:install` (fixture gerado removido) → `has_rich_text :content` e
  `content` fora de `usage_terms` → `type: :rich_textarea` em `Form::Input::BaseComponent` → `_form` e
  `show` → `actiontext.css` em `@layer components`, com listas, títulos, links e espaço entre blocos →
  populate e factory em HTML → testes de modelo, integração e sistema com o editor.
- **Verificação:** `bin/rails test test/models/usage_term test/controllers/admin test/lib` e
  `bin/rails test:system test/system/admin/usage_terms`
- **Depende de:** T1

## T3 — Listagem e atalho na área administrativa

- [x] Status
- **Objetivo:** admin vê os termos em ordem alfabética em `/admin/usage_terms`, com título, subtítulo,
  trilha e lista vazia, e chega lá pelo card de `/admin`.
- **Requisitos:** RF1, RF7, RF8 · CA1
- **Passos:** testes de integração → `resources :usage_terms` → `Admin::UsageTermsController#index` e
  `set_breadcrumbs` → `index`, `_table` e `_usage_term` (título com link e botões Ver, Editar e Excluir)
  → ícone `:eye` e `fill="currentColor"` no `:file_with_lines` → card em `_registrations` → textos em
  `views.pt-BR.yml`, inclusive `actions.show`. Na verificação em 320 px, a tabela ficou com 343 px:
  com três botões, palavras longas do título ("responsabilidade") não cabiam. As células passaram a
  `px-3` no celular, e os botões quebram de linha (`flex-wrap`), ficando empilhados ao lado do título.
- **Verificação:** `bin/rails test test/controllers/admin`
- **Depende de:** T1

## T4 — Página do termo

- [x] Status
- **Objetivo:** admin lê o termo com a formatação do editor, sem scripts, e tem as ações de editar e
  excluir; id inexistente responde 404.
- **Requisitos:** RF3, RF8 · CA1, CA4
- **Passos:** testes de integração (lista e negrito, sem `<script>`, `onclick` nem `javascript:`, trilha
  com o título, 404) → `show` e `set_usage_term` → `show.html.erb` com o rich text e `break-words` →
  textos.
- **Verificação:** `bin/rails test test/controllers/admin/usage_terms_controller_test.rb`
- **Depende de:** T3

## T5 — Cadastro e edição

- [x] Status
- **Objetivo:** admin cadastra e edita termos e vai para a página do termo; dados inválidos voltam ao
  formulário com os valores digitados, o erro e 422.
- **Requisitos:** RF2, RF4, RF6, RF8, RN7 · CA1–CA3
- **Passos:** testes de integração (redirect para a página do termo, 422 para título vazio, texto vazio
  e título repetido, trilha com `title_in_database` após erro) → `new`, `create`, `edit`, `update` →
  `_form` com o editor do Action Text, `new` e `edit` → textos e placeholders.
- **Verificação:** `bin/rails test test/controllers/admin/usage_terms_controller_test.rb`
- **Depende de:** T4

## T6 — Exclusão

- [x] Status
- **Objetivo:** admin exclui um termo pela listagem ou pela página do termo, depois de confirmar, e
  volta para a listagem com a mensagem.
- **Requisitos:** RF5, RN9 · CA1
- **Passos:** testes de integração → `destroy` → botão Excluir com `data-turbo-confirm` na listagem e na
  página do termo → textos.
- **Verificação:** `bin/rails test test/controllers/admin/usage_terms_controller_test.rb`
- **Depende de:** T4

## T7 — Controle de acesso

- [x] Status
- **Objetivo:** visitante vai para o login e usuário comum recebe 403 nas sete ações, sem alterar dados e
  sem ver a trilha.
- **Requisitos:** Regras de acesso · CA5
- **Passos:** `test/controllers/admin/usage_terms_controller_access_test.rb`, conferido contra falha.
- **Verificação:** `bin/rails test test/controllers/admin/usage_terms_controller_access_test.rb`
- **Depende de:** T5, T6

## T8 — Populate

- [x] Status
- **Objetivo:** o populate apaga os termos e cria o termo de exemplo do laboratório de informática.
- **Requisitos:** RF10 · CA6
- **Passos:** teste do populator → constantes do termo, `reset_records` e `setup_usage_terms`.
- **Verificação:** `bin/rails test test/lib`
- **Depende de:** T1

## T9 — Testes de sistema

- [x] Status
- **Objetivo:** comprovar no navegador o fluxo completo, com o editor, confirmação e toast, e a listagem,
  a página do termo e o formulário em 320 px com título e endereço longos.
- **Requisitos:** RF1–RF6, RF9 · CA1, CA3, CA4
- **Passos:** `manage_usage_terms_test.rb` e `manage_usage_terms_on_phone_test.rb`.
- **Verificação:** `bin/rails test:system test/system/admin/usage_terms`
- **Depende de:** T5, T6

## T10 — Verificação final

- [x] Status
- **Objetivo:** evidência de todos os critérios e nenhuma regressão.
- **Requisitos:** CA1–CA7 · Definition of Done
- **Passos:** suíte completa, system tests, RuboCop, ERB Lint, Brakeman, `bin/ci`, screenshots em 1400 e
  320 px, revisão do diff, evidências nesta página.
- **Verificação:** comandos da seção "Comandos de verificação" do plano.
- **Depende de:** T1–T9

## Evidências (2026-11-04)

Depois do rebase na `main` e do retorno do professor (unicidade padrão do Rails e Action Text).

| CA | Evidência |
| --- | --- |
| CA1 | `test/controllers/admin/usage_terms_controller_test.rb` (listagem em ordem, lista vazia, só o título com Ver e Editar, título, subtítulo e trilha nas quatro páginas, formulário com o editor, cadastro e edição indo para a página do termo, exclusão com confirmação e toast, 404 na página e na edição); `usage_term_ordered_by_title_test.rb`; `home_controller_test.rb` (atalho); `test/system/admin/usage_terms/manage_usage_terms_test.rb` (cadastro digitando no editor e usando Bold, edição trocando o texto por uma lista, exclusão pela página do termo e pela listagem, confirmação aceita e recusada); `manage_usage_terms_on_phone_test.rb` (320 px com título e endereço longos, botões com 44 px, formulário e cadastro pelo celular sem rolagem horizontal) |
| CA2 | `usage_term_validations_test.rb` (título vazio ou só com espaços, texto sem conteúdo `<div><br></div>`, mensagens próprias); controller test (422 com a mensagem junto ao campo e o outro valor digitado mantido, inclusive o texto no campo oculto do editor) |
| CA3 | `usage_term_validations_test.rb` (shoulda `case_insensitive`, título repetido em outra caixa, renomear para outro termo, o próprio termo pode trocar a caixa); `usage_term_normalize_test.rb`; `usage_term_constraints_test.rb` (índice em `LOWER(title)`); controller test (repetido no cadastro e na edição, com 422); system test (erro com "termo do laboratório") |
| CA4 | `usage_term_rich_text_test.rb` (lista e negrito preservados depois de gravar); controller test (lista e negrito na página do termo; `<script>`, `onclick` e `javascript:` removidos; HTML do título escapado); system test (negrito e lista no navegador) |
| CA5 | `test/controllers/admin/usage_terms_controller_access_test.rb`: visitante vai para `/login` e usuário comum recebe 403 nas sete ações, sem alterar dados, antes de buscar o termo, sem ver a trilha nem o texto |
| CA6 | `test/lib/tasks/db/populate/populator_test.rb`: o populate apaga os termos existentes e cria o do laboratório de informática, com a lista de quatro regras |
| CA7 | todos os anteriores |

| Comando | Resultado |
| --- | --- |
| `bin/rails test` | 215 runs, 1189 assertions, 0 failures, 0 errors |
| `bin/rails test:system` | 34 runs, 135 assertions, 0 failures, 0 errors |
| `bin/rubocop` | 141 files inspected, no offenses detected |
| `bundle exec erb_lint --lint-all` | No errors were found in ERB files |
| `bundle exec brakeman --no-pager --exit-on-warn` | 0 security warnings |
| `bin/importmap audit` | No vulnerable packages found |
| `bin/ci` | todas as etapas passaram |

### Observações

- **Teste de acesso conferido contra falha (2026-11-02):** com `skip_before_action
  :require_admin_area_access` adicionado temporariamente ao controller, 3 dos 4 testes falharam. O
  controller foi restaurado.
- **Teste de celular conferido contra falha (2026-11-02):** a primeira versão media só a página e não viu
  a tabela com 343 px; passou a medir a tabela, falhou, e voltou a passar com `px-3` e `flex-wrap`
  (veja T3).
- **Barra do editor no celular:** fazer a barra do Trix quebrar de linha em telas estreitas impediu o
  clique em Salvar no system test de 320 px (falha repetida em três execuções). A mudança foi desfeita,
  e a barra rola para o lado dentro dela mesma, sem rolar a página.
- **Migrations:** `db:rollback STEP=2` devolveu o `db/schema.rb` ao estado da `main`, e `db:migrate`
  gerou o mesmo arquivo de antes. O diff do `schema.rb` contém só `action_text_rich_texts`,
  `usage_terms` (sem `content`, com o índice em `LOWER(title)`) e a versão.
- **Telas:** conferidas por screenshot em 1280 e 320 px (formulário com erro no texto, página do termo
  com a lista e edição no celular). A primeira rodada usou um `tailwind.css` antigo, sem `min-h-64`;
  depois de `tailwindcss:build`, ficou certa.
- **Revisão independente:** nada bloqueante. Aplicadas: negrito nos títulos do texto, links no tamanho
  do texto, HTML do populate sem indentação e estas evidências. Conferido pelo revisor: validação e
  índice usam o mesmo `LOWER()` do SQLite, migrations reversíveis, sanitização na página do termo e
  nenhum N+1 na listagem. Um texto só com espaço de largura zero passa na validação; não foi tratado.
- `bin/rails db:populate` não foi rodado no banco de desenvolvimento. O teste do populator cobre o CA6.
