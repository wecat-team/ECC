---
paths:
  - "**/*.css"
  - "**/*.scss"
  - "**/*.sass"
  - "**/*.less"
  - "**/*.html"
  - "**/*.tsx"
  - "**/*.jsx"
  - "**/*.vue"
  - "**/*.svelte"
---
> File này mở rộng [common/coding-style.md](../common/coding-style.md) với nội dung frontend riêng cho web.

# Coding Style Web

## Tổ chức file

Tổ chức theo tính năng hoặc bề mặt (surface area), không theo loại file:

```text
src/
├── components/
│   ├── hero/
│   │   ├── Hero.tsx
│   │   ├── HeroVisual.tsx
│   │   └── hero.css
│   ├── scrolly-section/
│   │   ├── ScrollySection.tsx
│   │   ├── StickyVisual.tsx
│   │   └── scrolly.css
│   └── ui/
│       ├── Button.tsx
│       ├── SurfaceCard.tsx
│       └── AnimatedText.tsx
├── hooks/
│   ├── useReducedMotion.ts
│   └── useScrollProgress.ts
├── lib/
│   ├── animation.ts
│   └── color.ts
└── styles/
    ├── tokens.css
    ├── typography.css
    └── global.css
```

## CSS Custom Property

Định nghĩa design token dưới dạng biến. Không hardcode lặp lại bảng màu, typography hay khoảng cách:

```css
:root {
  --color-surface: oklch(98% 0 0);
  --color-text: oklch(18% 0 0);
  --color-accent: oklch(68% 0.21 250);

  --text-base: clamp(1rem, 0.92rem + 0.4vw, 1.125rem);
  --text-hero: clamp(3rem, 1rem + 7vw, 8rem);

  --space-section: clamp(4rem, 3rem + 5vw, 10rem);

  --duration-fast: 150ms;
  --duration-normal: 300ms;
  --ease-out-expo: cubic-bezier(0.16, 1, 0.3, 1);
}
```

## Thuộc tính chỉ dùng cho Animation

Ưu tiên chuyển động thân thiện với compositor:
- `transform`
- `opacity`
- `clip-path`
- `filter` (dùng hạn chế)

Tránh animate các thuộc tính gắn với layout:
- `width`
- `height`
- `top`
- `left`
- `margin`
- `padding`
- `border`
- `font-size`

## HTML ngữ nghĩa trước tiên

```html
<header>
  <nav aria-label="Main navigation">...</nav>
</header>
<main>
  <section aria-labelledby="hero-heading">
    <h1 id="hero-heading">...</h1>
  </section>
</main>
<footer>...</footer>
```

Đừng dùng các chồng `div` bọc chung chung khi đã có phần tử ngữ nghĩa phù hợp.

## Đặt tên

- Component: PascalCase (`ScrollySection`, `SurfaceCard`)
- Hook: tiền tố `use` (`useReducedMotion`)
- CSS class: kebab-case hoặc utility class
- Animation timeline: camelCase thể hiện ý đồ (`heroRevealTl`)
