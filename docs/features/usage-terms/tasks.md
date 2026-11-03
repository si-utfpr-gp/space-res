# Cadastro de termos de uso — Tarefas

Issue: #60 · [spec.md](spec.md) · [plan.md](plan.md)

Legenda: `[ ]` pendente · `[~]` em andamento · `[x]` concluída

## T1 — Modelo `UsageTerm` e tabela `usage_terms`

- [x] Status
- **Objetivo:** termos têm título obrigatório, normalizado e único pela comparação de campi, e texto
  obrigatório gravado com as quebras de linha, com mensagens próprias.
- **Requisitos:** RN1–RN7 · CA2, CA3, CA7
- **Passos:** testes de modelo (normalização, validações, restrições do banco, `ordered_by_title`) →
  migration `CreateUsageTerms` → `app/models/usage_term.rb` → factory `:usage_term` → modelo, atributos
  e erros em `models.pt-BR.yml` e `errors.pt-BR.yml`.
- **Verificação:** `bin/rails test test/models/usage_term`, `db:rollback` e `db:migrate` de novo, e diff do
  `db/schema.rb` só com `usage_terms`.
- **Depende de:** —

## T2 — Título repetido em cadastros simultâneos

- [x] Status
- **Objetivo:** um título exato gravado por outra requisição entre a validação e o `INSERT` vira erro
  de validação, e não HTTP 500.
- **Requisitos:** RN3, RF6 · CA3 · plano, "Race condition no título"
- **Passos:** `usage_term_concurrent_save_test.rb` com o validador desligado por Mocha, conferido contra
  falha (levanta `RecordNotUnique` sem a correção) → `UsageTerm#save` com `rescue
  ActiveRecord::RecordNotUnique`.
- **Verificação:** `bin/rails test test/models/usage_term`
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
- **Objetivo:** admin lê o termo com os parágrafos e as quebras de linha digitados, com o HTML exibido
  como texto, e tem as ações de editar e excluir; id inexistente responde 404.
- **Requisitos:** RF3, RF8 · CA1, CA4
- **Passos:** testes de integração (`<p>` por parágrafo, `<br>` nas quebras simples, `&lt;script&gt;`,
  trilha com o título, 404) → `show` e `set_usage_term` → `show.html.erb` com
  `simple_format(h(...))` e `break-words` → textos.
- **Verificação:** `bin/rails test test/controllers/admin/usage_terms_controller_test.rb`
- **Depende de:** T3

## T5 — Cadastro e edição

- [x] Status
- **Objetivo:** admin cadastra e edita termos e vai para a página do termo; dados inválidos voltam ao
  formulário com os valores digitados, o erro e 422.
- **Requisitos:** RF2, RF4, RF6, RF8, RN7 · CA1–CA3
- **Passos:** testes de integração (redirect para a página do termo, 422 para título vazio, texto vazio
  e título repetido, trilha com `title_in_database` após erro) → `new`, `create`, `edit`, `update` →
  `_form` com `textarea`, `new` e `edit` → textos e placeholders.
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
- **Objetivo:** comprovar no navegador o fluxo completo, com confirmação e toast, e a listagem e a página
  do termo em 320 px com título e endereço longos.
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

## Evidências (2026-11-02)

| CA | Evidência |
| --- | --- |
| CA1 | `test/controllers/admin/usage_terms_controller_test.rb` (listagem em ordem, lista vazia, só o título com Ver e Editar, título, subtítulo e trilha nas quatro páginas, cadastro e edição indo para a página do termo, exclusão com confirmação e toast, 404 na página e na edição); `usage_term_ordered_by_title_test.rb`; `home_controller_test.rb` (atalho); `test/system/admin/usage_terms/manage_usage_terms_test.rb` (fluxo pela página do termo e pela listagem, confirmação aceita e recusada); `manage_usage_terms_on_phone_test.rb` (320 px com título e endereço longos, botões com 44 px, cadastro pelo celular) |
| CA2 | `usage_term_validations_test.rb` (título vazio ou só com espaços, texto vazio ou só com espaços e quebras, mensagens próprias); controller test (422 com a mensagem junto ao campo e o outro valor digitado mantido) |
| CA3 | `usage_term_validations_test.rb` (shoulda `case_insensitive`, maiúsculas acentuadas, sem acento, sem espaços, com pontuação, renomear para outro termo; o próprio termo pode trocar maiúsculas e acentos); `usage_term_normalize_test.rb`; `usage_term_concurrent_save_test.rb` (título gravado por outra requisição vira erro no cadastro e na edição, outras violações continuam levantando exceção); controller test (repetido no cadastro, na edição e na corrida, com 422); system test (erro com "termo do laboratorio") |
| CA4 | controller test (`<p>` por parágrafo, `<br>` na quebra simples, HTML do texto e do título exibido como texto); `usage_term_normalize_test.rb` (`\r\n` → `\n`, pontas removidas, meio preservado); system test (três parágrafos e `<br>` no navegador) |
| CA5 | `test/controllers/admin/usage_terms_controller_access_test.rb`: visitante vai para `/login` e usuário comum recebe 403 nas sete ações, sem alterar dados, antes de buscar o termo, sem ver a trilha nem o texto |
| CA6 | `test/lib/tasks/db/populate/populator_test.rb`: o populate apaga os termos existentes e cria o do laboratório de informática, com três parágrafos |
| CA7 | todos os anteriores, mais `usage_term_constraints_test.rb` |

| Comando | Resultado |
| --- | --- |
| `bin/rails test` | 224 runs, 1207 assertions, 0 failures, 0 errors |
| `bin/rails test:system` | 34 runs, 132 assertions, 0 failures, 0 errors |
| `bin/rubocop` | 140 files inspected, no offenses detected |
| `bundle exec erb_lint --lint-all` | No errors were found in ERB files |
| `bundle exec brakeman --no-pager --exit-on-warn` | 0 security warnings |
| `bin/ci` | todas as etapas passaram |

### Observações

- **Teste de acesso conferido contra falha:** com `skip_before_action :require_admin_area_access`
  adicionado temporariamente ao controller, 3 dos 4 testes falharam. O controller foi restaurado.
- **Teste de corrida conferido contra falha:** sem o `rescue` em `UsageTerm#save`, os dois casos
  levantaram `ActiveRecord::RecordNotUnique`.
- **Teste de celular conferido contra falha:** a primeira versão media só a página e não viu a tabela com
  343 px; passou a medir a tabela, falhou, e voltou a passar com `px-3` e `flex-wrap` (veja T3).
- **Migration:** `db:rollback` devolveu o `db/schema.rb` ao estado do `main`, e `db:migrate` reaplicou a
  tabela. O diff do `schema.rb` contém só `usage_terms` e a versão.
- **Telas:** conferidas por screenshot em 1400 e 320 px (`/admin`, listagem, página do termo e edição com
  erro). A primeira rodada mostrou os botões da página do termo esticados, porque o CSS do Tailwind não
  tinha sido recompilado com as classes novas; depois de `tailwindcss:build`, ficaram certos.
- **Revisão independente:** nada bloqueante. Aplicadas: `rescue` só do índice do título, título digitado
  mantido após edição recusada, estado do registro após a corrida, mensagem de erro junto ao campo e XSS
  no título. Mantida, como risco aceito, a ordenação binária do SQLite (plano, "Riscos e trade-offs").
- `bin/rails db:populate` não foi rodado no banco de desenvolvimento. O teste do populator cobre o CA6.

