---
description: Thực thi một kế hoạch triển khai đa model đồng thời giữ Claude là bên duy nhất được ghi vào filesystem.
---

# Execute - Thực thi cộng tác đa model

Thực thi cộng tác đa model - Lấy prototype từ kế hoạch → Claude refactor và triển khai → Audit đa model và bàn giao.

> **Điều kiện tiên quyết:** Yêu cầu runtime `ccg-workflow` bên ngoài, runtime này **không** nằm trong bản cài ECC cơ bản. Khởi tạo nó bằng `npx ccg-workflow` để cấp phát `~/.claude/bin/codeagent-wrapper` và các file vai trò `~/.claude/.ccg/prompts/*` mà command này phụ thuộc. Nếu không có runtime đó, command này sẽ không chạy đúng.

$ARGUMENTS

---

## Giao thức cốt lõi

- **Giao thức ngôn ngữ**: Dùng **tiếng Anh** khi tương tác với tool/model, giao tiếp với người dùng bằng ngôn ngữ của họ
- **Chủ quyền code (Code Sovereignty)**: Các model bên ngoài **không có quyền ghi filesystem**, mọi thay đổi do Claude thực hiện
- **Refactor prototype bẩn (Dirty Prototype)**: Coi Unified Diff của Codex/Antigravity là "prototype bẩn", PHẢI refactor thành code đạt chuẩn production
- **Cơ chế cắt lỗ (Stop-Loss)**: Không chuyển sang giai đoạn tiếp theo cho đến khi output của giai đoạn hiện tại được xác thực
- **Điều kiện tiên quyết**: Chỉ thực thi sau khi người dùng trả lời tường minh "Y" với output của `/ccg:plan` (nếu thiếu, PHẢI xác nhận trước)

---

## Đặc tả gọi đa model

**Cú pháp gọi** (song song: dùng `run_in_background: true`):

```
# Resume session call (recommended) - Implementation Prototype
Bash({
  command: "~/.claude/bin/codeagent-wrapper --backend <codex|antigravity> resume <SESSION_ID> - \"$PWD\" <<'EOF'
ROLE_FILE: <role prompt path>
<TASK>
Requirement: <task description>
Context: <plan content + target files>
</TASK>
OUTPUT: Unified Diff Patch ONLY. Strictly prohibit any actual modifications.
EOF",
  run_in_background: true,
  timeout: 3600000,
  description: "Brief description"
})

# New session call - Implementation Prototype
Bash({
  command: "~/.claude/bin/codeagent-wrapper --backend <codex|antigravity> - \"$PWD\" <<'EOF'
ROLE_FILE: <role prompt path>
<TASK>
Requirement: <task description>
Context: <plan content + target files>
</TASK>
OUTPUT: Unified Diff Patch ONLY. Strictly prohibit any actual modifications.
EOF",
  run_in_background: true,
  timeout: 3600000,
  description: "Brief description"
})
```

**Cú pháp gọi Audit** (Code Review / Audit):

