---
description: Kiểm tra trạng thái vòng lặp đang hoạt động, tiến độ, tín hiệu lỗi và can thiệp được đề xuất.
---

# Lệnh Loop Status

Kiểm tra trạng thái vòng lặp đang hoạt động, tiến độ và tín hiệu lỗi.

Slash command này chỉ có thể chạy sau khi phiên hiện tại lấy nó ra khỏi hàng đợi. Nếu
bạn cần kiểm tra một phiên bị treo hoặc một phiên anh em, hãy chạy CLI đóng gói từ một
terminal khác:

```bash
npx --package ecc-universal ecc loop-status --json
```

CLI quét các file transcript JSONL cục bộ của Claude dưới
`~/.claude/projects/**` và báo cáo các lời gọi `ScheduleWakeup` đã cũ (stale) hoặc các lời gọi
tool `Bash` không có `tool_result` tương ứng.

## Cách dùng

`/loop-status [--watch]`

## Cần báo cáo gì

- pattern vòng lặp đang hoạt động
- pha hiện tại và checkpoint thành công gần nhất
- các kiểm tra thất bại (nếu có)
- độ lệch thời gian/chi phí ước tính
- can thiệp được đề xuất (continue/pause/stop)

## CLI xuyên phiên

- `ecc loop-status --json` xuất trạng thái dạng máy đọc được cho các transcript
  Claude cục bộ gần đây.
- `ecc loop-status --home <dir>` quét một thư mục home khác khi
  kiểm tra một profile cục bộ khác hoặc workspace được mount.
- `ecc loop-status --transcript <session.jsonl>` kiểm tra trực tiếp một
  transcript.
- `ecc loop-status --bash-timeout-seconds 1800` điều chỉnh ngưỡng
  Bash bị stale.
- `ecc loop-status --exit-code` thoát với mã `2` khi phát hiện tín hiệu
  vòng lặp hoặc tool bị stale, hoặc mã `1` khi không thể quét transcript.
- `--exit-code` kết hợp `--watch` yêu cầu `--watch-count` để các script watchdog
  không phải chờ mãi một process thoát.
- `ecc loop-status --watch` làm mới trạng thái cho đến khi bị ngắt.
- `ecc loop-status --watch --watch-count 3 --exit-code` làm mới một số lần
  giới hạn, rồi thoát với trạng thái cao nhất đã thấy.
- `ecc loop-status --watch --watch-count 3` phát ra một luồng watch có giới hạn cho
  script và bàn giao.
- `ecc loop-status --watch --write-dir ~/.claude/loops` duy trì
  `index.json` và các snapshot JSON theo từng phiên cho các terminal anh em hoặc
  script watchdog.

## Chế độ Watch

Khi có `--watch`, làm mới trạng thái định kỳ. Với `--json`, mỗi
lần làm mới được phát ra dưới dạng một đối tượng JSON mỗi dòng để một terminal hoặc script khác có thể
tiêu thụ luồng này.

## File snapshot

Dùng `--write-dir <dir>` khi một process riêng cần kiểm tra trạng thái vòng lặp
mà không phải chờ phiên Claude hiện tại lấy `/loop-status` ra khỏi hàng đợi. CLI
ghi:

- `index.json` với một dòng cho mỗi phiên được kiểm tra.
- `<session-id>.json` với toàn bộ payload trạng thái của phiên đó.

Các file này là snapshot của phân tích transcript cục bộ. Chúng không điều khiển hay
làm timeout các lời gọi tool của runtime Claude Code.

## Đối số

$ARGUMENTS:
- `--watch` tùy chọn
