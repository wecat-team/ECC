---
name: motion-advanced
description: Các pattern motion nâng cao cho React / Next.js — drag & drop, gesture, animation chữ, vẽ SVG path, custom hook, chuỗi animation imperative (useAnimate), loader, và cây quyết định API đầy đủ. Yêu cầu motion-foundations. Dùng khi xây dựng drag and drop, gesture, animation cho chữ hoặc SVG, hoặc chuỗi animation imperative trong React hoặc Next.js.
tags: [motion, animation, advanced, gestures, svg]
category: frontend
author: jeff
metadata:
  version: 1.0.0
---

# Motion Advanced

Các pattern animation phức tạp, tương tác và dựa trên vật lý.
Yêu cầu thiết lập `motion-foundations` trước.
Dùng khi `motion-patterns` chưa đủ.

## Khi nào kích hoạt

- Xây dựng sheet vuốt để đóng (drag-to-dismiss), gesture swipe, hoặc list có thể sắp xếp lại
- Animation chữ theo từng từ, từng ký tự, hoặc dạng bộ đếm trực tiếp
- Vẽ SVG path, morph icon, hoặc animation tiến trình hình tròn
- Viết custom animation hook (`useScrollReveal`, magnetic button, cursor follower)
- Sắp xếp chuỗi animation nhiều bước theo kiểu imperative bằng `useAnimate`
- Xây dựng spinner, shimmer skeleton, chỉ báo pulse, hoặc trạng thái loading của button

## Đầu ra

Skill này tạo ra:

- Tương tác drag: card kéo được, sheet drag-to-dismiss, list `Reorder.Group`
- Gesture hook: nhận diện swipe, long press, phác thảo pinch
- Component animation chữ: word reveal, character typewriter, number counter
- Animation SVG: path draw-on, icon morph, vòng tiến trình stroke
- Custom hook: `useScrollReveal`, `useHoverScale`, `useNavigationDirection`, `useInViewOnce`
- Chuỗi imperative qua `useAnimate` với `async/await` an toàn khi bị ngắt
- Component loader: spinner, shimmer, pulse dot, progress bar, trạng thái loading của button

## Nguyên tắc

- Chuyển động dựa trên vật lý (`useSpring`, `springs.*`) luôn tự nhiên hơn chuyển động dựa trên duration đối với thao tác trực tiếp.
- `useMotionValue` + `useTransform` tính các giá trị dẫn xuất mà không kích hoạt re-render.
- Chuỗi `useAnimate` là imperative và an toàn khi bị ngắt — gọi `animate()` giữa chừng sẽ tự động hủy animation trước đó.
- Motion value (`useMotionValue`, `useSpring`) an toàn với SSR và không gây lỗi hydration.

## Quy tắc

1. **Tương tác drag phải được test trên thiết bị cảm ứng**, không chỉ chuột. Prop `drag` hoạt động với cả hai nhưng cảm giác và ngưỡng khác nhau.
2. **Animation vô hạn phải tạm dừng khi `document.visibilityState === "hidden"`.** Tab nền không được tiêu tốn GPU/CPU.
3. **Ngưỡng swipe phải tường minh.** Không bao giờ suy ra ý định chỉ từ velocity; hãy kết hợp kiểm tra `offset` + `velocity`.
4. **Ref scope của `useAnimate` phải được gắn vào một phần tử DOM đã mount.** Gọi `animate()` trước khi mount sẽ ném lỗi một cách âm thầm.
5. **Không được tạo lại motion value mỗi lần render.** `useMotionValue(0)` trong thân component là đúng; `new MotionValue(0)` trong render thì không.
6. **Mọi giá trị token được import từ `motion-foundations`.** Không dùng số inline.
7. **Custom hook phải xử lý cleanup.** Mỗi `window.addEventListener` cần một `removeEventListener` tương ứng trong giá trị trả về của `useEffect`.
8. **SVG morph yêu cầu số lượng path command bằng nhau.** Các path có cấu trúc command khác nhau sẽ nhảy cóc thay vì nội suy.

## Hướng dẫn quyết định

### Chọn đúng API nâng cao

