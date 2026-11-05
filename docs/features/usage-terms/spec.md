# Cadastro de termos de uso — Especificação

Issue: #60 — Cadastro de termos de uso

Status: aprovada em 2026-11-02; revisada em 2026-11-03 com o retorno do professor: unicidade padrão do
Rails e texto com o editor do Action Text.

## Objetivo

Permitir que administradores mantenham, na área administrativa, os Termos de Uso e Responsabilidade dos
espaços. Um termo é cadastrado uma vez e, na Issue de espaços (#61), pode ser usado por vários espaços sem
repetir o texto.

## Escopo

- Um termo tem um título e um texto.
- Administradores listam, cadastram, visualizam, editam e excluem termos em `/admin/usage_terms`.
- A página inicial da área administrativa oferece acesso ao cadastro de termos.
- Popular o banco de desenvolvimento local cria um termo de exemplo.

Na interface, o cadastro se chama "Termos de uso" e cada item, "Termo de uso". A página pública
`/termos-de-uso`, com os termos de uso do próprio sistema, é outra coisa e não muda.

## Atores

- **Visitante:** não autenticado.
- **Usuário comum:** autenticado, sem perfil de administrador.
- **Administrador:** autenticado, com perfil de administrador.

## Histórias de usuário

- Como administrador, quero cadastrar o termo de um laboratório uma vez, para depois indicá-lo em todos
  os espaços que seguem as mesmas regras.
- Como administrador, quero escrever o texto com parágrafos, listas e destaques, e lê-lo como foi escrito.
- Como administrador, quero corrigir o texto de um termo e saber que a correção vale para todos os
  espaços que o usam.
- Como administrador, quero excluir um termo cadastrado por engano.
- Como administrador, quero ser avisado quando tento cadastrar um termo com um título que já existe.

## Requisitos funcionais

1. **RF1 — Listagem.** `/admin/usage_terms` mostra todos os termos em ordem alfabética de título. Cada
   termo mostra só o título, que leva à página do termo, e as ações de ver, editar e excluir. A página tem
   uma ação para cadastrar um novo termo. Sem termos cadastrados, a página informa que não há termos.
2. **RF2 — Cadastro.** Um formulário com os campos Título e Texto cria o termo. O campo Texto é o editor
   de texto rico do Action Text (Trix), com negrito, itálico, tachado, links, títulos, citações, listas e
   recuo. Com dados válidos, o administrador vai para a página do termo criado e vê uma mensagem de
   confirmação.
3. **RF3 — Visualização.** A página do termo mostra o título e o texto com a formatação feita no editor:
   parágrafos, quebras de linha, listas e destaques. O HTML do texto passa pelo sanitizador do Action
   Text: scripts, atributos de evento (`onclick`) e links `javascript:` são removidos e nada é executado.
   A página tem as ações de editar e excluir.
4. **RF4 — Edição.** O mesmo formulário, preenchido com os valores atuais, altera o termo. Com dados
   válidos, o administrador vai para a página do termo e vê uma mensagem de confirmação.
5. **RF5 — Exclusão.** A exclusão, feita pela listagem ou pela página do termo, pede confirmação antes
   de acontecer. Confirmada, o termo é removido e o administrador vai para a listagem com uma mensagem de
   confirmação.
6. **RF6 — Dados inválidos.** Com dados inválidos, nada é gravado. O formulário volta com os valores
   digitados e a mensagem de erro junto ao campo.
7. **RF7 — Atalho na área administrativa.** A página inicial de `/admin` exibe um atalho para o cadastro
   de termos, ao lado dos atalhos de campi, blocos e departamentos.
8. **RF8 — Hierarquia e navegação.** A listagem, o cadastro, a visualização e a edição mostram título,
   subtítulo e a trilha de navegação, como as páginas de campi: Dashboard › Área administrativa › Termos
   de uso, mais Novo, o título do termo, ou o título do termo › Editar.
9. **RF9 — Celular.** As páginas do cadastro funcionam no celular desde 320 px de largura: a listagem, a
   página do termo e o formulário cabem na tela sem rolagem horizontal, mesmo com títulos longos e
   palavras ou endereços longos no texto, que quebram em mais de uma linha. A barra de ferramentas do
   editor rola para o lado dentro dela mesma, sem rolar a página. As ações continuam fáceis de tocar. O
   formulário ocupa toda a largura disponível.
10. **RF10 — Termo local.** Popular o banco de desenvolvimento local cria um termo de exemplo, com
    parágrafos e uma lista numerada, para um laboratório de informática, além do que já cria hoje.

## Regras de negócio

- **RN1 — Título obrigatório.** Um título vazio, ou só com espaços, é recusado com a mensagem
  "Informe o título do termo."
- **RN2 — Espaços do título normalizados.** Antes de validar e gravar, os espaços das pontas do título
  são removidos e espaços repetidos viram um só: `"  Termo   do Laboratório "` é gravado como
  `"Termo do Laboratório"`.
- **RN3 — Título único.** Não podem existir dois termos com o mesmo título, sem diferenciar maiúsculas e
  minúsculas: `"Termo do Laboratório"` e `"termo do laboratório"` são o mesmo título. O título repetido
  é recusado com a mensagem "Já existe um termo cadastrado com este título." É a unicidade padrão do
  Rails (`uniqueness: { case_sensitive: false }`) com um índice único em `LOWER(title)`, como o
  professor definiu em 2026-11-03. Acentos, espaços e pontuação diferentes contam como títulos
  diferentes, e o `LOWER()` do SQLite só converte letras sem acento: `"Á"` e `"á"` são diferentes.
- **RN4 — Texto obrigatório.** Um texto vazio, ou só com espaços e linhas em branco, é recusado com a
  mensagem "Informe o texto do termo."
- **RN5 — Texto preservado.** O texto é gravado como o editor o produz, com a formatação, os parágrafos
  e as quebras de linha.
- **RN6 — Grafia do título preservada.** O título é gravado com as maiúsculas, os acentos e a pontuação
  digitados, com os espaços normalizados (RN2).
- **RN7 — Edição.** A edição segue as mesmas regras. Um termo não conflita com ele mesmo: salvar sem
  alterar o título, ou só trocando maiúsculas e minúsculas, é válido.
- **RN8 — Termo compartilhado.** Um termo é um registro só. Alterar o título ou o texto vale para todos
  os espaços que o usarem; não há cópia por espaço nem histórico de versões.
- **RN9 — Exclusão livre.** Nesta Issue, qualquer termo pode ser excluído. O bloqueio da exclusão de
  termos com espaços vinculados entra na #61, que cria o vínculo.
- Todo texto de interface é traduzido em português do Brasil.

## Regras de acesso

- Seguem as regras da #55: somente administradores acessam o cadastro.
- A permissão é verificada no servidor em todo endereço e ação do cadastro, inclusive nos envios de
  formulário e na exclusão feitos diretamente, sem passar pela tela.
- Um usuário comum recebe HTTP 403 em qualquer endereço ou ação do cadastro, inclusive na página de um
  termo, e nenhum dado é alterado.
- Um visitante é direcionado para a página de autenticação, e nenhum dado é alterado.
- Um endereço de termo inexistente responde como página não encontrada (HTTP 404).
- A página de acesso negado não mostra a trilha da área administrativa.

## Critérios de aceitação

| ID | Critério (da Issue) | Requisitos e regras |
| --- | --- | --- |
| CA1 | Administradores conseguem listar, cadastrar, visualizar, editar e excluir termos. | RF1–RF9, RN8, RN9 |
| CA2 | O cadastro sem título ou sem texto é recusado com mensagem de erro. | RF6, RN1, RN4 |
| CA3 | O cadastro de um título já existente é recusado. | RF6, RN2, RN3, RN6, RN7 |
| CA4 | A visualização mantém as quebras de linha e os parágrafos do texto. | RF2, RF3, RN5 |
| CA5 | Usuários comuns recebem HTTP 403 e usuários não autenticados são direcionados para a autenticação. | Regras de acesso |
| CA6 | O `populate` cria um termo de exemplo no ambiente local. | RF10 |
| CA7 | Existem testes automatizados para as validações e o controle de acesso. | Todos |

## Cenários

### Positivos

- Um administrador abre a área administrativa, segue o atalho de termos e vê a listagem em ordem
  alfabética de título.
- Um administrador cadastra "Termo de uso do laboratório de química" com um trecho em negrito, vai para
  a página do termo, vê o trecho em negrito e uma mensagem de confirmação.
- Um administrador toca no título de um termo na listagem e abre a página do termo.
- Um administrador edita o texto de um termo pela página do termo, troca-o por uma lista numerada,
  salva, volta para a página do termo e vê a lista, com mensagem de confirmação.
- Um administrador exclui um termo pela página do termo, confirma, vai para a listagem e não vê mais o
  termo, com mensagem de confirmação.
- Depois de popular o banco local, a listagem mostra o termo de exemplo, e a página dele mostra
  parágrafos e uma lista numerada.
- Na edição, a trilha mostra "Dashboard › Área administrativa › Termos de uso › <título do termo> ›
  Editar"; tocar em "Termos de uso" volta para a listagem, e tocar no título volta para a página do termo.
- Num celular de 320 px, o administrador vê a listagem, a página do termo e o formulário sem rolar para
  o lado, mesmo com um título longo ou um endereço longo no texto.

### Negativos

- Cadastrar com o título vazio mostra o formulário de novo, com erro no campo Título e o texto digitado
  mantido, e nada é gravado.
- Cadastrar com o texto vazio mostra o formulário de novo, com erro no campo Texto e o título digitado
  mantido, e nada é gravado.
- Com "Termo do Laboratório" cadastrado, cadastrar "termo do laboratório" é recusado com erro de título
  já em uso.
- Editar um termo para o título de outro termo existente é recusado com erro de título já em uso.
- Um texto enviado com `<script>`, `onclick` ou um link `javascript:` aparece na página do termo sem
  eles, e nada é executado.
- Um usuário comum abre `/admin/usage_terms`, a página de um termo, o formulário de cadastro ou o de
  edição e recebe HTTP 403.
- Um usuário comum envia um cadastro, uma edição ou uma exclusão diretamente e recebe HTTP 403, sem
  alteração nos dados.
- Um visitante abre ou envia qualquer endereço do cadastro e é direcionado para a autenticação, sem
  alteração nos dados.
- Desistir na confirmação de exclusão mantém o termo.
- Um usuário comum que recebe 403 não vê a trilha da área administrativa.

### Limite

- Um título só com espaços é tratado como vazio e recusado.
- Um texto só com espaços e linhas em branco é tratado como vazio e recusado.
- Com "Termo do Laboratório" cadastrado, cadastrar `"  termo do laboratório "` é recusado (normalizado
  e comparado sem diferenciar maiúsculas).
- Corrigir o mesmo termo de "Termo da quadra" para "TERMO DA QUADRA" é aceito.
- Sem nenhum termo cadastrado, a listagem mostra a mensagem de lista vazia.
- Um administrador abre a página ou a edição de um termo que não existe e recebe HTTP 404.

## Fora do escopo

- Vincular termos a espaços e indicar se o termo é obrigatório por espaço (#61, "Cadastro de espaços").
- Bloqueio da exclusão de termos com espaços vinculados (#61).
- Exibir o termo e registrar o aceite durante a reserva (contexto de reservas).
- Histórico de versões dos termos.
- Regras próprias para anexos no texto. O editor mantém o botão de anexo padrão do Action Text.
- A página pública `/termos-de-uso`, com os termos do próprio sistema.
- Criar termos fora do ambiente local de desenvolvimento (por exemplo, dados iniciais de produção).
- Busca, filtros e paginação na listagem.
