---
name: motion-patterns
description: Các pattern animation sẵn sàng cho production trong React / Next.js — button, modal, toast, stagger, page transition, exit animation, scroll và layout — xây trên token và spring của motion-foundations. Dùng khi animate một phần tử UI cụ thể trong React hoặc Next.js — button, modal, toast, stagger, page transition hoặc scroll.
tags: [motion, animation, ui-patterns]
category: frontend
author: jeff
metadata:
  version: 1.0.0
---

# Motion Patterns

Các pattern copy-paste cho những nhu cầu animation UI phổ biến nhất.
Mọi pattern ở đây đều xây trên token và spring của `motion-foundations`.
Không định nghĩa giá trị duration hoặc easing mới ở đây — hãy import chúng.

## Khi nào kích hoạt

- Animate button, card, modal hoặc toast notification
- Xây dựng hiệu ứng xuất hiện của list với stagger
- Thiết lập page transition trong Next.js App Router
- Thêm animation vào/ra cho nội dung có điều kiện
- Triển khai scroll-reveal, tiến trình liên kết với scroll, hoặc các section sticky story
- Xây dựng card mở rộng, accordion, hoặc shared-element transition

## Đầu ra

Skill này tạo ra:

- Animation accessible, an toàn với SSR cho mọi component UI tiêu chuẩn
- Các render có điều kiện bọc trong `AnimatePresence` với hành vi exit đúng
- Component bọc page transition cho Next.js App Router
- Các pattern scroll-reveal và liên kết với scroll dùng `useScroll` + `useTransform`
- Các pattern layout animation (`layout`, `layoutId`) cho phần tử mở rộng và crossfade

## Nguyên tắc

- Mọi pattern đều import từ `motion-foundations`. Không dùng số thô.
- Mọi render có điều kiện đều bọc trong `AnimatePresence` với một `key`.
- Exit animation luôn được định nghĩa cùng với enter animation — không bao giờ để sau.
- `layout` chỉ dùng cho các dịch chuyển nhỏ, tách biệt. Subtree lớn dùng transform tường minh.

## Quy tắc

1. **Luôn bọc render có điều kiện trong `AnimatePresence` với một `key`** trên phần tử con trực tiếp. Không có key thì exit animation không bao giờ chạy.
2. **Luôn định nghĩa `exit` khi định nghĩa `initial` + `animate`.** Một animation không có exit là chưa hoàn chỉnh.
3. **Dùng `mode="wait"` cho page transition.** Enter không được bắt đầu cho đến khi exit hoàn tất.
4. **Không bao giờ dùng `layout` trên subtree có hơn ~5 phần tử con hoặc DOM lồng sâu.** Hãy dùng transform `x`/`y` tường minh thay thế.
5. **Khoảng stagger phải nằm giữa `0.05s` và `0.10s`.** Thấp hơn cảm giác máy móc; cao hơn cảm giác ì ạch.
6. **Modal luôn phải có:** focus trap, đóng bằng phím Escape, scroll lock, `role="dialog"`, `aria-modal="true"`.
7. **Scroll reveal dùng `viewport={{ once: true }}`.** Lặp lại khi cuộn ra gây xao nhãng, không cung cấp thông tin.
8. **Mọi giá trị token được import từ `motion-foundations`.** Không dùng số inline.

## Hướng dẫn quyết định

### Chọn đúng pattern

| Tình huống | Pattern |
| ---------------------------------------- | ---------------------- |
| Phần tử xuất hiện / biến mất             | `AnimatePresence`      |
| List các mục tải lần lượt        | Stagger variants       |
| Điều hướng giữa các route                | Page transition wrapper|
| Phần tử đổi kích thước tại chỗ            | prop `layout`          |
| Cùng một phần tử di chuyển giữa các ngữ cảnh trang             | `layoutId`             |
| Phần tử xuất hiện khi cuộn vào tầm nhìn   | `whileInView`          |
| Giá trị gắn với vị trí cuộn            | `useScroll` + `useTransform` |

### Khi nào dùng `mode="wait"` so với `mode="sync"`

| Mode | Dùng khi |
| ------- | --------------------------------------- |
| `wait` | Page transition, hoán đổi nội dung (từng cái một) |
| `sync` | Notification xếp chồng, mục list (chồng lên nhau cũng được) |
| `popLayout` | Các mục bị xóa khỏi list có reflow |

## Khái niệm cốt lõi

### Hợp đồng của AnimatePresence

Ba điều phải luôn đúng:

1. `AnimatePresence` bọc lấy phần điều kiện
2. Phần tử con trực tiếp có một `key`
3. Phần tử con có prop `exit`

Thiếu bất kỳ điều nào trong số này thì exit animation sẽ lặng lẽ thất bại.

### layout so với layoutId

- `layout` — animate sự thay đổi kích thước/vị trí của chính phần tử đó tại chỗ
- `layoutId` — liên kết hai phần tử riêng biệt, crossfade giữa chúng qua các lần render

Dùng `layout="position"` cho chữ bên trong container đang mở rộng để ngăn việc reflow chữ bị animate.

