# Cadastro de departamentos — Especificação

Issue: #58 — Cadastro de departamentos

Status: aprovada em 2026-10-27.

## Objetivo

Permitir que administradores mantenham, na área administrativa, a lista de departamentos. Um
departamento é a unidade responsável por espaços: nas Issues de espaços e de usuários, os usuários de um
departamento passam a poder liberar as reservas dos espaços desse departamento.

## Escopo

- Um departamento é identificado somente pelo nome.
- Administradores listam, cadastram, editam e excluem departamentos em `/admin/departments`.
- A página inicial da área administrativa oferece acesso ao cadastro de departamentos.
- Popular o banco de desenvolvimento local cria departamentos de exemplo do campus Guarapuava.

## Atores

- **Visitante:** não autenticado.
- **Usuário comum:** autenticado, sem perfil de administrador.
- **Administrador:** autenticado, com perfil de administrador.

## Histórias de usuário

- Como administrador, quero cadastrar os departamentos para depois indicar qual deles responde por cada
  espaço.
- Como administrador, quero corrigir o nome de um departamento cadastrado com erro.
- Como administrador, quero excluir um departamento cadastrado por engano.
- Como administrador, quero ser avisado quando tento cadastrar um departamento que já existe.

## Requisitos funcionais

1. **RF1 — Listagem.** `/admin/departments` mostra todos os departamentos em ordem alfabética de nome.
   Cada departamento tem as ações de editar e excluir, e a página tem uma ação para cadastrar um novo
   departamento. Sem departamentos cadastrados, a página informa que não há departamentos.
2. **RF2 — Cadastro.** Um formulário com o campo Nome cria o departamento. Com dados válidos, o
   administrador volta para a listagem e vê uma mensagem de confirmação.
3. **RF3 — Edição.** O mesmo formulário, preenchido com o nome atual, altera o departamento. Com dados
   válidos, o administrador volta para a listagem e vê uma mensagem de confirmação.
4. **RF4 — Exclusão.** A exclusão pede confirmação antes de acontecer. Confirmada, o departamento é
   removido e o administrador volta para a listagem com uma mensagem de confirmação.
5. **RF5 — Dados inválidos.** Com dados inválidos, nada é gravado. O formulário volta com o valor
   digitado e a mensagem de erro junto ao campo.
6. **RF6 — Atalho na área administrativa.** A página inicial de `/admin` exibe um atalho para o
   cadastro de departamentos, ao lado dos atalhos de campi e de blocos.
7. **RF7 — Hierarquia e navegação.** A listagem, o cadastro e a edição mostram título, subtítulo e a
   trilha de navegação, como as páginas de campi: Dashboard › Área administrativa › Departamentos, mais
   Novo ou Editar.
8. **RF8 — Celular.** As páginas do cadastro funcionam no celular desde 320 px de largura: a listagem
   cabe na tela sem rolagem horizontal, mesmo com nomes longos, que quebram em mais de uma linha, e as
   ações de editar e excluir continuam fáceis de tocar. O formulário ocupa toda a largura disponível.
9. **RF9 — Departamentos locais.** Popular o banco de desenvolvimento local cria 25 departamentos,
   coordenações, diretorias e setores do campus Guarapuava, além do que já cria hoje: os 21 levantados
   na PR #51 (por exemplo, "Departamento Acadêmico de Engenharia", "Coordenação do Curso de Tecnologia
   em Sistemas para a Internet" e "Biblioteca") e, acrescentados em 2026-10-27, "Secretaria de Gestão
   Acadêmica", "Departamento Acadêmico de Exatas", "Departamento de Relações Interinstitucionais" e
   "Departamento de Apoio e Projetos Tecnológicos". Os nomes vão por extenso, sem sigla.

## Regras de negócio

- **RN1 — Nome obrigatório.** Um nome vazio, ou só com espaços, é recusado com a mensagem
  "Informe o nome do departamento."
- **RN2 — Espaços normalizados.** Antes de validar e gravar, os espaços das pontas são removidos e
  espaços repetidos viram um só: `"  Departamento   de Educação "` é gravado como
  `"Departamento de Educação"`.
- **RN3 — Nome único.** Não podem existir dois departamentos com o mesmo nome. A comparação segue a
  regra de campi e de blocos: ignora maiúsculas e minúsculas, acentos, cedilha, espaços e pontuação.
  `"Departamento de Educação"`, `"DEPARTAMENTO DE EDUCAÇÃO"`, `"Departamento de Educacao"` e
  `"Departamento-de-Educação."` são o mesmo nome. O nome repetido é recusado com a mensagem "Já existe
  um departamento cadastrado com este nome." Esta regra é mais rígida que o texto da Issue, que cita só
  maiúsculas e minúsculas, e repete a decisão mantida pelo professor para blocos em 2026-10-23.
- **RN4 — Grafia preservada.** O nome é gravado com as maiúsculas, os acentos e a pontuação digitados,
  com os espaços normalizados (RN2).
