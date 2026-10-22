---
name: continuous-learning-v2
description: Hệ thống học dựa trên instinct, quan sát session qua hook, tạo các instinct nguyên tử (atomic) kèm chấm điểm confidence, và tiến hóa chúng thành skill/command/agent. v2.1 bổ sung instinct theo phạm vi dự án (project-scoped) để ngăn nhiễm chéo giữa các dự án. Dùng khi ghi nhận bài học từ một session, quản lý instinct, hoặc nâng cấp chúng thành skill, command hay agent.
metadata:
  version: 2.1.0
  origin: ECC
---

# Continuous Learning v2.1 - Kiến trúc dựa trên Instinct

Một hệ thống học nâng cao biến các session Claude Code của bạn thành kiến thức tái sử dụng được thông qua các "instinct" nguyên tử - những hành vi nhỏ đã học được kèm chấm điểm confidence.

**v2.1** bổ sung **instinct theo phạm vi dự án (project-scoped)** — pattern React ở lại trong dự án React của bạn, convention Python ở lại trong dự án Python của bạn, và các pattern phổ quát (như "luôn validate input") được chia sẻ toàn cục.

## Khi nào kích hoạt

- Thiết lập học tự động từ các session Claude Code
- Cấu hình trích xuất hành vi dựa trên instinct qua hook
- Tinh chỉnh ngưỡng confidence cho các hành vi đã học
- Review, export hoặc import thư viện instinct
- Tiến hóa instinct thành skill, command hoặc agent hoàn chỉnh
- Quản lý instinct project-scoped so với global
- Nâng cấp instinct từ phạm vi dự án lên toàn cục

## Điểm mới trong v2.1

| Tính năng | v2.0 | v2.1 |
|---------|------|------|
| Lưu trữ | Toàn cục (`~/.claude/homunculus/`) | Theo dự án (`${XDG_DATA_HOME:-~/.local/share}/ecc-homunculus/projects/<hash>/`) |
| Phạm vi (Scope) | Mọi instinct áp dụng ở mọi nơi | Project-scoped + global |
| Phát hiện | Không có | git remote URL / đường dẫn repo |
| Nâng cấp (Promotion) | N/A | Project → global khi thấy ở 2+ dự án |
| Command | 4 (status/evolve/export/import) | 6 (+promote/projects) |
| Chéo dự án | Có nguy cơ nhiễm | Mặc định được cô lập |

## Điểm mới trong v2 (so với v1)

| Tính năng | v1 | v2 |
|---------|----|----|
| Quan sát | Stop hook (cuối session) | PreToolUse/PostToolUse (đáng tin cậy 100%) |
| Phân tích | Context chính | Agent chạy nền (Haiku) |
| Độ chi tiết | Skill đầy đủ | "Instinct" nguyên tử |
| Confidence | Không có | 0.3-0.9 có trọng số |
| Tiến hóa | Trực tiếp thành skill | Instinct -> cluster -> skill/command/agent |
| Chia sẻ | Không có | Export/import instinct |

## Mô hình Instinct

Một instinct là một hành vi nhỏ đã học được:

```yaml
---
id: prefer-functional-style
trigger: "when writing new functions"
confidence: 0.7
domain: "code-style"
source: "session-observation"
scope: project
project_id: "a1b2c3d4e5f6"
project_name: "my-react-app"
---

# Prefer Functional Style

## Action
Use functional patterns over classes when appropriate.

## Evidence
- Observed 5 instances of functional pattern preference
- User corrected class-based approach to functional on 2025-01-15
```

**Thuộc tính:**
- **Nguyên tử (Atomic)** -- một trigger, một action
- **Có trọng số confidence** -- 0.3 = tentative, 0.9 = gần như chắc chắn
- **Gắn tag domain** -- code-style, testing, git, debugging, workflow, v.v.
- **Có bằng chứng hậu thuẫn** -- theo dõi những observation nào đã tạo ra nó
- **Nhận biết scope** -- `project` (mặc định) hoặc `global`

## Cách hoạt động

