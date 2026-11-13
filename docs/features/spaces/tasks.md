# Cadastro de espaços — Tarefas

Issue: #61 · [spec.md](spec.md) · [plan.md](plan.md)

Legenda: `[ ]` pendente · `[~]` em andamento · `[x]` concluída

## T1 — Modelo `Space` e tabela `spaces`

- [x] Status
- **Objetivo:** espaços têm campus obrigatório, bloco opcional do mesmo campus, nome obrigatório e
  único no bloco (ou no campus, sem bloco), departamento e termo opcionais, aprovação e situação, com
  mensagens próprias.
- **Requisitos:** RN1–RN8, RN12 · CA2–CA5
- **Passos:** testes de modelo (associações, normalização, validações, restrições do banco, ordenação)
  → migration `CreateSpaces` → `app/models/space.rb` → factory `:space` → modelo, atributos e erros em
  `models.pt-BR.yml` e `errors.pt-BR.yml`.
- **Verificação:** `bin/rails test test/models/space`, `db:migrate:down` e `db:migrate` de novo, e diff
  do `db/schema.rb` só com `spaces`.
- **Depende de:** —

## T2 — Exclusões recusadas nos cadastros vizinhos

- [x] Status
- **Objetivo:** campus, bloco, departamento e termo de uso com espaços não são excluídos, e a mensagem
  diz o motivo e o próximo passo.
- **Requisitos:** RF9, RN10 · CA6
- **Passos:** testes de modelo e de integração → `has_many :spaces, dependent: :restrict_with_error`
  nos quatro modelos → `destroy` de blocos, departamentos e termos no formato de campi → mensagens em
  `errors.pt-BR.yml`.
- **Verificação:** `bin/rails test test/models test/controllers/admin`
- **Depende de:** T1

## T3 — Campo de marcação no form builder

- [x] Status
- **Objetivo:** o form builder tem a caixa de seleção com rótulo ligado, dica, erro, foco visível e
  área de toque de 44 px.
- **Requisitos:** RF6 · CA1
- **Passos:** testes em `tailwind_form_builder_test.rb` → `Form::Input::CheckBoxComponent` → método no
  `TailwindFormBuilder`.
- **Verificação:** `bin/rails test test/form_builders`
- **Depende de:** —

## T4 — Listagem, página do espaço e atalho

- [x] Status
- **Objetivo:** o administrador chega aos espaços pelo atalho de `/admin`, vê a listagem ordenada com
  localização, departamento, aprovação e situação, e abre a página do espaço com todos os dados.
- **Requisitos:** T2 (tarefa de uso), RF1, RF2, RF5, RF10, RF11 · CA1, CA7, CA8
- **Passos:** testes de integração (listagem, página, acesso, atalho) → rotas → `index` e `show` do
  controller → views `index`, `_table`, `_space`, `show` → helper da frase de liberação → ícone e item
  no atalho → textos.
- **Verificação:** `bin/rails test test/controllers/admin`
- **Depende de:** T1

## T5 — Cadastro, edição e exclusão

- [x] Status
- **Objetivo:** o administrador cadastra, corrige e exclui espaços, com erros junto aos campos e
  confirmação na exclusão.
- **Requisitos:** T1, T3, T4 (tarefas de uso), RF3, RF4 (sem JavaScript), RF7, RF8, RN9 · CA1–CA5, CA8
- **Passos:** testes de integração → `new`, `create`, `edit`, `update`, `destroy` → `_form`, `new`,
  `edit`, `_destroy_button` → textos.
- **Verificação:** `bin/rails test test/controllers/admin/spaces_controller_test.rb
  test/controllers/admin/spaces_controller_access_test.rb`
- **Depende de:** T3, T4

## T6 — Escolha do bloco filtrada pelo campus

- [x] Status
- **Objetivo:** ao escolher o campus, o campo Bloco mostra só os blocos daquele campus; trocar o campus
  limpa um bloco de outro campus.
- **Requisitos:** RF4, D1 · CA3
- **Passos:** teste de sistema → `ui/filtered_select_controller.js` → `data-` no `_form`.
- **Verificação:** `bin/rails test:system test/system/admin/spaces`
- **Depende de:** T5

## T7 — Situação do espaço: indisponibilidade e desativação

