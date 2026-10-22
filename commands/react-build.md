---
description: Sửa dần các lỗi build React (Vite, webpack, Next.js, CRA, Parcel, esbuild, Bun) — lỗi compile JSX/TSX, hydration mismatch, lỗi ranh giới server/client component, thiếu type. Gọi agent react-build-resolver để sửa tối thiểu, chính xác.
---

# React Build and Fix

Lệnh này gọi agent **react-build-resolver** để sửa dần các lỗi build React với thay đổi tối thiểu.

## Lệnh này làm gì

1. **Phát hiện hệ thống build**: Xác định Vite, webpack, Next.js, CRA, Parcel, esbuild hoặc Bun
2. **Chạy build**: Thực thi build script của project
3. **Phân tích lỗi**: Nhóm theo tầng (TypeScript / cấu hình bundler / runtime / hydration)
4. **Sửa dần**: Mỗi lần một lỗi, chạy lại build sau mỗi thay đổi
5. **Báo cáo tóm tắt**: Cho biết đã sửa gì và còn lại gì

## Khi nào dùng

Dùng `/react-build` khi:

- `npm run build` (hoặc tương đương pnpm/yarn/bun) thất bại
- Lỗi compile JSX/TSX sau khi nâng cấp TypeScript hoặc React
- Lỗi hydration mismatch của Next.js lúc runtime
- Lỗi ranh giới Server/Client Component trong App Router
- Sau khi cài đặt hoặc nâng cấp `react`, `react-dom`, `@types/react` hoặc một bundler
- Thiếu type hoặc lỗi "module not found" liên quan đến React

## Phạm vi

Lệnh này phụ trách các lỗi **build React/bundler/runtime hydration**. Với lỗi type TypeScript thuần túy không liên quan React, hãy dùng `/build-fix` (generic).

## Các lệnh chẩn đoán được chạy

```bash
# Project build script (preferred)
npm run build --if-present
pnpm build 2>/dev/null
yarn build 2>/dev/null
bun run build 2>/dev/null

# Standalone typecheck
npm run typecheck --if-present
tsc --noEmit -p tsconfig.json

# Bundler-specific fallback
next build                          # Next.js
vite build                          # Vite
react-scripts build                 # CRA
webpack --mode=production           # webpack
parcel build src/index.html         # Parcel
bun build ./src/index.tsx --outdir=dist
```

## Ví dụ phiên làm việc

````text
User: /react-build

Agent:
# React Build Resolution

## Build System Detected
Vite (vite.config.ts present, @vitejs/plugin-react in deps)

## Initial Diagnostics

```bash
$ npm run build
> tsc -b && vite build

src/components/UserCard.tsx:1:8 - error TS6133: 'React' is declared but its value is never read.
src/components/Modal.tsx:12:15 - error TS7016: Could not find a declaration file for module 'react-portal'.
src/pages/Home.tsx:42:5 - error: 'useState' is not defined
```

Errors found: 3

## Fix 1: Old JSX transform leftover

File: src/components/UserCard.tsx:1
Cause: `tsconfig.json` already uses `"jsx": "react-jsx"`; the explicit `import React` is unused.

```tsx
// Removed
- import React from 'react';
```

```bash
$ npm run build
# 2 errors remaining
```

## Fix 2: Missing types

File: src/components/Modal.tsx
Cause: `@types/react-portal` not installed.

```bash
$ npm i -D @types/react-portal
added 1 package
```

```bash
$ npm run build
# 1 error remaining
```

## Fix 3: Missing hook import

File: src/pages/Home.tsx
Cause: `useState` referenced but not imported.

```tsx
- import { useEffect } from "react";
+ import { useEffect, useState } from "react";
```

```bash
$ npm run build
# Build successful!
```

## Final Verification

```bash
$ npm run build
✓ built in 2.34s

$ npm test
✓ 47 tests passed
```

## Summary

| Metric | Count |
|--------|-------|
| Build errors fixed | 3 |
| Files modified | 2 |
| Dependencies added | 1 (@types/react-portal) |
| Remaining issues | 0 |

Build Status: PASS: SUCCESS
````

## Các lỗi thường gặp đã sửa

| Lỗi | Cách sửa điển hình |
|---|---|
| `'React' is not defined` | Đặt `"jsx": "react-jsx"` trong tsconfig (React 17+) |
| Thiếu `@types/react` | `npm i -D @types/react @types/react-dom` |
| `Unexpected token '<'` | Thêm `@vitejs/plugin-react` / `babel-loader` |
| `You're importing a component that needs useState` (Next.js) | Thêm `"use client"` hoặc chuyển hook vào một Client Component con |
| `Module not found: Can't resolve 'fs'` (Next.js) | Bỏ import `fs` hoặc chuyển logic vào Server Component / API route |
| `Hydration failed because the initial UI does not match` | Chuyển `Date.now()`/`Math.random()`/`window.*` vào `useEffect` |
| `Invalid hook call` | Có nhiều bản React — loại trùng qua `resolutions`/`overrides` |
| `Element type is invalid` | Import default và named không khớp |

## Chiến lược sửa

1. **Lỗi compile trước** — code phải build được
2. **Lỗi hydration thứ hai** — ảnh hưởng tính đúng đắn ở production
3. **Cấu hình bundler thứ ba** — khôi phục plugin/loader hoạt động đúng
4. **Mỗi lần một lỗi** — xác minh từng thay đổi
5. **Thay đổi tối thiểu** — KHÔNG BAO GIỜ dùng `// @ts-ignore` mà không giải thích
6. **Chạy lại sau mỗi lần sửa** — để lộ ngay các lỗi mới

## Điều kiện dừng

Agent sẽ dừng và báo cáo nếu:

- Cùng một lỗi vẫn tồn tại sau 3 lần thử
- Bản sửa gây ra nhiều lỗi hơn số lỗi nó giải quyết
- Cần thay đổi kiến trúc vượt quá phạm vi sửa build (ví dụ: thiết kế lại ranh giới RSC)
- Phiên bản bundler không còn hỗ trợ major React đã cài

## Các lệnh liên quan

- `/react-test` — chạy test sau khi build đã xanh
- `/react-review` — review chất lượng code sau khi build thành công
- `/build-fix` — công cụ sửa build chung (không phải React)
- skill `verification-loop` — vòng lặp verification đầy đủ

## Liên quan

- Agent: `agents/react-build-resolver.md`
- Skills: `skills/react-patterns/`, `skills/frontend-patterns/`
- Rules: `rules/react/coding-style.md`, `rules/react/patterns.md`
