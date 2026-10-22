---
name: motion-foundations
description: Motion token, spring preset, quy tắc hiệu năng, thích ứng thiết bị, bắt buộc accessibility và an toàn SSR cho React / Next.js dùng motion/react. Tầng nền tảng — mọi skill motion khác đều phụ thuộc vào nó. Dùng khi thiết lập motion token, spring preset, xử lý reduced-motion, hoặc animation an toàn với SSR trong React hoặc Next.js.
tags: [motion, animation, performance, accessibility]
category: frontend
author: jeff
metadata:
  version: 1.0.0
---

# Motion Foundations

Tầng cơ sở của hệ thống motion. Định nghĩa mọi giá trị, ràng buộc và
quy tắc mà các skill hạ nguồn (`motion-patterns`, `motion-advanced`) kế thừa.
Hãy nạp skill này trước khi bắt đầu bất kỳ công việc animation nào.

## Khi nào kích hoạt

- Bắt đầu bất kỳ component có animation nào từ đầu
- Thiết lập token, spring preset hoặc giá trị easing
- Triển khai hỗ trợ `prefers-reduced-motion`
- Debug hydration mismatch do trạng thái khởi tạo của animation
- Đánh giá xem một animation có nên tồn tại hay không

## Đầu ra

Skill này tạo ra:

- Một đối tượng `motionTokens` dùng chung (duration, easing, distance, scale)
- Một bản đồ preset `springs` dùng chung (5 config có tên)
- Một cổng `shouldAnimate()` được mọi component sử dụng
- Mặc định animation tuân thủ accessibility qua `useReducedMotion`
- Trạng thái khởi tạo an toàn với SSR, không có cảnh báo hydration

## Nguyên tắc

Motion phải thực hiện ít nhất một trong các việc sau, nếu không thì phải bỏ đi:

- Dẫn dắt sự chú ý
- Truyền đạt trạng thái
- Giữ tính liên tục về không gian

Khả năng phản hồi luôn quan trọng hơn độ mượt. Một animation 60 fps gây
trễ đầu vào còn tệ hơn là không có animation.

## Quy tắc

Đây là các quy tắc không thể thương lượng. Chúng áp dụng cho mọi component trong hệ thống.

1. **Chỉ dùng `motion/react`.** Không bao giờ import từ `framer-motion`. Không bao giờ trộn cả hai trong cùng một cây.
2. **`initial` phải khớp với output của server.** Nếu server render `opacity: 1`, thì prop `initial` cũng phải là `opacity: 1`. Không có ngoại lệ.
3. **Reduced motion ghi đè mọi thứ.** Khi `useReducedMotion()` trả về `true` hoặc `prefersReduced` là `true`, mọi transform đều bị vô hiệu hóa. Fade chỉ dùng opacity với thời lượng ≤ 0.2s là phương án thay thế duy nhất được phép.
4. **Không bao giờ animate các thuộc tính layout.** `width`, `height`, `top`, `left`, `margin`, `padding` bị cấm trong `animate`. Chỉ dùng `transform` và `opacity`.
5. **Mọi giá trị token đến từ `motionTokens`.** Cấm hardcode duration và easing trong file component.
6. **Mọi spring config đến từ map `springs`.** Cấm giá trị `stiffness`/`damping` inline.
7. **Bắt buộc có `"use client"`** ở mọi file import từ `motion/react`.
8. **Không bao giờ đọc `window` hoặc `navigator` ở cấp module.** Luôn bảo vệ bằng `typeof window !== "undefined"`.

## Hướng dẫn quyết định

### Chọn duration

| Token | Dùng khi |
| --------- | -------------------------------------------- |
| `instant` | Hiện/ẩn tooltip, focus ring, cập nhật badge |
| `fast` | Phản hồi button, đổi icon, bật/tắt chip |
| `normal` | Mở modal, mở rộng card, phần tử trang xuất hiện |
| `slow` | Hero entrance, chuyển trang toàn phần |
| `crawl` | Kể chuyện có chủ ý; dùng tiết kiệm |