| Tình huống | API |
| ------------------------------ | -------------------------------- |
| Drag có vật lý khi thả | `drag` + `dragTransition: springs.release` |
| List kéo thả để sắp xếp thứ tự | `Reorder.Group` + `Reorder.Item` |
| Đóng khi kéo vượt offset | `drag="y"` + kiểm tra offset trong `onDragEnd` |
| Swipe trái/phải | `drag="x"` + kiểm tra offset trong `onDragEnd` |
| Long press | hook `useLongPress` |
| Giá trị được làm mượt theo thời gian | `useSpring` |
| Giá trị dẫn xuất từ giá trị khác | `useTransform` |
| Chuỗi nhiều bước | `useAnimate` với `async/await` |
| Animation imperative một lần | `animate()` từ `motion` |
| Chữ xuất hiện từng từ | Stagger trên các span `inline-block` |
| Vẽ SVG dần dần | `pathLength` 0 → 1 |
| SVG morph | tween thuộc tính `d` (số command bằng nhau) |
| Tiến trình hình tròn | tween `strokeDashoffset` |

### Khi nào dùng `useSpring` so với spring transition

| | `useSpring` | `transition: springs.*` |
| -------------- | ---------------------------------------- | ----------------------- |
| Dùng cho | Cursor follower, giá trị bám theo con trỏ | Thay đổi trạng thái rời rạc |
| Cập nhật | Liên tục, ở mỗi frame | Kích hoạt bởi thay đổi state |
| Khi bị ngắt | Mượt — vật lý tiếp tục từ velocity | Khởi động lại từ giá trị hiện tại |

## Khái niệm cốt lõi

### useMotionValue + useTransform

Tính toán phản ứng (reactive) mà không re-render:

```tsx
const x = useMotionValue(0)
const opacity = useTransform(x, [-200, 0, 200], [0, 1, 0])
// opacity updates every frame as x changes — no setState, no re-render
```

### useAnimate

Trả về `[scope, animate]`. Ref scope phải được gắn vào một phần tử DOM.
Các lời gọi `animate()` an toàn khi bị ngắt — gọi giữa chừng sẽ hủy lượt chạy trước.

```tsx
const [scope, animate] = useAnimate()

async function play() {
  await animate(".step-1", { opacity: 1 }, { duration: 0.3 })
  await animate(".step-2", { x: 0 },       { duration: 0.4 })
        animate(".step-3", { scale: 1 },    { duration: 0.25 })  // fire and forget
}

return <div ref={scope}>...</div>
```

## Ví dụ code

### Card kéo được

```tsx
"use client"
import { motion } from "motion/react"
import { springs, motionTokens } from "@/lib/motion-tokens"

<motion.div
  drag
  dragConstraints={{ left: -100, right: 100, top: -100, bottom: 100 }}
  dragElastic={0.1}
  whileDrag={{
    scale: motionTokens.scale.pop,
    boxShadow: "0 16px 40px rgba(0,0,0,0.2)",
  }}
  dragTransition={springs.release}
/>
```

### Sheet drag-to-dismiss

```tsx
"use client"
import { motion, useMotionValue, useTransform } from "motion/react"

export function BottomSheet({ onClose }: { onClose: () => void }) {
  const y = useMotionValue(0)
  const opacity = useTransform(y, [0, 200], [1, 0])

  return (
    <motion.div
      drag="y"
      dragConstraints={{ top: 0 }}
      style={{ y, opacity }}
      onDragEnd={(_, info) => {
        // Rule 3: combine offset + velocity
        if (info.offset.y > 120 || info.velocity.y > 500) onClose()
      }}
    />
  )
}
```

### List sắp xếp lại được

```tsx
"use client"
import { Reorder } from "motion/react"

export function SortableList() {
  const [items, setItems] = useState(initialItems)
  return (
    <Reorder.Group axis="y" values={items} onReorder={setItems}>
      {items.map((item) => (
        <Reorder.Item key={item.id} value={item}>
          {item.label}
        </Reorder.Item>
      ))}
    </Reorder.Group>
  )
}
```

### Nhận diện swipe