- [x] Status
- **Objetivo:** pela página do espaço, o administrador marca o espaço como indisponível com o motivo,
  altera o motivo e o torna disponível de novo; desativa um espaço que deixou de existir, com
  confirmação, e o reativa. Refeita em 2026-11-17: a primeira versão tinha só ativo e inativo, e o
  professor pediu para separar a indisponibilidade temporária da desativação definitiva (D2).
- **Requisitos:** T6 e T7 (tarefas de uso), RF1, RF2, RF14, RF16, RN12–RN14, D8–D10 · CA11, CA8
- **Passos:** testes de modelo (enum, validações do motivo, mudanças de situação, restrições do banco)
  → `status` e `unavailability_reason` na migration `CreateSpaces` → enum, validações e métodos em
  `Space` → testes de integração (página do espaço, formulário do motivo, desativação, acesso) →
  rotas aninhadas → `Admin::Spaces::{Base,Unavailabilities,Deactivations}Controller` → ações e
  motivo na página do espaço, selo na listagem, formulário do motivo → textos.
- **Verificação:** `bin/rails test test/models/space test/controllers/admin` e
  `bin/rails test:system test/system/admin/spaces`
- **Depende de:** T4

## T8 — Troca de campus de um bloco com espaços

- [x] Status
- **Objetivo:** ao trocar o campus de um bloco, os espaços dele passam para o novo campus, com aviso
  antes e confirmação depois.
- **Requisitos:** RF15, RN11 · CA12
- **Passos:** testes de modelo e de integração → callback em `Building` → aviso no `_form` de blocos →
  mensagem em `Admin::BuildingsController#update` → textos.
- **Verificação:** `bin/rails test test/models/building test/controllers/admin/buildings_controller_test.rb`
- **Depende de:** T1

## T9 — Espaços de exemplo no populate

- [x] Status
- **Objetivo:** o banco local ganha espaços com e sem bloco, um indisponível e um desativado.
- **Requisitos:** RF13 · CA9
- **Passos:** teste do populator → `setup_spaces` e `Space` em `reset_records`.
- **Verificação:** `bin/rails test test/lib` e `bin/rails db:populate` duas vezes.
- **Depende de:** T1

## T10 — Testes de sistema, inclusive no celular

- [x] Status
- **Objetivo:** os fluxos das tarefas de uso funcionam no navegador, em tela grande e em 320 px.
- **Requisitos:** RF12 · CA1, CA7, CA11
- **Passos:** `manage_spaces_test.rb` e `manage_spaces_on_phone_test.rb`.
- **Verificação:** `bin/rails test:system test/system/admin/spaces test/system/admin/buildings`
- **Depende de:** T5–T8

## T11 — Verificação final

- [x] Status
- **Objetivo:** todos os critérios de aceitação têm evidência, e a verificação de uso da especificação
  está registrada.
- **Passos:** suíte completa, lint, Brakeman, verificação de uso (T1–T7 da especificação, em 1400, 390
  e 320 px), revisão independente.
- **Verificação:** os comandos do plano.
- **Depende de:** T1–T10

## Registro de verificação

### Comandos executados em 2026-11-12

- `bin/rails db:migrate`, `db:migrate:down VERSION=20261112133836` e `db:migrate` de novo: o diff do
  `db/schema.rb` tem só a tabela `spaces`, os seus índices e as suas quatro chaves estrangeiras.
- `bin/rails test`: 370 testes, 0 falhas.
- `bin/rails test:system`: 52 testes, 0 falhas (13 deles em `test/system/admin/spaces`).
- `bin/rubocop`: 170 arquivos, sem ofensas. `bundle exec erb_lint --lint-all`: sem erros.
  `bundle exec brakeman --no-pager`: 0 alertas.
- `bin/rails db:populate` não foi rodado no banco local, para não apagar os dados de desenvolvimento. O
  populate é coberto por `test/lib/tasks/db/populate/populator_test.rb`, inclusive rodando duas vezes.

### Comandos executados em 2026-11-17 (situação do espaço)

- Migration `CreateSpaces` alterada no lugar. Num banco temporário: `db:migrate`,
  `db:migrate:down VERSION=20261112133836` e `db:migrate` de novo. O diff do `db/schema.rb` tem só a
  troca de `active` por `status` e `unavailability_reason` e as duas restrições `CHECK`. No banco
  de desenvolvimento local, que tinha a tabela antiga e nenhum espaço,
  `bin/rails db:migrate:redo VERSION=20261112133836` recriou a tabela sem mudar o `schema.rb`.