### Chọn spring

| Preset | Dùng khi |
| --------- | ------------------------------------------ |
| `snappy` | UI mặc định — button, chip, mục điều hướng |
| `gentle` | Card, modal, panel hạ cánh nhẹ nhàng |
| `bouncy` | Khoảnh khắc vui tươi — empty state, onboarding |
| `instant` | Tooltip, popover, dropdown |
| `release` | Thả drag — cảm giác vật lý tự nhiên |

### Khi nào tắt hoàn toàn animation

Tắt (cho `shouldAnimate()` trả về `false`) khi:

- `prefersReduced` là `true`
- `isLowEnd` là `true` và animation không thiết yếu
- Phần tử nằm ngoài màn hình và sẽ không bao giờ vào viewport
- Animation thuần trang trí, không có mục đích UX

## Khái niệm cốt lõi

### Hệ thống token

```ts
// lib/motion-tokens.ts
export const motionTokens = {
  duration: {
    instant: 0.08,
    fast:    0.18,
    normal:  0.35,
    slow:    0.6,
    crawl:   1.0,
  },
  easing: {
    smooth: [0.22, 1, 0.36, 1],
    sharp:  [0.4, 0, 0.2, 1],
    bounce: [0.34, 1.56, 0.64, 1],
    linear: [0, 0, 1, 1],
  },
  distance: {
    xs: 4,
    sm: 8,
    md: 16,
    lg: 24,
    xl: 48,
  },
  scale: {
    subtle: 0.98,
    press:  0.95,
    pop:    1.04,
  },
}

export const springs = {
  snappy:  { type: "spring", stiffness: 300, damping: 30 },
  gentle:  { type: "spring", stiffness: 120, damping: 14 },
  bouncy:  { type: "spring", stiffness: 400, damping: 10 },
  instant: { type: "spring", stiffness: 600, damping: 35 },
  release: { type: "spring", stiffness: 200, damping: 20, restDelta: 0.001 },
}
```

### Runtime flag

```ts
// lib/motion-config.ts
export const motionConfig = {
  isLowEnd() {
    return (
      typeof navigator !== "undefined" &&
      navigator.hardwareConcurrency <= 4
    )
  },

  prefersReduced() {
    return (
      typeof window !== "undefined" &&
      window.matchMedia("(prefers-reduced-motion: reduce)").matches
    )
  },

  shouldAnimate({ essential = false } = {}) {
    if (this.prefersReduced()) return false
    if (!essential && this.isLowEnd()) return false
    return true
  },

  duration() {
    return this.isLowEnd() || this.prefersReduced()
      ? motionTokens.duration.instant
      : motionTokens.duration.normal
  },
}
```

### Accessibility

**Thứ tự ưu tiên (cao đến thấp):**

1. `prefers-reduced-motion: reduce` — vô hiệu hóa mọi transform, giới hạn transition opacity ≤ 0.2s
2. Phát hiện thiết bị cấu hình thấp — giảm duration, bỏ các animation không thiết yếu
3. Ưu tiên thiết kế — mọi thứ còn lại

Motion phải suy giảm một cách êm ái. Nó không bao giờ được biến mất đột ngột theo cách
gây layout shift hoặc làm rối định hướng.

```tsx
// hooks/use-reduced-motion.tsx
"use client"
import { useReducedMotion } from "motion/react"

export function useSafeMotion(fullY: number = 16) {
  const reduce = useReducedMotion()
  return {
    initial: { opacity: 0, y: reduce ? 0 : fullY },
    animate: { opacity: 1, y: 0 },
    exit:    { opacity: 0, y: reduce ? 0 : -fullY },
  }
}
```

```css
/* globals.css */
@media (prefers-reduced-motion: reduce) {
  .motion-safe-transition  { transition: opacity 0.15s; }
  .motion-reduce-transform { transform: none !important; }
}
```

```html
<!-- Tailwind -->
<div class="motion-safe:animate-fade motion-reduce:opacity-100"></div>
```

