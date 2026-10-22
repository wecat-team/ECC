---
name: plankton-code-quality
description: "Thực thi chất lượng code tại thời điểm ghi bằng Plankton — tự động format, lint và sửa lỗi nhờ Claude trên mỗi lần sửa file qua hook. Dùng khi thiết lập hook format, lint hoặc auto-fix tại thời điểm ghi cho các lần sửa file."
metadata:
  origin: community
---

# Skill Plankton Code Quality

Tài liệu tham chiếu tích hợp cho Plankton (credit: @alxfazio), một hệ thống thực thi chất lượng code tại thời điểm ghi dành cho Claude Code. Plankton chạy formatter và linter trên mỗi lần sửa file qua hook PostToolUse, sau đó spawn các Claude subprocess để sửa những vi phạm mà agent chưa bắt được.

## Khi nào dùng

- Bạn muốn tự động format và lint trên mỗi lần sửa file (không chỉ lúc commit)
- Bạn cần phòng vệ trước việc agent sửa config của linter để qua mặt thay vì sửa code
- Bạn muốn định tuyến model theo tầng cho việc sửa lỗi (Haiku cho style đơn giản, Sonnet cho logic, Opus cho type)
- Bạn làm việc với nhiều ngôn ngữ (Python, TypeScript, Shell, YAML, JSON, TOML, Markdown, Dockerfile)

## Cách hoạt động

### Kiến trúc ba phase

Mỗi khi Claude Code sửa hoặc ghi một file, hook PostToolUse `multi_linter.sh` của Plankton sẽ chạy:

```
Phase 1: Auto-Format (Silent)
├─ Runs formatters (ruff format, biome, shfmt, taplo, markdownlint)
├─ Fixes 40-50% of issues silently
└─ No output to main agent

Phase 2: Collect Violations (JSON)
├─ Runs linters and collects unfixable violations
├─ Returns structured JSON: {line, column, code, message, linter}
└─ Still no output to main agent

Phase 3: Delegate + Verify
├─ Spawns claude -p subprocess with violations JSON
├─ Routes to model tier based on violation complexity:
│   ├─ Haiku: formatting, imports, style (E/W/F codes) — 120s timeout
│   ├─ Sonnet: complexity, refactoring (C901, PLR codes, oxlint complexity) — 300s timeout
│   └─ Opus: type system, deep reasoning (unresolved-attribute) — 600s timeout
├─ Re-runs Phase 1+2 to verify fixes
└─ Exit 0 if clean, Exit 2 if violations remain (reported to main agent)
```

### Những gì agent chính nhìn thấy

| Tình huống | Agent thấy | Exit của hook |
|----------|-----------|-----------|
| Không có vi phạm | Không gì cả | 0 |
| Subprocess đã sửa hết | Không gì cả | 0 |
| Vẫn còn vi phạm sau subprocess | `[hook] N violation(s) remain` | 2 |
| Advisory (trùng lặp, tooling cũ) | `[hook:advisory] ...` | 0 |

Agent chính chỉ thấy những vấn đề mà subprocess không sửa được. Hầu hết các vấn đề chất lượng được giải quyết một cách trong suốt.

### Bảo vệ Config (phòng vệ trước việc lách luật)

LLM sẽ sửa `.ruff.toml` hoặc `biome.json` để tắt rule thay vì sửa code. Plankton chặn điều này bằng ba lớp:

1. **Hook PreToolUse** — `protect_linter_configs.sh` chặn các chỉnh sửa lên mọi config của linter trước khi chúng xảy ra
2. **Hook Stop** — `stop_config_guardian.sh` phát hiện thay đổi config qua `git diff` ở cuối session
3. **Danh sách file được bảo vệ** — `.ruff.toml`, `biome.json`, `.shellcheckrc`, `.yamllint`, `.hadolint.yaml` và nhiều file khác

### Thực thi Package Manager

Một hook PreToolUse trên Bash chặn các package manager legacy:
- `pip`, `pip3`, `poetry`, `pipenv` → Bị chặn (dùng `uv`)
- `npm`, `yarn`, `pnpm` → Bị chặn (dùng `bun`)
- Ngoại lệ được phép: `npm audit`, `npm view`, `npm publish`

## Thiết lập

### Bắt đầu nhanh

