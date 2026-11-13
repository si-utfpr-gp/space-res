# Gestão de usuários pelo admin — Especificação

Issue: #59 — Gestão de usuários pelo admin

Status: aprovada em 2026-11-09.

## Objetivo

Permitir que administradores vejam, na área administrativa, os usuários do sistema e definam o
departamento de cada um. Quando o fluxo de reservas existir, um usuário com departamento poderá liberar as
reservas dos espaços desse departamento.

## Escopo

- Administradores listam os usuários em `/admin/users`, com nome, e-mail e departamento.
- Administradores definem, trocam ou removem o departamento de um usuário.
- A exclusão de um departamento com usuários vinculados é recusada.
- A página inicial da área administrativa oferece acesso à gestão de usuários.
- Popular o banco de desenvolvimento local vincula o usuário de demonstração a um departamento.

## Atores

- **Visitante:** não autenticado.
- **Usuário comum:** autenticado, sem perfil de administrador.
- **Administrador:** autenticado, com perfil de administrador.

## Histórias de usuário

- Como administrador, quero ver todos os usuários e o departamento de cada um, para saber quem responde
  por cada departamento.
- Como administrador, quero vincular um docente ou técnico ao seu departamento, para que ele possa liberar
  as reservas dos espaços desse departamento quando esse fluxo existir.
- Como administrador, quero trocar ou remover o departamento de um usuário que mudou de setor ou saiu.
- Como administrador, quero ser impedido de excluir um departamento que ainda tem usuários, para não
  deixar usuários vinculados a um departamento que não existe.

## Requisitos funcionais

1. **RF1 — Listagem.** `/admin/users` mostra todos os usuários em ordem alfabética de nome. Cada linha
   mostra o nome, o e-mail e o departamento; um usuário sem departamento aparece como "Sem departamento".
   Usuários com perfil de administrador têm um selo "Administrador" junto ao nome, só informativo. Cada
   usuário tem a ação de editar. A página não tem ações de cadastrar nem de excluir usuários.
2. **RF2 — Edição do departamento.** A edição mostra o nome e o e-mail do usuário, só para leitura, e o
   campo Departamento, com os departamentos em ordem alfabética e a opção "Sem departamento". O campo vem
   preenchido com o departamento atual e traz a orientação de atribuir departamento apenas a docentes e
   técnicos. Ao salvar, o administrador volta para a listagem e vê uma mensagem de confirmação.
3. **RF3 — Remoção do departamento.** Escolher "Sem departamento" e salvar desvincula o usuário do
   departamento, com a mesma mensagem de confirmação.
4. **RF4 — Exclusão de departamento com usuários.** Na listagem de departamentos, excluir um departamento
   com usuários vinculados é recusado: o departamento continua cadastrado e o administrador volta para a
   listagem de departamentos com uma mensagem explicando que há usuários vinculados. Um departamento sem
   usuários continua sendo excluído como antes.
5. **RF5 — Atalho na área administrativa.** A página inicial de `/admin` exibe um atalho para a gestão de
   usuários, junto aos atalhos dos cadastros.
6. **RF6 — Hierarquia e navegação.** A listagem e a edição mostram título, subtítulo e a trilha de
   navegação, como os demais cadastros: Dashboard › Área administrativa › Usuários, mais Editar.
7. **RF7 — Celular.** As páginas funcionam no celular desde 320 px de largura: a listagem cabe na tela sem
   rolagem horizontal, mesmo com nomes, e-mails e departamentos longos, que quebram em mais de uma linha,
   e a ação de editar continua fácil de tocar. O formulário ocupa toda a largura disponível.
8. **RF8 — Usuário de demonstração.** Popular o banco de desenvolvimento local vincula o "User Demo" à
   "Coordenação do Curso de Tecnologia em Sistemas para a Internet". O "Admin Demo" continua sem
   departamento.

## Regras de negócio

- **RN1 — Departamento opcional.** Um usuário pode ter um departamento ou nenhum.
- **RN2 — Só o departamento muda.** A gestão de usuários altera somente o departamento. Nome, e-mail,
  senha e perfil de administrador não mudam por ela, nem quando enviados diretamente, sem passar pela
  tela: esses dados são ignorados.
- **RN3 — Departamento existente.** O departamento escolhido precisa existir. Um departamento inexistente,
  por exemplo excluído por outro administrador enquanto o formulário estava aberto, é recusado com a
  mensagem "Selecione um departamento cadastrado.", e nada é gravado.
- **RN4 — Qualquer usuário.** Qualquer usuário pode receber um departamento, inclusive administradores e o
  próprio administrador que está editando. Como o sistema ainda não registra o tipo de vínculo (docente,
  técnico ou aluno), cabe ao administrador atribuir departamento apenas a docentes e técnicos.
- **RN5 — Exclusão bloqueada.** Um departamento com pelo menos um usuário vinculado não pode ser excluído.
  A recusa mostra a mensagem "Não é possível excluir o departamento porque ele tem usuários vinculados."
