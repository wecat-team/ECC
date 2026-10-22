---
description: Tạo kế hoạch triển khai đa model (Codex + Antigravity) mà không sửa code production. Yêu cầu runtime ccg-workflow bên ngoài, không nằm trong bản cài ECC cơ bản (xem Điều kiện tiên quyết bên dưới). Dùng khi người dùng tường minh muốn có bản nháp kế hoạch từ hai model; với kế hoạch đơn model không cần runtime bổ sung hãy dùng /plan.
---

# Plan - Lập kế hoạch cộng tác đa model

Lập kế hoạch cộng tác đa model - Truy xuất context + Phân tích hai model → Sinh kế hoạch triển khai từng bước.

> **Điều kiện tiên quyết:** Yêu cầu runtime `ccg-workflow` bên ngoài, runtime này **không** nằm trong bản cài ECC cơ bản. Khởi tạo nó bằng `npx ccg-workflow` để cấp phát `~/.claude/bin/codeagent-wrapper` và các file vai trò `~/.claude/.ccg/prompts/*` mà command này phụ thuộc. Nếu không có runtime đó, command này sẽ không chạy đúng.

$ARGUMENTS

---

## Giao thức cốt lõi

- **Giao thức ngôn ngữ**: Dùng **tiếng Anh** khi tương tác với tool/model, giao tiếp với người dùng bằng ngôn ngữ của họ
- **Song song bắt buộc**: Các lời gọi Codex/Antigravity PHẢI dùng `run_in_background: true` (kể cả lời gọi đơn model, để tránh chặn main thread)
- **Chủ quyền code (Code Sovereignty)**: Các model bên ngoài **không có quyền ghi filesystem**, mọi thay đổi do Claude thực hiện
- **Cơ chế cắt lỗ (Stop-Loss)**: Không chuyển sang giai đoạn tiếp theo cho đến khi output của giai đoạn hiện tại được xác thực
- **Chỉ lập kế hoạch**: Command này cho phép đọc context và ghi vào các file kế hoạch `.claude/plan/*`, nhưng **KHÔNG BAO GIỜ sửa code production**

---

## Đặc tả gọi đa model

**Cú pháp gọi** (song song: dùng `run_in_background: true`):

```
Bash({
  command: "~/.claude/bin/codeagent-wrapper --backend <codex|antigravity> - \"$PWD\" <<'EOF'
ROLE_FILE: <role prompt path>
<TASK>
Requirement: <enhanced requirement>
Context: <retrieved project context>
</TASK>
OUTPUT: Step-by-step implementation plan with pseudo-code. DO NOT modify any files.
EOF",
  run_in_background: true,
  timeout: 3600000,
  description: "Brief description"
})
```

**Ghi chú về tham số model**:
- Không cần thêm flag model cho `--backend antigravity` hoặc `--backend codex`; `codeagent-wrapper` tự chọn model mặc định của từng backend.

**Role Prompt**:

| Giai đoạn | Codex | Antigravity |
|-------|-------|--------|
| Phân tích | `~/.claude/.ccg/prompts/codex/analyzer.md` | `~/.claude/.ccg/prompts/antigravity/analyzer.md` |
| Lập kế hoạch | `~/.claude/.ccg/prompts/codex/architect.md` | `~/.claude/.ccg/prompts/antigravity/architect.md` |

**Tái sử dụng session**: Mỗi lần gọi trả về `SESSION_ID: xxx` (thường do wrapper xuất ra), **PHẢI lưu lại** để dùng cho `/ccg:execute` sau đó.

**Chờ các tác vụ nền** (timeout tối đa 600000ms = 10 phút):

```
TaskOutput({ task_id: "<task_id>", block: true, timeout: 600000 })
```

**QUAN TRỌNG**:
- PHẢI chỉ định `timeout: 600000`, nếu không mặc định 30 giây sẽ gây timeout sớm
- Nếu sau 10 phút vẫn chưa xong, tiếp tục polling bằng `TaskOutput`, **KHÔNG BAO GIỜ kill process**
- Nếu bỏ qua việc chờ do timeout, **PHẢI gọi `AskUserQuestion` để hỏi người dùng muốn tiếp tục chờ hay kill tác vụ**

---

## Workflow thực thi

**Tác vụ lập kế hoạch**: $ARGUMENTS

### Giai đoạn 1: Truy xuất toàn bộ context

`[Mode: Research]`

#### 1.1 Cải thiện prompt (PHẢI thực hiện đầu tiên)

**Nếu ace-tool MCP khả dụng**, gọi tool `mcp__ace-tool__enhance_prompt`:

```
mcp__ace-tool__enhance_prompt({
  prompt: "$ARGUMENTS",
  conversation_history: "<last 5-10 conversation turns>",
  project_root_path: "$PWD"
})
```

