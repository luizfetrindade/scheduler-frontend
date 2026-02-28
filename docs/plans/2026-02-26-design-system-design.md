# Flutter Base App Design System — Design

**Date:** 2026-02-26
**Status:** Approved

## Summary

Design system para o Flutter Base App usando a Abordagem 1 (Tokens + Componentes isolados). Identidade visual dark & vibrante com accent roxo. Componentes: BaseButton (4 variantes), BaseInputField (completo), BaseCard (genérico).

---

## Estrutura de Arquivos

```
lib/
└── design_system/
    ├── base_design_system.dart
    ├── tokens/
    │   ├── app_colors.dart
    │   ├── app_typography.dart
    │   ├── app_spacing.dart
    │   ├── app_radius.dart
    │   └── app_shadows.dart
    └── components/
        ├── button/
        │   ├── base_button.dart
        │   └── base_button_variant.dart
        ├── input/
        │   └── base_input_field.dart
        └── card/
            └── base_card.dart
```

---

## Tokens

### Cores (`AppColors`)

| Token | Hex | Uso |
|---|---|---|
| `background` | `#0D0D0D` | Fundo principal |
| `surface` | `#1A1A1A` | Cards, inputs |
| `surfaceHigh` | `#242424` | Elementos elevados |
| `purple300` | `#C084FC` | Hover / estados leves |
| `purple500` | `#A855F7` | Accent principal |
| `purple700` | `#7E22CE` | Pressed |
| `textPrimary` | `#F5F5F5` | Texto principal |
| `textSecondary` | `#A3A3A3` | Texto secundário |
| `textDisabled` | `#525252` | Texto desabilitado |
| `error` | `#EF4444` | Destructive / erros |
| `success` | `#22C55E` | Sucesso |

### Tipografia (`AppTypography`)

| Token | Size | Weight | Uso |
|---|---|---|---|
| `displayLg` | 32sp | Bold | Títulos de tela |
| `headingMd` | 20sp | SemiBold | Seção / card title |
| `bodyMd` | 16sp | Regular | Texto principal |
| `bodySm` | 14sp | Regular | Labels, hints |
| `caption` | 12sp | Regular | Info secundária |

### Espaçamento (`AppSpacing`)

`xs=4` · `sm=8` · `md=12` · `lg=16` · `xl=24` · `xxl=32` · `xxxl=48`

### Border Radius (`AppRadius`)

`sm=4` · `md=8` · `lg=12` · `xl=16` · `full=999`

---

## Componentes

### BaseButton

**Variantes (`BaseButtonVariant`):**

| Variante | Fundo | Texto/Borda |
|---|---|---|
| `primary` | `purple500` | `textPrimary` |
| `secondary` | transparente | borda + texto `purple500` |
| `ghost` | transparente | texto `purple500`, sem borda |
| `destructive` | `error` | `textPrimary` |

**API:**
```dart
BaseButton(
  label: 'Iniciar Treino',
  onPressed: () {},
  variant: BaseButtonVariant.primary,
  isLoading: false,
  isDisabled: false,
  prefixIcon: Icons.play_arrow,
)
```

### BaseInputField

**API:**
```dart
BaseInputField(
  label: 'E-mail',
  hint: 'seu@email.com',
  controller: _controller,
  errorText: 'E-mail inválido',
  prefixIcon: Icons.email_outlined,
  suffixIcon: Icons.clear,
  isPassword: false,
  isDisabled: false,
  keyboardType: TextInputType.emailAddress,
)
```

### BaseCard

**API:**
```dart
BaseCard(
  child: Column(...),
  padding: AppSpacing.lg,
  onTap: () {},
  elevated: false,
)
```

---

## Testes

| Componente | Cobertura |
|---|---|
| `BaseButton` | Renderiza cada variante · dispara onPressed · mostra loading · não dispara quando disabled |
| `BaseInputField` | Renderiza label/hint · exibe errorText · toggle de visibilidade em senha · não editável quando disabled |
| `BaseCard` | Renderiza child · dispara onTap · sem tap quando onTap é null |
