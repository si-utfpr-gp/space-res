# Cadastro de blocos — Especificação

Issue: #57 — Cadastro de blocos

Status: aprovada em 2026-10-22.

## Objetivo

Permitir que administradores mantenham, na área administrativa, os blocos de cada campus. Os blocos
organizam os espaços, entregues por uma Issue posterior.

## Escopo

- Um bloco tem um nome e pertence a um campus.
- Administradores listam, cadastram, editam e excluem blocos em `/admin/buildings`.
- A página inicial da área administrativa oferece acesso ao cadastro de blocos.
- Um campus com blocos não pode ser excluído.
- Popular o banco de desenvolvimento local cria blocos de exemplo no campus Guarapuava.

## Atores

- **Visitante:** não autenticado.
- **Usuário comum:** autenticado, sem perfil de administrador.
- **Administrador:** autenticado, com perfil de administrador.

## Histórias de usuário

- Como administrador, quero cadastrar os blocos de cada campus para depois organizar os espaços por
  bloco.
- Como administrador, quero corrigir o nome ou o campus de um bloco cadastrado com erro.
- Como administrador, quero excluir um bloco cadastrado por engano.
- Como administrador, quero ser impedido de excluir um campus que ainda tem blocos, para não deixar
  blocos sem campus.

## Requisitos funcionais

1. **RF1 — Listagem.** `/admin/buildings` mostra todos os blocos, ordenados pelo nome do campus e
   depois pelo nome do bloco. Cada bloco mostra o nome e o campus, com as ações de editar e excluir. A
   página tem uma ação para cadastrar um novo bloco. Sem blocos cadastrados, a página informa que não
   há blocos.
2. **RF2 — Cadastro.** Um formulário com os campos Campus e Nome cria o bloco. Com dados válidos, o
   administrador volta para a listagem e vê uma mensagem de confirmação.
3. **RF3 — Escolha do campus.** O campo Campus é uma lista de seleção com todos os campi em ordem
   alfabética. Ela começa sem campus escolhido, com a opção "Selecione o campus", mesmo quando só
   existe um campus. O campo tem o mesmo visual dos outros campos do formulário: rótulo, mensagem de
   erro junto ao campo e área de toque confortável no celular.
4. **RF4 — Edição.** O mesmo formulário, preenchido com o campus e o nome atuais, altera o bloco. O
   administrador pode trocar o nome e o campus. Com dados válidos, volta para a listagem e vê uma
   mensagem de confirmação.
5. **RF5 — Exclusão.** A exclusão pede confirmação antes de acontecer. Confirmada, o bloco é removido e
   o administrador volta para a listagem com uma mensagem de confirmação.
6. **RF6 — Dados inválidos.** Com dados inválidos, nada é gravado. O formulário volta com os valores
   escolhidos e digitados e a mensagem de erro junto ao campo.
7. **RF7 — Campus com blocos.** Tentar excluir um campus que tem blocos não exclui nada. O
   administrador volta para a listagem de campi com uma mensagem de erro que explica o motivo.
8. **RF8 — Atalho na área administrativa.** A página inicial de `/admin` exibe um atalho para o
   cadastro de blocos, ao lado do atalho de campi.
9. **RF9 — Hierarquia e navegação.** A listagem, o cadastro e a edição mostram título, subtítulo e a
   trilha de navegação, como as páginas de campi: Dashboard › Área administrativa › Blocos, mais Novo
   ou Editar.
10. **RF10 — Celular.** As páginas do cadastro funcionam no celular desde 320 px de largura: a listagem
    cabe na tela sem rolagem horizontal, mostrando o nome e o campus de cada bloco, e as ações de
    editar e excluir continuam fáceis de tocar. O formulário ocupa toda a largura disponível.
11. **RF11 — Blocos locais.** Popular o banco de desenvolvimento local cria os blocos "Bloco B",
    "Bloco C" e "Bloco R" no campus Guarapuava, além do que já cria hoje. O campus não tem Bloco A.

## Regras de negócio