Chờ prompt đã được cải thiện, **thay $ARGUMENTS gốc bằng kết quả đã cải thiện** cho mọi giai đoạn sau.

**Nếu ace-tool MCP KHÔNG khả dụng**: Bỏ qua bước này và dùng nguyên `$ARGUMENTS` gốc cho mọi giai đoạn sau.

#### 1.2 Truy xuất context

**Nếu ace-tool MCP khả dụng**, gọi tool `mcp__ace-tool__search_context`:

```
mcp__ace-tool__search_context({
  query: "<semantic query based on enhanced requirement>",
  project_root_path: "$PWD"
})
```

- Xây dựng truy vấn ngữ nghĩa bằng ngôn ngữ tự nhiên (Where/What/How)
- **KHÔNG BAO GIỜ trả lời dựa trên giả định**

**Nếu ace-tool MCP KHÔNG khả dụng**, dùng các tool có sẵn của Claude Code làm phương án dự phòng:
1. **Glob**: Tìm các file liên quan theo pattern (ví dụ `Glob("**/*.ts")`, `Glob("src/**/*.py")`)
2. **Grep**: Tìm các symbol quan trọng, tên hàm, định nghĩa class (ví dụ `Grep("className|functionName")`)
3. **Read**: Đọc các file đã tìm thấy để thu thập context đầy đủ
4. **Task (Explore agent)**: Để khám phá sâu hơn, dùng `Task` với `subagent_type: "Explore"` để tìm trong toàn codebase

#### 1.3 Kiểm tra tính đầy đủ

- PHẢI lấy được **định nghĩa và chữ ký đầy đủ** của các class, hàm, biến liên quan
- Nếu context chưa đủ, kích hoạt **truy xuất đệ quy**
- Ưu tiên output: file đầu vào + số dòng + tên symbol quan trọng; chỉ thêm các đoạn code tối thiểu khi cần thiết để giải quyết sự mơ hồ

#### 1.4 Thống nhất yêu cầu

- Nếu yêu cầu vẫn còn mơ hồ, **PHẢI** đưa ra các câu hỏi dẫn dắt cho người dùng
- Cho đến khi ranh giới yêu cầu rõ ràng (không thiếu sót, không dư thừa)

### Giai đoạn 2: Phân tích cộng tác đa model

`[Mode: Analysis]`

#### 2.1 Phân phối input

**Gọi song song** Codex và Antigravity (`run_in_background: true`):

Phân phối **yêu cầu gốc** (không kèm ý kiến định sẵn) cho cả hai model:

1. **Phân tích Backend của Codex**:
   - ROLE_FILE: `~/.claude/.ccg/prompts/codex/analyzer.md`
   - Trọng tâm: Tính khả thi kỹ thuật, tác động kiến trúc, cân nhắc hiệu năng, rủi ro tiềm ẩn
   - OUTPUT: Các giải pháp đa góc nhìn + phân tích ưu/nhược điểm

2. **Phân tích Frontend của Antigravity**:
   - ROLE_FILE: `~/.claude/.ccg/prompts/antigravity/analyzer.md`
   - Trọng tâm: Tác động UI/UX, trải nghiệm người dùng, thiết kế trực quan
   - OUTPUT: Các giải pháp đa góc nhìn + phân tích ưu/nhược điểm

Chờ kết quả đầy đủ của cả hai model bằng `TaskOutput`. **Lưu SESSION_ID** (`CODEX_SESSION` và `ANTIGRAVITY_SESSION`).

#### 2.2 Kiểm chứng chéo

Tích hợp các góc nhìn và lặp để tối ưu:

1. **Xác định điểm đồng thuận** (tín hiệu mạnh)
2. **Xác định điểm bất đồng** (cần cân nhắc)
3. **Điểm mạnh bổ trợ nhau**: Backend logic theo Codex, thiết kế Frontend theo Antigravity
4. **Suy luận logic**: Loại bỏ các lỗ hổng logic trong giải pháp

#### 2.3 (Tùy chọn nhưng khuyến nghị) Bản nháp kế hoạch từ hai model

Để giảm rủi ro thiếu sót trong kế hoạch tổng hợp của Claude, có thể cho cả hai model song song xuất "bản nháp kế hoạch" (vẫn **KHÔNG được phép** sửa file):

1. **Bản nháp kế hoạch của Codex** (thẩm quyền Backend):
   - ROLE_FILE: `~/.claude/.ccg/prompts/codex/architect.md`
   - OUTPUT: Kế hoạch từng bước + pseudo-code (trọng tâm: luồng dữ liệu/edge case/xử lý lỗi/chiến lược test)