```tsx
"use client"
import { motion } from "motion/react"

const OFFSET_THRESHOLD  = 50
const VELOCITY_THRESHOLD = 300

<motion.div
  drag="x"
  dragConstraints={{ left: 0, right: 0 }}
  onDragEnd={(_, info) => {
    const swipedRight = info.offset.x > OFFSET_THRESHOLD  || info.velocity.x > VELOCITY_THRESHOLD
    const swipedLeft  = info.offset.x < -OFFSET_THRESHOLD || info.velocity.x < -VELOCITY_THRESHOLD
    if (swipedRight) onSwipeRight()
    if (swipedLeft)  onSwipeLeft()
  }}
/>
```

### Hook long press

```tsx
import { useRef } from "react"

export function useLongPress(callback: () => void, ms = 600) {
  const timerRef = useRef<ReturnType<typeof setTimeout>>()
  return {
    onPointerDown:  () => { timerRef.current = setTimeout(callback, ms) },
    onPointerUp:    () => clearTimeout(timerRef.current),
    onPointerLeave: () => clearTimeout(timerRef.current),
  }
}
```

### Word-by-word reveal

```tsx
"use client"
import { motion } from "motion/react"
import { springs } from "@/lib/motion-tokens"

export function AnimatedText({ text }: { text: string }) {
  return (
    <motion.p
      variants={{ visible: { transition: { staggerChildren: 0.05 } } }}
      initial="hidden"
      animate="visible"
    >
      {text.split(" ").map((word, i) => (
        <motion.span
          key={i}
          className="inline-block mr-1"
          variants={{
            hidden:  { opacity: 0, y: 12 },
            visible: { opacity: 1, y: 0, transition: springs.gentle },
          }}
        >
          {word}
        </motion.span>
      ))}
    </motion.p>
  )
}
```

### Number counter

```tsx
"use client"
import { useRef, useEffect } from "react"
import { animate } from "motion"
import { motionTokens } from "@/lib/motion-tokens"

export function Counter({ to }: { to: number }) {
  const nodeRef = useRef<HTMLSpanElement>(null)

  useEffect(() => {
    const controls = animate(0, to, {
      duration: motionTokens.duration.crawl,
      ease: motionTokens.easing.smooth,
      onUpdate: (v) => {
        if (nodeRef.current) nodeRef.current.textContent = Math.round(v).toString()
      },
    })
    return controls.stop   // Rule 7: cleanup
  }, [to])

  return <span ref={nodeRef} />
}
```

### SVG path draw-on

```tsx
"use client"
import { motion } from "motion/react"
import { motionTokens } from "@/lib/motion-tokens"

<motion.path
  d="M 0 100 Q 50 0 100 100"
  initial={{ pathLength: 0, opacity: 0 }}
  animate={{ pathLength: 1, opacity: 1 }}
  transition={{ duration: motionTokens.duration.slow, ease: motionTokens.easing.smooth }}
/>
```

### Vòng tiến trình stroke

```tsx
"use client"
import { motion } from "motion/react"
import { motionTokens } from "@/lib/motion-tokens"

const CIRCUMFERENCE = 2 * Math.PI * 40   // r=40

export function ProgressRing({ progress }: { progress: number }) {
  return (
    <svg width="100" height="100" viewBox="0 0 100 100">
      <circle cx="50" cy="50" r="40" fill="none" stroke="#e5e7eb" strokeWidth="8" />
      <motion.circle
        cx="50" cy="50" r="40"
        fill="none" stroke="#6366f1" strokeWidth="8"
        strokeLinecap="round"
        strokeDasharray={CIRCUMFERENCE}
        animate={{ strokeDashoffset: CIRCUMFERENCE - (progress / 100) * CIRCUMFERENCE }}
        transition={{ duration: motionTokens.duration.normal, ease: motionTokens.easing.smooth }}
        style={{ rotate: -90, transformOrigin: "center" }}
      />
    </svg>
  )
}
```

### Hook useScrollReveal

```tsx
"use client"
import { useRef } from "react"
import { useScroll, useTransform } from "motion/react"
import { motionTokens } from "@/lib/motion-tokens"

export function useScrollReveal() {
  const ref = useRef(null)
  const { scrollYProgress } = useScroll({ target: ref, offset: ["start end", "end start"] })
  const opacity = useTransform(scrollYProgress, [0, 0.3], [0, 1])
  const y       = useTransform(scrollYProgress, [0, 0.3], [motionTokens.distance.lg, 0])
  return { ref, style: { opacity, y } }
}

// Usage
const { ref, style } = useScrollReveal()
<motion.section ref={ref} style={style} />
```