## Ví dụ code

### Phản hồi button

```tsx
"use client"
import { motion } from "motion/react"
import { springs, motionTokens } from "@/lib/motion-tokens"

<motion.button
  whileHover={{ scale: motionTokens.scale.pop }}
  whileTap={{ scale: motionTokens.scale.press }}
  transition={springs.snappy}
/>
```

### Stagger list

```tsx
"use client"
import { motion } from "motion/react"
import { motionTokens, springs } from "@/lib/motion-tokens"

const container = {
  hidden: {},
  visible: {
    transition: {
      staggerChildren: 0.08,   // within the 0.05–0.10 rule
      delayChildren: 0.1,
    },
  },
}

const item = {
  hidden:  { opacity: 0, y: motionTokens.distance.md },
  visible: { opacity: 1, y: 0, transition: springs.gentle },
}

<motion.ul variants={container} initial="hidden" animate="visible">
  {items.map((i) => (
    <motion.li key={i.id} variants={item} />
  ))}
</motion.ul>
```

### Modal

```tsx
"use client"
import { motion, AnimatePresence } from "motion/react"
import { motionTokens, springs } from "@/lib/motion-tokens"

// Wrap at the call site:
// <AnimatePresence>{isOpen && <Modal key="modal" />}</AnimatePresence>

export function Modal({ onClose }: { onClose: () => void }) {
  return (
    <>
      {/* Overlay */}
      <motion.div
        className="fixed inset-0 bg-black/50"
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        exit={{ opacity: 0 }}
        onClick={onClose}
      />

      {/* Panel — accessibility requirements: focus trap, Escape close,
          scroll lock, role="dialog", aria-modal="true" */}
      <motion.div
        role="dialog"
        aria-modal="true"
        className="fixed inset-x-4 top-1/2 -translate-y-1/2 rounded-xl bg-white p-6"
        initial={{
          opacity: 0,
          scale: motionTokens.scale.press,
          y: motionTokens.distance.sm,
        }}
        animate={{ opacity: 1, scale: 1, y: 0 }}
        exit={{
          opacity: 0,
          scale: motionTokens.scale.press,
          y: motionTokens.distance.sm,
        }}
        transition={springs.gentle}
      />
    </>
  )
}
```

### Toast stack

```tsx
"use client"
import { motion, AnimatePresence } from "motion/react"
import { motionTokens, springs } from "@/lib/motion-tokens"

<AnimatePresence mode="sync">
  {toasts.map((t) => (
    <motion.div
      key={t.id}
      layout
      initial={{
        opacity: 0,
        x: motionTokens.distance.xl,
        scale: motionTokens.scale.subtle,
      }}
      animate={{ opacity: 1, x: 0, scale: 1 }}
      exit={{
        opacity: 0,
        x: motionTokens.distance.xl,
        scale: motionTokens.scale.subtle,
      }}
      transition={springs.snappy}
    />
  ))}
</AnimatePresence>
```

### Page transition (Next.js App Router)

```tsx
// components/page-transition.tsx
"use client"
import { motion, AnimatePresence } from "motion/react"
import { usePathname } from "next/navigation"
import { motionTokens } from "@/lib/motion-tokens"

const variants = {
  initial: { opacity: 0, y: motionTokens.distance.sm },
  enter:   { opacity: 1, y: 0 },
  exit:    { opacity: 0, y: -motionTokens.distance.sm },
}

export function PageTransition({ children }: { children: React.ReactNode }) {
  const pathname = usePathname()
  return (
    <AnimatePresence mode="wait">
      <motion.div
        key={pathname}
        variants={variants}
        initial="initial"
        animate="enter"
        exit="exit"
        transition={{
          duration: motionTokens.duration.normal,
          ease: motionTokens.easing.smooth,
        }}
      >
        {children}
      </motion.div>
    </AnimatePresence>
  )
}
```

### Scroll reveal

```tsx
"use client"
import { motion } from "motion/react"
import { motionTokens, springs } from "@/lib/motion-tokens"

<motion.div
  initial={{ opacity: 0, y: motionTokens.distance.lg }}
  whileInView={{ opacity: 1, y: 0 }}
  viewport={{ once: true, margin: "-80px" }}   // once: true — rule 7
  transition={{ duration: motionTokens.duration.slow, ease: motionTokens.easing.smooth }}
/>
```

### Scroll progress bar

```tsx
"use client"
import { motion, useScroll } from "motion/react"

export function ScrollProgress() {
  const { scrollYProgress } = useScroll()
  return (
    <motion.div
      className="fixed top-0 left-0 h-1 bg-indigo-500 origin-left w-full"
      style={{ scaleX: scrollYProgress }}
    />
  )
}
```

### Card mở rộng

