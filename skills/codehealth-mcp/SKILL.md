---
name: codehealth-mcp
description: Code Health cấu trúc theo thời gian thực qua CodeScene MCP — review trước khi sửa, kiểm tra độ chênh điểm (score delta) sau khi thay đổi, chặn (gate) commit và PR. Dùng khi review chất lượng code, refactor, kiểm tra xem các thay đổi do AI có làm giảm chất lượng một file hay không, hoặc trước commit/PR.
metadata:
  origin: community
---

# Code Health MCP (CodeScene)

Phản hồi về khả năng bảo trì ở mức cấu trúc cho việc lập trình có AI hỗ trợ. Bổ sung cho các skill về style/lint (`coding-standards`, `plankton-code-quality`) bằng điểm sức khỏe ở mức **thiết kế** và các regression gate.

**Upstream:** [codescene-oss/codescene-mcp-server](https://github.com/codescene-oss/codescene-mcp-server)
**Package:** `@codescene/codehealth-mcp` (stdio qua npx)

## Bảo mật và ranh giới

**Opt-in (ECC):** Khối `codescene` trong `mcp-configs/mcp-servers.json` chỉ là template. Việc cài plugin ECC không tự động bật các MCP server đi kèm. Chỉ sao chép entry này vào config của bạn nếu bạn muốn dùng. Bạn có thể loại nó ra khi cài đặt/đồng bộ ECC bằng `ECC_DISABLED_MCPS=codescene,...`.

**Credentials:** Không có token đi kèm. Tự đặt `CS_ACCESS_TOKEN` (xem [getting-a-personal-access-token.md](https://github.com/codescene-oss/codescene-mcp-server/blob/main/docs/getting-a-personal-access-token.md) trong repo upstream). KHÔNG BAO GIỜ commit token vào repo.

**Các tool đọc gì:** Khi được gọi, các tool phân tích file và trạng thái git **trong repository cục bộ** mà bạn trỏ tới (các đường dẫn bạn truyền vào, cộng với context branch cho `analyze_change_set`). Chúng không tự chạy. Với chế độ standalone, hãy theo tài liệu quyền riêng tư của upstream: [codescene-mcp-server README](https://github.com/codescene-oss/codescene-mcp-server#frequently-asked-questions) và [chính sách CodeScene](https://codescene.com/policies). Không dùng skill này cho secret, credential hoặc các đường dẫn bạn không muốn bị phân tích.

**Nếu MCP không khả dụng (offline, token sai, server crash):** KHÔNG bịa điểm Code Health. Báo cho người dùng biết bước kiểm tra đã bị bỏ qua. Chỉ tiếp tục khi có sự đồng ý rõ ràng của người dùng. Ưu tiên lint/test/verification-loop để gate khi MCP ngừng hoạt động. Bật lại các bước kiểm tra khi server kết nối trở lại.

## Khi nào dùng

- Người dùng yêu cầu **review chất lượng code**, **refactor** một file, hoặc kiểm tra xem **các thay đổi do AI** có làm giảm khả năng bảo trì không
- Trước khi sửa một **hotspot**, module legacy hoặc file không quen thuộc
- Trước **commit** hoặc **pull request** khi bạn cần một lớp bảo vệ về khả năng bảo trì
- Sau một diff lớn do agent viết — xác minh Code Health không bị thụt lùi
- Kết hợp với `verification-loop`, `tdd-workflow` hoặc `/quality-gate` như một bước kiểm tra cấu trúc (không thay thế test/lint)

## Khi nào kích hoạt

Cùng điều kiện kích hoạt như mục **Khi nào dùng** ở trên — tiêu đề này là thứ ECC dùng để tự động kích hoạt skill.

## Cách hoạt động

### 1. Kết nối MCP server

Sao chép entry `codescene` từ `mcp-configs/mcp-servers.json` vào config MCP của harness bạn dùng.

**Claude Code** (`~/.claude.json` → `mcpServers`):

```json
"codescene": {
  "command": "npx",
  "args": ["-y", "@codescene/codehealth-mcp"],
  "env": {
    "CS_ACCESS_TOKEN": "YOUR_CS_ACCESS_TOKEN_HERE"
  }
}
```

**Phạm vi dự án:** gộp cùng khối này vào `.mcp.json` ở thư mục gốc của repo.

Cách thiết lập token được ghi trong repo upstream (link ở trên). Chế độ standalone không yêu cầu tài khoản nền tảng CodeScene trả phí cho bốn tool liệt kê bên dưới. Khởi động lại session và xác nhận server `codescene` đã kết nối trước khi dựa vào các điểm số.

### 2. Chỉ gọi các tool standalone

| Tool | Khi nào dùng |
|------|-------------|
| `code_health_review` | Phân tích cấu trúc đầy đủ **trước khi** sửa một file |
| `code_health_score` | Điểm số nhanh sau mỗi thay đổi (kiểm tra delta) |
| `pre_commit_code_health_safeguard` | Chặn các commit gây ra regression về Code Health |
| `analyze_change_set` | Kiểm tra ở mức branch **trước khi** mở PR |

KHÔNG gọi các tool chỉ có trên platform (ví dụ danh sách hotspot technical debt toàn repository). KHÔNG tham chiếu `delta_analysis` — không có trên standalone.

### 3. Diễn giải điểm số (1–10)

| Khoảng | Ý nghĩa | Hành vi của agent |
|-------|---------|----------------|
| **9.0–10.0** | Xanh — khỏe mạnh | An toàn hơn để mở rộng; vẫn ưu tiên vertical slice |
| **4.0–8.9** | Vàng — có nợ kỹ thuật | Cẩn trọng; không refactor tiện tay |
| **1.0–3.9** | Đỏ — nợ kỹ thuật nghiêm trọng | Chỉ thay đổi phạm vi hẹp |

### 4. Chạy vòng lặp phản hồi

**Trước khi đụng vào một file**

1. Chạy `code_health_review` trên đường dẫn mục tiêu.
2. Ghi lại điểm baseline và các code smell được liệt kê.
3. Lên kế hoạch cho thay đổi nhỏ nhất đáp ứng được tác vụ.

Phạm vi theo điểm: **dưới 5** — chỉ diff tối thiểu; **5–7** — không refactor rộng; **trên 7** — an toàn hơn để refactor, vẫn xác minh sau mỗi lần sửa.

**Sau mỗi thay đổi**

1. Chạy `code_health_score` trên cùng file.
2. So sánh với baseline từ `code_health_review`.
3. Nếu điểm **bị thụt lùi**, hãy sửa trước khi tiếp tục. KHÔNG BAO GIỜ đánh dấu tác vụ hoàn thành khi điểm thấp hơn lúc bạn bắt đầu.

**Trước mỗi commit** — chạy `pre_commit_code_health_safeguard` trên đường dẫn repository.

**Trước một PR** — chạy `analyze_change_set` so với base branch (ví dụ `main`).

## Ví dụ

### Ví dụ: Cải thiện khả năng bảo trì của Flask

Trên `pallets/flask`, một vòng lặp agent chỉ dùng các tool standalone:

1. `code_health_review` trên một module mục tiêu (baseline **4.82**)
2. Refactor có mục tiêu để xử lý các smell được liệt kê
3. `code_health_score` sau mỗi lần sửa
4. `pre_commit_code_health_safeguard` trước commit
5. `analyze_change_set` trước PR

Kết quả: Code Health **4.82 → 9.1** (chỉ dùng token standalone miễn phí).

### Ví dụ: Khối bắt buộc cho AGENTS.md

Dán vào `AGENTS.md` hoặc `CLAUDE.md` của dự án:

```md
## Code Health (CodeScene MCP)

Before modifying any file: run `code_health_review`, note score and issues.

- Score below 5: problematic range — scope changes narrowly.
- Score 5–7: warning range — no broad refactors.

After each change: run `code_health_score` to verify delta.

- If score regressed: fix before continuing; never declare done if score dropped.

Before every commit: run `pre_commit_code_health_safeguard`.

Before PR: run `analyze_change_set`.
```

### Ví dụ: anti-pattern so với vòng lặp đúng

```markdown
# BAD: Edit first, check later
[large refactor without code_health_review]

# BAD: Ignore score drop
"Tests pass" → mark task done while Code Health decreased

# BAD: Broad refactor on red-score file (below 5)
Drive-by cleanup across the module

# GOOD: review → small change → score → commit safeguard → analyze_change_set
```

## Kết hợp với ECC

| ECC skill / flow | Vai trò của Code Health MCP |
|------------------|----------------------|
| `coding-standards` | Style/đặt tên; Code Health = cấu trúc/độ phức tạp |
| `plankton-code-quality` | Lint/format lúc viết; Code Health = gate cấu trúc trước/sau khi sửa |
| `verification-loop` / `/quality-gate` | Thêm kiểm tra regression cấu trúc trước khi "done" |
| `security-review` | Bảo mật so với khả năng bảo trì — dùng cả hai khi liên quan |
| `tdd-workflow` | Test pass ≠ thiết kế khỏe mạnh — kiểm tra điểm sau khi refactor |

**Mẹo về context:** ECC khuyến nghị giữ số lượng MCP thấp. Bật `codescene` khi thực hiện các chỉnh sửa đáng kể; tắt khi không cần.

## Skill liên quan

- `coding-standards` — convention nền tảng
- `plankton-code-quality` — hook lint/format lúc viết
- `verification-loop` — gate build/test/lint
- `tdd-workflow` — phát triển test-first
- `security-review` — checklist bảo mật
- `documentation-lookup` — tài liệu thư viện qua Context7 (độc lập)
