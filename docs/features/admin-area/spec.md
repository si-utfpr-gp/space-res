# Acesso à área administrativa — Especificação

Issue: #55 — Acesso do super admin à área administrativa

Status: aprovada em 2026-10-16.

## Objetivo

Oferecer uma área administrativa, restrita a usuários com perfil de administrador, que será o ponto
de entrada para os cadastros e configurações do sistema entregues por Issues posteriores.

## Escopo

- Usuários possuem um indicador de perfil de administrador. Todo usuário é comum, a menos que seja
  explicitamente definido como administrador.
- A área administrativa fica disponível em `/admin` e só é acessível por administradores.
- A página inicial da área administrativa é uma página simples que identifica a área.
- Administradores veem um atalho para a área administrativa no menu lateral da área logada.
- Os dados de desenvolvimento local definem um administrador.

## Atores

- **Visitante:** não autenticado.
- **Usuário comum:** autenticado, sem perfil de administrador.
- **Administrador:** autenticado, com perfil de administrador.

## Histórias de usuário

- Como administrador, quero uma área dedicada para acessar os cadastros e configurações do sistema
  em um só lugar.
- Como administrador, quero um atalho no menu lateral para chegar à área administrativa sem digitar
  o endereço.
- Como usuário comum, não quero ver opções que não posso usar.

## Requisitos funcionais

1. **RF1 — Perfil padrão.** Um usuário recém-criado não é administrador. O perfil está sempre
   definido (nunca vazio).
2. **RF2 — Acesso do administrador.** Um administrador que abre `/admin` vê a página inicial da área
   administrativa.
3. **RF3 — Usuário comum bloqueado.** Um usuário comum que abre qualquer endereço administrativo,
   inclusive digitando a URL diretamente, recebe uma resposta de acesso negado (HTTP 403). A resposta
   é uma página dentro do layout logado, com mensagem traduzida e um link de volta ao Dashboard.
4. **RF4 — Visitante redirecionado.** Um visitante que abre qualquer endereço administrativo é
   direcionado para a página de autenticação.
5. **RF5 — Atalho no menu.** O menu lateral da área logada exibe o item "Área administrativa" somente
   para administradores. Usuários comuns nunca o veem.
6. **RF6 — Administrador local.** Popular o banco de desenvolvimento local cria uma conta de
   administrador (`admin@utfpr.edu.br`) e mantém a conta demo comum existente
   (`demo@utfpr.edu.br`).

## Regras de negócio e autorização

- A verificação de permissão acontece no servidor, em todo endereço e ação administrativos. Esconder
  o item do menu é conveniência, nunca a proteção.
- Novas páginas administrativas criadas por Issues posteriores herdam a mesma restrição sem trabalho
  extra.
- Existe um único nível de administrador, sem permissões mais granulares.
- Nenhuma tela permite que um usuário conceda a si mesmo, ou a outro, o perfil de administrador. Em
  produção, o primeiro administrador é definido manualmente.
- Todo texto de interface é traduzido em português do Brasil.

## Critérios de aceitação

| ID | Critério (da Issue) | Requisito |
| --- | --- | --- |
| CA1 | Novos usuários são criados com `admin = false`. | RF1 |
| CA2 | Administradores autenticados conseguem acessar `/admin`. | RF2 |
| CA3 | Usuários comuns não conseguem acessar a área administrativa, mesmo informando a URL. | RF3 |
| CA4 | Usuários autenticados sem permissão recebem HTTP 403. | RF3 |
| CA5 | Usuários não autenticados são direcionados para a autenticação. | RF4 |
| CA6 | O atalho para a área administrativa aparece somente para administradores. | RF5 |
| CA7 | O `populate` define um usuário administrador no ambiente local. | RF6 |
| CA8 | Existem testes automatizados para as regras de acesso e autorização. | RF1–RF6 |

## Cenários

### Positivos

- Um administrador entra no sistema, vê "Área administrativa" no menu lateral, segue o link e chega
  à página administrativa.
- Um administrador digita `/admin` e chega à página administrativa.
- Depois de popular o banco local, entrar como `admin@utfpr.edu.br` dá acesso a `/admin`.

### Negativos

- Um usuário comum digita `/admin` e recebe HTTP 403 com a página de acesso negado, ainda dentro do
  layout logado, com link de volta ao Dashboard.
- O menu lateral de um usuário comum não contém o item da área administrativa.
- Um visitante digita `/admin` e é redirecionado para a página de autenticação.

### Limite

- Um usuário criado sem informar o perfil é um usuário comum.
- Uma tentativa de gravar o perfil vazio é rejeitada; o usuário é administrador ou não é.
- Depois de popular o banco local, `demo@utfpr.edu.br` continua usuário comum e tem o acesso a
  `/admin` negado.

## Fora do escopo

- Cadastros e funcionalidades da área administrativa (Issues próprias: #56 a #63).
- Gestão de usuários pela interface administrativa (Issue #59, "Gestão de usuários pelo admin").
- Diferentes níveis de permissão administrativa.
- Devolver o usuário ao endereço solicitado originalmente depois do login (hoje o login sempre leva
  ao Dashboard).
