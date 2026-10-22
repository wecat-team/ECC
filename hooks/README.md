# Hooks

Hook là các tự động hóa hướng sự kiện, kích hoạt trước hoặc sau khi Claude Code thực thi tool. Chúng thực thi chất lượng code, bắt lỗi sớm và tự động hóa các kiểm tra lặp đi lặp lại.

## Hook hoạt động như thế nào

```
User request → Claude picks a tool → PreToolUse hook runs → Tool executes → PostToolUse hook runs
```

- Hook **PreToolUse** chạy trước khi tool thực thi. Chúng có thể **chặn** (exit code 2) hoặc **cảnh báo** (stderr mà không chặn).
- Hook **PostToolUse** chạy sau khi tool hoàn tất. Chúng có thể phân tích đầu ra và trả về phản hồi trước khi Claude tiếp tục.
- Hook **UserPromptSubmit** chạy trước khi Claude xử lý prompt của người dùng.
- Hook **Stop** chạy sau mỗi phản hồi của Claude.
- Hook **SessionStart/SessionEnd** chạy tại các ranh giới vòng đời của session.
- Hook **PreCompact** chạy trước khi nén context (context compaction), hữu ích để lưu trạng thái.

## Hook trong Plugin này

Các định nghĩa lifecycle của memory persistence nằm trong `hooks/memory-persistence/`.
Hook graph thực thi vẫn là `hooks/hooks.json`; thư mục memory persistence là hợp đồng ổn định cho hành vi SessionStart, PreCompact, observation, activity tracking và SessionEnd.

Các ID và mô tả hook ổn định nằm trong `hooks/hooks.metadata.json`, được căn theo event và chỉ số với `hooks/hooks.json`. Claude Code kiểm tra `hooks.json` của plugin theo schema của chính nó và báo mọi key khác (`$schema`, `id`, `description`) là không xác định lúc load, vì vậy `hooks.json` chỉ chứa những gì harness chấp nhận. Trình cài đặt, validator và dashboard của ECC gộp sidecar trở lại thông qua `scripts/lib/hooks-config.js`; `node scripts/ci/validate-hooks.js` thất bại nếu hai file lệch nhau, và `node scripts/ci/check-hooks-schema-keys.js` thất bại nếu `hooks.json` hoặc `hooks/codex-hooks.json` mang bất kỳ key nào ngoài tập đã được tài liệu hóa của loader tương ứng.

Mỗi mục sidecar cũng mang một `fingerprint` của mục matcher mà nó mô tả (matcher cộng với các hook command), vì vậy việc sắp xếp lại `hooks.json` mà không sắp xếp lại sidecar, hoặc sửa một command mà không cập nhật sidecar, sẽ bị phát hiện thay vì âm thầm hoán đổi ID. Khi sắp xếp lại hook, hãy di chuyển các mục sidecar tương ứng trước. Sau đó chạy `node scripts/ci/validate-hooks.js --update-fingerprints` để làm mới các command đã thay đổi và commit cả hai file. Trình cập nhật từ chối các fingerprint đã biết ở vị trí khác và chỉ ghi sau khi validation thành công.

## Cài đặt các Hook này thủ công

Với bản cài thủ công Claude Code, KHÔNG dán nguyên `hooks.json` thô của repo vào `~/.claude/settings.json` hoặc sao chép trực tiếp vào `~/.claude/hooks/hooks.json`. File được check in hướng tới plugin/repo và được thiết kế để cài qua trình cài đặt ECC hoặc load như một plugin.

Hãy dùng trình cài đặt để các hook command được viết lại theo Claude root thực tế của bạn:

```bash
bash ./install.sh --target claude --modules hooks-runtime --enable-hooks
```

```powershell
pwsh -File .\install.ps1 --target claude --modules hooks-runtime --enable-hooks
```

Việc này cài các hook script dưới `~/.claude/` và đăng ký các hook entry đã được resolve
trong `~/.claude/settings.json`. Cài đặt và hook entry hiện có của người dùng được giữ nguyên,
trong khi các entry do ECC sở hữu được theo dõi bằng ID ổn định để cập nhật
idempotent và gỡ cài đặt an toàn. Trên Windows, Claude config root là
`%USERPROFILE%\.claude`.

### Hook PreToolUse

