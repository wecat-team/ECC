---
name: nanoclaw-repl
description: Vận hành và mở rộng NanoClaw, REPL không dependency và nhận biết session của ECC, với các session lưu bền vững dạng markdown và slash command để chuyển model, nạp skill, phân nhánh session, tìm kiếm xuyên session, nén lịch sử và export. Dùng khi chạy hoặc mở rộng scripts/claw.js, hoặc khi tiếp tục, phân nhánh, nén, tìm kiếm hay export một session NanoClaw.
metadata:
  origin: ECC
---

# NanoClaw REPL

Use this skill when running or extending `scripts/claw.js`.

## Capabilities

- persistent markdown-backed sessions
- model switching with `/model`
- dynamic skill loading with `/load`
- session branching with `/branch`
- cross-session search with `/search`
- history compaction with `/compact`
- export to md/json/txt with `/export`
- session metrics with `/metrics`

## Operating Guidance

1. Keep sessions task-focused.
2. Branch before high-risk changes.
3. Compact after major milestones.
4. Export before sharing or archival.

## Extension Rules

- keep zero external runtime dependencies
- preserve markdown-as-database compatibility
- keep command handlers deterministic and local