```
Session Activity (in a git repo)
      |
      | Hooks capture prompts + tool use (100% reliable)
      | + detect project context (git remote / repo path)
      v
+---------------------------------------------+
|  projects/<project-hash>/observations.jsonl  |
|   (prompts, tool calls, outcomes, project)   |
+---------------------------------------------+
      |
      | Observer agent reads (background, Haiku)
      v
+---------------------------------------------+
|          PATTERN DETECTION                   |
|   * User corrections -> instinct             |
|   * Error resolutions -> instinct            |
|   * Repeated workflows -> instinct           |
|   * Scope decision: project or global?       |
+---------------------------------------------+
      |
      | Creates/updates
      v
+---------------------------------------------+
|  projects/<project-hash>/instincts/personal/ |
|   * prefer-functional.yaml (0.7) [project]   |
|   * use-react-hooks.yaml (0.9) [project]     |
+---------------------------------------------+
|  instincts/personal/  (GLOBAL)               |
|   * always-validate-input.yaml (0.85) [global]|
|   * grep-before-edit.yaml (0.6) [global]     |
+---------------------------------------------+
      |
      | /evolve clusters + /promote
      v
+---------------------------------------------+
|  projects/<hash>/evolved/ (project-scoped)   |
|  evolved/ (global)                           |
|   * commands/new-feature.md                  |
|   * skills/testing-workflow.md               |
|   * agents/refactor-specialist.md            |
+---------------------------------------------+
```

## Phát hiện dự án

Hệ thống tự động phát hiện dự án hiện tại của bạn:

1. **Biến môi trường `CLAUDE_PROJECT_DIR`** (ưu tiên cao nhất) -- được tôn trọng như một override tường minh ngay cả khi thư mục không phải git repo (được hash theo đường dẫn tuyệt đối của nó)
2. **`git remote get-url origin`** -- được hash để tạo ID dự án portable (cùng repo trên các máy khác nhau cho cùng một ID)
3. **`git rev-parse --show-toplevel`** -- dự phòng dùng đường dẫn repo (phụ thuộc máy)
4. **Dự phòng toàn cục** -- nếu không phát hiện được dự án nào, instinct sẽ vào phạm vi global

Mỗi dự án có một ID hash 12 ký tự (ví dụ `a1b2c3d4e5f6`). Một file registry tại `${XDG_DATA_HOME:-~/.local/share}/ecc-homunculus/projects.json` ánh xạ các ID với tên dễ đọc.

### Thư mục dữ liệu

Continuous-learning-v2 lưu dữ liệu observer bên ngoài `~/.claude` để cơ chế bảo vệ đường dẫn nhạy cảm của Claude Code không chặn việc ghi instinct chạy nền:

1. `CLV2_HOMUNCULUS_DIR` khi được đặt thành một đường dẫn tuyệt đối
2. `$XDG_DATA_HOME/ecc-homunculus`
3. `$HOME/.local/share/ecc-homunculus`

Người dùng hiện có với dữ liệu tại `~/.claude/homunculus` có thể migrate một lần:

```bash
bash skills/continuous-learning-v2/scripts/migrate-homunculus.sh
```

## Bắt đầu nhanh

### 1. Bật Observation Hook

**Nếu cài dưới dạng plugin** (khuyến nghị):

Không cần thêm khối hook nào trong `settings.json`. Claude Code v2.1+ tự động nạp `hooks/hooks.json` của plugin, và `observe.sh` đã được đăng ký sẵn ở đó.

Nếu trước đây bạn đã sao chép `observe.sh` vào `~/.claude/settings.json`, hãy xóa khối `PreToolUse` / `PostToolUse` trùng lặp đó. Việc nhân đôi hook của plugin gây thực thi hai lần và lỗi resolve `${CLAUDE_PLUGIN_ROOT}` vì biến đó chỉ khả dụng bên trong các entry `hooks/hooks.json` do plugin quản lý.

**Nếu cài thủ công** vào `~/.claude/skills`, hãy thêm đoạn này vào `~/.claude/settings.json` của bạn:

```json
{
  "hooks": {
    "PreToolUse": [{
      "matcher": "*",
      "hooks": [{
        "type": "command",
        "command": "~/.claude/skills/continuous-learning-v2/hooks/observe.sh"
      }]
    }],
    "PostToolUse": [{
      "matcher": "*",
      "hooks": [{
        "type": "command",
        "command": "~/.claude/skills/continuous-learning-v2/hooks/observe.sh"
      }]
    }]
  }
}
```

