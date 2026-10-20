# Cadastro de campi — Especificação

Issue: #56 — Cadastro de campi

Status: aprovada em 2026-10-19 (RN4, RN6 e mensagens de erro revisadas no mesmo dia). RF9 e RF10
acrescentados em 2026-10-20, a partir do feedback do professor sobre o layout.

## Objetivo

Permitir que administradores mantenham, na área administrativa, a lista de campi da UTFPR. Os campi
são a base dos cadastros de blocos e de espaços, entregues por Issues posteriores.

## Escopo

- Um campus é identificado somente pelo nome.
- Administradores listam, cadastram, editam e excluem campi em `/admin/campi`.
- A página inicial da área administrativa oferece acesso ao cadastro de campi.
- Depois de cadastrar, editar ou excluir, o administrador vê uma mensagem de confirmação. Para isso,
  a área logada passa a exibir mensagens de confirmação e de aviso.
- Popular o banco de desenvolvimento local cria o campus Guarapuava.

## Atores

- **Visitante:** não autenticado.
- **Usuário comum:** autenticado, sem perfil de administrador.
- **Administrador:** autenticado, com perfil de administrador.

## Histórias de usuário

- Como administrador, quero cadastrar os campi da UTFPR para depois organizar blocos e espaços por
  campus.
- Como administrador, quero corrigir o nome de um campus cadastrado com erro.
- Como administrador, quero excluir um campus cadastrado por engano.
- Como administrador, quero ser avisado quando tento cadastrar um campus que já existe.

## Requisitos funcionais

1. **RF1 — Listagem.** `/admin/campi` mostra todos os campi em ordem alfabética de nome. Cada campus
   tem as ações de editar e excluir, e a página tem uma ação para cadastrar um novo campus. Sem
   campi cadastrados, a página informa que não há campi.
2. **RF2 — Cadastro.** Um formulário com o campo Nome cria o campus. Com dados válidos, o
   administrador volta para a listagem e vê uma mensagem de confirmação.
3. **RF3 — Edição.** O mesmo formulário, preenchido com o nome atual, altera o campus. Com dados
   válidos, o administrador volta para a listagem e vê uma mensagem de confirmação.
4. **RF4 — Exclusão.** A exclusão pede confirmação antes de acontecer. Confirmada, o campus é
   removido e o administrador volta para a listagem com uma mensagem de confirmação.
5. **RF5 — Dados inválidos.** Com dados inválidos, nada é gravado. O formulário volta com o valor
   digitado e a mensagem de erro junto ao campo.
6. **RF6 — Atalho na área administrativa.** A página inicial de `/admin` exibe um atalho para o
   cadastro de campi.
7. **RF7 — Mensagens na área logada.** As páginas da área logada exibem as mensagens de confirmação e
   de aviso geradas pelas ações do usuário.
8. **RF8 — Campus local.** Popular o banco de desenvolvimento local cria o campus Guarapuava, além dos
   usuários que já cria hoje.
9. **RF9 — Hierarquia e navegação.** A listagem, o cadastro, a edição e a página inicial da área
   administrativa mostram um título, um subtítulo que explica a página e uma trilha de navegação
   (breadcrumbs) que começa no Dashboard e termina na página atual. Os itens anteriores da trilha são
   links; a página atual não é. A trilha substitui o botão Voltar da listagem.
10. **RF10 — Celular.** As páginas do cadastro funcionam no celular desde 320 px de largura: a
    listagem cabe na tela sem rolagem horizontal e as ações de editar e excluir continuam fáceis de
    tocar. O formulário ocupa toda a largura disponível, em qualquer tela.

## Regras de negócio

- **RN1 — Nome obrigatório.** Um nome vazio, ou só com espaços, é recusado com a mensagem
  "Informe o nome do campus."
- **RN2 — Espaços normalizados.** Antes de validar e gravar, os espaços das pontas são removidos e
  espaços repetidos viram um só: `"  Pato   Branco "` é gravado como `"Pato Branco"`.
- **RN3 — Nome único.** Não podem existir dois campi com o mesmo nome, sem diferenciar maiúsculas e
  minúsculas, inclusive em letras acentuadas: `"Campo Mourão"` e `"CAMPO MOURÃO"` são o mesmo nome.
  O nome repetido é recusado com a mensagem "Já existe um campus cadastrado com este nome."
- **RN4 — Só letras e números contam.** A comparação da RN3 também ignora acentos, cedilha, espaços e
  pontuação: `"Campo Mourao"`, `"campomourao"` e `"Campo-Mourão"` são o mesmo nome que
  `"Campo Mourão"`. Esta regra é mais rígida que o texto da Issue, que cita só maiúsculas e
  minúsculas.
- **RN5 — Grafia preservada.** O nome é gravado com as maiúsculas, os acentos e a pontuação
  digitados, com os espaços normalizados (RN2). A comparação da RN3 e da RN4 não muda o nome gravado.
- **RN6 — Edição.** A edição segue as mesmas regras. Um campus não conflita com ele mesmo: salvar sem
  alterar o nome, ou só trocando maiúsculas, minúsculas, acentos, espaços ou pontuação, é válido. Por
  exemplo, corrigir `"Campo Mourao"` para `"Campo Mourão"` no mesmo campus.
