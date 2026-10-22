---
description: Điều phối việc khởi tạo một MVP chạy được từ tài liệu thiết kế/spec — tiếp nhận, chia lát cắt, scaffold, TDD, review, commit có cổng kiểm soát (tái sử dụng GAN harness). Wrapper cho skill orch-build-mvp.
---

# /orch-build-mvp

Khởi chạy thủ công orchestrator **orch-build-mvp**: biến một tài liệu SDD/PRD/system-design
thành một vertical slice chạy được.

## Cách dùng

```
/orch-build-mvp <path to design/spec doc>
```

Ví dụ:

```
/orch-build-mvp civicpulse/docs/SDD-v0.6.md
```

## Nó làm gì

Gọi skill `orch-build-mvp` với `$ARGUMENTS` là đường dẫn tài liệu. Skill
(thông qua engine dùng chung `orch-pipeline`, pipeline đầy đủ gồm cả Scaffold) sẽ:

1. Đọc spec; trích xuất phạm vi, các quyết định đã chốt, và danh sách tính năng sắp xếp theo
**các vertical slice mỏng** (đường đi end-to-end đầu tiên trước). → **GATE 1** (duyệt kế hoạch các slice).
2. Scaffold slice end-to-end đầu tiên.
3. Tái sử dụng GAN harness: chuyển SDD thành `gan-harness/spec.md` +
   `eval-rubric.md`, rồi chạy `/gan-build "<brief>" --skip-planner`
   (vòng lặp generator → evaluator) cho đến khi điểm đạt hoặc chững lại (plateau).
4. `code-reviewer` (+ `security-reviewer` với bất kỳ slice nào có trigger bảo mật), sau đó
   commit scaffold và từng slice thành các commit `feat:` riêng biệt. → **GATE 2**.

Nếu `$ARGUMENTS` trống, hãy hỏi người dùng đường dẫn tới tài liệu thiết kế/spec.
