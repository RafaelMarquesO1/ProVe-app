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
  - **`GoogleFonts.oswald`**: Usado para títulos, conferindo um estilo clássico e forte.
- **Tema:**
  - O tema da aplicação é configurado em `lib/main.dart` e utiliza a paleta de cores e a tipografia definidas.
- **Consistência Visual:**
  - As telas principais (`Home`, `Menu`, `Plano de Leitura`) possuem um preenchimento superior padronizado (`padding`) de `72px` para garantir um design coeso e arejado.

---

## Arquitetura

O aplicativo segue uma arquitetura simples e organizada, com uma clara separação de responsabilidades.

- **Estrutura de Arquivos:**
  - **`lib/main.dart`**: Ponto de entrada, configuração do tema e do roteador.
  - **`lib/routes.dart`**: Centraliza todas as rotas da aplicação.
  - **`lib/screens`**: Contém todas as telas da aplicação, cada uma em seu próprio arquivo.
  - **`lib/widgets`**: Contém widgets reutilizáveis.
- **Roteamento:**
  - **`go_router`**: Utilizado para gerenciar a navegação.
- **Gerenciamento de Estado:**
  - **`ReadingSettingsProvider`**: Um Singleton para gerenciar as configurações de leitura.

---

## Recursos e Funcionalidades

### 1. Autenticação e Perfil

- **Telas de Login/Cadastro:** `login_page.dart`, `signup_page.dart`.
- **Edição de Perfil:** `edit_profile_page.dart` para nome, foto e senha.

### 2. Navegação Principal

- **Estrutura com Navegação Inferior:** `main_scaffold.dart` e `bottom_nav_bar.dart`.
- **Telas Principais:** `home_page.dart`, `reading_plan_page.dart`, `menu_page.dart`.

### 3. Experiência de Leitura

- **Leitura Diária:** `reading_page.dart` exibe o capítulo do dia.
- **Leitura em Áudio (Text-to-Speech):**
  - Reprodução do texto com destaque do versículo atual.
  - Seleção de voz **masculina/feminina** e ajuste de **velocidade**.
  - Lógica de seleção de voz robusta e normalização de velocidade para Android.
- **Configurações de Leitura:** `reading_settings_page.dart` para personalizar a experiência (tamanho da fonte, cor de fundo, voz).

### 4. Acompanhamento de Progresso

- **Plano de Leitura:** `reading_plan_page.dart` com calendário e estatísticas de progresso (sequência e total de dias lidos).

---

## Plano Atual: Refinamento da Experiência e Consistência Visual

Nesta sessão, o foco foi refinar a usabilidade do aplicativo, corrigindo falhas na reprodução de áudio e aprimorando a consistência visual da interface.

### Plano de Ação Concluído:

1.  **Correções na Reprodução de Áudio (`reading_page.dart`):**
    - **Seleção de Voz Masculina:** A lógica foi aprimorada para buscar vozes por palavras-chave (ex: "masculino", "homem"), garantindo uma seleção mais precisa.
    - **Normalização da Velocidade (Android):** A velocidade da fala foi ajustada para corresponder à escala do Android, onde `1.0x` agora representa a velocidade normal.
    - **Estabilidade:** A aplicação das configurações de áudio foi simplificada para ocorrer apenas no início da reprodução, aumentando a estabilidade do recurso.

2.  **Consistência Visual e Espaçamento:**
    - Um espaçamento superior (`padding`) foi padronizado em `72px` nas telas de `Home`, `Menu` e `Plano de Leitura`, criando uma experiência visual mais harmoniosa e profissional.

3.  **Atualização do `blueprint.md`:**
    - Este documento foi detalhadamente atualizado para refletir todas as correções e melhorias implementadas.