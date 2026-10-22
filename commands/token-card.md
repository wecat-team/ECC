---
description: Render một thẻ thống kê token-usage từ log session của agent cục bộ và commit vào repo. Gọi skill token-card.
argument-hint: "[--out PATH] [--theme auto|light|dark] [--dry-run]"
---

# Token Card

Lớp tương thích mỏng. Workflow nằm trong skill **token-card**
(`skills/token-card/SKILL.md`), vốn là bề mặt chuẩn; lệnh này tồn tại để các
harness slash-command có thể truy cập nó.

## Cách dùng

```
/token-card                       # write the configured output (./tokenchit.svg by default)
/token-card --out docs/usage.svg  # write somewhere else
/token-card --theme dark
/token-card --dry-run             # report what would be written, write nothing
```

## Nó làm gì

Render một thẻ SVG về mức sử dụng AI coding agent của máy này — token, chi phí tương đương,
streak, phân chia theo từng agent — từ log session cục bộ của Claude Code, Codex, Gemini CLI và OpenCode, và ghi
nó vào working tree dưới dạng một file mà README có thể tham chiếu.

Hãy làm theo skill để biết workflow đầy đủ, bao gồm bước xác nhận bắt buộc trước lần tải
registry đầu tiên, phiên bản CLI được pin, và các quy tắc dry-run.
