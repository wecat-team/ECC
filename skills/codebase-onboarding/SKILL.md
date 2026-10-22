---
name: codebase-onboarding
description: Phân tích một codebase lạ và tạo hướng dẫn onboarding có cấu trúc gồm bản đồ kiến trúc, các entry point chính, convention và một CLAUDE.md khởi đầu. Dùng khi tham gia dự án mới hoặc thiết lập Claude Code lần đầu trong một repo.
metadata:
  origin: ECC
---

# Codebase Onboarding

Phân tích một cách có hệ thống một codebase lạ và tạo ra hướng dẫn onboarding có cấu trúc. Được thiết kế cho developer tham gia dự án mới hoặc thiết lập Claude Code lần đầu trong một repo có sẵn.

## Khi nào dùng

- Lần đầu mở một dự án với Claude Code
- Tham gia một team hoặc repository mới
- Người dùng hỏi "help me understand this codebase"
- Người dùng yêu cầu tạo CLAUDE.md cho một dự án
- Người dùng nói "onboard me" hoặc "walk me through this repo"

## Cách hoạt động

### Giai đoạn 1: Trinh sát (Reconnaissance)

Thu thập các tín hiệu thô về dự án mà không đọc từng file. Chạy các kiểm tra này song song:

```
1. Package manifest detection
   → package.json, go.mod, Cargo.toml, pyproject.toml, pom.xml, build.gradle,
     Gemfile, composer.json, mix.exs, pubspec.yaml

2. Framework fingerprinting
   → next.config.*, nuxt.config.*, angular.json, vite.config.*,
     django settings, flask app factory, fastapi main, rails config

3. Entry point identification
   → main.*, index.*, app.*, server.*, cmd/, src/main/

4. Directory structure snapshot
   → Top 2 levels of the directory tree, ignoring node_modules, vendor,
     .git, dist, build, __pycache__, .next

5. Config and tooling detection
   → .eslintrc*, .prettierrc*, tsconfig.json, Makefile, Dockerfile,
     docker-compose*, .github/workflows/, .env.example, CI configs

6. Test structure detection
   → tests/, test/, __tests__/, *_test.go, *.spec.ts, *.test.js,
     pytest.ini, jest.config.*, vitest.config.*
```

### Giai đoạn 2: Lập bản đồ kiến trúc

Từ dữ liệu trinh sát, xác định:

**Tech Stack**
- Ngôn ngữ và các ràng buộc phiên bản
- Framework và các thư viện chính
- Database và ORM
- Build tool và bundler
- Nền tảng CI/CD

**Kiến trúc (Architecture Pattern)**
- Monolith, monorepo, microservices hoặc serverless
- Tách frontend/backend hoặc full-stack
- Kiểu API: REST, GraphQL, gRPC, tRPC

**Các thư mục chính**
Ánh xạ các thư mục cấp cao nhất với mục đích của chúng:

<!-- Ví dụ cho một dự án React — thay bằng các thư mục phát hiện được -->
```
src/components/  → React UI components
src/api/         → API route handlers
src/lib/         → Shared utilities
src/db/          → Database models and migrations
tests/           → Test suites
scripts/         → Build and deployment scripts
```

**Luồng dữ liệu (Data Flow)**
Truy vết một request từ điểm vào đến response:
- Request đi vào đâu? (router, handler, controller)
- Nó được kiểm tra (validate) như thế nào? (middleware, schema, guard)
- Business logic nằm ở đâu? (service, model, use case)
- Nó chạm tới database bằng cách nào? (ORM, raw query, repository)

### Giai đoạn 3: Phát hiện convention

Xác định các pattern mà codebase đã tuân theo:

**Quy ước đặt tên**
- Đặt tên file: kebab-case, camelCase, PascalCase, snake_case
- Pattern đặt tên component/class
- Đặt tên file test: `*.test.ts`, `*.spec.ts`, `*_test.go`

**Pattern code**
- Phong cách xử lý lỗi: try/catch, Result type, error code
- Dependency injection hoặc import trực tiếp
- Cách tiếp cận quản lý state
- Pattern bất đồng bộ: callback, promise, async/await, channel

**Convention Git**
- Cách đặt tên branch dựa trên các branch gần đây
- Phong cách commit message dựa trên các commit gần đây
- Workflow PR (squash, merge, rebase)
- Nếu repo chưa có commit nào hoặc chỉ có lịch sử nông (ví dụ `git clone --depth 1`), hãy bỏ qua mục này và ghi chú "Git history unavailable or too shallow to detect conventions"

### Giai đoạn 4: Tạo các artifact onboarding

Tạo ra hai output:

#### Output 1: Hướng dẫn Onboarding