- **RN5 — Edição.** A edição segue as mesmas regras. Um departamento não conflita com ele mesmo: salvar
  sem alterar o nome, ou só trocando maiúsculas, acentos, espaços ou pontuação, é válido.
- **RN6 — Exclusão livre.** Nesta Issue, qualquer departamento pode ser excluído. O bloqueio da
  exclusão de departamentos com usuários ou espaços entra nas Issues que criam esses vínculos (#59 e
  #61).
- Todo texto de interface é traduzido em português do Brasil.

## Regras de acesso

- Seguem as regras da #55: somente administradores acessam o cadastro.
- A permissão é verificada no servidor em todo endereço e ação do cadastro, inclusive nos envios de
  formulário e na exclusão feitos diretamente, sem passar pela tela.
- Um usuário comum recebe HTTP 403 em qualquer endereço ou ação do cadastro, e nenhum dado é alterado.
- Um visitante é direcionado para a página de autenticação, e nenhum dado é alterado.
- Um endereço de departamento inexistente responde como página não encontrada (HTTP 404).
- A página de acesso negado não mostra a trilha da área administrativa.

## Critérios de aceitação

| ID | Critério (da Issue) | Requisitos e regras |
| --- | --- | --- |
| CA1 | Administradores conseguem listar, cadastrar, editar e excluir departamentos. | RF1–RF8 |
| CA2 | O cadastro sem nome é recusado com mensagem de erro. | RF5, RN1 |
| CA3 | O cadastro de um nome já existente é recusado, mesmo com maiúsculas e minúsculas diferentes. | RF5, RN2–RN5 |
| CA4 | Usuários comuns recebem HTTP 403 e usuários não autenticados são direcionados para a autenticação. | Regras de acesso |
| CA5 | O `populate` cria departamentos de exemplo no ambiente local. | RF9 |
| CA6 | Existem testes automatizados para as validações e o controle de acesso. | Todos |

## Cenários

### Positivos

- Um administrador abre a área administrativa, segue o atalho de departamentos e vê a listagem em
  ordem alfabética.
- Um administrador cadastra "Departamento de Educação", volta para a listagem, vê o departamento na
  lista e uma mensagem de confirmação.
- Um administrador edita "Departamento de Educação" para "Departamento de Extensão" e vê o novo nome na
  listagem, com mensagem de confirmação.
- Um administrador exclui um departamento, confirma, e o departamento some da listagem, com mensagem
  de confirmação.
- Depois de popular o banco local, a listagem mostra os 25 departamentos de Guarapuava.
- Na edição, a trilha mostra "Dashboard › Área administrativa › Departamentos › Editar"; tocar em
  "Departamentos" volta para a listagem.
- Num celular de 320 px, o administrador vê a listagem sem rolar para o lado, mesmo com "Núcleo de
  Acompanhamento Psicopedagógico e Assistência Estudantil", toca em "Novo departamento", cadastra e vê
  a mensagem de confirmação.

### Negativos

- Cadastrar com o nome vazio mostra o formulário de novo, com erro no campo Nome, e nada é gravado.
- Com "Departamento de Educação" cadastrado, cadastrar "departamento de educação",
  "DEPARTAMENTO DE EDUCAÇÃO", "Departamento de Educacao" ou "Departamento-de-Educação." é recusado com
  erro de nome já em uso.
- Editar um departamento para o nome de outro departamento existente é recusado com erro de nome já em
  uso.
- Um usuário comum abre `/admin/departments`, o formulário de cadastro ou o de edição e recebe HTTP 403.
- Um usuário comum envia um cadastro, uma edição ou uma exclusão diretamente e recebe HTTP 403, sem
  alteração nos dados.
- Um visitante abre ou envia qualquer endereço do cadastro e é direcionado para a autenticação, sem
  alteração nos dados.
- Desistir na confirmação de exclusão mantém o departamento.
- Um usuário comum que recebe 403 não vê a trilha da área administrativa.

### Limite

- Um nome só com espaços é tratado como vazio e recusado.
- Com "Biblioteca" cadastrado, cadastrar `"  biblioteca "` é recusado (normalizado e comparado sem
  diferenciar maiúsculas).
- Corrigir o mesmo departamento de "Departamento de Educacao" para "Departamento de Educação" é aceito.
- Sem nenhum departamento cadastrado, a listagem mostra a mensagem de lista vazia.
- Um administrador abre a edição de um departamento que não existe e recebe HTTP 404.

## Fora do escopo

- Vincular usuários a departamentos (#59, "Gestão de usuários pelo admin").
- Vincular espaços a departamentos (#61, "Cadastro de espaços").
- Bloqueio da exclusão de departamentos com usuários ou espaços (#59 e #61).
- Fluxo de liberação de reservas.
- Outros dados do departamento além do nome (sigla, campus, e-mail, responsável).
- Criar departamentos fora do ambiente local de desenvolvimento (por exemplo, dados iniciais de
  produção).
- Busca, filtros e paginação na listagem.
- Página de detalhes de um departamento.