- `bin/rails test`: 411 testes, 0 falhas.
- `bin/rails test:system`: 56 testes, 0 falhas.
- `bin/rubocop`: 176 arquivos, sem ofensas. `bundle exec erb_lint --lint-all`: sem erros.
  `bundle exec brakeman --no-pager`: 0 alertas.
- `bin/ci` não foi rodado inteiro, porque o Brakeman com `--ensure-latest` falha sem rede. Os passos
  dele foram rodados separados, como acima. Nenhuma gem mudou, então `bundler-audit` e
  `importmap audit` não foram rodados.

### Critérios de aceitação

| CA | Evidência |
| --- | --- |
| CA1 | `spaces_controller_test.rb` (listagem, página, cadastro, edição, exclusão) e `manage_spaces_test.rb` |
| CA2 | "creates a space in a building…" e "creates a space without building…"; sistema: "admin registers a space without building" |
| CA3 | Modelo e integração: "rejects a building of another campus"; sistema: "offers only the buildings of the chosen campus" |
| CA4 | `space_validations_test.rb`, `space_constraints_test.rb` e "rejects a name already taken in the building and accepts it in another building" |
| CA5 | `space_validations_test.rb`, `space_constraints_test.rb` e "rejects a name already taken among the spaces without building of the campus" |
| CA6 | Testes de associação e de integração de campi, blocos, departamentos e termos de uso; sistema: "explains why a building with spaces cannot be deleted" |
| CA7 | "shows the location, the department and the approval of each space" e `manage_spaces_on_phone_test.rb` |
| CA8 | `spaces_controller_access_test.rb`, nas catorze ações (nove até 2026-11-12) |
| CA9 | `populator_test.rb` (com um espaço indisponível e um desativado desde 2026-11-17) |
| CA10 | Os arquivos acima |
| CA11 | Revisto em 2026-11-17. Modelo: `space_status_test.rb` e `space_constraints_test.rb`. Integração: as ações de cada situação na página do espaço, "marks unavailable and deactivated spaces in the list, in text", "ignores a forged status or reason…", "keeps the status and the reason of a space when it is edited", `unavailabilities_controller_test.rb` e `deactivations_controller_test.rb`. Sistema: "admin marks a space as unavailable, changes the reason and makes it available again", "admin cancels marking a space as unavailable", "admin deactivates a space after confirming and reactivates it", "keeps the status when the deactivation is not confirmed" e, no celular, "admin marks a space as unavailable on a phone…" |
| CA12 | `building_campus_change_test.rb`, integração de blocos e sistema: "moves the spaces of a building along when its campus changes" |

### Verificação de uso

Feita nas telas renderizadas pelo navegador dos testes de sistema, com os dados do populate, em 1400,
390 e 320 px (listagem, página do espaço ativo e inativo, formulário, formulário com erro e edição de
bloco). Em 2026-11-17, refeita para T6 e T7 em 1280 e 320 px: listagem com os selos, página do espaço
disponível e indisponível e formulário do motivo.

| Tarefa | Entende sem orientação? | Informação no momento certo? | Previne erros e explica? | Etapas desnecessárias? | Consistente? |
| --- | --- | --- | --- | --- | --- |
| T1 Cadastrar | Campos na ordem da tarefa, com exemplos e dicas | A regra de quem libera aparece junto à caixa de aprovação | Bloco filtrado pelo campus; erro junto ao campo; valores mantidos | Só campus e nome são obrigatórios | Mesmo formulário e botões dos outros cadastros |
| T2 Encontrar e conferir | Listagem por campus, bloco e nome; o nome leva à página | Localização, departamento, aprovação e estado na listagem; descrição e termo na página | — | Um toque da listagem à página | Mesma tabela e ações dos termos de uso |
| T3 Corrigir | Editar na listagem e na página | Formulário preenchido | Mesmas validações; trilha com o nome gravado | — | Igual aos outros cadastros |
| T4 Remover | Excluir na listagem e na página | A confirmação diz que não há como desfazer | Confirmação cita o nome e oferece a desativação | — | Mesmo botão e confirmação |
| T5 Exclusão recusada | A mensagem diz o motivo | Aparece logo após a tentativa | Diz o próximo passo | — | Mesmo aviso nos quatro cadastros |
| T6 Indisponível por um tempo | "Marcar como indisponível" na página do espaço; o formulário tem um campo só, com exemplo | O formulário diz que o motivo aparece para quem reserva; a página mostra a situação, o que ela significa e o motivo, com "Alterar motivo" ao lado | Motivo obrigatório, com erro junto ao campo; o limite de 100 caracteres é aplicado na digitação | Um formulário de um campo; "Tornar disponível" é um toque | Mesmo formulário, trilha e botões dos cadastros |
| T7 Desativar | "Desativar" na página do espaço | Selo "Desativado" na listagem; a página diz que o espaço não aparece na reserva | Confirmação explica o efeito e aponta "Marcar como indisponível" para o caso temporário; "Reativar" desfaz | Confirmação só na desativação, que é a mudança de maior efeito | Mesmo padrão de botões e confirmações |