```markdown
# Onboarding Guide: [Project Name]

## Overview
[2-3 sentences: what this project does and who it serves]

## Tech Stack
<!-- Example for a Next.js project — replace with detected stack -->
| Layer | Technology | Version |
|-------|-----------|---------|
| Language | TypeScript | 5.x |
| Framework | Next.js | 14.x |
| Database | PostgreSQL | 16 |
| ORM | Prisma | 5.x |
| Testing | Jest + Playwright | - |

## Architecture
[Diagram or description of how components connect]

## Key Entry Points
<!-- Example for a Next.js project — replace with detected paths -->
- **API routes**: `src/app/api/` — Next.js route handlers
- **UI pages**: `src/app/(dashboard)/` — authenticated pages
- **Database**: `prisma/schema.prisma` — data model source of truth
- **Config**: `next.config.ts` — build and runtime config

## Directory Map
[Top-level directory → purpose mapping]

## Request Lifecycle
[Trace one API request from entry to response]

## Conventions
- [File naming pattern]
- [Error handling approach]
- [Testing patterns]
- [Git workflow]

## Common Tasks
<!-- Example for a Node.js project — replace with detected commands -->
- **Run dev server**: `npm run dev`
- **Run tests**: `npm test`
- **Run linter**: `npm run lint`
- **Database migrations**: `npx prisma migrate dev`
- **Build for production**: `npm run build`

## Where to Look
<!-- Example for a Next.js project — replace with detected paths -->
| I want to... | Look at... |
|--------------|-----------|
| Add an API endpoint | `src/app/api/` |
| Add a UI page | `src/app/(dashboard)/` |
| Add a database table | `prisma/schema.prisma` |
| Add a test | `tests/` matching the source path |
| Change build config | `next.config.ts` |
```

#### Output 2: CLAUDE.md khởi đầu

Tạo hoặc cập nhật một CLAUDE.md riêng cho dự án dựa trên các convention đã phát hiện. Nếu `CLAUDE.md` đã tồn tại, hãy đọc nó trước và bổ sung — giữ nguyên các chỉ dẫn riêng của dự án hiện có và nêu rõ những gì đã được thêm hoặc thay đổi.

```markdown
# Project Instructions

## Tech Stack
[Detected stack summary]

## Code Style
- [Detected naming conventions]
- [Detected patterns to follow]

## Testing
- Run tests: `[detected test command]`
- Test pattern: [detected test file convention]
- Coverage: [if configured, the coverage command]

## Build & Run
- Dev: `[detected dev command]`
- Build: `[detected build command]`
- Lint: `[detected lint command]`

## Project Structure
[Key directory → purpose map]

## Conventions
- [Commit style if detectable]
- [PR workflow if detectable]
- [Error handling patterns]
```

## Best Practice

1. **Đừng đọc mọi thứ** — trinh sát nên dùng Glob và Grep, không phải Read trên từng file. Chỉ đọc có chọn lọc với các tín hiệu mơ hồ.
2. **Xác minh, đừng đoán** — nếu một framework được phát hiện từ config nhưng code thực tế dùng thứ khác, hãy tin vào code.
3. **Tôn trọng CLAUDE.md hiện có** — nếu đã có, hãy bổ sung thay vì thay thế. Nêu rõ cái gì mới so với cái có sẵn.
4. **Giữ ngắn gọn** — hướng dẫn onboarding nên có thể quét qua trong 2 phút. Chi tiết thuộc về code, không phải về hướng dẫn.
5. **Đánh dấu điều chưa biết** — nếu không thể tự tin phát hiện một convention, hãy nói rõ thay vì đoán. "Could not determine test runner" tốt hơn một đáp án sai.

## Anti-Pattern cần tránh

- Tạo CLAUDE.md dài hơn 100 dòng — hãy giữ cho tập trung
- Liệt kê mọi dependency — chỉ làm nổi bật những dependency định hình cách bạn viết code
- Mô tả những tên thư mục hiển nhiên — `src/` không cần giải thích
- Sao chép README — hướng dẫn onboarding bổ sung góc nhìn cấu trúc mà README thiếu

## Ví dụ

### Ví dụ 1: Lần đầu trong một repo mới
**Người dùng**: "Onboard me to this codebase"
**Hành động**: Chạy đầy đủ workflow 4 giai đoạn → tạo Onboarding Guide + CLAUDE.md khởi đầu
**Output**: Onboarding Guide được in thẳng vào cuộc hội thoại, cộng với một `CLAUDE.md` được ghi vào thư mục gốc của dự án

### Ví dụ 2: Tạo CLAUDE.md cho dự án có sẵn
**Người dùng**: "Generate a CLAUDE.md for this project"
**Hành động**: Chạy Giai đoạn 1-3, bỏ qua Onboarding Guide, chỉ tạo CLAUDE.md
**Output**: `CLAUDE.md` riêng cho dự án với các convention đã phát hiện

### Ví dụ 3: Bổ sung CLAUDE.md hiện có
**Người dùng**: "Update the CLAUDE.md with current project conventions"
**Hành động**: Đọc CLAUDE.md hiện có, chạy Giai đoạn 1-3, gộp các phát hiện mới
**Output**: `CLAUDE.md` đã cập nhật với các phần bổ sung được đánh dấu rõ ràng
