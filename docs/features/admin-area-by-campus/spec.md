# Área administrativa organizada por campus — Especificação

Issue: #89 — Protótipos da área administrativa organizada por campus

Status: protótipos aprovados pelo professor em 2026-11-25, junto com as decisões D2 a D7. A
implementação segue estes protótipos e fica para uma Issue nova.

Protótipos: abra [`prototypes/index.html`](prototypes/index.html) no navegador. Não precisa de
servidor nem de internet.

## Objetivo

Organizar a área administrativa a partir das tarefas de quem a usa, e não dos cadastros. Hoje a
entrada lista seis cadastros soltos (campi, blocos, espaços, departamentos, termos de uso e
usuários), e quase todos pedem o campus em algum campo. Com a administração por campus (#93), cada
pessoa cuida de um campus, então o campus passa a ser o ponto de partida da navegação.

## Perfis

- **Administrador geral:** usuário com o perfil de administrador da #55. Cuida de todos os campi,
  dos cadastros que valem para todos e de quem administra cada campus.
- **Administrador de campus:** usuário que recebeu a administração de um ou mais campi (#93). Cuida
  dos blocos, espaços, departamentos e termos de uso desses campi.

## Organização proposta

```text
Área administrativa (/admin)
├── Campi: um cartão por campus, com o resumo e o botão "Gerenciar"
│   └── Página do campus (/admin/campi/:id)          menu lateral do campus
│       ├── Visão geral
│       ├── Espaços        listagem, cadastro, página do espaço
│       ├── Blocos
│       ├── Departamentos  (#90)
│       ├── Termos de uso  (#91)
│       └── Administradores (#93, só o administrador geral)
└── Cadastros gerais (só o administrador geral)
    └── Usuários
```

- Dentro de um campus, o menu lateral mostra só as opções daquele campus, com um seletor no topo
  para trocar de campus sem voltar à entrada.
- O campus vem da página, então os formulários de bloco, espaço, departamento e termo de uso não
  pedem o campus. Isso já resolve a #92: o campus de um bloco é o da página em que ele foi
  cadastrado.
- As listas dos formulários (blocos, departamentos e termos de uso) trazem só os registros do
  campus, então o formulário de espaço não precisa mais filtrar os blocos pelo campus escolhido.

## Tarefas e fluxos

Cada fluxo diz quem faz, o objetivo, como começa, as ações, as regras e o resultado. Os nomes das
telas são os dos protótipos.

### Administrador geral

**G1. Colocar um novo campus em uso**

- **Objetivo:** que outro campus passe a usar o sistema, com responsáveis próprios.
- **Início:** Entrada › "Cadastrar campus".
- **Ações:** informa o nome do campus e salva; no cartão do novo campus, escolhe "Definir
  administradores", busca o usuário e escolhe "Adicionar".
- **Regras:** o nome do campus é único. Um campus pode ter mais de um administrador.
- **Resultado:** o campus aparece na entrada. Enquanto não tiver administradores, o cartão avisa
  "Sem administradores. Por enquanto, só o administrador geral gerencia este campus."

**G2. Definir ou remover os administradores de um campus**

- **Objetivo:** dar ou tirar de alguém a responsabilidade por um campus.
- **Início:** Entrada › campus › menu "Administradores", ou "Gerenciar" no quadro de
  administradores da visão geral.
- **Ações:** para adicionar, busca pelo nome ou pelo e-mail e escolhe "Adicionar". Para remover,
  escolhe "Remover" e confirma.
- **Regras:** só aparecem usuários já cadastrados. Remover a administração não remove o usuário, que
  continua com acesso ao sistema.
- **Resultado:** a lista de administradores atuais é atualizada, com o aviso "Ana Paula Ribeiro
  agora administra o campus Guarapuava." ou equivalente.

**G3. Gerenciar os usuários**

- **Início:** Entrada › Cadastros gerais › Usuários.
- **Observação:** a tela de usuários continua como está. A mudança dela (LDAP, status, listagem)
  fica para a Issue de usuários.

**G4. Cuidar de qualquer campus**

- **Início:** Entrada › "Gerenciar <campus>".
- **Ações:** as mesmas do administrador de campus (C1 a C6), em qualquer campus.

### Administrador de campus

**C1. Disponibilizar um espaço para reserva**

- **Objetivo:** que uma sala, laboratório ou outro espaço possa ser reservado.
- **Início:** página do campus › "Cadastrar" no resumo de espaços, ou Espaços › "Novo espaço".
- **Ações:** escolhe o bloco (ou "Sem bloco"), informa nome e descrição, escolhe o departamento
  responsável, se precisa de aprovação e o termo de uso, e salva.
- **Regras:** nome e descrição são obrigatórios. Bloco, departamento e termo de uso são do campus
  da página. As dicas de cada campo explicam quem libera as reservas e quem precisa aceitar o termo.
- **Resultado:** volta para a listagem com o aviso "Espaço cadastrado com sucesso." Com erro, o
  formulário continua preenchido e cada campo mostra a mensagem, como "Informe o nome do espaço."

**C2. Cadastrar um bloco antes dos espaços dele**

- **Início:** página do campus › "Cadastrar" no resumo de blocos, ou Blocos › "Novo bloco".
- **Ações:** informa o nome e salva.
- **Regras:** o campus é o da página e não muda depois (#92).
- **Resultado:** o bloco passa a aparecer no formulário de espaço daquele campus.

**C3. Tirar um espaço de uso por um tempo ou de vez**

- **Início:** Espaços › espaço › "Marcar como indisponível" ou "Desativar".
- **Regras:** as da gestão de espaços (#61): o indisponível continua na reserva com o motivo; o
  desativado sai da reserva.
- **Resultado:** o espaço indisponível aparece no quadro "Espaços indisponíveis" da visão geral até
  voltar a ficar disponível.

**C4. Cadastrar os departamentos que respondem pelos espaços**

- **Início:** página do campus › "Cadastrar" no resumo de departamentos, ou Departamentos › "Novo
  departamento".
- **Regras:** as da #90: o nome é único dentro do campus.
- **Resultado:** o departamento passa a aparecer no formulário de espaço daquele campus.

**C5. Publicar um termo de uso e ligá-lo aos espaços**

- **Início:** página do campus › Termos de uso › "Novo termo de uso".
- **Ações:** informa título e conteúdo e salva; depois, edita cada espaço e escolhe o termo.
- **Regras:** as da #91: o título é único dentro do campus.
- **Resultado:** quem reservar esses espaços precisa aceitar o termo.

**C6. Ver o que precisa de atenção**

- **Início:** página do campus (visão geral).
- **Resultado:** o resumo de cada cadastro, os espaços indisponíveis com o motivo e os
  administradores do campus.

## Telas prototipadas

| Tela | Arquivo | Critério da #89 |
| --- | --- | --- |
| Entrada na área administrativa | `prototypes/admin.html` | entrada na área administrativa |
| Página do campus | `prototypes/campus.html` | página de um campus com o menu lateral |
| Espaços do campus | `prototypes/campus-espacos.html` | uma listagem |
| Novo espaço, com e sem erros | `prototypes/campus-espaco-novo.html` | um formulário |
| Administradores do campus | `prototypes/campus-administradores.html` | apoio à #93 |

Todas as telas funcionam em tela grande e no celular a partir de 320 px. A barra do protótipo troca
o perfil e abre a tela numa moldura de celular (`prototypes/celular.html`), com larguras de 320,
360 e 390 px.

As telas de blocos, departamentos e termos de uso não foram prototipadas: seguem o padrão da
listagem e do formulário de espaços, sem o campo Campus.

## Decisões

As propostas D2 a D7 foram aprovadas junto com os protótipos em 2026-11-25.

| # | Pergunta | Decisão |
| --- | --- | --- |
| D1 | Em que ferramenta fazer os protótipos? | Decidido: HTML, a pedido do professor Marczal em 2026-11-19. |
| D2 | Onde ficam os cadastros que não pertencem a um campus? | Os campi ficam na própria entrada; os usuários, em "Cadastros gerais". Os dois só para o administrador geral. |
| D3 | Quem administra um só campus passa pela entrada? | Não: "Área administrativa" abre direto a página do campus. |
| D4 | Um usuário pode administrar mais de um campus? (#93) | Sim. O seletor do menu lateral mostra só os campi dele. |
| D5 | O administrador de campus define outros administradores? (#93) | Não, só o administrador geral. Pela URL, recebe acesso negado (HTTP 403). |
| D6 | A listagem de espaços ganha filtros? | Sim: nome, bloco e situação. |
| D7 | O que mais a visão geral do campus deve mostrar? | Por enquanto, o resumo dos cadastros, os espaços indisponíveis e os administradores. |

## Checklist de usabilidade

- [x] A pessoa entende o que fazer sem ajuda: a entrada pede para escolher o campus, e cada resumo
  da visão geral tem "Ver todos" e "Cadastrar".
- [x] A informação aparece no momento certo: as dicas dos campos dizem quem libera as reservas e
  que as listas são só do campus.
- [x] Os erros são evitados e as restrições explicadas: o campus não pode ser escolhido errado
  porque vem da página; um campus sem administradores avisa quem o gerencia; a exclusão de um campus
  com cadastros explica o motivo.
- [x] Sem passos desnecessários: o formulário de espaço perdeu o campo Campus e o filtro de blocos;
  quem administra um só campus entra direto nele (D3).
- [x] Consistente com o resto do sistema: mesmo cabeçalho, trilha de navegação, botões, tabela que
  vira lista no celular e mensagens das telas atuais.
- [x] Os protótipos foram aprovados (2026-11-25).

## Fora do escopo

- Implementação do novo layout, que fica para uma Issue aberta depois da aprovação.
- Mudanças no modelo de dados (#90, #91, #92 e #93 cuidam delas).
- Fluxo de liberação das reservas.

## Como alterar os protótipos

As telas são HTML estático com o CSS do sistema. Depois de mudar as classes de alguma tela, gere o
CSS de novo na raiz do projeto:

```sh
bundle exec tailwindcss -i docs/features/admin-area-by-campus/prototypes/assets/prototype.tailwind.css \
  -o docs/features/admin-area-by-campus/prototypes/assets/prototype.css --minify
```

`prototypes/assets/prototype.js` só simula o necessário para navegar: perfil, notas, menu no
celular, filtros, avisos e a moldura de celular.
