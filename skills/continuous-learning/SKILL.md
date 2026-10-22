---
name: continuous-learning
description: "[DEPRECATED - dùng continuous-learning-v2] Bộ trích xuất skill v1 kiểu legacy dùng stop-hook. v2 là tập cha hoàn toàn (strict superset) với việc học dựa trên instinct, theo phạm vi dự án, đáng tin cậy nhờ hook. KHÔNG gọi v1: khi có yêu cầu continuous learning, session learning hoặc pattern extraction, hãy định tuyến sang continuous-learning-v2 thay thế."
metadata:
  origin: ECC
---

# Skill Continuous Learning - DEPRECATED

> **DEPRECATED 2026-04-28.** Hãy dùng `continuous-learning-v2` thay thế. v2 là tập cha hoàn toàn: quan sát bằng stop-hook trở thành quan sát bằng PreToolUse/PostToolUse, skill đầy đủ trở thành các instinct nguyên tử kèm chấm điểm confidence, và lưu trữ chỉ toàn cục trở thành theo phạm vi dự án cộng với nâng cấp lên global.
>
> File này được giữ lại để tham khảo lưu trữ và để tương thích ngược với các bản cài hiện có.

---

## Tài liệu v1 gốc (lưu trữ)

Tự động đánh giá các session Claude Code khi kết thúc để trích xuất các pattern tái sử dụng được và có thể lưu thành learned skill.

## Khi nào kích hoạt

- Thiết lập trích xuất pattern tự động từ các session Claude Code
- Cấu hình Stop hook để đánh giá session
- Review hoặc tuyển chọn các learned skill trong `~/.claude/skills/learned/`
- Điều chỉnh ngưỡng trích xuất hoặc các danh mục pattern
- So sánh cách tiếp cận v1 (này) với v2 (dựa trên instinct)

## Trạng thái

Skill v1 này vẫn được hỗ trợ, nhưng `continuous-learning-v2` là đường đi ưu tiên cho các bản cài mới. Hãy giữ v1 khi bạn muốn rõ ràng dùng luồng trích xuất Stop-hook đơn giản hơn hoặc cần tương thích với các workflow learned-skill cũ.

## Cách hoạt động

Skill này chạy dưới dạng **Stop hook** ở cuối mỗi session:

1. **Đánh giá session**: Kiểm tra xem session có đủ số tin nhắn không (mặc định: 10+)
2. **Phát hiện pattern**: Xác định các pattern có thể trích xuất từ session
3. **Trích xuất skill**: Lưu các pattern hữu ích vào `~/.claude/skills/learned/`

## Cấu hình

Chỉnh sửa `config.json` để tùy chỉnh:

```json
{
  "min_session_length": 10,
  "extraction_threshold": "medium",
  "auto_approve": false,
  "learned_skills_path": "~/.claude/skills/learned/",
  "patterns_to_detect": [
    "error_resolution",
    "user_corrections",
    "workarounds",
    "debugging_techniques",
    "project_specific"
  ],
  "ignore_patterns": [
    "simple_typos",
    "one_time_fixes",
    "external_api_issues"
  ]
}
```

## Các loại Pattern

| Pattern | Mô tả |
|---------|-------------|
| `error_resolution` | Cách các lỗi cụ thể đã được giải quyết |
| `user_corrections` | Pattern từ các lần người dùng sửa lại |
| `workarounds` | Giải pháp cho các điểm kỳ quặc của framework/thư viện |
| `debugging_techniques` | Các cách debug hiệu quả |
| `project_specific` | Convention riêng của dự án |

## Thiết lập Hook

Thêm vào `~/.claude/settings.json` của bạn:

```json
{
  "hooks": {
    "Stop": [{
      "matcher": "*",
      "hooks": [{
        "type": "command",
        "command": "~/.claude/skills/continuous-learning/evaluate-session.sh"
      }]
    }]
  }
}
```

## Tại sao dùng Stop Hook?

- **Nhẹ**: Chạy một lần ở cuối session
- **Không chặn**: Không thêm độ trễ cho mỗi tin nhắn
- **Context đầy đủ**: Có quyền truy cập toàn bộ transcript của session

## Liên quan

- [The Longform Guide](https://x.com/affaanmustafa/status/2014040193557471352) - Phần về continuous learning
- Lệnh `/learn` - Trích xuất pattern thủ công giữa chừng session

---

## Ghi chú so sánh (Nghiên cứu: Jan 2025)

### So với Homunculus

Homunculus v2 có cách tiếp cận tinh vi hơn:

| Tính năng | Cách tiếp cận của chúng ta | Homunculus v2 |
|---------|--------------|---------------|
| Quan sát | Stop hook (cuối session) | PreToolUse/PostToolUse hook (đáng tin cậy 100%) |
| Phân tích | Context chính | Agent chạy nền (Haiku) |
| Độ chi tiết | Skill đầy đủ | "Instinct" nguyên tử |
| Confidence | Không có | 0.3-0.9 có trọng số |
| Tiến hóa | Trực tiếp thành skill | Instinct → cluster → skill/command/agent |
| Chia sẻ | Không có | Export/import instinct |

**Nhận định then chốt từ homunculus:**
> "v1 relied on skills to observe. Skills are probabilistic—they fire ~50-80% of the time. v2 uses hooks for observation (100% reliable) and instincts as the atomic unit of learned behavior."

### Các cải tiến v2 tiềm năng

1. **Học dựa trên instinct** - Các hành vi nhỏ hơn, nguyên tử, kèm chấm điểm confidence
2. **Observer chạy nền** - Agent Haiku phân tích song song
3. **Confidence suy giảm** - Instinct mất confidence nếu bị mâu thuẫn
4. **Gắn tag domain** - code-style, testing, git, debugging, v.v.
5. **Lộ trình tiến hóa** - Gom nhóm các instinct liên quan thành skill/command

Xem: `docs/continuous-learning-v2-spec.md` để biết đặc tả đầy đủ.
