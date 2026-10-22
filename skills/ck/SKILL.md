---
name: ck
description: "Bộ nhớ bền vững theo từng dự án cho Claude Code (Context Keeper), điều khiển bởi các lệnh Node.js /ck có tính xác định: init, save, resume, info, list, forget và migrate v1 sang v2, kèm SessionStart hook chèn bản tóm tắt dự án gọn nhẹ. Dùng khi context phải tồn tại xuyên suốt các session, lưu trạng thái session cùng các bước tiếp theo và quyết định, tiếp tục từ chỗ session trước đã dừng, hoặc quay lại một dự án mà không cần giải thích lại."
metadata:
  version: 2.0.0
  origin: community
author: sreedhargs89
repo: https://github.com/sreedhargs89/context-keeper
---

# ck — Context Keeper

Bạn là trợ lý **Context Keeper**. Khi người dùng gọi bất kỳ lệnh `/ck:*` nào,
hãy chạy script Node.js tương ứng và trình bày stdout của nó cho người dùng nguyên văn.
Các script nằm tại: `~/.claude/skills/ck/commands/` (mở rộng `~` thành `$HOME`).

---

## Cấu trúc dữ liệu

```
~/.claude/ck/
├── projects.json              ← path → {name, contextDir, lastUpdated}
└── contexts/<name>/
    ├── context.json           ← SOURCE OF TRUTH (structured JSON, v2)
    └── CONTEXT.md             ← generated view — do not hand-edit
```

---

## Các lệnh

### `/ck:init` — Đăng ký một dự án
```bash
node "$HOME/.claude/skills/ck/commands/init.mjs"
```
Script xuất ra JSON với thông tin tự động phát hiện. Trình bày nó dưới dạng bản nháp để xác nhận:
```
Here's what I found — confirm or edit anything:
Project:     <name>
Description: <description>
Stack:       <stack>
Goal:        <goal>
Do-nots:     <constraints or "None">
Repo:        <repo or "none">
```
Chờ người dùng phê duyệt. Áp dụng mọi chỉnh sửa. Sau đó pipe JSON đã xác nhận vào save.mjs --init:
```bash
echo '<confirmed-json>' | node "$HOME/.claude/skills/ck/commands/save.mjs" --init
```
Schema JSON đã xác nhận: `{"name":"...","path":"...","description":"...","stack":["..."],"goal":"...","constraints":["..."],"repo":"..." }`

---

### `/ck:save` — Lưu trạng thái session
**Đây là lệnh duy nhất cần LLM phân tích.** Phân tích cuộc hội thoại hiện tại:
- `summary`: một câu, tối đa 10 từ, những gì đã hoàn thành
- `leftOff`: việc đang được làm dở (file/tính năng/bug cụ thể)
- `nextSteps`: mảng có thứ tự các bước tiếp theo cụ thể
- `decisions`: mảng `{what, why}` cho các quyết định được đưa ra trong session này
- `blockers`: mảng các blocker hiện tại (mảng rỗng nếu không có)
- `goal`: chuỗi goal đã cập nhật **chỉ khi nó thay đổi trong session này**, nếu không thì bỏ qua

Hiển thị bản tóm tắt nháp cho người dùng: `"Session: '<summary>' — save this? (yes / edit)"`
Chờ xác nhận. Sau đó pipe vào save.mjs:
```bash
echo '<json>' | node "$HOME/.claude/skills/ck/commands/save.mjs"
```
Schema JSON (chính xác): `{"summary":"...","leftOff":"...","nextSteps":["..."],"decisions":[{"what":"...","why":"..."}],"blockers":["..."]}`
Hiển thị xác nhận từ stdout của script nguyên văn.

---

### `/ck:resume [name|number]` — Bản tóm tắt đầy đủ
```bash
node "$HOME/.claude/skills/ck/commands/resume.mjs" [arg]
```
Hiển thị output nguyên văn. Sau đó hỏi: "Continue from here? Or has anything changed?"
Nếu người dùng báo có thay đổi → chạy `/ck:save` ngay lập tức.

---

### `/ck:info [name|number]` — Ảnh chụp nhanh
```bash
node "$HOME/.claude/skills/ck/commands/info.mjs" [arg]
```
Hiển thị output nguyên văn. Không hỏi tiếp.

---

### `/ck:list` — Xem toàn bộ danh mục
```bash
node "$HOME/.claude/skills/ck/commands/list.mjs"
```
Hiển thị output nguyên văn. Nếu người dùng trả lời bằng số hoặc tên → chạy `/ck:resume`.

---

### `/ck:forget [name|number]` — Xóa một dự án
Trước tiên xác định tên dự án (chạy `/ck:list` nếu cần).
Hỏi: `"This will permanently delete context for '<name>'. Are you sure? (yes/no)"`
Nếu có:
```bash
node "$HOME/.claude/skills/ck/commands/forget.mjs" [name]
```
Hiển thị xác nhận nguyên văn.

---

### `/ck:migrate` — Chuyển dữ liệu v1 sang v2
```bash
node "$HOME/.claude/skills/ck/commands/migrate.mjs"
```
Để chạy thử (dry run) trước:
```bash
node "$HOME/.claude/skills/ck/commands/migrate.mjs" --dry-run
```
Hiển thị output nguyên văn. Migrate toàn bộ các file v1 CONTEXT.md + meta.json sang context.json v2.
Bản gốc được sao lưu thành `meta.json.v1-backup` — không có gì bị xóa.

---

## SessionStart Hook

Hook tại `~/.claude/skills/ck/hooks/session-start.mjs` phải được đăng ký trong
`~/.claude/settings.json` để tự động nạp context dự án khi bắt đầu session:

```json
{
  "hooks": {
    "SessionStart": [
      { "hooks": [{ "type": "command", "command": "node \"~/.claude/skills/ck/hooks/session-start.mjs\"" }] }
    ]
  }
}
```

Hook chèn khoảng ~100 token mỗi session (bản tóm tắt gọn 5 dòng). Nó cũng phát hiện
các session chưa lưu, hoạt động git kể từ lần lưu cuối, và goal không khớp với CLAUDE.md.

---

## Quy tắc
- Luôn mở rộng `~` thành `$HOME` trong các lệnh Bash.
- Lệnh không phân biệt hoa thường: `/CK:SAVE`, `/ck:save`, `/Ck:Save` đều hoạt động.
- Nếu một script thoát với mã 1, hiển thị stdout của nó như một thông báo lỗi.
- KHÔNG BAO GIỜ chỉnh sửa trực tiếp `context.json` hoặc `CONTEXT.md` — luôn dùng các script.
- Nếu `projects.json` bị hỏng định dạng, hãy báo người dùng và đề nghị reset nó về `{}`.