- **RN1 — Campus obrigatório.** Todo bloco pertence a um campus. Sem campus escolhido, ou com um campus
  que não existe, o bloco é recusado com a mensagem "Selecione o campus."
- **RN2 — Nome obrigatório.** Um nome vazio, ou só com espaços, é recusado com a mensagem "Informe o
  nome do bloco."
- **RN3 — Espaços normalizados.** Antes de validar e gravar, os espaços das pontas são removidos e
  espaços repetidos viram um só: `"  Bloco   A "` é gravado como `"Bloco A"`.
- **RN4 — Nome único no campus.** Não podem existir dois blocos com o mesmo nome no mesmo campus. A
  comparação segue a regra de campi: ignora maiúsculas e minúsculas, acentos, cedilha, espaços e
  pontuação. No mesmo campus, `"Bloco A"`, `"bloco a"`, `"BlocoA"` e `"Bloco-A"` são o mesmo nome. O
  nome repetido é recusado com a mensagem "Já existe um bloco com este nome neste campus." Esta regra é
  mais rígida que o texto da Issue, que cita só maiúsculas e minúsculas (decisão de 2026-10-22).
- **RN5 — Mesmo nome em campi diferentes.** Campi diferentes podem ter blocos com o mesmo nome:
  "Bloco A" de Guarapuava e "Bloco A" de Pato Branco coexistem.
- **RN6 — Grafia preservada.** O nome é gravado com as maiúsculas, os acentos e a pontuação digitados,
  com os espaços normalizados (RN3).
- **RN7 — Edição.** A edição segue as mesmas regras. Um bloco não conflita com ele mesmo: salvar sem
  alterar o nome, ou só trocando maiúsculas, acentos, espaços ou pontuação, é válido. Trocar o campus
  de um bloco é recusado se o campus de destino já tem um bloco com o mesmo nome.
- **RN8 — Exclusão de bloco livre.** Nesta Issue, qualquer bloco pode ser excluído. O bloqueio da
  exclusão de blocos com espaços entra na Issue de espaços.
- **RN9 — Exclusão de campus com blocos.** Um campus com pelo menos um bloco não pode ser excluído. A
  tentativa é recusada com a mensagem "Não é possível excluir o campus porque ele tem blocos
  cadastrados." Um campus sem blocos continua podendo ser excluído. Esta regra substitui a RN7 da
  especificação de campi ("Exclusão livre").
- Todo texto de interface é traduzido em português do Brasil.

## Regras de acesso

- Seguem as regras da #55: somente administradores acessam o cadastro.
- A permissão é verificada no servidor em todo endereço e ação do cadastro, inclusive nos envios de
  formulário e na exclusão feitos diretamente, sem passar pela tela.
- Um usuário comum recebe HTTP 403 em qualquer endereço ou ação do cadastro, e nenhum dado é
  alterado.
- Um visitante é direcionado para a página de autenticação, e nenhum dado é alterado.
- Um endereço de bloco inexistente responde como página não encontrada (HTTP 404).
- A página de acesso negado não mostra a trilha da área administrativa.

## Critérios de aceitação

| ID | Critério (da Issue) | Requisitos e regras |
| --- | --- | --- |
| CA1 | Administradores conseguem listar, cadastrar, editar e excluir blocos. | RF1–RF6, RF8–RF10 |
| CA2 | O cadastro exige nome e campus. | RF3, RF6, RN1–RN3 |
| CA3 | Um bloco com o mesmo nome de outro no mesmo campus é recusado; o mesmo nome em campi diferentes é aceito. | RF6, RN4–RN7 |
| CA4 | A exclusão de um campus com blocos é recusada com mensagem explicando o motivo. | RF7, RN9 |
| CA5 | A listagem mostra o campus de cada bloco. | RF1, RF10 |
| CA6 | Usuários comuns recebem HTTP 403 e usuários não autenticados são direcionados para a autenticação. | Regras de acesso |
| CA7 | O `populate` cria blocos de exemplo no campus Guarapuava. | RF11 |
| CA8 | Existem testes automatizados para as validações, a regra de exclusão e o controle de acesso. | Todos |

