---
name: skill-host-compat
description: Lint các skill ECC để đảm bảo frontmatter an toàn cho Codex/Cursor và các phần thay thế chỉ dành cho Claude trước khi mở PR cho skill.
origin: ECC
---

# Skill Host Compatibility

Chạy cùng gate host-compat mà CI dùng trên `skills/` trước khi mở PR cho skill.
Việc kiểm tra này dành cho các bản sao trên Codex và Cursor, không phải chất lượng runtime chỉ dành cho Claude.

## Khi nào kích hoạt

- Thêm hoặc chỉnh sửa một skill trong `skills/`
- Sao chép một skill vào `.agents/skills/` hoặc `.cursor/skills/`
- Một review hỏi liệu skill có an toàn để cài vào Codex hoặc Cursor hay không
- CI báo các phát hiện của `validate-skill-host-compat.js`

## Khái niệm cốt lõi

Các skill chuẩn (canonical) nằm trong `skills/`. Codex nạp `.agents/skills/`. Cursor nạp một tập con
nhỏ hơn trong `.cursor/skills/`. CONTRIBUTING ghi rõ việc đồng bộ này là thủ công.

`validate-skills.js` chỉ kiểm tra `SKILL.md` có tồn tại và `name` /
`description` là YAML dùng được. `tests/ci/codex-skill-surface.test.js` chỉ
nhìn thấy `.agents/skills/`. Script này là gate xuyên các cây thư mục (cross-tree):

1. Các phần thay thế chỉ dành cho Claude trong các fence `bash` / `sh` / `zsh` có thể thực thi
   ở các bản chiếu (projection) Codex/Cursor (`${CLAUDE_SESSION_ID}`, `${CLAUDE_SKILL_DIR}`, `${CLAUDE_PLUGIN_ROOT}`,
   `${CLAUDE_PROJECT_DIR}`, `$ARGUMENTS`) sẽ bị fail. Codex giữ nguyên các token đó
   dưới dạng văn bản thuần. Trong bản sao Codex, hãy viết lại `${CLAUDE_PROJECT_DIR}` thành
   `$(pwd)` hoặc một đường dẫn tường minh.
2. Một bản sao Codex chỉ được dùng `name`, `description`, `metadata`, `license`,
   và `allowed-tools`. `origin: ECC` có thể giữ lại ở bản sao chuẩn trong `skills/`
   và phải được loại bỏ ở bản sao Codex.
3. Một skill được liệt kê trong `agents/openai.yaml` mà có thư mục `skills/` thì phải
   có `.agents/skills/<name>/`. Bản sao Cursor là tùy chọn; khi có, `name:`
   phải khớp với tên thư mục.
4. Các mục trong checklist của CONTRIBUTING (When to Activate, Anti-Patterns, name
   khớp với tên thư mục, giới hạn 500/800 dòng) chỉ cảnh báo. Chúng chỉ fail khi dùng
   `--strict-checklist`.

Mặc định cảnh báo WARN về frontmatter của `validate-skills.js` không đổi (#1663).

## Ví dụ code

Từ thư mục gốc của repo:

```bash
node scripts/ci/validate-skill-host-compat.js
```

In số lượng mà không làm fail:

```bash
node scripts/ci/validate-skill-host-compat.js --inventory
```

Nâng các cảnh báo checklist thành lỗi:

```bash
node scripts/ci/validate-skill-host-compat.js --strict-checklist
```

Slash command:

```
/skill-host-compat
/skill-host-compat --inventory
```

## Anti-Pattern

Các bản chiếu Codex và Cursor phải xử lý (resolve) các phần thay thế chỉ dành cho Claude trong các khối có thể thực thi. Các ví dụ phạm vi Claude trong bản chuẩn vẫn hợp lệ. Các tham số POSIX `$1` và `${1}` mang tính mơ hồ và cần được review thay vì làm fail gate này. Fence này là
pattern bị cấm:

```bash
echo "${CLAUDE_SESSION_ID}"
ls "${CLAUDE_SKILL_DIR}"
node "${CLAUDE_PLUGIN_ROOT}/scripts/setup.js" $ARGUMENTS
cd "${CLAUDE_PROJECT_DIR}"
```

Không thêm `version:` hoặc `origin:` vào bản sao Codex trong `.agents/skills/`.
Không coi việc `validate-skills.js` chạy pass là đã an toàn cho Codex. Không yêu cầu
mọi mục trong `skills/` phải có bản sao Cursor.

## Best Practice

- Giữ `origin: ECC` ở bản chuẩn nếu template trong CONTRIBUTING yêu cầu.
- Bỏ `origin`, `version` và `argument-hint` ở bản sao Codex.
- Hiển thị các lệnh portable giữa các host trong bash fence (`npx`, `ecc`, hoặc một
  root đã được resolve). Viết lại `${CLAUDE_PROJECT_DIR}` trong bản sao Codex thành `$(pwd)` hoặc một
  đường dẫn tường minh. Giữ các dạng hợp lệ trong phạm vi Claude ở hướng dẫn chuẩn; resolve các biến của host trong bản chiếu đích.
- Chạy script này trước `npm test` khi thay đổi là một skill mới.
- Dùng `--inventory` để xem số lượng cảnh báo checklist mà không làm fail cây thư mục.

## Skill liên quan

- `skill-comply` — trace hành vi lúc runtime, không phải tính portable giữa các host
- `skill-stocktake` — audit tổng thể các skill đã cài trong `~/.claude/skills`
- `skill-scout` — tìm kiếm các skill hiện có trước khi tạo skill mới