- **RN6 — Operações simultâneas.** Se um administrador vincula um usuário a um departamento ao mesmo tempo
  em que outro exclui esse departamento, uma das duas operações é recusada com a mensagem da RN3 ou da
  RN5. Nunca sobra usuário vinculado a departamento inexistente.
- Todo texto de interface é traduzido em português do Brasil.

## Regras de acesso

- Seguem as regras da #55: somente administradores acessam a gestão de usuários.
- A permissão é verificada no servidor em todo endereço e ação, inclusive nos envios de formulário feitos
  diretamente, sem passar pela tela.
- Um usuário comum recebe HTTP 403 em qualquer endereço ou ação da gestão de usuários, e nenhum dado é
  alterado.
- Um visitante é direcionado para a página de autenticação, e nenhum dado é alterado.
- Um endereço de usuário inexistente responde como página não encontrada (HTTP 404).
- A página de acesso negado não mostra a trilha da área administrativa.

## Critérios de aceitação

| ID | Critério (da Issue) | Requisitos e regras |
| --- | --- | --- |
| CA1 | Administradores conseguem listar os usuários com nome, e-mail e departamento. | RF1, RF5–RF7 |
| CA2 | Administradores conseguem definir, trocar e remover o departamento de um usuário. | RF2, RF3, RN1, RN3, RN4 |
| CA3 | A exclusão de um departamento com usuários vinculados é recusada com mensagem explicando o motivo. | RF4, RN5, RN6 |
| CA4 | O perfil `admin` não pode ser alterado pela tela de gestão de usuários. | RF1, RN2 |
| CA5 | Usuários comuns recebem HTTP 403 e usuários não autenticados são direcionados para a autenticação. | Regras de acesso |
| CA6 | Existem testes automatizados para a atribuição de departamento, a regra de exclusão e o controle de acesso. | Todos |

## Cenários

### Positivos

- Um administrador abre a área administrativa, segue o atalho de usuários e vê todos os usuários em ordem
  alfabética, com nome, e-mail e departamento; o "Admin Demo" tem o selo "Administrador".
- Um administrador edita um usuário sem departamento, escolhe "Departamento de Educação", salva, volta
  para a listagem, vê o departamento na linha do usuário e uma mensagem de confirmação.
- Um administrador troca o departamento de um usuário de "Departamento de Educação" para "Biblioteca" e
  vê o novo departamento na listagem.
- Um administrador escolhe "Sem departamento" para um usuário vinculado, salva e vê "Sem departamento" na
  linha do usuário.
- Um administrador vincula a si mesmo a um departamento.
- Um administrador exclui um departamento sem usuários, confirma, e o departamento some da listagem.
- Depois de popular o banco local, a listagem mostra o "User Demo" na "Coordenação do Curso de Tecnologia
  em Sistemas para a Internet" e o "Admin Demo" sem departamento.
- Na edição, a trilha mostra "Dashboard › Área administrativa › Usuários › Editar"; tocar em "Usuários"
  volta para a listagem.
- Num celular de 320 px, o administrador vê a listagem sem rolar para o lado, toca em "Editar", troca o
  departamento e vê a mensagem de confirmação.

### Negativos

- Um administrador tenta excluir a "Biblioteca", que tem um usuário vinculado, confirma, e vê a mensagem
  de que o departamento tem usuários vinculados; a "Biblioteca" continua na listagem.
- Um envio direto da edição com o perfil de administrador, nome, e-mail ou senha diferentes não altera
  esses dados; só o departamento, se enviado, muda.
- Um envio da edição com um departamento que não existe é recusado com a mensagem da RN3, e o
  departamento do usuário continua o mesmo.
- Um usuário comum abre `/admin/users` ou a edição de um usuário e recebe HTTP 403.
- Um usuário comum envia uma edição diretamente e recebe HTTP 403, sem alteração nos dados.
- Um visitante abre ou envia qualquer endereço da gestão de usuários e é direcionado para a autenticação,
  sem alteração nos dados.
- Um usuário comum que recebe 403 não vê a trilha da área administrativa.

### Limite

- Salvar a edição sem mudar o departamento é aceito e mantém o departamento.
- Um departamento com um único usuário vinculado não pode ser excluído; depois de remover o departamento
  desse usuário, a exclusão é aceita.
- Um administrador vincula um usuário a um departamento enquanto outro administrador exclui esse mesmo
  departamento: ou o vínculo é recusado (RN3), ou a exclusão é recusada (RN5).
- Um administrador abre a edição de um usuário que não existe e recebe HTTP 404.

## Fora do escopo

- Criar e excluir contas de usuário.
- Alterar o perfil de administrador pela interface: continua definido pelo `populate` no ambiente local e
  manualmente em produção, como na #55.
- Alterar nome, e-mail ou senha de um usuário.
- Registrar o tipo de vínculo do usuário (docente, técnico ou aluno) e restringir o departamento a
  docentes e técnicos.
- Mais de um departamento por usuário.
- Busca, filtros e paginação na listagem.
- Mostrar os usuários de um departamento na tela de departamentos.
- Fluxo de liberação de reservas.
- Bloqueio da exclusão de departamentos com espaços vinculados (#61).