### Cursor follower

```tsx
"use client"
import { useEffect } from "react"
import { motion, useMotionValue, useSpring } from "motion/react"
import { springs } from "@/lib/motion-tokens"

export function CursorFollower() {
  const x = useMotionValue(-100)
  const y = useMotionValue(-100)
  const sx = useSpring(x, springs.gentle)
  const sy = useSpring(y, springs.gentle)

  useEffect(() => {
    const move = (e: MouseEvent) => { x.set(e.clientX); y.set(e.clientY) }
    window.addEventListener("mousemove", move)
    return () => window.removeEventListener("mousemove", move)   // Rule 7
  }, [])

  return (
    <motion.div
      className="fixed top-0 left-0 w-6 h-6 rounded-full bg-indigo-500
                 pointer-events-none -translate-x-1/2 -translate-y-1/2 z-50"
      style={{ x: sx, y: sy }}
    />
  )
}
```

### Shimmer skeleton

```tsx
"use client"
import { useEffect } from "react"
import { motion, useAnimation } from "motion/react"
import { motionTokens } from "@/lib/motion-tokens"

export function ShimmerSkeleton({ className = "" }: { className?: string }) {
  const controls = useAnimation()

  useEffect(() => {
    const play = () =>
      controls.start({
        x: ["-100%", "100%"],
        transition: {
          repeat: Infinity,
          duration: motionTokens.duration.crawl,
          ease: motionTokens.easing.linear,
        },
      })

    const handleVisibility = () => {
      if (document.visibilityState === "hidden") controls.stop()
      else void play()
    }

    void play()
    document.addEventListener("visibilitychange", handleVisibility)
    return () => {
      controls.stop()
      document.removeEventListener("visibilitychange", handleVisibility)
    }
  }, [controls])

  return (
    <div className={`relative overflow-hidden bg-gray-200 rounded ${className}`}>
      <motion.div
        className="absolute inset-0 bg-gradient-to-r from-transparent via-white/60 to-transparent"
        initial={{ x: "-100%" }}
        animate={controls}
      />
    </div>
  )
}
```

### Trạng thái loading của button

```tsx
"use client"
import { motion, AnimatePresence } from "motion/react"
import { motionTokens, springs } from "@/lib/motion-tokens"

export function LoadingButton({
  loading,
  label,
  onClick,
}: {
  loading: boolean
  label: string
  onClick: () => void
}) {
  return (
    <motion.button
      onClick={onClick}
      animate={{ opacity: loading ? 0.7 : 1 }}
      whileTap={loading ? {} : { scale: motionTokens.scale.press }}
      transition={springs.snappy}
      disabled={loading}
    >
      <AnimatePresence mode="wait">
        {loading ? (
          <motion.span
            key="loading"
            initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }}
            transition={{ duration: motionTokens.duration.fast }}
          >
            …
          </motion.span>
        ) : (
          <motion.span
            key="label"
            initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }}
            transition={{ duration: motionTokens.duration.fast }}
          >
            {label}
          </motion.span>
        )}
      </AnimatePresence>
    </motion.button>
  )
}
```

### Animation vô hạn với tạm dừng theo visibility

```tsx
"use client"
import { useEffect } from "react"
import { motion, useAnimation } from "motion/react"
import { motionTokens } from "@/lib/motion-tokens"

export function PulseDot() {
  const controls = useAnimation()

  useEffect(() => {
    const pulse = () =>
      controls.start({
        scale: [1, 1.4, 1],
        opacity: [1, 0.6, 1],
        transition: { repeat: Infinity, duration: motionTokens.duration.crawl },
      })

    // Rule 2: pause when tab is hidden
    const handleVisibility = () => {
      if (document.visibilityState === "hidden") controls.stop()
      else void pulse()
    }

    void pulse()
    document.addEventListener("visibilitychange", handleVisibility)
    // Rule 7: stop controls and remove listeners on unmount.
    return () => {
      controls.stop()
      document.removeEventListener("visibilitychange", handleVisibility)
    }
  }, [controls])

  return <motion.span className="w-2 h-2 rounded-full bg-green-400" animate={controls} />
}
```

## Ví dụ end-to-end

