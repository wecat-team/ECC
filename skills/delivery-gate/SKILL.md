---
name: delivery-gate
description: "Stop hook chặn Claude kết thúc cho đến khi các kiểm tra chất lượng đạt. Phát hiện pattern biện minh (heuristic trên văn bản bề mặt), learning log cũ (mtime của filesystem) và dung lượng đĩa thấp. Bổ trợ self-audit bằng cách cưỡng chế cơ học thói quen ghi nhận học hỏi. Dùng khi cần chặn Claude một cách cơ học khỏi việc tuyên bố hoàn thành trước khi các kiểm tra chất lượng và việc ghi nhận learning thực sự đạt."
metadata:
  version: 1.1.1
  origin: ECC
---

# Delivery Gate — Cổng chất lượng cơ học cho Claude Code

Một **Stop hook** kiểm tra ba thứ trước khi Claude có thể kết thúc phiên, chỉ dùng **các kiểm tra tất định** — timestamp sửa đổi file, mức dùng đĩa và regex trên văn bản transcript. Không dùng suy luận AI.

Điều này khác với các gate suy luận (như `self-audit`): delivery-gate kiểm tra các sự kiện có thể xác minh bằng máy; self-audit kiểm tra chất lượng đầu ra qua bốn chiều suy luận. Kết hợp lại chúng tạo thành phòng thủ nhiều lớp:
- **delivery-gate**: "Hôm nay thư viện learning đã được chạm tới chưa? Dung lượng đĩa còn an toàn không?"
- **self-audit**: "Nội dung file có đúng, đầy đủ và trung thực không?"

Đây là cùng một pattern với các gate trong pipeline CI — các kiểm tra tự động, tất định, xác minh những sự kiện máy đọc được thay vì tin vào trạng thái tự báo cáo.

## Kiểm tra những gì

| Kiểm tra | Cơ chế | Khi phát hiện |
|-------|-----------|--------|
| Pattern biện minh | Regex trên phần cuối transcript | **Chỉ cảnh báo** (không bao giờ chặn) |
| Thư viện learning cũ | mtime trên 5 đường dẫn cấu hình được | Cảnh báo nếu một số bị cũ; **Chặn** nếu >=3 bị cũ HOẶC growth-log bị cũ + task phức tạp |
| Dung lượng đĩa < 50GB | `shutil.disk_usage` | Cảnh báo |
| Dung lượng đĩa < 15GB | `shutil.disk_usage` | **Chặn** (exit 2) |

Việc phát hiện biện minh cảnh báo về các pattern như "skip tests for now" và "pre-existing bug" — các tín hiệu bề mặt cho thấy suy nghĩ có thể đã bị cắt ngắn. Nó không bao giờ tự chặn, vì heuristic regex có thể false-positive. Các điều kiện chặn là: đĩa ở mức critical, `>=3 learning libs stale`, HOẶC riêng `growth-log` bị stale (tất cả đều yêu cầu task phức tạp >=3 lần edit).

## Vì sao

Các kiểm tra tích hợp sẵn của Claude Code bao phủ chất lượng code (build → type → lint → test). Nhưng còn một kiểu lỗi khác: agent tạo ra code chạy được trong khi **vệ sinh phiên làm việc bị bỏ bê** — learning không được ghi nhận, lối tắt được biện minh, đĩa cạn dần trong im lặng.

Qua nhiều phiên "ship rồi quên", con người không tiến bộ. Hook này cưỡng chế thói quen đó: task phức tạp → phải chạm tới các thư viện learning.

## Cài đặt

Từ thư mục gốc của repo ECC:

```bash
mkdir -p ~/.claude/scripts
cp skills/delivery-gate/hooks/quality-gate.py ~/.claude/scripts/
```

Thêm vào `~/.claude/settings.json`:
```json
{
  "hooks": {
    "Stop": [{
      "hooks": [{
        "type": "command",
        "command": "python3 ~/.claude/scripts/quality-gate.py",
        "timeout": 5000
      }]
    }]
  }
}
```

## Thư viện learning

Tạo các file này trong thư mục memory của project. Hook kiểm tra xem có ít nhất một file được cập nhật trong ngày hôm nay hay không:

```
memory/
├── growth-log/          # Daily learning entries (directory)
├── decisions/log.md     # Decision log
├── output-index.md      # Index of session outputs
├── ratings-tracker.md   # Skill ratings over time
└── tooling_capabilities.md  # Known tools inventory
```

Hãy tùy chỉnh dict `LIBS` cho khớp với cấu trúc file của bạn.

## Cấu hình

Chỉnh sửa `quality-gate.py`:

| Biến | Mặc định | Mục đích |
|----------|---------|---------|
| `RATIONALIZE` | 4 pattern | Pattern regex để phát hiện biện minh |
| `LIBS` | 5 thư viện | File/thư mục cần kiểm tra xem có được cập nhật hôm nay không |
| `COMPLEX_THRESHOLD` | 3 | Số lần gọi Edit/Write để phân loại là phức tạp |
| `DISK_WARN_GB` | 50 | Cảnh báo khi dưới mức này |
| `DISK_CRIT_GB` | 15 | Chặn khi dưới mức này |

## Ví dụ

**Phiên đơn giản — cho phép:**
```
edit_count=1 (< 3, not complex) → exit 0
```

**Task phức tạp, đã ghi nhận learning — cho phép:**
```
edit_count=5 (complex) → checks LIBS → growth-log updated today → exit 0
```

**Task phức tạp, không có learning — BỊ CHẶN:**
```
edit_count=4 (complex) → checks LIBS → all 5 stale → exit 2
stderr: "Blocked: complex task completed but no learning captured today."
```

**Dung lượng đĩa thấp — BỊ CHẶN:**
```
disk_free=12GB < 15GB critical → exit 2
stderr: "Blocked: disk space at 12GB (threshold: 15GB)."
```

## Hạn chế

Hook cưỡng chế **thói quen** chạm tới các thư viện learning, không phải **chất lượng** của những gì được ghi lại. Nếu `output-index.md` được cập nhật nhưng `growth-log` bị bỏ qua, hook vẫn cho qua (1 trên 5 thư viện được chạm tới). Đây là chủ đích: các gate cơ học kiểm tra những sự kiện có thể xác minh bằng máy. Để xác minh chất lượng nội dung, hãy kết hợp với `self-audit`.

## Tương thích

- Python 3.8+ (dùng `from __future__ import annotations`)
- Đa nền tảng: Windows, macOS, Linux
- Không có dependency ngoài stdlib

## Chất lượng

Đoạn code này đã trải qua 4 vòng code review tự động (CodeRabbit + Greptile) với 9 bug thật được tìm ra và sửa.

## Xem thêm

- `self-audit` — Gate chất lượng suy luận (tính đầy đủ/nhất quán/có căn cứ/trung thực)
- `verification-loop` — Kiểm tra chất lượng code (build/type/lint/test)
- `gateguard` — Gate an toàn PreToolUse