Acessibilidade conferida: uso só pelo teclado no formulário (teste de sistema), rótulos ligados aos
campos, foco visível na caixa de seleção, situação ("Indisponível", "Desativado") em texto e não só em
cor, áreas de toque de 44 px (inclusive "Alterar motivo") e ausência de rolagem horizontal em 320 px.

Não feito: medição de contraste com ferramenta, teste com leitor de tela e teste com pessoas do
público-alvo, recomendado pelo professor.

### Observação

`bin/rails test test/controllers/users test/system/users`, com testes de integração e de sistema da
reserva no mesmo processo, falha de forma intermitente também sem as mudanças desta Issue. Rodados
separados, como no CI, passam.

### Revisão independente

O `reviewer` não achou bloqueio em integridade dos dados, acesso, regressões, views, JavaScript ou
cobertura dos critérios. Confirmou a migration reversível, os dois índices de acordo com as duas
validações, o 403 antes da busca do espaço e `active` fora dos parâmetros. Não conferiu o token CSRF de
desativar e reativar num navegador real (a proteção fica desligada nos testes); conferiu pelo código.

Ajustes feitos a partir dela:

- `requires_approval` em branco, enviado direto, dava HTTP 500 (`NOT NULL` do banco). Agora é erro de
  validação, com 422 e mensagem no campo; testes de modelo e de integração.
- Em `UsageTerm`, `has_many :spaces` vem antes de `has_rich_text`: a exclusão recusada para antes de
  tocar no texto do termo. Um teste confirma que o texto continua lá.
- Ao trocar o campus do bloco, os espaços movidos têm o `updated_at` atualizado.
- O texto de "Cadastros simultâneos" no plano foi corrigido: o SQLite atende as escritas uma por vez.

Revisão independente de 2026-11-17, da situação do espaço: confirmou o acesso (403 antes da busca do
espaço nas sete rotas novas), o token CSRF e os verbos, o motivo fora de `space_params`, as restrições
`CHECK` de acordo com o modelo, o `update_all` da troca de campus sem conflito com elas e a ausência de
restos de `active`. Ajustes feitos a partir dela:

- "Marcar como indisponível" e "Alterar motivo" funcionavam a partir de qualquer situação: uma aba
  antiga trazia de volta um espaço desativado ou desfazia o "Tornar disponível" de outro
  administrador. Agora cada mudança só vale a partir das situações certas (RF14), e as outras voltam
  para a página do espaço com o aviso "Nada foi alterado: o espaço está …". Testes de modelo e de
  integração.
- As ações que não mudavam nada mostravam a mensagem de sucesso, por exemplo "Espaço disponível de
  novo" para um espaço desativado. Agora mostram o mesmo aviso.
- A verificação da situação e a gravação podiam se intercalar entre duas requisições. Agora as duas
  ficam na mesma transação, com `with_lock`. Um teste com uma cópia do espaço carregada antes da
  mudança confirma.

Os ajustes foram verificados pelos testes acima; a revisão não foi repetida sobre eles.

Mantido, para decisão do desenvolvedor e do professor:

- Nomes que diferem só em maiúscula acentuada ("Auditório" e "AUDITÓRIO") são aceitos como
  diferentes, porque o `LOWER()` do SQLite só converte letras sem acento. É a consequência da decisão
  D5 (padrão do Rails, como nos termos de uso). Campi, blocos e departamentos usam a regra mais rígida.
  Em 2026-11-13, o professor decidiu manter o padrão do Rails, porque o banco vai migrar para
  PostgreSQL.
- Um campus com blocos e espaços sem bloco, ou um departamento com usuários e espaços, mostra um motivo
  por vez na exclusão recusada.
