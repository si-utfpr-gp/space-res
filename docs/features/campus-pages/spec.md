# Área administrativa organizada por campus — Especificação

Issue: #99 — Área administrativa organizada por campus

Status: aprovada pelo desenvolvedor em 2026-11-27, com as propostas D4 a D8. A Issue e as respostas
das decisões em aberto dela foram aprovadas pelo professor em 2026-11-26.

Referência: os fluxos e os protótipos aprovados na #89, em
[`../admin-area-by-campus/`](../admin-area-by-campus/spec.md) (PR #98).

## Objetivo

Fazer do campus o ponto de partida da área administrativa, como nos protótipos da #89: a entrada
mostra os campi, e os blocos e espaços passam a ser gerenciados dentro da página de cada campus, sem o
campo Campus nos formulários.

## Escopo

- Entrada da área administrativa com um cartão por campus e a seção "Cadastros gerais".
- Página do campus, com menu lateral próprio, seletor de campus e visão geral.
- Espaços dentro do campus: listagem com filtros, cadastro, edição, página do espaço,
  indisponibilidade, desativação e exclusão.
- Blocos dentro do campus: listagem, cadastro, edição e exclusão.
- Campus fixo para blocos e espaços, o que resolve a #92.
- Fim dos endereços soltos de campi, blocos e espaços.

## Atores

- **Visitante:** não autenticado.
- **Usuário comum:** autenticado, sem perfil de administrador.
- **Administrador geral:** autenticado, com o perfil de administrador da #55. Nesta Issue, é o único
  que acessa a área administrativa, e administra todos os campi. O administrador de campus chega com a
  #93.

## Histórias de usuário

- Como administrador, quero escolher o campus na entrada da área administrativa e ver logo quantos
  espaços e blocos ele tem e se algum espaço está indisponível.
- Como administrador, quero cadastrar blocos e espaços dentro da página do campus, sem escolher o
  campus em cada formulário.
- Como administrador, quero ver na visão geral do campus os espaços indisponíveis e o motivo, para
  acompanhar o que precisa de atenção.
- Como administrador, quero filtrar os espaços do campus por nome, bloco e situação, para achar um
  espaço rápido.
- Como administrador, quero trocar de campus pelo menu lateral, sem voltar à entrada.

## Requisitos funcionais

1. **RF1 — Entrada.** `/admin` tem o título "Área administrativa" e o subtítulo "Escolha o campus que
   você quer gerenciar." A seção "Campi" tem o botão "Cadastrar campus" e um cartão por campus, em
   ordem alfabética. Cada cartão mostra o nome do campus, a quantidade de espaços e a de blocos, a
   quantidade de espaços indisponíveis quando houver algum ("1 espaço indisponível") e o botão
   "Gerenciar <campus>", que abre a página do campus. Sem campi, a seção informa "Nenhum campus
   cadastrado." e mantém o botão de cadastro.
2. **RF2 — Cadastros gerais.** Abaixo dos campi, a seção "Cadastros gerais" diz que esses cadastros
   valem para todos os campi e dá acesso a Usuários, Departamentos e Termos de uso. As telas desses
   três cadastros não mudam nesta Issue.
3. **RF3 — Cadastro de campus.** "Cadastrar campus" abre o formulário atual, só com o nome. Ao salvar,
   o administrador volta para a entrada, vê o cartão do novo campus e a mensagem de confirmação.
4. **RF4 — Página do campus.** `/admin/campi/:id` tem o título "Campus <nome>", o subtítulo "Visão
   geral dos cadastros do campus e do que precisa de atenção." e os botões "Editar campus" e "Excluir
   campus". A visão geral mostra:
   - "Cadastros do campus": o resumo de Espaços, com a quantidade e quantos estão disponíveis,
     indisponíveis e desativados (só as situações que têm espaços), e o de Blocos, com a quantidade e
     os nomes em ordem alfabética. Cada resumo tem "Ver todos" e "Cadastrar". Sem registros, o resumo
     informa "Nenhum espaço cadastrado." ou "Nenhum bloco cadastrado."
   - "Espaços indisponíveis": cada espaço indisponível do campus, com o bloco (ou "Sem bloco"), o
     motivo e o link "Ver espaço". Sem nenhum, informa "Nenhum espaço indisponível."
5. **RF5 — Menu lateral do campus.** Nas páginas de um campus, o menu lateral mostra o link de volta
   para "Área administrativa", o campus atual com o seletor de campus, os itens Visão geral, Espaços e
   Blocos, com o item atual destacado, e, separados, Dashboard e Minhas reservas. No celular, o menu
   abre pelo botão do cabeçalho, como hoje. A entrada e os cadastros gerais continuam com o menu
   lateral atual.
6. **RF6 — Seletor de campus.** O seletor ("Trocar de campus") lista os campi em ordem alfabética,
   com o atual marcado. Escolher outro campus abre a mesma seção (Visão geral, Espaços ou Blocos) do
   campus escolhido. A partir de um formulário ou da página de um espaço, abre a listagem da seção.
   Com um único campus cadastrado, o menu mostra o nome dele, sem o seletor.
7. **RF7 — Listagem de espaços.** `/admin/campi/:id/spaces` tem o título "Espaços", o subtítulo
   "Gerencie as salas, os laboratórios e os outros espaços do campus <nome> que podem ser
   reservados." e o botão "Novo espaço". A tabela mostra só os espaços do campus, ordenados pelo bloco
   (os sem bloco por último) e pelo nome, com as colunas Nome (com a situação, quando não está
   disponível), Bloco, Departamento responsável e Aprovação, e as ações Ver, Editar e Excluir. Sem
   espaços no campus, informa "Nenhum espaço cadastrado neste campus."
8. **RF8 — Filtros da listagem de espaços.** Acima da tabela ficam os filtros Nome (busca por parte do
   nome), Bloco ("Todos os blocos", cada bloco do campus e "Sem bloco") e Situação ("Todas as
   situações", "Disponível", "Indisponível" e "Desativado"). Os filtros se combinam. A tabela se
   atualiza ao mudar um filtro, sem tirar o foco do campo, e a quantidade encontrada é anunciada
   ("7 espaços", "1 espaço"). Sem resultado, a página informa "Nenhum espaço encontrado com estes
   filtros." e oferece "Limpar filtros". Os filtros ficam no endereço da página, então recarregar a
   página ou voltar a ela pelo navegador mantém o filtro. Os links para a listagem (trilha, menu e
   depois de salvar) abrem a listagem sem filtros.
9. **RF9 — Cadastro de espaço.** "Novo espaço", ou "Cadastrar" no resumo, abre o formulário sem o
   campo Campus. O formulário mostra "Campus <nome>" como informação, e o campo Bloco lista "Sem
   bloco" e os blocos do campus, com a dica "Só aparecem os blocos deste campus." antes da atual.
   Os outros campos não mudam. Departamentos e termos de uso continuam
   sendo todos os cadastrados até a #90 e a #91. Ao salvar, o administrador volta para a listagem de
   espaços do campus com "Espaço cadastrado com sucesso."
10. **RF10 — Edição, página e situação do espaço.** A edição usa o mesmo formulário, preenchido. A
    página do espaço, a indisponibilidade, a desativação, a reativação e a exclusão funcionam como na
    #61, dentro do campus: botões, cancelamentos e redirecionamentos levam às páginas do campus.
11. **RF11 — Blocos.** `/admin/campi/:id/buildings` tem o título "Blocos", o subtítulo "Gerencie os
    blocos do campus <nome>, que organizam os espaços." e o botão "Novo bloco". A tabela mostra só os
    blocos do campus, em ordem alfabética, com o nome e as ações Editar e Excluir, sem a coluna
    Campus. O cadastro e a edição pedem só o nome. Ao salvar, o administrador volta para a listagem de
    blocos do campus com a mensagem de confirmação. A exclusão pede confirmação ("Excluir o bloco
    <nome>?").
12. **RF12 — Editar e excluir o campus.** "Editar campus" abre o formulário do campus; ao salvar, o
    administrador volta para a página do campus. "Excluir campus" pede confirmação; feita a
    exclusão, o administrador volta para a entrada com a mensagem de confirmação. Se a exclusão for
    recusada, ele continua na página do campus, com a mensagem explicando o motivo (RN9).
13. **RF13 — Hierarquia e navegação.** Toda página tem título, subtítulo e trilha de navegação:
    Dashboard › Área administrativa › <campus> › Espaços ou Blocos › Novo, <espaço>, Editar ou
    Indisponibilidade. O cadastro de campus termina em "Novo campus"; a edição, em <campus> ›
    Editar.
14. **RF14 — Endereços antigos.** A listagem de campi (`/admin/campi`) dá lugar à entrada. Os
    endereços de blocos e espaços fora do campus (`/admin/buildings` e `/admin/spaces`, com os
    endereços abaixo deles) deixam de existir, sem redirecionamento.
15. **RF15 — Celular.** Todas as telas funcionam no celular a partir de 320 px, sem rolagem
    horizontal: cartões, resumos e filtros ficam um abaixo do outro, a tabela de espaços mostra bloco,
    departamento e aprovação abaixo do nome, e os botões continuam fáceis de tocar.

## Regras de negócio

- **RN1 — Campus do endereço.** O campus de um bloco ou de um espaço novo é o do endereço da página
  (`/admin/campi/1/...`). Os formulários não têm o campo Campus, e um campus enviado no formulário é
  ignorado. Trocar o campus no endereço só é aceito se o usuário pode administrar aquele campus. Nesta
  Issue, só o administrador geral, que administra todos (D1).
- **RN2 — Campus fixo.** O campus de um bloco ou de um espaço não muda depois do cadastro. Um envio
  direto com outro campus não muda o campus do bloco, o do espaço nem o dos espaços do bloco. Esta
  regra substitui a RN7 da especificação de blocos (troca de campus livre) e a D4 da #61 (os espaços
  acompanhavam o bloco).
- **RN3 — Correção de campus.** Um bloco cadastrado no campus errado é excluído e cadastrado de novo
  no campus certo (D2). Vale o mesmo para um espaço (D5). Um bloco com espaços continua sem poder ser
  excluído, com a mensagem atual.
- **RN4 — Bloco do espaço.** O bloco de um espaço precisa ser do campus do espaço. Um envio direto
  com um bloco de outro campus é recusado com a mensagem "Selecione um bloco deste campus."
- **RN5 — Isolamento.** As páginas de um campus mostram e alteram só os blocos e os espaços dele. Um
  bloco ou espaço de outro campus não abre pelo endereço de um campus (HTTP 404), em nenhuma ação:
  ver, editar, excluir, indisponibilidade ou desativação.
- **RN6 — Contagens.** A quantidade de espaços conta todas as situações. O aviso do cartão e o quadro
  "Espaços indisponíveis" contam só os indisponíveis.
- **RN7 — Busca por nome.** A busca encontra os espaços cujo nome contém o texto digitado, ignorando
  maiúsculas e minúsculas, acentos, espaços e pontuação, como a comparação de nomes de campi e blocos:
  "laboratorio" encontra "Laboratório de Informática C3", e "b 102" encontra "Sala B102" (D7). Uma
  busca vazia ou só com espaços não filtra.
- **RN8 — Filtros desconhecidos.** Uma situação desconhecida, ou um bloco que não é do campus,
  enviados direto pelo endereço, são ignorados: a listagem se comporta como se fosse "Todas as
  situações" ou "Todos os blocos".
- **RN9 — Exclusão de campus.** Um campus com blocos ou espaços continua sem poder ser excluído. Como
  blocos e espaços não mudam mais de campus, a mensagem deixa de sugerir a mudança: "Não é possível
  excluir o campus porque ele tem blocos cadastrados. Exclua-os antes."
- **RN10 — Cadastros gerais.** Departamentos e termos de uso continuam valendo para todos os campi até
  a #90 e a #91.
- Todo texto de interface é traduzido em português do Brasil.

## Regras de acesso

- Seguem as regras da #55: só o administrador geral acessa a área administrativa, incluindo as
  páginas de campus.
- A permissão é verificada no servidor em todo endereço e ação, inclusive nos envios feitos
  diretamente, sem passar pela tela.
- Um usuário comum recebe HTTP 403 em qualquer endereço da área administrativa, mesmo de um campus que
  não existe, e nenhum dado é alterado.
- Um visitante é direcionado para a autenticação, e nenhum dado é alterado.
- Para o administrador, um campus inexistente no endereço responde HTTP 404, assim como um bloco ou
  espaço inexistente ou de outro campus.

## Critérios de aceitação

| ID | Critério (da Issue) | Requisitos e regras |
| --- | --- | --- |
| CA1 | A entrada mostra um cartão por campus, com o resumo e o botão "Gerenciar", e a seção "Cadastros gerais". | RF1–RF3, RN6 |
| CA2 | A página do campus tem o menu lateral com o seletor de campus e a visão geral com o resumo dos cadastros e os espaços indisponíveis. | RF4–RF6, RF12, RF13, RN6, RN9 |
| CA3 | Blocos e espaços são listados, cadastrados, editados e excluídos dentro da página do campus, sem o campo Campus. | RF7, RF9–RF11, RF14, RN1, RN3, RN5 |
| CA4 | O formulário de espaço lista só os blocos do campus. | RF9, RN4 |
| CA5 | A listagem de espaços filtra por nome, bloco e situação. | RF8, RN7, RN8 |
| CA6 | Um envio direto com outro campus não muda o campus de um bloco nem o de um espaço. | RN1, RN2 |
| CA7 | A movimentação dos espaços junto com o bloco, o aviso no formulário e a mensagem com a contagem deixam de existir. | RN2 |
| CA8 | As telas funcionam em tela grande e no celular a partir de 320 px. | RF15 |
| CA9 | Existem testes automatizados para as telas, as regras e o controle de acesso. | Todos |

## Cenários

### Positivos

- Com Guarapuava (7 espaços, 3 blocos, 1 indisponível) e Pato Branco (sem cadastros), o administrador
  abre a área administrativa e vê os dois cartões, em ordem alfabética, com as quantidades, o aviso "1
  espaço indisponível" só em Guarapuava, e os Cadastros gerais com Usuários, Departamentos e Termos de
  uso.
- O administrador cadastra o campus Toledo e volta para a entrada, com o cartão de Toledo e a mensagem
  de confirmação.
- Em "Gerenciar Guarapuava", ele vê "5 disponíveis, 1 indisponível e 1 desativado", "Bloco B, Bloco
  C e Bloco R" e a Sala B102 em "Espaços indisponíveis", com o motivo "Sala em reforma".
- Na listagem de espaços de Guarapuava, escolhe Pato Branco no seletor e vê a listagem de espaços de
  Pato Branco.
- Cadastra a "Sala B201" no Bloco B sem escolher o campus, e a vê na listagem de Guarapuava com a
  mensagem de confirmação.
- Filtra por "laboratorio" e pela situação "Disponível", vê só os laboratórios disponíveis com a
  quantidade e, ao recarregar a página, o filtro continua.
- Filtra pelo bloco "Sem bloco" e vê só os espaços fora de blocos.
- Cadastra o "Bloco D" informando só o nome. O bloco aparece na listagem de blocos e no formulário de
  espaço de Guarapuava, e não no de Pato Branco.
- Marca um espaço como indisponível; ele entra no quadro "Espaços indisponíveis" da visão geral e sai
  quando volta a ficar disponível.
- Exclui pela página dele um campus sem blocos e sem espaços, e volta para a entrada, já sem o
  cartão.
- Num celular de 320 px, abre o menu, troca de campus, filtra os espaços e cadastra um espaço sem
  rolar para o lado.

### Negativos

- Excluir Guarapuava, que tem blocos, mantém o campus e mostra na página dele "Não é possível excluir
  o campus porque ele tem blocos cadastrados. Exclua-os antes."
- Excluir um bloco com espaços é recusado com a mensagem atual.
- Um envio direto da edição de um bloco de Guarapuava com o campus Pato Branco grava o resto e deixa o
  bloco e os espaços dele em Guarapuava.
- Um envio direto de cadastro de espaço pelo endereço de Guarapuava, com o campus Pato Branco no
  formulário, cria o espaço em Guarapuava.
- Um envio direto de espaço pelo endereço de Guarapuava com um bloco de Pato Branco é recusado com
  "Selecione um bloco deste campus."
- Pelo endereço de Guarapuava, ver, editar, excluir, marcar como indisponível ou desativar um espaço
  ou um bloco de Pato Branco responde HTTP 404 e não altera nada.
- Um usuário comum abre a entrada, a página de um campus ou qualquer tela de blocos e espaços, ou
  envia um formulário direto, e recebe HTTP 403, sem alteração nos dados.
- Um visitante é direcionado para a autenticação, sem alteração nos dados.
- `/admin/campi`, `/admin/buildings` e `/admin/spaces` respondem como página não encontrada.

### Limite

- Sem campi, a entrada mostra "Nenhum campus cadastrado." e o botão "Cadastrar campus".
- Num campus sem blocos e sem espaços, o cartão mostra zero nas duas quantidades, sem aviso de
  indisponíveis, e a visão geral mostra "Nenhum espaço cadastrado.", "Nenhum bloco cadastrado." e
  "Nenhum espaço indisponível."
- Com um único campus, o menu mostra o nome dele, sem o seletor.
- Num campus sem blocos, o campo Bloco do formulário e o filtro de bloco só oferecem "Sem bloco"
  (além de "Todos os blocos", no filtro).
- Filtros sem resultado mostram "Nenhum espaço encontrado com estes filtros." e "Limpar filtros".
- Uma busca só com espaços ou só com pontuação não filtra.
- Uma situação desconhecida, ou um bloco de outro campus, no endereço da listagem é ignorado.
- Um campus inexistente no endereço responde HTTP 404 ao administrador e HTTP 403 ao usuário comum.
- Singular e plural: "1 espaço", "2 espaços", "1 espaço indisponível", "2 espaços indisponíveis".
- Um nome de campus longo quebra a linha no cartão, no título e no menu, sem rolagem lateral.

## Decisões

D1 a D3 vieram da Issue e foram respondidas pelo professor em 2026-11-26. D4 a D8 foram propostas
desta especificação, aprovadas pelo desenvolvedor em 2026-11-27.

| # | Pergunta | Decisão |
| --- | --- | --- |
| D1 | Um envio direto com outro campus é recusado ou ignorado? | O campus vem do endereço. Outro campus no endereço só é aceito se o usuário pode administrar aquele campus. O campus enviado no formulário é ignorado. |
| D2 | Como corrigir um bloco cadastrado no campus errado? | Excluir o bloco e cadastrá-lo de novo no campus certo. |
| D3 | Os endereços antigos de blocos e espaços deixam de existir? | Sim, sem redirecionamento. |
| D4 | Para onde leva o seletor de campus? | Proposta: para a mesma seção do campus escolhido, como diz a nota dos protótipos ("abre a mesma página, para o campus Pato Branco"). |
| D5 | O campus de um espaço também fica fixo? | Proposta: sim, como o do bloco. Para corrigir, o espaço é excluído e cadastrado de novo. |
| D6 | Depois de cadastrar um campus, para onde vai o administrador? | Proposta: para a entrada, onde vê o cartão do novo campus (fluxo G1 da #89). |
| D7 | A busca por nome ignora acentos? | Proposta: sim, com a mesma comparação dos nomes de campi e blocos. |
| D8 | O endereço do campus fica no singular, como no exemplo do professor (`/admin/campus/1`)? | Proposta: manter `/admin/campi/1`, no plural como os outros endereços e como na #89. |

## Checklist de usabilidade

- [x] A pessoa entende o que fazer sem ajuda: a entrada pede para escolher o campus, e cada resumo da
  visão geral tem "Ver todos" e "Cadastrar".
- [x] A informação aparece no momento certo: o formulário de espaço mostra o campus e diz que só
  aparecem os blocos dele; a visão geral mostra os espaços indisponíveis com o motivo.
- [x] Os erros são evitados e as restrições explicadas: o campus vem do endereço e não pode ser
  escolhido errado; a exclusão recusada de um campus ou de um bloco explica o motivo e o que fazer.
- [x] Sem passos desnecessários: os formulários de bloco e de espaço perderam o campo Campus e o
  filtro de blocos; o seletor troca de campus sem voltar à entrada.
- [x] Consistente com o resto do sistema: mesmo cabeçalho, trilha, botões, mensagens e tabela que
  vira lista no celular.

## Fora do escopo

- Departamentos e termos de uso por campus (#90 e #91), com os resumos deles na visão geral, os itens
  no menu e a contagem no cartão.
- Administradores de campus (#93): o quadro "Administradores do campus", o aviso "Sem
  administradores", o item Administradores no menu, "Definir administradores" e a entrada direta de
  quem administra um só campus.
- Mudanças na tela de usuários.
- Mover blocos ou espaços entre campi.
- Paginação das listagens.
- Fluxo de liberação das reservas.
- Mudanças no banco de dados.