## Cenários

### Positivos

- Um administrador abre a área administrativa, segue o atalho de blocos e vê a listagem ordenada por
  campus e nome, com o campus de cada bloco.
- Um administrador cadastra "Bloco D" no campus Guarapuava, volta para a listagem, vê "Bloco D" com o
  campus Guarapuava e uma mensagem de confirmação.
- Com "Bloco A" em Guarapuava, um administrador cadastra "Bloco A" em Pato Branco, e os dois aparecem
  na listagem.
- Um administrador edita "Bloco D" para "Bloco E" e vê o novo nome na listagem, com mensagem de
  confirmação.
- Um administrador troca o campus de um bloco de Guarapuava para Pato Branco e vê o novo campus na
  listagem.
- Um administrador exclui um bloco, confirma, e o bloco some da listagem, com mensagem de confirmação.
- Um administrador exclui um campus sem blocos, como antes.
- Depois de popular o banco local, a listagem mostra "Bloco B", "Bloco C" e "Bloco R" no campus
  Guarapuava.
- Num celular de 320 px, o administrador vê a listagem sem rolar para o lado, toca em "Novo bloco",
  escolhe o campus, cadastra e vê a mensagem de confirmação.

### Negativos

- Cadastrar sem escolher o campus mostra o formulário de novo, com erro no campo Campus, e nada é
  gravado.
- Cadastrar com o nome vazio mostra o formulário de novo, com erro no campo Nome, o campus escolhido
  continua selecionado, e nada é gravado.
- Com "Bloco A" em Guarapuava, cadastrar "bloco a", "BlocoA" ou "Bloco-A." em Guarapuava é recusado
  com erro de nome já em uso.
- Editar um bloco para o nome de outro bloco do mesmo campus é recusado com erro de nome já em uso.
- Com "Bloco A" em Guarapuava e em Pato Branco, trocar o campus do "Bloco A" de Pato Branco para
  Guarapuava é recusado com erro de nome já em uso.
- Com blocos em Guarapuava, excluir o campus Guarapuava mantém o campus e os blocos e mostra a
  mensagem "Não é possível excluir o campus porque ele tem blocos cadastrados."
- Um usuário comum abre `/admin/buildings`, o formulário de cadastro ou o de edição e recebe HTTP 403.
- Um usuário comum envia um cadastro, uma edição ou uma exclusão diretamente e recebe HTTP 403, sem
  alteração nos dados.
- Um visitante abre ou envia qualquer endereço do cadastro e é direcionado para a autenticação, sem
  alteração nos dados.
- Desistir na confirmação de exclusão mantém o bloco.

### Limite

- Um nome só com espaços é tratado como vazio e recusado.
- Com "Bloco A" em Guarapuava, cadastrar `"  bloco   a "` em Guarapuava é recusado (normalizado e
  comparado pela RN4).
- Salvar a edição de "bloco a" como "Bloco A" no mesmo bloco é aceito.
- Um envio direto com o identificador de um campus que não existe é recusado com "Selecione o
  campus."
- Sem nenhum campus cadastrado, o formulário mostra a lista de seleção só com "Selecione o campus", e
  o envio é recusado com "Selecione o campus."
- Sem nenhum bloco cadastrado, a listagem mostra a mensagem de lista vazia.
- Um administrador abre a edição de um bloco que não existe e recebe HTTP 404.
- Excluir o último bloco de um campus libera a exclusão do campus.

## Fora do escopo

- Cadastro de espaços (Issue #61) e bloqueio da exclusão de blocos com espaços.
- Outros dados do bloco além do nome e do campus.
- Busca, filtros (por exemplo, por campus) e paginação na listagem.
- Página de detalhes de um bloco.
- Listar ou cadastrar blocos a partir da página de um campus.
- Criar blocos fora do ambiente local de desenvolvimento (por exemplo, dados iniciais de produção).