> **Lưu ý:** Plankton yêu cầu cài đặt thủ công từ repository của nó. Hãy review code trước khi cài.

```bash
# Install core dependencies
brew install jaq ruff uv

# Install Python linters
uv sync --all-extras

# Start Claude Code — hooks activate automatically
claude
```

Không có lệnh cài đặt, không có cấu hình plugin. Các hook trong `.claude/settings.json` được tự động nhận diện khi bạn chạy Claude Code trong thư mục Plankton.

### Tích hợp theo từng dự án

Để dùng hook Plankton trong dự án của bạn:

1. Sao chép thư mục `.claude/hooks/` vào dự án của bạn
2. Sao chép cấu hình hook trong `.claude/settings.json`
3. Sao chép các file config của linter (`.ruff.toml`, `biome.json`, v.v.)
4. Cài các linter cho ngôn ngữ của bạn

### Dependency theo từng ngôn ngữ

| Ngôn ngữ | Bắt buộc | Tùy chọn |
|----------|----------|----------|
| Python | `ruff`, `uv` | `ty` (type), `vulture` (dead code), `bandit` (bảo mật) |
| TypeScript/JS | `biome`; `oxlint` (>= 1.37.0) khi dùng `complexity` | `semgrep`, `knip` (export chết) |
| Shell | `shellcheck`, `shfmt` | — |
| YAML | `yamllint` | — |
| Markdown | `markdownlint-cli2` | — |
| Dockerfile | `hadolint` (>= 2.12.0) | — |
| TOML | `taplo` | — |
| JSON | `jaq` | — |

## Kết hợp với ECC

### Bổ sung cho nhau, không chồng lấn

| Mối quan tâm | ECC | Plankton |
|---------|-----|----------|
| Thực thi chất lượng code | Hook PostToolUse (Prettier, tsc) | Hook PostToolUse (20+ linter + sửa lỗi bằng subprocess) |
| Quét bảo mật | AgentShield, agent security-reviewer | Bandit (Python), Semgrep (TypeScript) |
| Bảo vệ config | — | PreToolUse chặn + Stop hook phát hiện |
| Package manager | Phát hiện + thiết lập | Thực thi (chặn PM legacy) |
| Tích hợp CI | — | Pre-commit hook cho git |
| Định tuyến model | Thủ công (`/model opus`) | Tự động (độ phức tạp của vi phạm → tầng) |

### Kết hợp khuyến nghị

1. Cài ECC làm plugin của bạn (agent, skill, command, rule)
2. Thêm hook Plankton để thực thi chất lượng tại thời điểm ghi
3. Dùng AgentShield cho các lần kiểm toán bảo mật
4. Dùng verification-loop của ECC làm cổng cuối trước các PR

### Tránh xung đột Hook

Nếu chạy cả hook ECC và Plankton:
- Hook Prettier của ECC và formatter biome của Plankton có thể xung đột trên file JS/TS
- Cách giải quyết: tắt hook PostToolUse Prettier của ECC khi dùng Plankton (biome của Plankton toàn diện hơn)
- Cả hai có thể cùng tồn tại trên các loại file khác nhau (ECC xử lý phần Plankton không bao phủ)

## Tham chiếu cấu hình

`.claude/hooks/config.json` của Plankton điều khiển mọi hành vi:

```json
{
  "languages": {
    "python": true,
    "shell": true,
    "yaml": true,
    "json": true,
    "toml": true,
    "dockerfile": true,
    "markdown": true,
    "typescript": {
      "enabled": true,
      "js_runtime": "auto",
      "biome_nursery": "warn",
      "semgrep": true
    }
  },
  "phases": {
    "auto_format": true,
    "subprocess_delegation": true
  },
  "subprocess": {
    "tiers": {
      "haiku":  { "timeout": 120, "max_turns": 10 },
      "sonnet": { "timeout": 300, "max_turns": 10 },
      "opus":   { "timeout": 600, "max_turns": 15 }
    },
    "volume_threshold": 5
  }
}
```

**Các thiết lập chính:**
- Tắt các ngôn ngữ bạn không dùng để hook chạy nhanh hơn
- `volume_threshold` — số vi phạm vượt quá giá trị này sẽ tự động chuyển lên tầng model cao hơn
- `subprocess_delegation: false` — bỏ qua hoàn toàn Phase 3 (chỉ báo cáo vi phạm)

