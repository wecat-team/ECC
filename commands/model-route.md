---
description: Đề xuất tầng model tốt nhất cho tác vụ hiện tại dựa trên độ phức tạp, rủi ro và ngân sách.
---

# Lệnh Model Route

Đề xuất tầng model tốt nhất cho tác vụ hiện tại theo độ phức tạp và ngân sách.

## Cách dùng

`/model-route [task-description] [--budget low|med|high]`

## Heuristic định tuyến

- `haiku`: thay đổi cơ học, xác định, rủi ro thấp
- `sonnet`: mặc định cho triển khai và refactor
- `opus`: kiến trúc, review chuyên sâu, yêu cầu mơ hồ

## Output bắt buộc

- model được đề xuất
- mức độ tin cậy
- vì sao model này phù hợp
- model dự phòng nếu lần thử đầu thất bại

## Đối số

$ARGUMENTS:
- `[task-description]` văn bản tự do, tùy chọn
- `--budget low|med|high` tùy chọn
