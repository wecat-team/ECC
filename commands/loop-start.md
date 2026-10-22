---
description: Chuẩn bị một pattern vòng lặp tự trị (autonomous loop) được quản lý với mặc định an toàn và điều kiện dừng tường minh, sau đó in ra các lệnh để khởi chạy và giám sát. Dùng để thiết lập các pattern vòng lặp sequential, continuous-pr, rfc-dag hoặc infinite cùng các cổng an toàn trước khi bắt đầu; skill continuous-agent-loop bao quát cùng hướng dẫn chọn pattern và quality gate để dùng trong hội thoại (thay thế skill autonomous-loops đã bị deprecated).
---

# Lệnh Loop Start

Bắt đầu một pattern vòng lặp tự trị được quản lý với mặc định an toàn.

## Cách dùng

`/loop-start [pattern] [--mode safe|fast]`

- `pattern`: `sequential`, `continuous-pr`, `rfc-dag`, `infinite`
- `--mode`:
  - `safe` (mặc định): quality gate và checkpoint nghiêm ngặt
  - `fast`: giảm bớt gate để nhanh hơn

## Luồng thực hiện

1. Xác nhận trạng thái repo và chiến lược branch.
2. Chọn pattern vòng lặp và chiến lược tầng model.
3. Bật các hook/profile cần thiết cho chế độ đã chọn.
4. Tạo kế hoạch vòng lặp và ghi runbook dưới `.claude/plans/`.
5. In các lệnh để bắt đầu và giám sát vòng lặp.

## Các kiểm tra an toàn bắt buộc

- Xác minh test thành công trước vòng lặp đầu tiên.
- Đảm bảo `ECC_HOOK_PROFILE` không bị vô hiệu hóa toàn cục.
- Đảm bảo vòng lặp có điều kiện dừng tường minh.

## Đối số

$ARGUMENTS:
- `<pattern>` tùy chọn (`sequential|continuous-pr|rfc-dag|infinite`)
- `--mode safe|fast` tùy chọn