## Ghi đè bằng biến môi trường

| Biến | Mục đích |
|----------|---------|
| `HOOK_SKIP_SUBPROCESS=1` | Bỏ qua Phase 3, báo cáo vi phạm trực tiếp |
| `HOOK_SUBPROCESS_TIMEOUT=N` | Ghi đè timeout của tầng |
| `HOOK_DEBUG_MODEL=1` | Log các quyết định chọn model |
| `HOOK_SKIP_PM=1` | Bỏ qua việc thực thi package manager |

## Tham khảo

- Plankton (credit: @alxfazio)
- Plankton REFERENCE.md — Tài liệu kiến trúc đầy đủ (credit: @alxfazio)
- Plankton SETUP.md — Hướng dẫn cài đặt chi tiết (credit: @alxfazio)

## Bổ sung của ECC v1.8

### Hook Profile có thể sao chép

Đặt hành vi chất lượng nghiêm ngặt:

```bash
export ECC_HOOK_PROFILE=strict
export ECC_QUALITY_GATE_FIX=true
export ECC_QUALITY_GATE_STRICT=true
```

### Bảng cổng theo ngôn ngữ

- TypeScript/JavaScript: ưu tiên Biome, dự phòng Prettier
- Python: Ruff format/check
- Go: gofmt

### Bảo vệ chống can thiệp Config (Config Tamper Guard)

Trong quá trình thực thi chất lượng, hãy đánh dấu các thay đổi lên file config trong cùng một lượt lặp:

- `biome.json`, `.eslintrc*`, `prettier.config*`, `tsconfig.json`, `pyproject.toml`

Nếu config bị đổi để chặn vi phạm, yêu cầu review tường minh trước khi merge.

### Pattern tích hợp CI

Dùng các lệnh giống như hook local trong CI:

1. chạy kiểm tra formatter
2. chạy kiểm tra lint/type
3. fail nhanh ở chế độ strict
4. công bố bản tóm tắt khắc phục

### Chỉ số sức khỏe

Theo dõi:
- số lần sửa bị cổng đánh dấu
- thời gian khắc phục trung bình
- vi phạm lặp lại theo danh mục
- số lần chặn merge do cổng thất bại

---

## Phần bổ sung của Gabe: oxlint complexity + ratchet ceiling (JS/TS)

Lấp khoảng trống JS/TS trong bảng định tuyến model ở trên. Độ phức tạp của Python (ruff C901,
PLR) đã được định tuyến sang Sonnet. JS/TS chưa có rule tương đương được bật theo mặc định.

### Bật rule `complexity` của oxlint khi dùng nó