```
Bash({
  command: "~/.claude/bin/codeagent-wrapper --backend <codex|antigravity> resume <SESSION_ID> - \"$PWD\" <<'EOF'
ROLE_FILE: <role prompt path>
<TASK>
Scope: Audit the final code changes.
Inputs:
- The applied patch (git diff / final unified diff)
- The touched files (relevant excerpts if needed)
Constraints:
- Do NOT modify any files.
- Do NOT output tool commands that assume filesystem access.
</TASK>
OUTPUT:
1) A prioritized list of issues (severity, file, rationale)
2) Concrete fixes; if code changes are needed, include a Unified Diff Patch in a fenced code block.
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
| Triển khai | `~/.claude/.ccg/prompts/codex/architect.md` | `~/.claude/.ccg/prompts/antigravity/frontend.md` |
| Review | `~/.claude/.ccg/prompts/codex/reviewer.md` | `~/.claude/.ccg/prompts/antigravity/reviewer.md` |

**Tái sử dụng session**: Nếu `/ccg:plan` cung cấp SESSION_ID, dùng `resume <SESSION_ID>` để tái sử dụng context.

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

**Tác vụ cần thực thi**: $ARGUMENTS

### Giai đoạn 0: Đọc kế hoạch

`[Mode: Prepare]`

1. **Xác định loại input**:
   - Đường dẫn file kế hoạch (ví dụ `.claude/plan/xxx.md`)
   - Mô tả tác vụ trực tiếp

2. **Đọc nội dung kế hoạch**:
   - Nếu có đường dẫn file kế hoạch, đọc và parse
   - Trích xuất: loại tác vụ, các bước triển khai, key file, SESSION_ID

3. **Xác nhận trước khi thực thi**:
   - Nếu input là "mô tả tác vụ trực tiếp" hoặc kế hoạch thiếu `SESSION_ID` / key file: xác nhận với người dùng trước
   - Nếu không thể xác nhận người dùng đã trả lời "Y" với kế hoạch: PHẢI xác nhận lại trước khi tiếp tục

4. **Định tuyến theo loại tác vụ**:

   | Loại tác vụ | Nhận diện | Định tuyến |
   |-----------|-----------|-------|
   | **Frontend** | Trang, component, UI, style, layout | Antigravity |
   | **Backend** | API, interface, database, logic, thuật toán | Codex |
   | **Fullstack** | Gồm cả frontend và backend | Codex ∥ Antigravity song song |

---

### Giai đoạn 1: Truy xuất context nhanh

`[Mode: Retrieval]`

**Nếu ace-tool MCP khả dụng**, dùng nó để truy xuất context nhanh:

Dựa trên danh sách "Key Files" trong kế hoạch, gọi `mcp__ace-tool__search_context`:

```
mcp__ace-tool__search_context({
  query: "<semantic query based on plan content, including key files, modules, function names>",
  project_root_path: "$PWD"
})
```

**Chiến lược truy xuất**:
- Trích xuất các đường dẫn đích từ bảng "Key Files" của kế hoạch
- Xây dựng truy vấn ngữ nghĩa bao quát: file đầu vào, module dependency, các định nghĩa type liên quan
- Nếu kết quả chưa đủ, thêm 1-2 lần truy xuất đệ quy

**Nếu ace-tool MCP KHÔNG khả dụng**, dùng các tool có sẵn của Claude Code làm phương án dự phòng:
1. **Glob**: Tìm các file đích từ bảng "Key Files" của kế hoạch (ví dụ `Glob("src/components/**/*.tsx")`)
2. **Grep**: Tìm các symbol quan trọng, tên hàm, định nghĩa type trong toàn codebase
3. **Read**: Đọc các file đã tìm thấy để thu thập context đầy đủ
4. **Task (Explore agent)**: Để khám phá rộng hơn, dùng `Task` với `subagent_type: "Explore"`

**Sau khi truy xuất**:
- Sắp xếp các đoạn code đã truy xuất
- Xác nhận đã có đủ context để triển khai
- Chuyển sang Giai đoạn 3

---

### Giai đoạn 3: Lấy prototype

`[Mode: Prototype]`

**Định tuyến theo loại tác vụ**:

#### Route A: Frontend/UI/Style → Antigravity

**Giới hạn**: Context < 32k token

1. Gọi Antigravity (dùng `~/.claude/.ccg/prompts/antigravity/frontend.md`)
2. Input: Nội dung kế hoạch + context đã truy xuất + các file đích
3. OUTPUT: `Unified Diff Patch ONLY. Strictly prohibit any actual modifications.`
4. **Antigravity là thẩm quyền thiết kế frontend, prototype CSS/React/Vue của nó là baseline trực quan cuối cùng**
5. **CẢNH BÁO**: Bỏ qua các đề xuất về backend logic của Antigravity
6. Nếu kế hoạch có `ANTIGRAVITY_SESSION`: ưu tiên `resume <ANTIGRAVITY_SESSION>`

#### Route B: Backend/Logic/Thuật toán → Codex

1. Gọi Codex (dùng `~/.claude/.ccg/prompts/codex/architect.md`)
2. Input: Nội dung kế hoạch + context đã truy xuất + các file đích
3. OUTPUT: `Unified Diff Patch ONLY. Strictly prohibit any actual modifications.`
4. **Codex là thẩm quyền về backend logic, tận dụng khả năng suy luận logic và debug của nó**
5. Nếu kế hoạch có `CODEX_SESSION`: ưu tiên `resume <CODEX_SESSION>`

#### Route C: Fullstack → Gọi song song

1. **Gọi song song** (`run_in_background: true`):
   - Antigravity: Xử lý phần frontend
   - Codex: Xử lý phần backend
2. Chờ kết quả đầy đủ của cả hai model bằng `TaskOutput`
3. Mỗi bên dùng `SESSION_ID` tương ứng từ kế hoạch để `resume` (tạo session mới nếu thiếu)

**Làm theo các chỉ dẫn `QUAN TRỌNG` trong `Đặc tả gọi đa model` ở trên**

---

### Giai đoạn 4: Triển khai code

`[Mode: Implement]`

**Claude với vai trò Code Sovereign thực hiện các bước sau**:

1. **Đọc Diff**: Parse Unified Diff Patch do Codex/Antigravity trả về

2. **Sandbox trong đầu (Mental Sandbox)**:
   - Mô phỏng việc áp dụng Diff vào các file đích
   - Kiểm tra tính nhất quán logic
   - Xác định các xung đột hoặc tác dụng phụ tiềm ẩn

3. **Refactor và dọn dẹp**:
   - Refactor "prototype bẩn" thành **code có độ dễ đọc cao, dễ bảo trì, đạt chuẩn enterprise**
   - Loại bỏ code thừa
   - Đảm bảo tuân thủ chuẩn code hiện có của dự án
   - **Không sinh comment/tài liệu trừ khi cần thiết**, code phải tự giải thích

4. **Phạm vi tối thiểu**:
   - Thay đổi chỉ giới hạn trong phạm vi yêu cầu
   - **Bắt buộc review** các tác dụng phụ
   - Thực hiện các chỉnh sửa có mục tiêu

5. **Áp dụng thay đổi**:
   - Dùng tool Edit/Write để thực hiện các sửa đổi thực tế
   - **Chỉ sửa code cần thiết**, không bao giờ ảnh hưởng đến các chức năng khác đang có của người dùng

6. **Tự xác minh** (rất khuyến nghị):
   - Chạy lint / typecheck / test hiện có của dự án (ưu tiên phạm vi liên quan tối thiểu)
   - Nếu thất bại: sửa regression trước, rồi mới chuyển sang Giai đoạn 5

---

### Giai đoạn 5: Audit và bàn giao

`[Mode: Audit]`

#### 5.1 Audit tự động

**Sau khi thay đổi có hiệu lực, PHẢI gọi song song ngay** Codex và Antigravity để Code Review:

1. **Codex Review** (`run_in_background: true`):
   - ROLE_FILE: `~/.claude/.ccg/prompts/codex/reviewer.md`
   - Input: Diff đã thay đổi + các file đích
   - Trọng tâm: Bảo mật, hiệu năng, xử lý lỗi, tính đúng đắn của logic

2. **Antigravity Review** (`run_in_background: true`):
   - ROLE_FILE: `~/.claude/.ccg/prompts/antigravity/reviewer.md`
   - Input: Diff đã thay đổi + các file đích
   - Trọng tâm: Accessibility, tính nhất quán thiết kế, trải nghiệm người dùng

Chờ kết quả review đầy đủ của cả hai model bằng `TaskOutput`. Ưu tiên tái sử dụng các session của Giai đoạn 3 (`resume <SESSION_ID>`) để nhất quán context.

#### 5.2 Tích hợp và sửa

1. Tổng hợp phản hồi review của Codex + Antigravity
2. Cân nhắc theo quy tắc tin cậy: Backend theo Codex, Frontend theo Antigravity
3. Thực hiện các bản sửa cần thiết
4. Lặp lại Giai đoạn 5.1 khi cần (đến khi rủi ro chấp nhận được)

#### 5.3 Xác nhận bàn giao

Sau khi audit đạt, báo cáo cho người dùng:

```markdown
## Execution Complete

