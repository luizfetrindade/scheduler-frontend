# Navigation Enhancements Design

**Goal:** Elevar a qualidade visual da navegação com floating navbar glassmorphic no mobile e sidebar expansível/retrátil com glass no desktop/web.

**Architecture:** Substituição completa de `_MobileLayout` e `_Sidebar` em `lib/app_shell.dart`. A navbar mobile vira um widget 100% customizado (`_FloatingNavBar`) sobre um `Stack`. A sidebar vira `StatefulWidget` com estado `_expanded`. Ambos usam `BackdropFilter + ImageFilter.blur` para o efeito glass. Nenhuma dependência externa nova.

**Tech Stack:** Flutter, dart:ui (ImageFilter), AnimatedPositioned, AnimatedContainer, AnimatedOpacity, BackdropFilter, ClipRRect.

---

## Mobile — Floating Navbar

### Layout

`_MobileLayout` usa `Stack` em vez de `Scaffold.bottomNavigationBar`:

```
Scaffold(body: Stack([
  child,                                          // conteúdo full-screen
  Positioned(bottom:16, left:16, right:16,
    child: _FloatingNavBar(...))
]))
```

O conteúdo rola por baixo da navbar. O `child` deve ter `padding` inferior suficiente para não ficar escondido — resolvido adicionando `MediaQuery.removePadding` ou `SizedBox(height: 80)` no final da lista.

### `_FloatingNavBar`

```
ClipRRect(borderRadius: 28px)
└── BackdropFilter(ImageFilter.blur(sigmaX:12, sigmaY:12))
    └── Container(
          color: AppColors.surface.withValues(alpha:0.65),
          decoration: border 1px AppColors.surfaceHigh.withValues(alpha:0.5),
          padding: horizontal 8px, vertical 8px,
          height: 64px,
        )
        └── LayoutBuilder → calcula largura de cada item
            └── Stack([
                  AnimatedPositioned(  // pílula deslizante
                    left: selectedIndex * itemWidth + 4,
                    duration: 250ms, curve: easeInOut,
                    child: Container(
                      width: itemWidth - 8, height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.purple700.withValues(alpha:0.5),
                        borderRadius: 22px,
                      ),
                    ),
                  ),
                  Row(items.map(_NavItemButton))  // ícones sobre a pílula
                ])
```

### `_NavItemButton`

- `width: itemWidth`, `height: 48px`
- `AnimatedScale(scale: isSelected ? 1.15 : 1.0, duration: 200ms)`
- `AnimatedDefaultTextStyle` ou `TweenAnimationBuilder<Color>` para cor do ícone
- Ícone ativo: `AppColors.purple300` / Inativo: `AppColors.textSecondary`
- Toque: `GestureDetector.onTap → onSelect(index)`

---

## Desktop — Sidebar Expansível com Glass

### Estado

`_Sidebar` vira `StatefulWidget`:
```dart
bool _expanded = true;
```
Persiste apenas na sessão (não salvo em storage nesta fase).

### Larguras
- Expandida: `220px`
- Retraída: `64px`

### Transição

`AnimatedContainer(duration: 250ms, curve: easeInOut, width: _expanded ? 220 : 64)`

### Glass

```
ClipRect
└── BackdropFilter(ImageFilter.blur(sigmaX:12, sigmaY:12))
    └── Container(color: AppColors.surface.withValues(alpha:0.75))
```

### Toggle

`IconButton` no topo:
- Expandida: `Icons.menu_open` (ou `Icons.chevron_left`) → retrair
- Retraída: `Icons.menu` (ou `Icons.chevron_right`) → expandir

### `_SidebarTile` adaptado

- Expandido: `ListTile(leading: Icon, title: AnimatedOpacity(Text))`
- Retraído: só `Icon` centralizado + `Tooltip(label)`
- O `title` (texto) usa `AnimatedOpacity(opacity: _expanded ? 1 : 0, duration: 150ms)`
- O tile inteiro usa `AnimatedContainer` para padding

### Footer retraído

- Expandido: `CircleAvatar` + nome + botão logout (como hoje)
- Retraído: só `CircleAvatar` centralizado + `Tooltip('Sair')` no avatar para logout

---

## Arquivos Afetados

- `lib/app_shell.dart` — única mudança (refatoração interna de `_MobileLayout` e `_Sidebar`)
- `test/app_shell_test.dart` — atualizar testes que esperam `NavigationBar` nativo

---

## Fora do Escopo

- Persistência do estado collapsed/expanded entre sessões
- Animação de conteúdo (push lateral quando sidebar expande)
- Tooltip automático nos itens mobile