### An toàn SSR / hydration

**Quy tắc: `initial` phải luôn khớp với những gì server render.**

```tsx
// WRONG — server renders opacity:1 but initial says 0 → hydration mismatch
<motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} />

// CORRECT — use AnimatePresence or defer to client mount
"use client"
const [mounted, setMounted] = useState(false)
useEffect(() => setMounted(true), [])

<motion.div
  initial={{ opacity: mounted ? 0 : 1 }}
  animate={{ opacity: 1 }}
/>
```

## Ví dụ code

### End-to-end: token + spring + accessibility + SSR guard

```tsx
// components/fade-in-card.tsx
"use client"

import { useState, useEffect } from "react"
import { motion } from "motion/react"
import { motionTokens, springs } from "@/lib/motion-tokens"
import { useSafeMotion } from "@/hooks/use-reduced-motion"
import { motionConfig } from "@/lib/motion-config"

interface FadeInCardProps {
  children: React.ReactNode
  delay?: number
}

export function FadeInCard({ children, delay = 0 }: FadeInCardProps) {
  // SSR guard — initial must match server output (opacity: 1)
  const [mounted, setMounted] = useState(false)
  useEffect(() => setMounted(true), [])

  // Accessibility — disables transform when reduced motion is preferred
  const safeMotion = useSafeMotion(motionTokens.distance.md)

  // Device gate — skip animation on low-end hardware
  if (!motionConfig.shouldAnimate() || !mounted) {
    return <div>{children}</div>
  }

  return (
    <motion.div
      initial={safeMotion.initial}
      animate={safeMotion.animate}
      exit={safeMotion.exit}
      transition={{
        ...springs.gentle,
        delay,
      }}
      whileHover={{ scale: motionTokens.scale.pop }}
      whileTap={{ scale: motionTokens.scale.press }}
    >
      {children}
    </motion.div>
  )
}
```

## Ràng buộc / Ngoài phạm vi

Skill này **không** bao gồm:

- Các pattern component UI (button, modal, stagger) → xem `motion-patterns`
- Drag, gesture, SVG, animation chữ, custom hook → xem `motion-advanced`
- Animation chỉ dùng CSS hoặc class `animate-*` của Tailwind mà không có `motion/react`
- Thư viện animation bên thứ ba (GSAP, anime.js, v.v.)
- Quyết định thiết kế motion (khi nào animate, nhấn mạnh gì) — đó là mối quan tâm về thiết kế, không phải ràng buộc code

## Anti-Pattern

| Anti-pattern | Quy tắc bị vi phạm | Cách sửa |
| --------------------------------------- | ------- | ------------------------------- |
| `import { motion } from "framer-motion"` | Quy tắc 1 | Dùng `motion/react` |
| `initial={{ opacity: 0 }}` trên component SSR | Quy tắc 2 | Thêm mount guard |
| Bỏ qua kiểm tra `useReducedMotion` | Quy tắc 3 | Dùng hook `useSafeMotion` |
| `animate={{ width: "100%" }}` | Quy tắc 4 | Dùng transform `scaleX` thay thế |
| `transition={{ duration: 0.4 }}` inline | Quy tắc 5 | Dùng `motionTokens.duration.normal` |
| `{ stiffness: 300, damping: 30 }` inline | Quy tắc 6 | Dùng `springs.snappy` |
| Thiếu directive `"use client"` | Quy tắc 7 | Thêm vào đầu file |
| `navigator.hardwareConcurrency` ở cấp module | Quy tắc 8 | Bọc trong `typeof navigator !== "undefined"` |

## Skill liên quan

- **`motion-patterns`** — dùng các token và spring định nghĩa ở đây để xây dựng các pattern button, modal, stagger, page transition và scroll. Không định nghĩa lại bất kỳ giá trị nào.
- **`motion-advanced`** — dùng các token và spring định nghĩa ở đây cho các pattern drag, SVG, chữ và gesture. Bổ sung các chuỗi `useAnimate` và custom hook lên trên nền tảng này.
