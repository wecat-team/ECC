---
name: dmux-workflows
description: "Điều phối multi-agent bằng dmux (trình quản lý pane tmux cho AI agent). Các pattern cho workflow agent song song trên Claude Code, Codex, OpenCode và các harness khác. Dùng khi chạy nhiều phiên agent song song hoặc điều phối workflow phát triển multi-agent."
metadata:
  origin: ECC
---

# Workflow dmux

Điều phối các phiên AI agent song song bằng dmux, một trình quản lý pane tmux cho các agent harness.

## Khi nào kích hoạt

- Chạy nhiều phiên agent song song
- Điều phối công việc giữa Claude Code, Codex và các harness khác
- Các task phức tạp hưởng lợi từ song song kiểu chia để trị
- Người dùng nói "run in parallel", "split this work", "use dmux" hoặc "multi-agent"

## dmux là gì

dmux là công cụ điều phối dựa trên tmux, quản lý các pane của AI agent:
- Nhấn `n` để tạo pane mới kèm prompt
- Nhấn `m` để merge đầu ra của pane về phiên chính
- Hỗ trợ: Claude Code, Codex, OpenCode, Cline, Gemini, Qwen

**Cài đặt:** Cài dmux từ repository của nó sau khi review package. Xem [github.com/standardagents/dmux](https://github.com/standardagents/dmux)

## Bắt đầu nhanh

```bash
# Start dmux session
dmux

# Create agent panes (press 'n' in dmux, then type prompt)
# Pane 1: "Implement the auth middleware in src/auth/"
# Pane 2: "Write tests for the user service"
# Pane 3: "Update API documentation"

# Each pane runs its own agent session
# Press 'm' to merge results back
```

## Các pattern workflow

### Pattern 1: Nghiên cứu + Triển khai

Tách nghiên cứu và triển khai thành các nhánh song song:

```
Pane 1 (Research): "Research best practices for rate limiting in Node.js.
  Check current libraries, compare approaches, and write findings to
  /tmp/rate-limit-research.md"

Pane 2 (Implement): "Implement rate limiting middleware for our Express API.
  Start with a basic token bucket, we'll refine after research completes."

# After Pane 1 completes, merge findings into Pane 2's context
```

### Pattern 2: Tính năng nhiều file

Song song hóa công việc trên các file độc lập:

```
Pane 1: "Create the database schema and migrations for the billing feature"
Pane 2: "Build the billing API endpoints in src/api/billing/"
Pane 3: "Create the billing dashboard UI components"

# Merge all, then do integration in main pane
```

### Pattern 3: Vòng lặp Test + Fix

Chạy test ở một pane, sửa ở pane khác:

```
Pane 1 (Watcher): "Run the test suite in watch mode. When tests fail,
  summarize the failures."

Pane 2 (Fixer): "Fix failing tests based on the error output from pane 1"
```

### Pattern 4: Đa harness

Dùng các công cụ AI khác nhau cho các task khác nhau:

```
Pane 1 (Claude Code): "Review the security of the auth module"
Pane 2 (Codex): "Refactor the utility functions for performance"
Pane 3 (Claude Code): "Write E2E tests for the checkout flow"
```

### Pattern 5: Pipeline code review

Các góc nhìn review song song:

```
Pane 1: "Review src/api/ for security vulnerabilities"
Pane 2: "Review src/api/ for performance issues"
Pane 3: "Review src/api/ for test coverage gaps"

# Merge all reviews into a single report
```

## Best practice

1. **Chỉ dùng task độc lập.** Không song song hóa các task phụ thuộc vào đầu ra của nhau.
2. **Ranh giới rõ ràng.** Mỗi pane nên làm việc trên các file hoặc mối quan tâm riêng biệt.
3. **Merge có chiến lược.** Review đầu ra của pane trước khi merge để tránh xung đột.
4. **Dùng git worktree.** Với công việc dễ xung đột file, hãy dùng worktree riêng cho mỗi pane.
5. **Ý thức về tài nguyên.** Mỗi pane tiêu tốn API token — giữ tổng số pane dưới 5-6.

## Tích hợp Git Worktree

Cho các task chạm tới những file chồng chéo:

```bash
# Create worktrees for isolation
git worktree add -b feat/auth ../feature-auth HEAD
git worktree add -b feat/billing ../feature-billing HEAD

# Run agents in separate worktrees
# Pane 1: cd ../feature-auth && claude
# Pane 2: cd ../feature-billing && claude

# Merge branches when done
git merge feat/auth
git merge feat/billing
```

## Công cụ bổ trợ

| Công cụ | Chức năng | Khi nào dùng |
|------|-------------|-------------|
| **dmux** | Quản lý pane tmux cho agent | Các phiên agent song song |
| **Superset** | Terminal IDE cho 10+ agent song song | Điều phối quy mô lớn |
| **Claude Code Task tool** | Sinh subagent trong cùng process | Song song theo chương trình trong một phiên |
| **Codex multi-agent** | Các vai trò agent tích hợp sẵn | Công việc song song riêng cho Codex |

## ECC Helper

ECC hiện có một helper để điều phối pane tmux bên ngoài với các git worktree riêng biệt:

```bash
node scripts/orchestrate-worktrees.js plan.json --execute
```

Ví dụ `plan.json`:

```json
{
  "sessionName": "skill-audit",
  "baseRef": "HEAD",
  "launcherCommand": "codex exec --cwd {worktree_path} --task-file {task_file}",
  "workers": [
    { "name": "docs-a", "task": "Fix skills 1-4 and write handoff notes." },
    { "name": "docs-b", "task": "Fix skills 5-8 and write handoff notes." }
  ]
}
```

Helper này:
- Tạo một git worktree gắn với branch cho mỗi worker
- Tùy chọn phủ các `seedPaths` được chọn từ bản checkout chính vào worktree của từng worker
- Ghi các file `task.md`, `handoff.md` và `status.md` cho từng worker dưới `.orchestration/<session>/`
- Khởi động một phiên tmux với mỗi worker một pane
- Chạy lệnh của từng worker trong pane riêng của nó
- Để pane chính rảnh cho orchestrator

Dùng `seedPaths` khi các worker cần truy cập các file local đã bị sửa (dirty) hoặc chưa được theo dõi (untracked) và chưa thuộc `HEAD`, như script điều phối local, kế hoạch nháp hoặc tài liệu:

```json
{
  "sessionName": "workflow-e2e",
  "seedPaths": [
    "scripts/orchestrate-worktrees.js",
    "scripts/lib/tmux-worktree-orchestrator.js",
    ".claude/plan/workflow-e2e-test.json"
  ],
  "launcherCommand": "bash {repo_root}/scripts/orchestrate-codex-worker.sh {task_file} {handoff_file} {status_file}",
  "workers": [
    { "name": "seed-check", "task": "Verify seeded files are present before starting work." }
  ]
}
```

## Xử lý sự cố

- **Pane không phản hồi:** Chuyển thẳng sang pane đó hoặc kiểm tra bằng `tmux capture-pane -pt <session>:0.<pane-index>`.
- **Xung đột merge:** Dùng git worktree để cô lập thay đổi file theo từng pane.
- **Dùng nhiều token:** Giảm số pane song song. Mỗi pane là một phiên agent đầy đủ.
- **Không tìm thấy tmux:** Cài bằng `brew install tmux` (macOS) hoặc `apt install tmux` (Linux).