```tsx
"use client"
import { useState } from "react"
import { motion, AnimatePresence } from "motion/react"
import { springs, motionTokens } from "@/lib/motion-tokens"

export function ExpandingCard({ title, body }: { title: string; body: string }) {
  const [expanded, setExpanded] = useState(false)

  return (
    <motion.div layout onClick={() => setExpanded(!expanded)} className="cursor-pointer">
      {/* layout="position" prevents text reflow from animating */}
      <motion.h2 layout="position" className="font-semibold">
        {title}
      </motion.h2>

      <AnimatePresence>
        {expanded && (
          <motion.p
            key="body"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            transition={{ duration: motionTokens.duration.fast }}
          >
            {body}
          </motion.p>
        )}
      </AnimatePresence>
    </motion.div>
  )
}
```

### Shared-element crossfade

```tsx
// Source context
<motion.img layoutId="hero-image" src={src} className="w-16 h-16 rounded" />

// Destination context (same layoutId — motion handles the transition)
<motion.img layoutId="hero-image" src={src} className="w-full rounded-xl" />
```

### Accordion

```tsx
<motion.div
  initial={false}
  animate={{ opacity: open ? 1 : 0, scaleY: open ? 1 : 0 }}
  style={{ transformOrigin: "top", overflow: "hidden" }}
  transition={{
    duration: motionTokens.duration.normal,
    ease: motionTokens.easing.smooth,
  }}
> {children}
</motion.div>
```

## Ví dụ end-to-end

Một list stagger xuất hiện khi mount, xử lý presence có điều kiện, và
tôn trọng reduced motion — kết hợp token, spring, AnimatePresence và
hook accessibility từ `motion-foundations`:

```tsx
"use client"
import { useState } from "react"
import { motion, AnimatePresence } from "motion/react"
import { motionTokens, springs } from "@/lib/motion-tokens"
import { useSafeMotion } from "@/hooks/use-reduced-motion"

const containerVariants = {
  hidden: {},
  visible: {
    transition: { staggerChildren: 0.08, delayChildren: 0.1 },
  },
}

function ListItem({ label, onRemove }: { label: string; onRemove: () => void }) {
  const safe = useSafeMotion(motionTokens.distance.sm)
  return (
    <motion.li
      variants={{
        hidden:  safe.initial,
        visible: safe.animate,
      }}
      exit={safe.exit}
      transition={springs.gentle}
      className="flex items-center justify-between p-3 rounded-lg bg-white shadow-sm"
    >
      <span>{label}</span>
      <button onClick={onRemove}>Remove</button>
    </motion.li>
  )
}

export function AnimatedList({ items, onRemove }: {
  items: { id: string; label: string }[]
  onRemove: (id: string) => void
}) {
  return (
    <motion.ul
      variants={containerVariants}
      initial="hidden"
      animate="visible"
      className="space-y-2"
    >
      <AnimatePresence mode="popLayout">
        {items.map((item) => (
          <ListItem
            key={item.id}
            label={item.label}
            onRemove={() => onRemove(item.id)}
          />
        ))}
      </AnimatePresence>
    </motion.ul>
  )
}
```

## Ràng buộc / Ngoài phạm vi

Skill này **không** bao gồm:

- Định nghĩa token và spring → xem `motion-foundations`
- Tương tác drag, gesture swipe, list có thể sắp xếp lại → xem `motion-advanced`
- Animation chữ (word/character reveal, counter) → xem `motion-advanced`
- Vẽ hoặc morph SVG path → xem `motion-advanced`
- Custom animation hook → xem `motion-advanced`
- Transition chỉ dùng CSS không dùng `motion/react`

## Anti-Pattern

| Anti-pattern | Quy tắc bị vi phạm | Cách sửa |
| -------------------------------------------- | ------- | ------------------------------------------ |
| Phần tử con của `AnimatePresence` thiếu `key` | Quy tắc 1 | Thêm `key` ổn định cho phần tử con trực tiếp |
| `initial` + `animate` không có `exit` | Quy tắc 2 | Luôn định nghĩa cả ba cùng nhau |
| Page transition không có `mode="wait"` | Quy tắc 3 | Thêm `mode="wait"` vào `AnimatePresence` |
| `layout` trên list 50 mục | Quy tắc 4 | Dùng `mode="popLayout"` hoặc transform tường minh |
| `staggerChildren: 0.2` trên list 10 mục | Quy tắc 5 | Giới hạn ở `0.08–0.10` |
| Modal không có focus trap | Quy tắc 6 | Thêm `focus-trap-react` hoặc Radix Dialog |
| `whileInView` không có `viewport={{ once: true }}` | Quy tắc 7 | Hiệu ứng xuất hiện lặp lại gây xao nhãng, không cung cấp thông tin |
| `transition={{ duration: 0.3 }}` inline | Quy tắc 8 | Dùng `motionTokens.duration.normal` |

## Skill liên quan

- **`motion-foundations`** — định nghĩa mọi token, spring, hook `useSafeMotion` và các SSR guard mà mọi pattern ở đây đều import. Phải được thiết lập trước.
- **`motion-advanced`** — mở rộng các pattern này với drag, gesture, SVG, chữ, custom hook và sequencing imperative. Không định nghĩa lại bất kỳ pattern nào của skill này.