### Change Summary
| File | Operation | Description |
|------|-----------|-------------|
| path/to/file.ts | Modified | Description |

### Audit Results
- Codex: <Passed/Found N issues>
- Antigravity: <Passed/Found N issues>

### Recommendations
1. [ ] <Suggested test steps>
2. [ ] <Suggested verification steps>
```

---

## Quy tắc chính

1. **Code Sovereignty** – Mọi sửa đổi file do Claude thực hiện, các model bên ngoài không có quyền ghi
2. **Refactor prototype bẩn** – Output của Codex/Antigravity được coi là bản nháp, PHẢI refactor
3. **Quy tắc tin cậy** – Backend theo Codex, Frontend theo Antigravity
4. **Thay đổi tối thiểu** – Chỉ sửa code cần thiết, không có tác dụng phụ
5. **Audit bắt buộc** – PHẢI thực hiện Code Review đa model sau khi thay đổi

---

## Cách dùng

```bash
# Execute plan file
/ccg:execute .claude/plan/feature-name.md

# Execute task directly (for plans already discussed in context)
/ccg:execute implement user authentication based on previous plan
```

---

## Quan hệ với /ccg:plan

1. `/ccg:plan` sinh kế hoạch + SESSION_ID
2. Người dùng xác nhận bằng "Y"
3. `/ccg:execute` đọc kế hoạch, tái sử dụng SESSION_ID, thực thi triển khai
