---
name: evolve
description: Phân tích instinct và đề xuất hoặc sinh ra các cấu trúc tiến hóa (evolved structures)
command: true
---

# Lệnh Evolve

## Triển khai

Chạy instinct CLI bằng đường dẫn gốc của plugin:

```bash
python3 "${CLAUDE_PLUGIN_ROOT}/skills/continuous-learning-v2/scripts/instinct-cli.py" evolve [--generate]
```

Hoặc nếu `CLAUDE_PLUGIN_ROOT` chưa được đặt (cài đặt thủ công):

```bash
python3 ~/.claude/skills/continuous-learning-v2/scripts/instinct-cli.py evolve [--generate]
```

Phân tích các instinct và gom nhóm những instinct liên quan thành các cấu trúc cấp cao hơn:
- **Commands**: Khi các instinct mô tả những hành động do người dùng gọi
- **Skills**: Khi các instinct mô tả những hành vi được kích hoạt tự động
- **Agents**: Khi các instinct mô tả những quy trình phức tạp, nhiều bước

## Cách dùng

```
/evolve                    # Analyze all instincts and suggest evolutions
/evolve --generate         # Also generate files under evolved/{skills,commands,agents}
```

## Quy tắc tiến hóa

### → Command (do người dùng gọi)
Khi các instinct mô tả những hành động mà người dùng sẽ yêu cầu một cách tường minh:
- Nhiều instinct về "when user asks to..."
- Các instinct có trigger kiểu "when creating a new X"
- Các instinct theo một chuỗi có thể lặp lại

Ví dụ:
- `new-table-step1`: "when adding a database table, create migration"
- `new-table-step2`: "when adding a database table, update schema"
- `new-table-step3`: "when adding a database table, regenerate types"

→ Tạo ra: command **new-table**

### → Skill (kích hoạt tự động)
Khi các instinct mô tả những hành vi cần xảy ra tự động:
- Trigger khớp theo pattern
- Phản hồi xử lý lỗi
- Áp dụng code style

Ví dụ:
- `prefer-functional`: "when writing functions, prefer functional style"
- `use-immutable`: "when modifying state, use immutable patterns"
- `avoid-classes`: "when designing modules, avoid class-based design"

→ Tạo ra: skill `functional-patterns`

### → Agent (cần chiều sâu/cô lập)
Khi các instinct mô tả những quy trình phức tạp, nhiều bước, được lợi từ việc cô lập:
- Workflow debug
- Chuỗi refactor
- Tác vụ nghiên cứu

Ví dụ:
- `debug-step1`: "when debugging, first check logs"
- `debug-step2`: "when debugging, isolate the failing component"
- `debug-step3`: "when debugging, create minimal reproduction"
- `debug-step4`: "when debugging, verify fix with test"

→ Tạo ra: agent **debugger**

## Cần làm gì

1. Phát hiện context dự án hiện tại
2. Đọc instinct của dự án + global (dự án được ưu tiên khi trùng ID)
3. Nhóm các instinct theo pattern trigger/domain
4. Xác định:
   - Ứng viên skill (cụm trigger có từ 2 instinct trở lên)
   - Ứng viên command (instinct workflow có độ tin cậy cao)
   - Ứng viên agent (cụm lớn hơn, độ tin cậy cao)
5. Hiển thị các ứng viên được nâng cấp (project -> global) khi phù hợp
6. Nếu truyền `--generate`, ghi file vào:
   - Phạm vi dự án: `~/.claude/homunculus/projects/<project-id>/evolved/`
   - Global dự phòng: `~/.claude/homunculus/evolved/`

## Định dạng output

```
============================================================
  EVOLVE ANALYSIS - 12 instincts
  Project: my-app (a1b2c3d4e5f6)
  Project-scoped: 8 | Global: 4
============================================================

High confidence instincts (>=80%): 5

## SKILL CANDIDATES
1. Cluster: "adding tests"
   Instincts: 3
   Avg confidence: 82%
   Domains: testing
   Scopes: project

## COMMAND CANDIDATES (2)
  /adding-tests
    From: test-first-workflow [project]
    Confidence: 84%

## AGENT CANDIDATES (1)
  adding-tests-agent
    Covers 3 instincts
    Avg confidence: 82%
```

## Flag

- `--generate`: Sinh thêm các file evolved ngoài output phân tích

## Định dạng file được sinh ra

### Command
```markdown
---
name: new-table
description: Create a new database table with migration, schema update, and type generation
command: /new-table
evolved_from:
  - new-table-migration
  - update-schema
  - regenerate-types
---

# New Table Command

[Generated content based on clustered instincts]

## Steps
1. ...
2. ...
```

### Skill
```markdown
---
name: functional-patterns
description: Enforce functional programming patterns
evolved_from:
  - prefer-functional
  - use-immutable
  - avoid-classes
---

# Functional Patterns Skill

[Generated content based on clustered instincts]
```

### Agent
```markdown
---
name: debugger
description: Systematic debugging agent
model: sonnet
evolved_from:
  - debug-check-logs
  - debug-isolate
  - debug-reproduce
---

# Debugger Agent

[Generated content based on clustered instincts]
```