2. **Bản nháp kế hoạch của Antigravity** (thẩm quyền Frontend):
   - ROLE_FILE: `~/.claude/.ccg/prompts/antigravity/architect.md`
   - OUTPUT: Kế hoạch từng bước + pseudo-code (trọng tâm: kiến trúc thông tin/tương tác/accessibility/nhất quán trực quan)

Chờ kết quả đầy đủ của cả hai model bằng `TaskOutput`, ghi lại các khác biệt chính trong đề xuất của họ.

#### 2.4 Sinh kế hoạch triển khai (Bản cuối của Claude)

Tổng hợp cả hai bản phân tích, sinh **Kế hoạch triển khai từng bước**:

```markdown
## Implementation Plan: <Task Name>

### Task Type
- [ ] Frontend (→ Antigravity)
- [ ] Backend (→ Codex)
- [ ] Fullstack (→ Parallel)

### Technical Solution
<Optimal solution synthesized from Codex + Antigravity analysis>

### Implementation Steps
1. <Step 1> - Expected deliverable
2. <Step 2> - Expected deliverable
...

### Key Files
| File | Operation | Description |
|------|-----------|-------------|
| path/to/file.ts:L10-L50 | Modify | Description |

### Risks and Mitigation
| Risk | Mitigation |
|------|------------|

### SESSION_ID (for /ccg:execute use)
- CODEX_SESSION: <session_id>
- ANTIGRAVITY_SESSION: <session_id>
```

### Kết thúc Giai đoạn 2: Bàn giao kế hoạch (Không thực thi)

**Trách nhiệm của `/ccg:plan` kết thúc tại đây, PHẢI thực hiện các hành động sau**:

1. Trình bày kế hoạch triển khai hoàn chỉnh cho người dùng (bao gồm pseudo-code)
2. Lưu kế hoạch vào `.claude/plan/<feature-name>.md` (trích tên tính năng từ yêu cầu, ví dụ `user-auth`, `payment-module`)
3. Xuất thông báo bằng **chữ in đậm** (PHẢI dùng đường dẫn file thực tế đã lưu):

---
**Kế hoạch đã được tạo và lưu tại `.claude/plan/actual-feature-name.md`**

**Vui lòng review kế hoạch ở trên. Bạn có thể:**
- **Sửa kế hoạch**: Cho tôi biết cần điều chỉnh gì, tôi sẽ cập nhật kế hoạch
- **Thực thi kế hoạch**: Sao chép lệnh sau vào một phiên mới

```
/ccg:execute .claude/plan/actual-feature-name.md
```
---

**LƯU Ý**: `actual-feature-name.md` ở trên PHẢI được thay bằng tên file thực tế đã lưu!

4. **Kết thúc ngay phản hồi hiện tại** (Dừng tại đây. Không gọi tool nào nữa.)

**TUYỆT ĐỐI CẤM**:
- Hỏi người dùng "Y/N" rồi tự động thực thi (việc thực thi là trách nhiệm của `/ccg:execute`)
- Bất kỳ thao tác ghi nào vào code production
- Tự động gọi `/ccg:execute` hoặc bất kỳ hành động triển khai nào
- Tiếp tục kích hoạt các lời gọi model khi người dùng chưa yêu cầu tường minh việc sửa đổi

---

## Lưu kế hoạch

Sau khi lập kế hoạch xong, lưu kế hoạch vào:

- **Lần lập kế hoạch đầu tiên**: `.claude/plan/<feature-name>.md`
- **Các phiên bản lặp**: `.claude/plan/<feature-name>-v2.md`, `.claude/plan/<feature-name>-v3.md`...

Việc ghi file kế hoạch phải hoàn tất trước khi trình bày kế hoạch cho người dùng.

---

## Luồng sửa kế hoạch

Nếu người dùng yêu cầu sửa kế hoạch:

1. Điều chỉnh nội dung kế hoạch dựa trên phản hồi của người dùng
2. Cập nhật file `.claude/plan/<feature-name>.md`
3. Trình bày lại kế hoạch đã sửa
4. Nhắc người dùng review hoặc thực thi lại

---

## Các bước tiếp theo

Sau khi người dùng phê duyệt, **thủ công** thực thi:

```bash
/ccg:execute .claude/plan/<feature-name>.md
```

---

## Quy tắc chính

1. **Chỉ lập kế hoạch, không triển khai** – Command này không thực hiện bất kỳ thay đổi code nào
2. **Không hỏi Y/N** – Chỉ trình bày kế hoạch, để người dùng quyết định bước tiếp theo
3. **Quy tắc tin cậy** – Backend theo Codex, Frontend theo Antigravity
4. Các model bên ngoài **không có quyền ghi filesystem**
5. **Bàn giao SESSION_ID** – Kế hoạch PHẢI bao gồm `CODEX_SESSION` / `ANTIGRAVITY_SESSION` ở cuối (để dùng cho `/ccg:execute resume <SESSION_ID>`)
