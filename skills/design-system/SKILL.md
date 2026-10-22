---
name: design-system
description: "Sinh design system từ codebase hiện có hoặc audit tính nhất quán thị giác: trích xuất token (màu sắc, typography, spacing, shadow) vào design-tokens.json và CSS custom properties kèm DESIGN.md giải thích lý do và bản xem trước HTML tương tác, chấm điểm UI trên 10 chiều, và gắn cờ các pattern AI-slop. Dùng khi bắt đầu một design system, audit tính nhất quán thị giác trước khi redesign, hoặc review PR có chạm tới styling."
metadata:
  origin: ECC
---

# Design System — Sinh & Audit hệ thống thị giác

## Khi nào dùng

- Bắt đầu dự án mới cần một design system
- Audit codebase hiện có về tính nhất quán thị giác
- Trước khi redesign — hiểu rõ những gì đang có
- Khi UI trông "lệch" nhưng không chỉ ra được vì sao
- Review các PR có chạm tới styling

## Cách hoạt động

### Chế độ 1: Sinh Design System

Phân tích codebase và sinh ra một design system gắn kết:

```
1. Scan CSS/Tailwind/styled-components for existing patterns
2. Extract: colors, typography, spacing, border-radius, shadows, breakpoints
3. Research 3 competitor sites for inspiration (via browser MCP)
4. Propose a design token set (JSON + CSS custom properties)
5. Generate DESIGN.md with rationale for each decision
6. Create an interactive HTML preview page (self-contained, no deps)
```

Đầu ra: `DESIGN.md` + `design-tokens.json` + `design-preview.html`

### Chế độ 2: Visual Audit

Chấm điểm UI trên 10 chiều (mỗi chiều 0-10):

```
1. Color consistency — are you using your palette or random hex values?
2. Typography hierarchy — clear h1 > h2 > h3 > body > caption?
3. Spacing rhythm — consistent scale (4px/8px/16px) or arbitrary?
4. Component consistency — do similar elements look similar?
5. Responsive behavior — fluid or broken at breakpoints?
6. Dark mode — complete or half-done?
7. Animation — purposeful or gratuitous?
8. Accessibility — contrast ratios, focus states, touch targets
9. Information density — cluttered or clean?
10. Polish — hover states, transitions, loading states, empty states
```

Mỗi chiều nhận một điểm số, các ví dụ cụ thể và một cách sửa kèm file:line chính xác.

### Chế độ 3: Phát hiện AI Slop

Nhận diện các pattern thiết kế chung chung do AI sinh ra:

```
- Gratuitous gradients on everything
- Purple-to-blue defaults
- "Glass morphism" cards with no purpose
- Rounded corners on things that shouldn't be rounded
- Excessive animations on scroll
- Generic hero with centered text over stock gradient
- Sans-serif font stack with no personality
```

## Ví dụ

**Sinh cho một ứng dụng SaaS:**
```
/design-system generate --style minimal --palette earth-tones
```

**Audit UI hiện có:**
```
/design-system audit --url http://localhost:3000 --pages / /pricing /docs
```

**Kiểm tra AI slop:**
```
/design-system slop-check
```