Sheet drag-to-dismiss với nội dung shimmer, trạng thái loading và hỗ trợ
reduced motion — kết hợp `useMotionValue`, `useTransform`, `useSafeMotion`,
`AnimatePresence` và các token từ `motion-foundations`:

```tsx
"use client"
import { useState } from "react"
import { motion, AnimatePresence, useMotionValue, useTransform } from "motion/react"
import { springs, motionTokens } from "@/lib/motion-tokens"
import { useSafeMotion } from "@/hooks/use-reduced-motion"
import { ShimmerSkeleton } from "./shimmer-skeleton"

export function DismissibleSheet({
  isOpen,
  onClose,
  loading,
  children,
}: {
  isOpen: boolean
  onClose: () => void
  loading: boolean
  children: React.ReactNode
}) {
  const safe = useSafeMotion(motionTokens.distance.xl)
  const y = useMotionValue(0)
  const opacity = useTransform(y, [0, 200], [1, 0])

  return (
    <AnimatePresence>
      {isOpen && (
        <>
          {/* Backdrop */}
          <motion.div
            key="backdrop"
            className="fixed inset-0 bg-black/40"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            onClick={onClose}
          />

          {/* Sheet — drag-to-dismiss */}
          <motion.div
            key="sheet"
            className="fixed bottom-0 inset-x-0 rounded-t-2xl bg-white p-6"
            drag="y"
            dragConstraints={{ top: 0 }}
            style={{ y, opacity }}
            onDragEnd={(_, info) => {
              if (info.offset.y > 120 || info.velocity.y > 500) onClose()
            }}
            initial={safe.initial}
            animate={safe.animate}
            exit={safe.exit}
            transition={springs.gentle}
          >
            {loading ? (
              <div className="space-y-3">
                <ShimmerSkeleton className="h-4 w-3/4" />
                <ShimmerSkeleton className="h-4 w-1/2" />
                <ShimmerSkeleton className="h-20 w-full" />
              </div>
            ) : children}
          </motion.div>
        </>
      )}
    </AnimatePresence>
  )
}
```

## Ràng buộc / Ngoài phạm vi

Skill này **không** bao gồm:

- Định nghĩa token và spring → xem `motion-foundations`
- Các pattern UI tiêu chuẩn (button, modal, stagger, page transition) → xem `motion-patterns`
- Animation chỉ dùng CSS hoặc `animate-*` của Tailwind mà không có `motion/react`
- Animation dựa trên Canvas hoặc WebGL (Three.js, Pixi, v.v.)
- Hệ thống drag-and-drop đầy đủ với state manager bên ngoài (dnd-kit, react-beautiful-dnd)
- Animation kiểu game-loop hoặc từng frame một

## Anti-Pattern

| Anti-pattern | Quy tắc bị vi phạm | Cách sửa |
| ---------------------------------------------- | ------- | ------------------------------------------------ |
| `drag` chỉ được test trên desktop | Quy tắc 1 | Test trên touch emulator và thiết bị thật |
| `animate={{ repeat: Infinity }}` không có tạm dừng | Quy tắc 2 | Thêm listener `visibilitychange` |
| `onDragEnd` chỉ kiểm tra offset, không kiểm tra velocity | Quy tắc 3 | Kiểm tra cả `info.offset` và `info.velocity` |
| `animate(scope, ...)` trước `useEffect` | Quy tắc 4 | Chỉ gọi `animate()` sau khi mount |
| `const x = new MotionValue(0)` trong render | Quy tắc 5 | Dùng `const x = useMotionValue(0)` |
| `transition={{ duration: 1.2 }}` inline | Quy tắc 6 | Dùng `motionTokens.duration.crawl` |
| `useEffect` không có cleanup | Quy tắc 7 | Trả về `removeEventListener` / `controls.stop` |
| SVG morph giữa các path có command khác nhau | Quy tắc 8 | Chuẩn hóa path command trước khi animate |

## Skill liên quan

- **`motion-foundations`** — định nghĩa mọi token, spring, `useSafeMotion` và các SSR guard được import ở đây. Phải được thiết lập trước khi dùng skill này.
- **`motion-patterns`** — xử lý các pattern UI tiêu chuẩn (button, modal, stagger, page transition, scroll reveal). Hãy dùng nó trước khi dùng các pattern nâng cao ở đây.