### 2. Khởi tạo cấu trúc thư mục

Hệ thống tự tạo thư mục ở lần dùng đầu tiên, nhưng bạn cũng có thể tạo thủ công:

```bash
# Global directories
mkdir -p "${XDG_DATA_HOME:-$HOME/.local/share}/ecc-homunculus"/{instincts/{personal,inherited},evolved/{agents,skills,commands},projects}

# Project directories are auto-created when the hook first runs in a git repo
```

### 3. Dùng các lệnh Instinct

```bash
/instinct-status     # Show learned instincts (project + global)
/evolve              # Cluster related instincts into skills/commands
/instinct-export     # Export instincts to file
/instinct-import     # Import instincts from others
/promote             # Promote project instincts to global scope
/projects            # List all known projects and their instinct counts
```

## Các lệnh

| Lệnh | Mô tả |
|---------|-------------|
| `/instinct-status` | Hiển thị tất cả instinct (project-scoped + global) kèm confidence |
| `/evolve` | Gom nhóm các instinct liên quan thành skill/command, đề xuất các lần nâng cấp |
| `/instinct-export` | Export instinct (có thể lọc theo scope/domain) |
| `/instinct-import <file>` | Import instinct với kiểm soát scope |
| `/promote [id]` | Nâng cấp instinct dự án lên phạm vi global |
| `/projects` | Liệt kê tất cả dự án đã biết và số lượng instinct của chúng |

## Cấu hình

Chỉnh sửa `config.json` để điều khiển observer chạy nền:

```json
{
  "version": "2.1",
  "observer": {
    "enabled": false,
    "run_interval_minutes": 5,
    "min_observations_to_analyze": 20
  }
}
```

| Key | Mặc định | Mô tả |
|-----|---------|-------------|
| `observer.enabled` | `false` | Bật agent observer chạy nền |
| `observer.run_interval_minutes` | `5` | Tần suất observer phân tích các observation |
| `observer.min_observations_to_analyze` | `20` | Số observation tối thiểu trước khi phân tích chạy |

Các hành vi khác (ghi nhận observation, ngưỡng instinct, phạm vi dự án, tiêu chí nâng cấp) được cấu hình qua giá trị mặc định trong code của `instinct-cli.py` và `observe.sh`.

### Hỗ trợ nền tảng của Observer

