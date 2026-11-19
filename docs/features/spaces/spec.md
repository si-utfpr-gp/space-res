# Cadastro de espaços — Especificação

Issue: #61 — Cadastro de espaços

Status: aprovada pelo desenvolvedor em 2026-11-12, com as decisões D1 a D7 (seção "Decisões"). Em
2026-11-13, o professor confirmou D1, D3, D4 e D5 e, na D2, pediu que se separassem duas situações: a
indisponibilidade temporária e a desativação definitiva. A revisão de 2026-11-17 (T6, T7, RF14, RF16,
RN12–RN14 e as decisões D8 a D10) aguarda a aprovação do desenvolvedor. Na revisão da PR #88, também
em 2026-11-17, o professor pediu a descrição obrigatória (RN15, D11) e mandou os outros pontos para
Issues próprias (ver "Fora do escopo").

## Objetivo

Permitir que administradores mantenham, na área administrativa, os espaços reserváveis do campus: salas,
laboratórios, auditórios e espaços fora de blocos, como a quadra e o planetário. O espaço cadastrado é o
que depois aparece para reserva (Issue #63) e pode ser dividido em partes (Issue #62).

## Escopo

- Um espaço tem nome, campus, bloco (opcional), descrição, departamento responsável
  (opcional), termo de uso (opcional), a indicação de que a reserva precisa de aprovação e uma
  situação: disponível, indisponível (com o motivo) ou desativado.
- Administradores encontram, cadastram, conferem, corrigem, marcam como indisponíveis, desativam,
  devolvem ao uso e excluem espaços em `/admin/spaces`.
- A página inicial da área administrativa oferece acesso ao cadastro de espaços.
- Campi, blocos, departamentos e termos de uso com espaços vinculados não podem ser excluídos.
- Os formulários ganham o campo de marcação (caixa de seleção), que ainda não existe no sistema.
- Popular o banco de desenvolvimento local cria espaços de exemplo, com e sem bloco.

## Atores

- **Visitante:** não autenticado.
- **Usuário comum:** autenticado, sem perfil de administrador.
- **Administrador:** autenticado, com perfil de administrador. É quem executa todas as tarefas desta
  especificação.

## Tarefas e fluxos

Cada tarefa responde: quem executa, qual o objetivo, como o fluxo começa, quais ações são necessárias,
quais regras se aplicam e que resultado e retorno aparecem.

### T1 — Cadastrar um espaço para que ele possa ser reservado

- **Quem e quando:** o administrador, na implantação do sistema (dezenas de espaços em sequência) e
  depois, de vez em quando, ao surgir uma sala nova.
- **Objetivo:** deixar o espaço disponível para reserva, com as informações de que o solicitante precisa
  para escolhê-lo e com a regra de liberação correta.
- **Início:** Área administrativa › atalho Espaços › botão "Novo espaço".
- **Ações:** escolher o campus; escolher o bloco ou "Sem bloco"; informar o nome; descrever o espaço
  (tipo, capacidade, andar, equipamentos); escolher o departamento responsável ou "Sem departamento";
  marcar se a reserva precisa de aprovação; escolher o termo de uso ou "Sem termo de uso"; salvar.
- **Regras:** RN1–RN8, RN15.
- **Resultado e retorno:** o administrador volta para a listagem, vê o espaço novo e uma mensagem de
  confirmação. Com dados inválidos, o formulário volta com o que foi preenchido e o erro junto ao campo.

### T2 — Encontrar um espaço e conferir os dados dele

- **Quem e quando:** o administrador, antes de corrigir um espaço ou para responder a uma dúvida ("quem
  libera o Laboratório B3?").
- **Objetivo:** localizar o espaço e ver onde fica, quem responde por ele, se a reserva precisa de
  aprovação e qual termo se aplica.
- **Início:** Área administrativa › atalho Espaços.
- **Ações:** percorrer a listagem, organizada por campus, bloco e nome; abrir a página do espaço para
  ver a descrição e o termo de uso.
- **Regras:** RF1, RF2.
- **Resultado e retorno:** a listagem mostra o essencial de cada espaço; a página do espaço mostra
  todos os dados e as ações de editar, mudar a situação e excluir.

### T3 — Corrigir os dados de um espaço

- **Quem e quando:** o administrador, quando um dado foi cadastrado errado ou mudou (o espaço passou a
  outro departamento, passou a exigir aprovação).
- **Objetivo:** manter o cadastro igual à realidade.
- **Início:** ação Editar na listagem ou na página do espaço.
- **Ações:** alterar os campos necessários no mesmo formulário do cadastro e salvar.
- **Regras:** as mesmas do cadastro (RN1–RN8).
- **Resultado e retorno:** volta para a listagem com mensagem de confirmação, ou o formulário volta com
  o erro junto ao campo.

### T4 — Remover um espaço cadastrado por engano

- **Quem e quando:** o administrador, raramente.
- **Objetivo:** tirar do cadastro um espaço que não deveria existir.
- **Início:** ação Excluir na listagem ou na página do espaço.
- **Ações:** acionar Excluir e confirmar.
- **Regras:** RN9.
- **Resultado e retorno:** o espaço some da listagem e aparece uma mensagem de confirmação. Desistir na
  confirmação mantém o espaço. A confirmação lembra que, para só tirar o espaço de uso, existe a
  desativação (T7).

### T5 — Entender por que um campus, bloco, departamento ou termo não pode ser excluído

- **Quem e quando:** o administrador, ao tentar excluir um cadastro que ainda é usado por espaços.
- **Objetivo:** saber o motivo e o que fazer para concluir a exclusão.
- **Início:** ação Excluir na listagem de campi, blocos, departamentos ou termos de uso.
- **Ações:** ler a mensagem; seguir o caminho indicado (mover os espaços para outro cadastro ou
  excluí-los) e tentar de novo.
- **Regras:** RN10.
- **Resultado e retorno:** nada é excluído; a mensagem diz o motivo e o próximo passo.

### T6 — Impedir as reservas de um espaço por um tempo, dizendo o motivo, e liberá-lo depois

- **Quem e quando:** o administrador, quando um espaço fica fora de uso por um período (reforma,
  manutenção, interdição) e quando ele volta a funcionar.
- **Objetivo:** o espaço continua visível para quem reserva, mas não aceita reservas, e quem tenta
  reservar entende por quê.
- **Início:** ação "Marcar como indisponível" na página do espaço.
- **Ações:** escrever o motivo, como "Sala em reforma", e salvar. Para corrigir o motivo, "Alterar
  motivo". Para encerrar a indisponibilidade, "Tornar disponível", que não pede confirmação.
- **Regras:** RN12, RN13.
- **Resultado e retorno:** a página do espaço mostra "Indisponível", o motivo e as ações de alterar o
  motivo e tornar disponível, com uma mensagem de confirmação. A listagem marca o espaço como
  indisponível. Sem motivo, o formulário volta com o erro junto ao campo e nada muda.

### T7 — Tirar de uso um espaço que deixou de existir

- **Quem e quando:** o administrador, raramente: quando duas salas são unificadas e uma delas deixa de
  existir, ou quando o espaço é demolido ou devolvido.
- **Objetivo:** o espaço deixa de aparecer para reserva, sem apagar o cadastro (nem, no futuro, as
  reservas antigas dele).
- **Início:** ação "Desativar" na página do espaço.
- **Ações:** acionar Desativar e confirmar. A confirmação diz que o espaço deixará de aparecer na
  reserva e que, para impedir reservas só por um tempo, o caminho é "Marcar como indisponível". Para
  desfazer um engano, "Reativar", que não pede confirmação.
- **Regras:** RN12, RN14.
- **Resultado e retorno:** a página do espaço mostra "Desativado" e a ação Reativar, com uma mensagem
  de confirmação, e a listagem marca o espaço como desativado. Desistir na confirmação mantém a
  situação. Reativado, o espaço volta como disponível.

## Requisitos funcionais

1. **RF1 — Listagem.** `/admin/spaces` mostra todos os espaços, ordenados por campus, bloco e nome,
   com os espaços sem bloco depois dos blocos do mesmo campus. Cada espaço mostra nome, campus, bloco
   (ou "Sem bloco"), departamento responsável (ou "Sem departamento") e se a reserva precisa de
   aprovação, com as ações de ver, editar e excluir. Um espaço indisponível ou desativado aparece na
   mesma posição, com a marca "Indisponível" ou "Desativado" em texto, não só em cor. A página tem a
   ação "Novo espaço". Sem espaços cadastrados, a página informa que não há espaços e mantém a ação de
   cadastrar.
2. **RF2 — Página do espaço.** Mostra todos os dados do espaço: nome, situação (disponível,
   indisponível com o motivo, ou desativado) e o que ela significa para a reserva, campus, bloco,
   descrição, departamento responsável, se a reserva precisa de aprovação e quem a libera (RF5), e o
   termo de uso, com acesso ao texto do termo. Oferece as ações de editar, de mudar a situação (RF14) e
   de excluir. É nesta página que a Issue #62 mostrará as subdivisões.
3. **RF3 — Cadastro e edição.** Um único formulário, com os campos na ordem da tarefa T1: Campus,
   Bloco, Nome, Descrição, Departamento responsável, "A reserva precisa de aprovação" e Termo de uso.
   Com dados válidos, o administrador volta para a listagem e vê uma mensagem de confirmação. Na
   edição, o formulário vem preenchido com os dados atuais.
4. **RF4 — Escolha do campus e do bloco.** O campo Campus começa em "Selecione o campus". O campo Bloco
   tem a opção "Sem bloco" e, depois que o campus é escolhido, mostra só os blocos daquele campus; ao
   trocar o campus, um bloco de outro campus deixa de estar escolhido. Sem JavaScript, o campo lista
   todos os blocos agrupados por campus. O servidor valida nos dois casos (RN2).
5. **RF5 — Quem libera a reserva.** O formulário e a página do espaço dizem, em texto, quem libera as
   reservas: com departamento, os usuários daquele departamento; sem departamento, somente os
   administradores. Quando a reserva não precisa de aprovação, informa que ela é confirmada sem
   liberação. O administrador não precisa conhecer a regra de antemão.
6. **RF6 — Campo de marcação.** A caixa "A reserva precisa de aprovação" tem o mesmo padrão visual dos
   outros campos, rótulo que também marca a caixa ao ser clicado, foco visível e uso pelo teclado.
   Começa desmarcada.
7. **RF7 — Exclusão.** A exclusão pede confirmação, citando o nome do espaço e lembrando que a
   exclusão não pode ser desfeita e que a desativação tira o espaço de uso sem apagá-lo. Confirmada, o
   espaço é removido e o administrador volta para a listagem com uma mensagem de confirmação.
8. **RF8 — Dados inválidos.** Com dados inválidos, nada é gravado. O formulário volta com os valores
   escolhidos e digitados e a mensagem de erro junto ao campo.
9. **RF9 — Exclusões recusadas.** Tentar excluir um campus, bloco, departamento ou termo de uso com
   espaços vinculados não exclui nada. O administrador volta para a listagem correspondente com uma
   mensagem que explica o motivo e o próximo passo (RN10).
10. **RF10 — Atalho na área administrativa.** A página inicial de `/admin` exibe o atalho Espaços, junto
    dos outros cadastros.
11. **RF11 — Hierarquia e navegação.** As páginas mostram título, subtítulo e a trilha de navegação:
    Dashboard › Área administrativa › Espaços, mais Novo, o nome do espaço, Editar ou
    Indisponibilidade.
12. **RF12 — Celular.** As páginas funcionam desde 320 px de largura: a listagem cabe sem rolagem
    horizontal, com nome, localização, departamento e aprovação de cada espaço, as ações continuam
    fáceis de tocar e o formulário ocupa toda a largura.
13. **RF13 — Espaços locais.** Popular o banco de desenvolvimento local cria espaços de exemplo no
    campus Guarapuava: com bloco (salas e laboratórios, com e sem aprovação, com e sem departamento e
    termo) e sem bloco (quadra e planetário). Um dos espaços é criado indisponível, com motivo, e outro
    desativado.
14. **RF14 — Mudança de situação.** A página do espaço oferece as ações conforme a situação:
    - disponível: "Marcar como indisponível" e "Desativar";
    - indisponível: "Alterar motivo", "Tornar disponível" e "Desativar";
    - desativado: "Reativar".

    "Marcar como indisponível" e "Alterar motivo" abrem o formulário do motivo (RF16). "Desativar"
    pede confirmação (T7). "Tornar disponível" e "Reativar" mudam a situação na hora. Depois de cada
    ação, a página do espaço mostra a nova situação com uma mensagem de confirmação. Uma ação que não
    vale para a situação em que o espaço está agora (repetida, ou feita numa página aberta antes de
    outra mudança) não muda nada; a página do espaço mostra a situação atual e o aviso "Nada foi
    alterado: o espaço está desativado." (ou disponível, ou indisponível).
15. **RF15 — Campus de um bloco com espaços.** Na edição de um bloco que tem espaços, o formulário
    avisa, junto ao campo Campus, que os espaços do bloco acompanham a troca de campus (RN11). A
    mensagem de confirmação da edição informa quando espaços foram movidos.
16. **RF16 — Formulário do motivo.** Tem o título "Marcar como indisponível" (ou "Alterar motivo") e
    um único campo, Motivo, com a dica de que o texto aparece para quem tenta reservar, por exemplo
    "Sala em reforma". Ocupa toda a largura e tem as ações Salvar e Cancelar; Cancelar volta para a
    página do espaço sem mudar nada. Na alteração, o campo vem preenchido com o motivo atual.

## Regras de negócio

- **RN1 — Campus obrigatório.** Todo espaço pertence a um campus. Sem campus, ou com um campus que não
  existe, o espaço é recusado com "Selecione o campus."
- **RN2 — Bloco opcional e do mesmo campus.** O espaço pode não ter bloco. Quando tem, o bloco precisa
  ser do campus escolhido; um bloco de outro campus, ou que não existe, é recusado com "Selecione um
  bloco do campus escolhido."
- **RN3 — Nome obrigatório.** Um nome vazio, ou só com espaços, é recusado com "Informe o nome do
  espaço." Os espaços das pontas e os repetidos são removidos antes de validar e gravar.
- **RN4 — Nome único no bloco.** Dois espaços do mesmo bloco não podem ter o mesmo nome, sem
  diferenciar maiúsculas de minúsculas (decisão D5). O repetido é recusado com "Já existe um espaço com
  este nome neste bloco." Blocos diferentes podem ter espaços com o mesmo nome.
- **RN5 — Nome único entre espaços sem bloco.** Dois espaços sem bloco do mesmo campus não podem ter o
  mesmo nome, com a mesma comparação. O repetido é recusado com "Já existe um espaço sem bloco com este
  nome neste campus." Um espaço sem bloco pode ter o mesmo nome de um espaço que está em um bloco.
- **RN6 — Departamento responsável opcional.** Com departamento, os usuários daquele departamento
  poderão liberar as reservas do espaço; sem departamento, só os administradores. Um departamento que
  não existe é recusado com "Selecione um departamento cadastrado."
- **RN7 — Termo de uso opcional.** O espaço pode não ter termo. Um termo que não existe é recusado com
  "Selecione um termo de uso cadastrado."
- **RN8 — Aprovação.** "A reserva precisa de aprovação" indica se a reserva precisa ser liberada por um
  responsável. O padrão é não precisar. O fluxo de liberação fica fora desta Issue.
- **RN9 — Exclusão de espaço.** Nesta Issue, qualquer espaço pode ser excluído, em qualquer situação,
  porque ainda não há reservas gravadas. A exclusão serve para cadastros feitos por engano; para tirar
  um espaço de uso, os caminhos são a indisponibilidade (RN13) e a desativação (RN14).
- **RN10 — Cadastros em uso.** Um campus, bloco, departamento ou termo de uso com pelo menos um espaço
  não pode ser excluído. A mensagem diz o motivo e o próximo passo, por exemplo: "Não é possível excluir
  o bloco porque ele tem espaços cadastrados. Mova os espaços para outro bloco ou exclua-os antes."
  (decisão D3). Sem espaços vinculados, a exclusão segue as regras que já existem.
- **RN11 — Campus de um bloco com espaços.** A troca de campus na edição do bloco continua livre, sob
  responsabilidade do administrador (RN7 da especificação de blocos, decisão do professor em
  2026-10-23). Para o espaço nunca ficar em um campus diferente do campus do seu bloco (RN2), os
  espaços do bloco passam para o novo campus na mesma operação: ou mudam o bloco e todos os seus
  espaços, ou nada muda (decisão D4).
- **RN12 — Situação do espaço.** Todo espaço está em uma de três situações: disponível, indisponível
  ou desativado (decisões D2 e D8). Um espaço novo começa disponível. Editar os dados do espaço não
  muda a situação nem o motivo. Em qualquer situação, o espaço continua no cadastro, com todos os
  dados, e conta como espaço vinculado na RN10. Nesta Issue, a situação é gravada e mostrada na área
  administrativa; o efeito na tela de reserva entra quando ela passar a usar o cadastro de espaços
  (Issue #63).
- **RN13 — Indisponibilidade temporária.** O espaço indisponível continua aparecendo na listagem de
  reservas, mas não pode ser reservado, e a listagem mostra o motivo. O motivo é obrigatório e curto,
  com até 100 caracteres; os espaços das pontas e os repetidos são removidos antes de validar. Vazio,
  ou só com espaços, é recusado com "Informe o motivo da indisponibilidade."; longo demais, com "O
  motivo deve ter no máximo 100 caracteres." O motivo pode ser alterado enquanto o espaço está
  indisponível e é apagado quando o espaço deixa de estar indisponível.
- **RN14 — Desativação definitiva.** O espaço desativado deixa de aparecer na listagem de reservas.
  Pode ser reativado e volta como disponível. O nome dele continua ocupado: outro espaço do mesmo bloco,
  ou sem bloco no mesmo campus, não pode usar o mesmo nome (RN4, RN5, decisão D10).
- **RN15 — Descrição obrigatória.** Todo espaço tem uma descrição, com o que o solicitante precisa para
  escolhê-lo, como tipo, capacidade, andar e equipamentos. Uma descrição vazia, ou só com espaços, é
  recusada com "Informe a descrição do espaço." (decisão D11).
- Todo texto de interface é traduzido em português do Brasil.

## Regras de acesso

- Seguem as regras da #55: somente administradores acessam o cadastro.
- A permissão é verificada no servidor em todo endereço e ação do cadastro, inclusive nos envios de
  formulário e na exclusão feitos diretamente, sem passar pela tela.
- Um usuário comum recebe HTTP 403 em qualquer endereço ou ação do cadastro, e nenhum dado é alterado.
- Um visitante é direcionado para a página de autenticação, e nenhum dado é alterado.
- Um endereço de espaço inexistente responde como página não encontrada (HTTP 404).

## Decisões

D1 a D7 foram tomadas pelo desenvolvedor em 2026-11-12; D1 a D5 foram levadas ao professor, que
respondeu em 2026-11-13. D8 a D10 são da revisão de 2026-11-17, feita a partir da resposta à D2. D11
veio da revisão da PR #88 pelo professor, também em 2026-11-17.

| ID | Pergunta | Decisão |
| --- | --- | --- |
| D1 | Como evitar que o administrador escolha um bloco de outro campus? | Ao escolher o campus, o campo Bloco mostra só os blocos daquele campus; o servidor valida de qualquer forma (RF4, RN2). A Issue previa só a lista agrupada por campus. Confirmada pelo professor. |
| D2 | Excluir ou desativar um espaço? | Os dois. O professor confirmou e pediu que se separassem duas situações: a indisponibilidade temporária, em que o espaço continua na listagem de reservas, não pode ser reservado e mostra o motivo (por exemplo, "Sala em reforma"), e a desativação definitiva, em que o espaço sai da listagem de reservas (por exemplo, quando duas salas são unificadas e uma delas deixa de existir). A exclusão continua para cadastros feitos por engano (RN9). A Issue não previa a situação (T6, T7, RF14, RN12–RN14). |
| D3 | O que dizer quando a exclusão de um campus, bloco, departamento ou termo é recusada? | O motivo e o próximo passo (RN10). Confirmada pelo professor. |
| D4 | O que acontece ao trocar o campus de um bloco que tem espaços? | A troca continua livre, como decidido pelo professor em 2026-10-23, e os espaços do bloco passam junto para o novo campus (RF15, RN11). Confirmada pelo professor. Na revisão da PR #88, ele indicou que não permitiria mais a troca de campus de um bloco; a mudança fica para uma Issue própria, e esta PR mantém o comportamento atual. |
| D5 | Como comparar nomes repetidos? | Padrão do Rails, sem diferenciar maiúsculas de minúsculas, como pedido na revisão dos termos de uso em 2026-11-03 (RN4, RN5). O professor manteve o padrão mesmo com a limitação do SQLite, que só converte letras sem acento ("Auditório" e "AUDITÓRIO" contam como nomes diferentes), porque o banco vai migrar para PostgreSQL, possivelmente depois do primeiro deploy. |
| D6 | Como encontrar um espaço quando houver muitos? | Só a ordenação por campus, bloco e nome. Busca e filtro ficam fora desta Issue. |
| D7 | Os espaços também são cadastrados a partir da página de um bloco? | Não nesta Issue. |
| D8 | Como representar as duas situações pedidas na D2? | Uma única situação com três valores que se excluem: disponível, indisponível e desativado. Duas marcações independentes ("ativo" e "indisponível") permitiriam combinações sem sentido, como um espaço desativado e indisponível por reforma (RN12). |
| D9 | Como o administrador muda a situação? | Por ações próprias na página do espaço, fora do formulário de edição, que continua só com os dados do cadastro. "Marcar como indisponível" abre um formulário só com o motivo, limitado a 100 caracteres por aparecer na listagem de reservas. "Desativar" pede confirmação, porque tira o espaço da reserva e pode ser confundida com a indisponibilidade. "Tornar disponível" e "Reativar" não pedem (T6, T7, RF14, RF16, RN13). |
| D10 | O nome de um espaço desativado continua ocupado? | Sim. Para usar o nome em outro espaço, o administrador renomeia ou exclui o desativado. Assim não ficam dois espaços com o mesmo nome no mesmo bloco, o que confundiria quem consultar reservas antigas (RN14). |
| D11 | A descrição é obrigatória? | Sim, a pedido do professor na revisão da PR #88. A Issue e a primeira versão a deixavam opcional (RN15). |

## Critérios de aceitação

| ID | Critério (da Issue) | Requisitos e regras |
| --- | --- | --- |
| CA1 | Administradores conseguem listar, cadastrar, editar e excluir espaços. | T1–T4, RF1–RF3, RF6–RF8, RF10–RF12 |
| CA11 | (Além da Issue, decisão D2.) Administradores conseguem marcar um espaço como indisponível, com o motivo, desativá-lo e devolvê-lo ao uso, e a listagem mostra a situação de cada espaço. | T6, T7, RF1, RF2, RF14, RF16, RN12–RN14 |
| CA12 | (Além da Issue, decisão D4.) Ao trocar o campus de um bloco, os espaços do bloco passam para o novo campus, com aviso antes e confirmação depois. | RF15, RN11 |
| CA2 | É possível cadastrar espaços com bloco e sem bloco. | RF4, RN2 |
| CA3 | Um bloco de outro campus é recusado. | RF4, RN2 |
| CA4 | Um nome repetido no mesmo bloco é recusado; o mesmo nome em blocos diferentes é aceito. | RN4 |
| CA5 | Um nome repetido entre espaços sem bloco do mesmo campus é recusado. | RN5 |
| CA6 | A exclusão de campi, blocos, departamentos ou termos com espaços vinculados é recusada com mensagem explicando o motivo. | T5, RF9, RN10 |
| CA7 | A listagem mostra campus, bloco, departamento e se a reserva precisa de aprovação. | RF1, RF12 |
| CA8 | Usuários comuns recebem HTTP 403 e usuários não autenticados são direcionados para a autenticação. | Regras de acesso |
| CA9 | O `populate` cria espaços de exemplo com e sem bloco. | RF13 |
| CA10 | Existem testes automatizados para as validações, as regras de exclusão e o controle de acesso. | Todos |

## Verificação de uso

Antes de considerar a funcionalidade concluída, conferir cada tarefa (T1–T7) com estas perguntas:

- A pessoa entende o que fazer sem orientação externa?
- As informações aparecem no momento adequado?
- O sistema previne erros e explica as restrições?
- Há etapas desnecessárias?
- A interface é consistente com o restante do sistema?

A conferência usa as heurísticas de Nielsen e os critérios da WCAG 2.2 aplicáveis (teclado, contraste,
rótulos e mensagens de erro). O resultado é registrado em `tasks.md`.

## Cenários

### Positivos

- Um administrador abre a área administrativa, segue o atalho Espaços e vê a listagem ordenada por
  campus, bloco e nome.
- Um administrador cadastra "Sala 101" no Bloco B de Guarapuava, sem departamento e sem aprovação, e
  vê o espaço na listagem com uma mensagem de confirmação.
- Um administrador cadastra "Quadra poliesportiva" em Guarapuava com "Sem bloco" e vê o espaço na
  listagem, depois dos blocos.
- Com "Sala 101" no Bloco B, um administrador cadastra "Sala 101" no Bloco C, e as duas aparecem.
- Um administrador cadastra um laboratório com departamento, aprovação marcada e termo de uso; a página
  do espaço mostra que os usuários daquele departamento liberam as reservas e dá acesso ao termo.
- Um administrador marca a aprovação em um espaço sem departamento, e o formulário informa que só os
  administradores liberarão as reservas.
- Um administrador edita um espaço, troca o departamento e vê o novo departamento na listagem.
- Um administrador exclui um espaço, confirma, e o espaço some da listagem.
- Um administrador escolhe o campus no formulário, e o campo Bloco passa a mostrar só os blocos dele.
- Um administrador marca a "Sala 101" como indisponível com o motivo "Sala em reforma": a página
  mostra "Indisponível" e o motivo, e a listagem marca o espaço como indisponível. Ao tornar
  disponível, o motivo some e o espaço volta como disponível.
- Um administrador altera o motivo de um espaço indisponível para "Sala em reforma até março", e a
  página mostra o novo motivo.
- Um administrador desativa a "Sala 102", que foi unificada com a "Sala 101", e confirma: a página
  mostra "Desativado" e a ação Reativar, e a listagem marca o espaço como desativado. Ao reativar, o
  espaço volta como disponível.
- Um administrador desativa um espaço que estava indisponível; o motivo é apagado.
- Um administrador corrige o campus de um bloco que não tem espaços, como antes.
- Um administrador troca o campus de um bloco com espaços: o formulário avisa antes, e depois os
  espaços do bloco aparecem na listagem com o novo campus.
- Depois de excluir o último espaço de um bloco, o administrador consegue excluir o bloco.
- Depois de popular o banco local, a listagem mostra espaços com bloco e sem bloco.
- Num celular de 320 px, o administrador vê a listagem sem rolar para o lado e cadastra um espaço.

### Negativos

- Cadastrar sem campus mostra o formulário de novo, com erro no campo Campus, e nada é gravado.
- Cadastrar com o nome vazio mostra o formulário de novo, com erro no campo Nome e os outros campos
  preenchidos.
- Cadastrar sem descrição, ou com uma descrição só de espaços, mostra o formulário de novo, com erro no
  campo Descrição, e nada é gravado.
- Enviar um bloco de outro campus é recusado com erro no campo Bloco.
- Com "Sala 101" no Bloco B, cadastrar "sala 101" no Bloco B é recusado com erro de nome já em uso.
- Com "Planetário" sem bloco em Guarapuava, cadastrar outro "Planetário" sem bloco em Guarapuava é
  recusado.
- Excluir um campus, bloco, departamento ou termo de uso com espaços mantém tudo e mostra a mensagem
  com o motivo e o próximo passo.
- Trocar o campus de um bloco com espaços para um campus que já tem um bloco com o mesmo nome é
  recusado, e o bloco e os espaços ficam como estavam.
- Excluir um bloco cujos espaços estão todos desativados ou indisponíveis também é recusado.
- Marcar um espaço como indisponível sem motivo, ou com um motivo só de espaços, mostra o formulário de
  novo com o erro no campo, e a situação não muda.
- Um usuário comum abre ou envia qualquer endereço do cadastro, inclusive as mudanças de situação, e
  recebe HTTP 403, sem alteração nos dados.
- Um visitante abre ou envia qualquer endereço do cadastro e é direcionado para a autenticação.
- Desistir na confirmação de exclusão mantém o espaço.
- Desistir na confirmação de desativação mantém a situação.
- Com a página aberta antes de outro administrador desativar o espaço, "Marcar como indisponível",
  "Alterar motivo" ou "Tornar disponível" não muda nada, e a página do espaço avisa que ele está
  desativado. Um espaço desativado só volta pela ação Reativar.

### Limite

- Um nome só com espaços é tratado como vazio e recusado.
- Um espaço sem bloco e um espaço em bloco, no mesmo campus, podem ter o mesmo nome.
- Editar um espaço sem alterar o nome é aceito: o espaço não conflita com ele mesmo.
- Mover um espaço para um bloco que já tem um espaço com o mesmo nome é recusado.
- Um envio direto com departamento ou termo de uso que não existe é recusado com erro no campo.
- Sem nenhum bloco cadastrado, o campo Bloco mostra só "Sem bloco", e o espaço pode ser cadastrado.
- Sem nenhum espaço cadastrado, a listagem mostra a mensagem de lista vazia.
- Desativar um espaço já desativado, ou tornar disponível um que já está disponível, não muda nada e
  só avisa a situação atual.
- Um motivo com 100 caracteres é aceito; com 101, é recusado.
- Editar um espaço indisponível ou desativado mantém a situação e o motivo, mesmo que o envio direto
  do formulário de edição traga outra situação.
- Com a "Sala 102" desativada no Bloco B, cadastrar outra "Sala 102" no Bloco B é recusado com erro de
  nome já em uso.
- Ao trocar o campus de um bloco, os espaços sem bloco dos dois campi não mudam.
- Um administrador abre a página ou a edição de um espaço que não existe e recebe HTTP 404.

## Fora do escopo

- Cadastro de subdivisões (Issue #62).
- Exibição dos espaços na tela de reserva, incluindo esconder os desativados e mostrar o motivo dos
  indisponíveis (Issue #63).
- Fluxo de aprovação das reservas e aceite do termo de uso na reserva.
- Bloqueio da exclusão de espaços com reservas: entra quando as reservas forem gravadas.
- O que acontece com as reservas já feitas de um espaço que fica indisponível ou é desativado: entra
  quando as reservas forem gravadas.
- Período da indisponibilidade (datas de início e fim, volta automática) e motivo da desativação.
- Busca, filtros (inclusive por situação) e paginação na listagem (decisão D6).
- Página de um bloco com os seus espaços (decisão D7).
- Campos estruturados para tipo, capacidade, andar e equipamentos: ficam na descrição livre.
- Criar espaços fora do ambiente local de desenvolvimento (por exemplo, dados iniciais de produção).
- Pontos da revisão da PR #88 que vão para Issues próprias: departamento e termo de uso por campus;
  administrador geral e administração delegada por campus; layout e navegação organizados por campus,
  com protótipos antes; e o fim da troca de campus de um bloco (D4, RN11).