| Hook | Matcher | Hành vi | Exit Code |
|------|---------|----------|-----------|
| **Dev server blocker** | `Bash` | Chặn `npm run dev` v.v. bên ngoài tmux — đảm bảo truy cập được log | 2 (chặn) |
| **Tmux reminder** | `Bash` | Gợi ý dùng tmux cho các lệnh chạy lâu (npm test, cargo build, docker) | 0 (cảnh báo) |
| **Git push reminder** | `Bash` | Nhắc review thay đổi trước `git push` | 0 (cảnh báo) |
| **Pre-commit quality check** | `Bash` | Chạy kiểm tra chất lượng trước `git commit`: lint các file đã stage, kiểm tra định dạng commit message khi được truyền qua `-m/--message`, phát hiện console.log/debugger/secret | 2 (chặn lỗi critical) / 0 (cảnh báo) |
| **Doc file warning** | `Write` | Cảnh báo về các file `.md`/`.txt` không chuẩn (cho phép README, CLAUDE, CONTRIBUTING, CHANGELOG, LICENSE, SKILL, docs/, skills/); xử lý đường dẫn đa nền tảng | 0 (cảnh báo) |
| **Strategic compact** | `Edit\|Write` | Gợi ý `/compact` thủ công tại các khoảng hợp lý (khoảng mỗi ~50 lần gọi tool) | 0 (cảnh báo) |
| **Hookify runtime** | `.*` | Đánh giá các rule Hookify cục bộ của project đã bật trước các tool shell và file | 0 (quyết định warn/block có cấu trúc) |

### Hook PostToolUse

| Hook | Matcher | Nó làm gì |
|------|---------|-------------|
| **PR logger** | `Bash` | Ghi log URL của PR và lệnh review sau `gh pr create` |
| **Build analysis** | `Bash` | Phân tích nền sau các lệnh build (async, không chặn) |
| **Quality gate** | `Edit\|Write\|MultiEdit` | Chạy các kiểm tra chất lượng nhanh sau khi chỉnh sửa |
| **Design quality check** | `Edit\|Write\|MultiEdit` | Cảnh báo khi các chỉnh sửa frontend trôi về UI giống template chung chung |
| **Prettier format** | `Edit` | Tự động format file JS/TS bằng Prettier sau khi chỉnh sửa |
| **TypeScript check** | `Edit` | Chạy `tsc --noEmit` sau khi sửa file `.ts`/`.tsx` |
| **console.log warning** | `Edit` | Cảnh báo về các câu lệnh `console.log` trong file đã sửa |
| **Hookify runtime** | `.*` | Đánh giá các rule Hookify cục bộ của project trên các tool shell và file đã hoàn tất |

### Hook Lifecycle

| Hook | Event | Nó làm gì |
|------|-------|-------------|
| **Session start** | `SessionStart` | Tải context trước đó và phát hiện package manager |
| **Hookify prompt rules** | `UserPromptSubmit` | Đánh giá các prompt rule trước khi prompt của người dùng đến Claude |
| **Plan Canvas sessions** | `SessionStart` | Hiển thị các review Plan Canvas đang mở trên trình duyệt để session mới có thể tiếp tục vòng lặp |
| **Pre-compact** | `PreCompact` | Lưu trạng thái trước khi nén context |
| **Hookify completion rules** | `Stop` | Cảnh báo hoặc yêu cầu thêm một lượt khi một completion rule đã bật khớp |
| **Console.log audit** | `Stop` | Kiểm tra tất cả file đã sửa về `console.log` sau mỗi phản hồi |
| **Session summary** | `Stop` | Lưu trạng thái session khi có đường dẫn transcript |
| **Pattern extraction** | `Stop` | Đánh giá session để tìm các pattern có thể trích xuất (continuous learning) |
| **Cost tracker** | `Stop` | Phát ra các marker telemetry chi phí chạy gọn nhẹ |
| **Desktop notify** | `Stop` | Gửi thông báo desktop macOS kèm tóm tắt task (standard+) |
| **Session end marker** | `SessionEnd` | Marker lifecycle và log dọn dẹp |

## Tùy chỉnh Hook

### Tắt một Hook

Xóa hoặc comment out hook entry trong `hooks.json`. Nếu cài dưới dạng plugin, hãy ghi đè trong `~/.claude/settings.json` của bạn:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Write",
        "hooks": [],
        "description": "Override: allow all .md file creation"
      }
    ]
  }
}
```

### Điều khiển Hook lúc runtime (Khuyến nghị)

Dùng biến môi trường để điều khiển hành vi hook mà không cần sửa `hooks.json`:

```bash
# Master switch. Explicit environment values override plugin preferences.
export ECC_HOOKS_ENABLED=true

# minimal | standard | strict (default: standard)
export ECC_HOOK_PROFILE=standard

# Disable specific hook IDs (comma-separated)
export ECC_DISABLED_HOOKS="pre:bash:tmux-reminder,post:edit:typecheck"