Observer chạy nền yêu cầu WSL2, Linux hoặc macOS. Trên Windows gốc
(Git Bash / MSYS2) nó khởi động và báo thành công, nhưng process bị kill
khi hook sinh ra nó thoát và Job Object của nó đóng lại, nên không có phân tích nào
được chạy — đặt `observer.enabled: true` ở đó thực chất là no-op
(xem issue #2489).

`observe.sh` phát hiện điều này ở lần gọi hook tiếp theo và ghi một cảnh báo
giải thích vào `observer-start.log` sau khi observer đã không thể
sống sót nhiều lần liên tiếp.

| Biến môi trường | Mặc định | Mô tả |
|---------|---------|-------------|
| `ECC_OBSERVER_NOSURVIVE_WARN_AFTER` | `3` | Số lần không sống sót liên tiếp trước khi ghi cảnh báo |

## Cấu trúc file

```
${XDG_DATA_HOME:-~/.local/share}/ecc-homunculus/
+-- identity.json           # Your profile, technical level
+-- projects.json           # Registry: project hash -> name/path/remote
+-- observations.jsonl      # Global observations (fallback)
+-- instincts/
|   +-- personal/           # Global auto-learned instincts
|   +-- inherited/          # Global imported instincts
+-- evolved/
|   +-- agents/             # Global generated agents
|   +-- skills/             # Global generated skills
|   +-- commands/           # Global generated commands
+-- projects/
    +-- a1b2c3d4e5f6/       # Project hash (from git remote URL)
    |   +-- project.json    # Per-project metadata mirror (id/name/root/remote)
    |   +-- observations.jsonl
    |   +-- observations.archive/
    |   +-- instincts/
    |   |   +-- personal/   # Project-specific auto-learned
    |   |   +-- inherited/  # Project-specific imported
    |   +-- evolved/
    |       +-- skills/
    |       +-- commands/
    |       +-- agents/
    +-- f6e5d4c3b2a1/       # Another project
        +-- ...
```

## Hướng dẫn quyết định Scope

| Loại Pattern | Scope | Ví dụ |
|-------------|-------|---------|
| Convention ngôn ngữ/framework | **project** | "Use React hooks", "Follow Django REST patterns" |
| Ưu tiên cấu trúc file | **project** | "Tests in `__tests__`/", "Components in src/components/" |
| Code style | **project** | "Use functional style", "Prefer dataclasses" |
| Chiến lược xử lý lỗi | **project** | "Use Result type for errors" |
| Thực hành bảo mật | **global** | "Validate user input", "Sanitize SQL" |
| Best practice chung | **global** | "Write tests first", "Always handle errors" |
| Ưu tiên workflow của tool | **global** | "Grep before Edit", "Read before Write" |
| Thực hành Git | **global** | "Conventional commits", "Small focused commits" |

## Nâng cấp Instinct (Project -> Global)

Khi cùng một instinct xuất hiện trong nhiều dự án với confidence cao, nó là ứng viên để nâng cấp lên phạm vi global.

**Tiêu chí tự động nâng cấp:**
- Cùng instinct ID trong 2+ dự án
- Confidence trung bình >= 0.8

**Cách nâng cấp:**

```bash
# Promote a specific instinct
python3 instinct-cli.py promote prefer-explicit-errors

# Auto-promote all qualifying instincts
python3 instinct-cli.py promote

# Preview without changes
python3 instinct-cli.py promote --dry-run
```

Lệnh `/evolve` cũng đề xuất các ứng viên để nâng cấp.

## Chấm điểm Confidence

Confidence tiến hóa theo thời gian:

| Điểm | Ý nghĩa | Hành vi |
|-------|---------|----------|
| 0.3 | Tentative | Được gợi ý nhưng không bắt buộc |
| 0.5 | Moderate | Áp dụng khi liên quan |
| 0.7 | Strong | Tự động được duyệt để áp dụng |
| 0.9 | Near-certain | Hành vi cốt lõi |

**Confidence tăng** khi:
- Pattern được quan sát lặp lại
- Người dùng không sửa hành vi được gợi ý
- Các instinct tương tự từ nguồn khác đồng thuận

**Confidence giảm** khi:
- Người dùng sửa hành vi một cách tường minh
- Pattern không được quan sát trong thời gian dài
- Xuất hiện bằng chứng mâu thuẫn

## Tại sao dùng Hook thay vì Skill để quan sát?

> "v1 relied on skills to observe. Skills are probabilistic -- they fire ~50-80% of the time based on Claude's judgment."

Hook kích hoạt **100% thời gian**, một cách xác định. Điều này nghĩa là:
- Mọi tool call đều được quan sát
- Không bỏ sót pattern nào
- Việc học toàn diện

## Tương thích ngược

v2.1 hoàn toàn tương thích với v2.0 và v1:
- Instinct global hiện có có thể được migrate từ `~/.claude/homunculus/instincts/` bằng `scripts/migrate-homunculus.sh`
- Các skill `~/.claude/skills/learned/` hiện có từ v1 vẫn hoạt động
- Stop hook vẫn chạy (nhưng giờ cũng cấp dữ liệu cho v2)
- Migrate dần dần: chạy cả hai song song

## Quyền riêng tư

- Observation ở lại **cục bộ** trên máy của bạn
- Instinct project-scoped được cô lập theo từng dự án
- Chỉ **instinct** (pattern) mới có thể được export — không phải observation thô
- Không có code thực tế hay nội dung hội thoại nào được chia sẻ
- Bạn kiểm soát những gì được export và nâng cấp

## Liên quan

- [ECC-Tools GitHub App](https://github.com/apps/ecc-tools) - Tạo instinct từ lịch sử repo
- Homunculus - Dự án cộng đồng đã truyền cảm hứng cho kiến trúc dựa trên instinct của v2 (observation nguyên tử, chấm điểm confidence, pipeline tiến hóa instinct)
- [The Longform Guide](https://x.com/affaanmustafa/status/2014040193557471352) - Phần Continuous learning

---

*Học dựa trên instinct: dạy Claude các pattern của bạn, từng dự án một.*