Rule `complexity` của oxlint (nguồn: rule `complexity` của eslint, được port sang) nằm trong
danh mục "restriction", mà oxlint không bật theo mặc định. Phải bật thủ công. Đã verify với [rule complexity của Oxlint](https://oxc.rs/docs/guide/usage/linter/rules/eslint/complexity)
(2026-08-27): tùy chọn mặc định là `max: 20`. Rule có sẵn trong oxlint >= 1.37.0.

Bảng Dependency theo từng ngôn ngữ của skill này giữ `oxlint` là tùy chọn cho TypeScript/JS
nói chung. Khi áp dụng rule `complexity`, hãy dùng oxlint >= 1.37.0 và coi nó là
dependency bắt buộc. Thêm rule vào cấu hình oxlint được hỗ trợ mà dự án đã
dùng (`.oxlintrc.json`, `.oxlintrc.jsonc`, `oxlint.config.ts` hoặc `oxlint.config.mts`). Nếu
chưa có, hãy tạo một cái; không tạo file cấu hình thứ hai trong cùng thư mục.

Đo điểm phức tạp tệ nhất hiện tại của codebase trước khi chọn mức trần được thực thi ban đầu.
Template bên dưới cố ý chưa hoàn chỉnh: hãy thay `<MEASURED_CEILING>` bằng
điểm đó, có thể cộng thêm một chút dư địa, trước khi commit cổng `"error"`.
Mặc định 20 của Oxlint là mục tiêu dài hạn, không phải mức trần khởi đầu an toàn cho mọi nơi.

```json
{
  "rules": {
    "complexity": ["error", { "max": "<MEASURED_CEILING>" }]
  }
}
```

Hãy thay placeholder trước khi chạy oxlint; nó không phải là ngưỡng số hợp lệ cho đến khi
repo được đo. Xem phần ratchet bên dưới để biết mức trần được đặt như thế nào trên
một codebase thực.

### Dòng định tuyến model

Thêm các vi phạm `complexity` của oxlint vào cùng dòng với mục Python hiện có trong
bảng subprocess của Phase 3:

```
├─ Sonnet: complexity, refactoring (C901, PLR codes, oxlint complexity), 300s timeout
```

Cùng tầng với C901/PLR của Python. Một vi phạm độ phức tạp dù ở ngôn ngữ nào cũng là một công việc refactor,
ngôn ngữ không làm thay đổi tầng model.

### Kỹ thuật ratchet-ceiling

Nguồn: [Hunk PR #861](https://github.com/modem-dev/hunk/pull/861) (merge ngày 2026-08-26, được verify với
diff và mô tả của chính PR qua GitHub API, không diễn giải lại từ trí nhớ). Hunk
đã bật rule `complexity` của oxlint với `"error", { "max": 80 }` trong `.oxlintrc.json`.
Điểm tệ nhất của họ vào thời điểm đó là 78 (`App`), tiếp theo là 76
(`validateFileViewLayout`). Từ phần thân PR: "This is intentionally an initial
regression ceiling rather than the long-term target... so 80 adds enforcement without
grandfathering or suppressions. The ceiling can be ratcheted downward as existing
hotspots are simplified." Và: "A global ceiling does not prevent a function below 80
from growing toward it."

Kỹ thuật, như thực sự được chạy trong PR đó:

1. Đo điểm phức tạp tệ nhất hiện tại trong codebase (oxlint báo cáo nó khi
   rule kích hoạt).
2. Đặt mức trần ĐƯỢC THỰC THI ở giá trị ít nhất bằng điểm tệ nhất đó, không phải
   mặc định 20 của oxlint. Thêm một chút dư địa nếu cần để lần bật ban đầu
   không làm CI fail trên một điểm mà bạn chưa sửa (hunk dùng 80 so với điểm
   tệ nhất là 78).
3. Commit nó dưới dạng `"error"`, nối vào bước lint CI hiện có. Đây là một cổng thực sự
   từ commit đầu tiên, không phải một gợi ý.
4. Không bao giờ grandfather. Mức trần là toàn cục. Một function đang ở mức 40 hôm nay không được
   miễn trừ, sau này nó vẫn không được vượt mức trần. Đó là toàn bộ ý nghĩa: bắt
   sự tăng trưởng, không chỉ những thủ phạm tệ nhất hôm nay.
5. Không bao giờ suppress hàng loạt. Không dùng comment disable theo file hoặc theo function để làm một
   vi phạm biến mất. Hãy sửa nó hoặc để nó dưới mức trần.
6. Mỗi lần một hotspot bị đánh dấu được refactor xuống dưới mức trần, hãy đo lại giá trị
   tối đa toàn cục trên toàn bộ codebase. Chỉ hạ mức trần bằng tay xuống một giá trị
   vẫn ít nhất bằng điểm của mọi function còn lại (cộng thêm dư địa có chủ đích).
   Đây là một bước thủ công thực hiện trong commit riêng, không tự động. Đó là cách
   mức trần dịch chuyển về phía giá trị mặc định thực sự là 20 của linter theo thời gian thay vì nằm yên
   ở điểm tệ nhất của codebase mãi mãi.

Một lưu ý, nói thẳng: bản thân PR đã đi thẳng từ "rule tắt" sang thực thi `"error"`
trong một commit. Nó không đi qua giai đoạn chỉ báo cáo hoặc chỉ cảnh báo trước.
Bắt đầu với rule ở `"warn"` cho một lượt CI trước khi chuyển sang
`"error"` là một bước phân đoạn hợp lý nếu một team chưa từng đo điểm tệ nhất của mình
và không muốn bị CI fail bất ngờ, nhưng bước phân đoạn đó là thực hành thận trọng của riêng Gabe,
không phải thứ được verify trong PR của hunk. Hãy nói rõ điều đó nếu bạn dùng nó, đừng gán nó
cho nguồn.