# Lower the hook input cap in bytes (default and maximum: 1048576).
# run-with-flags.js adds runner-level fail-closed handling for
# pre:edit-write:gateguard-fact-force and pre:mcp-health-check because they
# cannot inspect the complete request. Other safety hooks, including the Bash
# dispatcher and config protection, retain their own fail-closed behavior.
# If a trusted tool call legitimately exceeds the cap, retry with a smaller
# input or temporarily set ECC_GATEGUARD=off (or GATEGUARD_DISABLED=1) for
# GateGuard, or ECC_MCP_HEALTH_FAIL_OPEN=yes for MCP health, then restore it.
# These switches reduce only the named protection while enabled; they do not
# bypass the Bash dispatcher or config-protection checks.
export ECC_HOOK_INPUT_MAX_BYTES=524288

# Disable only GateGuard during setup or recovery
export ECC_GATEGUARD=off

# Cap SessionStart additional context (default: 8000 chars)
export ECC_SESSION_START_MAX_CHARS=4000

# Disable SessionStart additional context entirely
export ECC_SESSION_START_CONTEXT=off

# Keep context/scope/loop warnings but suppress API-rate cost estimates
export ECC_CONTEXT_MONITOR_COST_WARNINGS=off
```

Windows PowerShell:

```powershell
[Environment]::SetEnvironmentVariable('ECC_CONTEXT_MONITOR_COST_WARNINGS', 'off', 'User')
```

Giá trị chỉ dùng cho thiết lập Claude:
- `off` — tắt công việc hook ECC cục bộ thông qua `ecc setup`; nó không phải là một runtime hook profile.

Các runtime hook profile:
- `minimal` — chỉ giữ các hook lifecycle và an toàn thiết yếu.
- `standard` — mặc định; cân bằng giữa các kiểm tra chất lượng + an toàn.
- `strict` — bật thêm các lời nhắc bổ sung và guardrail chặt chẽ hơn.

Plugin Claude cung cấp các lựa chọn tương tự dưới dạng cài đặt cá nhân `hooks_enabled` và
`hook_profile`. Chạy `ecc setup --mode claude-plugin` để cài đặt hoặc
cập nhật plugin và thay đổi các tùy chọn đó.

### Runtime Hookify Rule

ECC load trực tiếp các file `.claude/hookify.*.local.md` đã bật; không cần
plugin Hookify riêng hay Python runtime. Rule hỗ trợ các event `bash`, `file`,
`prompt`, `stop` và `all`, cùng với một `pattern` regex đơn giản hoặc một danh sách
`conditions` kết hợp bằng AND. `warn` thêm context hiển thị cho Claude trong khi
vẫn cho phép hành động. `block` từ chối một lệnh gọi `PreToolUse` khớp và dùng
hợp đồng quyết định chặn của event cho các event prompt, post-tool và stop.

Việc load rule bị giới hạn theo project và có biên. Các file rule là symlink, quá lớn, sai định dạng
hoặc có regex không an toàn sẽ bị bỏ qua kèm chẩn đoán thay vì làm hỏng
toàn bộ chuỗi hook. Mỗi lần đánh giá regex cũng có timeout cứng 25 ms.
Các stop rule bỏ qua `stop_hook_active: true` để tránh vòng lặp tiếp diễn.

Các file được Git theo dõi bị tắt theo mặc định vì việc mở một repository không
được kích hoạt các chỉ dẫn do repository tác giả viết. Các rule được tạo cục bộ, bị gitignore
vẫn tiếp tục hoạt động tự động. Để review và tin cậy tường minh các rule được theo dõi,
đặt `ECC_HOOKIFY_ALLOW_TRACKED=1`; các message vẫn được gắn nhãn là
dữ liệu rule cục bộ không tin cậy khi được truyền cho Claude.

### Viết Hook của riêng bạn

Hook là các shell command nhận đầu vào của tool dưới dạng JSON trên stdin. Một hook
không có quyết định hay context nào để trả về thì nên để stdout rỗng. Chỉ đầu ra hook tường minh,
như quyết định deny hoặc `additionalContext`, mới được ghi ra
stdout; payload đầu vào KHÔNG ĐƯỢC echo lại như một phản hồi no-op.

**Cấu trúc cơ bản:**

```javascript
// my-hook.js
let data = '';
process.stdin.on('data', chunk => data += chunk);
process.stdin.on('end', () => {
  const input = JSON.parse(data);

  // Access tool info
  const toolName = input.tool_name;        // "Edit", "Bash", "Write", etc.
  const toolInput = input.tool_input;      // Tool-specific parameters
  const toolOutput = input.tool_output;    // Only available in PostToolUse

  // Warn (non-blocking): write to stderr
  console.error('[Hook] Warning message shown to Claude');

  // Block (PreToolUse only): exit with code 2
  // process.exit(2);

  // No opinion: leave stdout empty.
});
```

**Exit code:**
- `0` — Thành công (tiếp tục thực thi)
- `2` — Chặn lệnh gọi tool (chỉ PreToolUse)
- Các giá trị khác không phải 0 — Lỗi (được log nhưng không chặn)

### Schema đầu vào của Hook

```typescript
interface HookInput {
  tool_name: string;          // "Bash", "Edit", "Write", "Read", etc.
  tool_input: {
    command?: string;         // Bash: the command being run
    file_path?: string;       // Edit/Write/Read: target file
    old_string?: string;      // Edit: text being replaced
    new_string?: string;      // Edit: replacement text
    content?: string;         // Write: file content
  };
  tool_output?: {             // PostToolUse only
    output?: string;          // Command/tool output
  };
}
```

### Hook bất đồng bộ

Với các hook không nên chặn luồng chính (ví dụ: phân tích nền):

```json
{
  "type": "command",
  "command": "node my-slow-hook.js",
  "async": true,
  "timeout": 30
}
```

Hook bất đồng bộ chạy ở nền. Chúng không thể chặn việc thực thi tool.

## Các công thức Hook phổ biến

### Cảnh báo về comment TODO

```json
{
  "matcher": "Edit",
  "hooks": [{
    "type": "command",
    "command": "node -e \"let d='';process.stdin.on('data',c=>d+=c);process.stdin.on('end',()=>{const i=JSON.parse(d);const ns=i.tool_input?.new_string||'';if(/TODO|FIXME|HACK/.test(ns)){console.error('[Hook] New TODO/FIXME added - consider creating an issue')}})\""
  }],
  "description": "Warn when adding TODO/FIXME comments"
}
```

### Chặn việc tạo file lớn

```json
{
  "matcher": "Write",
  "hooks": [{
    "type": "command",
    "command": "node -e \"let d='';process.stdin.on('data',c=>d+=c);process.stdin.on('end',()=>{const i=JSON.parse(d);const c=i.tool_input?.content||'';const lines=c.split('\\n').length;if(lines>800){console.error('[Hook] BLOCKED: File exceeds 800 lines ('+lines+' lines)');console.error('[Hook] Split into smaller, focused modules');process.exit(2)}})\""
  }],
  "description": "Block creation of files larger than 800 lines"
}
```

### Tự động format file Python bằng ruff

```json
{
  "matcher": "Edit",
  "hooks": [{
    "type": "command",
    "command": "node -e \"let d='';process.stdin.on('data',c=>d+=c);process.stdin.on('end',()=>{const i=JSON.parse(d);const p=i.tool_input?.file_path||'';if(/\\.py$/.test(p)){const{execFileSync}=require('child_process');try{execFileSync('ruff',['format',p],{stdio:'pipe'})}catch(e){}}})\""
  }],
  "description": "Auto-format Python files with ruff after edits"
}
```

### Yêu cầu file test đi kèm các file source mới

```json
{
  "matcher": "Write",
  "hooks": [{
    "type": "command",
    "command": "node -e \"const fs=require('fs');let d='';process.stdin.on('data',c=>d+=c);process.stdin.on('end',()=>{const i=JSON.parse(d);const p=i.tool_input?.file_path||'';if(/src\\/.*\\.(ts|js)$/.test(p)&&!/\\.test\\.|\\.spec\\./.test(p)){const testPath=p.replace(/\\.(ts|js)$/,'.test.$1');if(!fs.existsSync(testPath)){console.error('[Hook] No test file found for: '+p);console.error('[Hook] Expected: '+testPath);console.error('[Hook] Consider writing tests first (/tdd)')}}})\""
  }],
  "description": "Remind to create tests when adding new source files"
}
```

## Ghi chú đa nền tảng

Logic hook được triển khai trong các script Node.js để hoạt động đa nền tảng trên Windows, macOS và Linux. Observer của continuous-learning được cung cấp dưới dạng hook chế độ Node và ủy quyền cho triển khai `observe.sh` hiện có thông qua một runner được kiểm soát theo profile với hành vi fallback an toàn cho Windows.

## Liên quan

- [rules/common/hooks.md](../rules/common/hooks.md) — Hướng dẫn kiến trúc hook
- [skills/strategic-compact/](../skills/strategic-compact/) — Skill strategic compaction
- [scripts/hooks/](../scripts/hooks/) — Các triển khai hook script
