# Memory Persistence Hooks

Các định nghĩa lifecycle hook này ghi lại hợp đồng memory persistence của ECC cho bản cài plugin và bản cài thủ công của Claude Code.

Các triển khai thực thi nằm trong `scripts/hooks/`:

- `session-start.js` tải context trước đó có giới hạn, phát hiện trạng thái project và chuẩn bị metadata của session.
- `pre-compact.js` ghi lại trạng thái trước khi nén context (context compaction).
- `session-end.js` lưu các bản tóm tắt cuối session khi có metadata của transcript.
- `observe-runner.js` ghi lại các observation về việc dùng tool cho continuous learning.
- `session-activity-tracker.js` ghi lại việc dùng tool và hoạt động file cho trạng thái và khả năng quan sát (observability) của ECC2.

Hook graph được cài đặt vẫn là `hooks/hooks.json`. Thư mục này là bề mặt định nghĩa lifecycle ổn định, dễ đọc với con người, được harness audit và các tài liệu longform tham chiếu.

## Hợp đồng Lifecycle

| Sự kiện | Hook | Mục đích | Chặn (Blocking) |
|---|---|---|---|
| `SessionStart` | `session:start` | Tải context trước đó có giới hạn và metadata của project | không |
| `PreCompact` | `pre:compact` | Lưu trạng thái trước khi nén context | không |
| `PreToolUse` | `pre:observe:continuous-learning` | Ghi lại ý định dùng tool làm tín hiệu học | không |
| `PostToolUse` | `post:observe:continuous-learning` | Ghi lại kết quả của tool làm tín hiệu học | không |
| `PostToolUse` | `post:session-activity-tracker` | Ghi lại hoạt động tool và file cho metric của ECC2 | không |
| `Stop` | `stop:format-typecheck` | Quality gate theo lô sau các lần chỉnh sửa | có khi hook thất bại |
| `Stop` | `stop:check-console-log` | Audit các file đã sửa về việc log debug | warn/error tùy đầu ra của hook |

## Kỳ vọng với Operator

- Giữ việc lưu trữ ở cục bộ theo mặc định.
- Tránh gửi transcript hoặc dấu vết tool tới các dịch vụ hosted trừ khi người dùng bật tường minh một integration.
- Giới hạn context được tải khi bắt đầu session bằng `ECC_SESSION_START_MAX_CHARS`.
- Cho phép tắt bằng `ECC_SESSION_START_CONTEXT=off`.
- Giữ các lifecycle hook được kiểm soát theo profile qua `ECC_HOOK_PROFILE` và `ECC_DISABLED_HOOKS`.

## Các file liên quan

- `hooks/hooks.json`
- `hooks/README.md`
- `scripts/hooks/session-start.js`
- `scripts/hooks/pre-compact.js`
- `scripts/hooks/session-end.js`
- `scripts/hooks/observe-runner.js`
- `scripts/hooks/session-activity-tracker.js`
- `docs/architecture/observability-readiness.md`
