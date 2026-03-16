# Blueprint do Aplicativo: Sabedoria Diária

## Visão Geral

Este aplicativo, "Sabedoria Diária", foi projetado para ser um companheiro de meditação e estudo focado exclusivamente no livro de Provérbios. A cada dia, o usuário é convidado a ler um capítulo de Provérbios, correspondente ao dia do mês, incentivando um hábito de leitura diária e a busca por sabedoria.

---

## Design e Estilo

O design do aplicativo é limpo, moderno e inspirador, com o objetivo de criar uma experiência de leitura agradável e focada.

- **Paleta de Cores:**
  - **Primária:** Um tom de roxo profundo (`#4A148C`), usado para cabeçalhos, botões e elementos de destaque.
  - **Secundária:** Um laranja/dourado (`#D98F2B`), usado para ícones e marcadores.
  - **Fundo:** Um bege claro (`#F5F5DC`) para a tela de leitura, proporcionando conforto visual.
- **Tipografia:**
  - **`GoogleFonts.lato`**: Usado para o texto do corpo, garantindo legibilidade.
  - **`GoogleFonts.oswald`**: Usado para títulos, conferindo um estilo cláss-ico e forte.
- **Tema:**
  - O tema da aplicação é configurado em `lib/main.dart` e utiliza a paleta de cores e a tipografia definidas.

---

## Arquitetura

O aplicativo segue uma arquitetura simples e organizada, com uma clara separação de responsabilidades.

- **Estrutura de Arquivos:**
  - **`lib/main.dart`**: Ponto de entrada, configuração do tema e do roteador.
  - **`lib/routes.dart`**: Centraliza todas as rotas da aplicação.
  - **`lib/screens`**: Contém todas as telas da aplicação, cada uma em seu próprio arquivo.
  - **`lib/widgets`**: Contém widgets reutilizáveis (atualmente, a navegação inferior).
- **Roteamento:**
  - **`go_router`**: Utilizado para gerenciar a navegação, permitindo rotas aninhadas e uma configuração centralizada.
- **Gerenciamento de Estado:**
  - O estado é gerenciado localmente em cada tela (`StatefulWidget`) devido à simplicidade da aplicação.

---

## Recursos e Funcionalidades

### 1. Autenticação

- **`lib/screens/login_page.dart`**: Tela de login com campos para e-mail e senha.
- **`lib/screens/signup_page.dart`**: Tela de cadastro com campos para nome, e-mail e senha.

### 2. Navegação Principal

- **`lib/widgets/bottom_nav_bar.dart`**: Barra de navegação inferior personalizada.
- **`lib/screens/main_scaffold.dart`**: Estrutura principal que abriga a navegação e as telas principais.

### 3. Telas Principais

- **`lib/screens/home_page.dart`**: A tela inicial, que recebe o usuário com uma mensagem inspiradora, um versículo do dia, e acesso rápido à leitura.
- **`lib/screens/reading_page.dart`**: A tela de leitura, que exibe o capítulo de Provérbios correspondente ao dia do mês.
- **`lib/screens/history_page.dart`**: Um calendário que exibe o histórico de leitura do usuário.
- **`lib/screens/reading_plan_page.dart`**: Uma tela que exibe as metas de leitura e as conquistas do usuário.
- **`lib/screens/menu_page.dart`**: Uma tela de menu com opções de navegação.
- **`lib/screens/edit_profile_page.dart`**: Tela que permite ao usuário editar seu nome, foto e senha.

---

## Plano Atual: Foco em Provérbios

Nesta sessão, o aplicativo foi totalmente reorientado para focar exclusivamente no livro de Provérbios.

### Plano de Ação Concluído:

1.  **Tela de Leitura (`reading_page.dart`):**
    - O conteúdo foi alterado para exibir um capítulo de Provérbios com base no dia do mês.
    - O texto de exemplo foi substituído por versículos reais de Provérbios.

2.  **Tela de Metas (`reading_plan_page.dart`):**
    - A meta "Concluir o livro de Gênesis" foi alterada para "Concluir o livro de Provérbios".
    - A conquista "Gênesis Completo" foi alterada para "Provérbios Completo".

3.  **Tela Inicial (`home_page.dart`):**
    - A mensagem de boas-vindas foi alterada para "Sabedoria Diária".
    - Os cards foram implementados com conteúdo relevante sobre Provérbios.

4.  **Tela de Histórico (`history_page.dart`):**
    - O histórico de leitura foi atualizado para exibir o progresso em Provérbios.

5.  **Atualização do `blueprint.md`:**
    - Este documento foi completamente reescrito para refletir a nova direção do aplicativo.

---

## Plano Atual: Melhorias na Experiência de Leitura

Nesta sessão, o foco é aprimorar a experiência de leitura, adicionando novos recursos à tela de leitura.

### Plano de Ação:

1.  **Leitor de Voz (`reading_page.dart`):**
    - Integração do pacote `flutter_tts` para fornecer funcionalidade de conversão de texto em fala.
    - Adição de um botão à barra de aplicativos para iniciar e parar a leitura do capítulo.
    - O botão mudará seu ícone para refletir o estado atual (reproduzindo/parado).

2.  **Botão "Voltar ao Topo" (`reading_page.dart`):**
    - Adição de um `FloatingActionButton` à tela de leitura.
    - Quando pressionado, o botão rolará suavemente o usuário para o topo do capítulo.

3.  **Atualização do `blueprint.md`:**
    - Este documento será atualizado para refletir os novos recursos e mudanças.