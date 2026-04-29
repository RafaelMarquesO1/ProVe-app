# Guia de Cores Tema-Adaptáveis

## Visão Geral

O aplicativo ProVê agora possui um sistema centralizado de cores adaptáveis ao tema claro/escuro. Use a classe `ThemeColors` para garantir que as cores se adaptem corretamente em ambos os modos.

## Classe ThemeColors

Localizada em `lib/utils/theme_colors.dart`, fornece métodos estáticos para obter cores tema-adaptáveis:

### Métodos Disponíveis

#### 1. **Overlays de Surface**
```dart
ThemeColors.getSurfaceOverlay(context, opacity: 0.04)
```
- Retorna uma cor semi-transparente (branca em modo escuro, preta em modo claro)
- Use para backgrounds leves em cards e containers
- Padrão: 4% de opacidade

#### 2. **Divisores e Borders**
```dart
ThemeColors.getDividerColor(context)
```
- Retorna uma cor de divisão tema-adaptável
- Use em separadores, borders, e linhas

#### 3. **Texto Secundário**
```dart
ThemeColors.getSecondaryTextColor(context, opacity: 0.7)
```
- Texto com opacidade reduzida (70% por padrão)
- Use em subtítulos e texto menos importante

#### 4. **Texto Terciário**
```dart
ThemeColors.getTertiaryTextColor(context, opacity: 0.5)
```
- Texto ainda mais fraco (50% por padrão)
- Use em hints e labels pequenos

#### 5. **Ícones Secundários**
```dart
ThemeColors.getSecondaryIconColor(context)
```
- Cor para ícones não-primários

#### 6. **Background de Cards**
```dart
ThemeColors.getCardBackground(context)
```
- Retorna a cor apropriada para cards (branco em modo claro, #1C1C1E em escuro)

#### 7. **Background Leve**
```dart
ThemeColors.getLightBackground(context)
```
- Cor para backgrounds leves (Colors.grey.shade50 em claro, #2A2A2C em escuro)

#### 8. **Cores de Shimmer (Loading)**
```dart
ThemeColors.getShimmerColors(context)
```
- Retorna uma lista de 3 cores para gradiente de shimmer
- Use em animações de carregamento

#### 9. **Cor Desabilitada**
```dart
ThemeColors.getDisabledColor(context)
```
- Cor para elementos desabilitados/inativos

#### 10. **Sombras**
```dart
ThemeColors.getCardShadow(context, opacity: 0.04)
ThemeColors.getElevatedShadow(context)
```
- Sombras tema-adaptáveis
- Use em `boxShadow` de containers e cards

## Exemplos de Uso

### Exemplo 1: Container com Overlay
```dart
Container(
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: ThemeColors.getSurfaceOverlay(context),
    borderRadius: BorderRadius.circular(16),
  ),
  child: Text('Conteúdo aqui'),
)
```

### Exemplo 2: Divisor Tema-Adaptável
```dart
Container(
  width: 1,
  height: 24,
  color: ThemeColors.getDividerColor(context),
)
```

### Exemplo 3: Card com Sombra
```dart
Container(
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: ThemeColors.getCardBackground(context),
    borderRadius: BorderRadius.circular(16),
    boxShadow: [ThemeColors.getCardShadow(context)],
  ),
  child: Text('Card'),
)
```

### Exemplo 4: Shimmer (Loading)
```dart
Container(
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(8),
    gradient: LinearGradient(
      colors: ThemeColors.getShimmerColors(context),
      stops: const [0.0, 0.5, 1.0],
    ),
  ),
)
```

## Cores do Tema Principal

### Material 3 ColorScheme
Para cores primárias, use sempre `Theme.of(context).colorScheme`:
```dart
colorScheme.primary          // Cor primária (laranja)
colorScheme.secondary        // Cor secundária
colorScheme.error            // Cor de erro
colorScheme.onSurface        // Texto/elementos sobre surface
colorScheme.onPrimary        // Texto/elementos sobre primary
```

### Paleta de Cores do App
- **Primary**: `Color.fromRGBO(224, 159, 62, 1)` (Laranja)
- **Light Background**: `Color(0xFFFFF9F0)`
- **Dark Background**: `Color(0xFF121212)`
- **Dark Card**: `Color(0xFF1C1C1E)`

## Boas Práticas

1. **Nunca** use cores hardcoded como `Colors.white`, `Colors.black`, ou `Colors.grey.shade*` para backgrounds
2. **Sempre** use `ThemeColors` ou `colorScheme` para manter consistência
3. Para novos components, verifique se `ThemeColors` já possui um método apropriado
4. Se precisar de uma nova cor adaptável, adicione um método em `ThemeColors`
5. Use `.withValues(alpha: ...)` em vez de `.withOpacity()` (mais eficiente)

## Testando o Tema Escuro

1. Abra o menu (engrenagem)
2. Toque em "Tema escuro" para ativar/desativar
3. Verifique se todos os elementos se adaptam corretamente

## Troubleshooting

### Cores não se adaptam ao tema?
- Verifique se está usando `Theme.of(context)` ou `ThemeColors`
- Se usar valor hardcoded, mude para usar `ThemeColors` ou `colorScheme`

### Texto fica ilegível no modo escuro?
- Use cores de `colorScheme` ou `ThemeColors` em vez de hardcoded

### Sombras desaparecem em modo escuro?
- Use `ThemeColors.getCardShadow()` ou `ThemeColors.getElevatedShadow()`
- Nunca use `Colors.black.withOpacity()` para sombras