- **RN7 — Exclusão livre.** Nesta Issue, qualquer campus pode ser excluído. O bloqueio de exclusão de
  campi com blocos ou espaços entra nas Issues de blocos e de espaços.
- Todo texto de interface é traduzido em português do Brasil.

## Regras de acesso

- Seguem as regras da #55: somente administradores acessam o cadastro.
- A permissão é verificada no servidor em todo endereço e ação do cadastro, inclusive nos envios de
  formulário e na exclusão feitos diretamente, sem passar pela tela.
- Um usuário comum recebe HTTP 403 em qualquer endereço ou ação do cadastro, e nenhum dado é
  alterado.
- Um visitante é direcionado para a página de autenticação, e nenhum dado é alterado.
- Um endereço de campus inexistente responde como página não encontrada (HTTP 404).
- A página de acesso negado não mostra a trilha da área administrativa.

## Critérios de aceitação

| ID | Critério (da Issue) | Requisitos e regras |
| --- | --- | --- |
| CA1 | Administradores conseguem listar, cadastrar, editar e excluir campi. | RF1–RF4, RF6, RF7 |
| CA2 | O cadastro sem nome é recusado com mensagem de erro. | RF5, RN1 |
| CA3 | O cadastro de um nome já existente é recusado, mesmo com maiúsculas e minúsculas diferentes. | RF5, RN2–RN4, RN6 |
| CA4 | Usuários comuns recebem HTTP 403 em todas as rotas do cadastro. | Regras de acesso |
| CA5 | Usuários não autenticados são direcionados para a autenticação. | Regras de acesso |
| CA6 | O `populate` cria o campus Guarapuava no ambiente local. | RF8 |
| CA7 | Existem testes automatizados para as validações e o controle de acesso. | Todos |

## Cenários

### Positivos

- Um administrador abre a área administrativa, segue o atalho de campi e vê a listagem em ordem
  alfabética.
- Um administrador cadastra "Pato Branco", volta para a listagem, vê "Pato Branco" na lista e uma
  mensagem de confirmação.
- Um administrador edita "Pato Branco" para "Ponta Grossa" e vê o novo nome na listagem, com
  mensagem de confirmação.
- Um administrador exclui um campus, confirma, e o campus some da listagem, com mensagem de
  confirmação.
- Depois de popular o banco local, a listagem mostra "Guarapuava".
- Na edição, a trilha mostra "Dashboard › Área administrativa › Campi › Editar"; tocar em "Campi" volta
  para a listagem.
- Num celular de 320 px, o administrador vê a listagem inteira sem rolar para o lado, toca em "Novo
  campus", cadastra e vê a mensagem de confirmação.

### Negativos

- Cadastrar com o nome vazio mostra o formulário de novo, com erro no campo Nome, e nada é gravado.
- Com "Guarapuava" cadastrado, cadastrar "guarapuava" é recusado com erro de nome já em uso.
- Com "Campo Mourão" cadastrado, cadastrar "CAMPO MOURÃO" é recusado com erro de nome já em uso.
- Com "Campo Mourão" cadastrado, cadastrar "Campo Mourao" é recusado com erro de nome já em uso.
- Com "Campo Mourão" cadastrado, cadastrar "campomourao" ou "Campo-Mourão." é recusado com erro de
  nome já em uso.
- Editar um campus para o nome de outro campus existente é recusado com erro de nome já em uso.
- Um usuário comum abre `/admin/campi`, o formulário de cadastro ou o de edição e recebe HTTP 403.
- Um usuário comum envia um cadastro, uma edição ou uma exclusão diretamente e recebe HTTP 403, sem
  alteração nos dados.
- Um visitante abre ou envia qualquer endereço do cadastro e é direcionado para a autenticação, sem
  alteração nos dados.
- Desistir na confirmação de exclusão mantém o campus.
- Um usuário comum que recebe 403 não vê a trilha da área administrativa.

### Limite

- Um nome só com espaços é tratado como vazio e recusado.
- Com "Pato Branco" cadastrado, cadastrar `"  pato   branco "` é recusado (normalizado e comparado sem
  diferenciar maiúsculas).
- Salvar a edição de "guarapuava" como "Guarapuava" é aceito.
- Corrigir o mesmo campus de "Campo Mourao" para "Campo Mourão" é aceito.
- Sem nenhum campus cadastrado, a listagem mostra a mensagem de lista vazia.
- Um administrador abre a edição de um campus que não existe e recebe HTTP 404.
- No Dashboard, que é a raiz, a trilha não aparece.

## Fora do escopo

- Cadastro de blocos e de espaços (Issues #57 e #61).
- Outros dados do campus além do nome (cidade, sigla, endereço).
- Bloqueio da exclusão de campi com blocos ou espaços (Issues de blocos e de espaços).
- Criar campi fora do ambiente local de desenvolvimento (por exemplo, dados iniciais de produção).
- Busca, filtros e paginação na listagem.
- Página de detalhes de um campus.
