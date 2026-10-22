---
description: Điều phối việc thay đổi một tính năng đang hoạt động sang hành vi mong muốn mới — cập nhật test theo spec mới, đổi phần triển khai, review, commit có cổng kiểm soát. Wrapper cho skill orch-change-feature.
---

# /orch-change-feature

Khởi chạy thủ công orchestrator **orch-change-feature**: đổi hành vi
đang hoạt động sang một spec mong muốn mới, theo hướng test-first.

## Cách dùng

```
/orch-change-feature <the new desired behavior>
```

Ví dụ:

```
/orch-change-feature make nws-poller alert at 2 warnings instead of 3
/orch-change-feature instead of sorting by date, sort by priority
```

## Nó làm gì

Gọi skill `orch-change-feature` với `$ARGUMENTS` làm yêu cầu. Skill
(thông qua engine dùng chung `orch-pipeline`) sẽ:

1. Phân loại quy mô (mức sàn mặc định: small) và nêu rõ tier.
2. Chỉ lập kế hoạch nhẹ nếu hành vi mới cần nghiên cứu. → **GATE 1** (duyệt kế hoạch test thay đổi).
3. **Cập nhật các test hiện có** để thể hiện hành vi mới, rồi đổi phần
   triển khai cho đến khi xanh. (Đổi test trước chính là điều biến việc này thành
   một tinh chỉnh, không phải một bản sửa lỗi.)
4. `code-reviewer` (+ `security-reviewer` khi có trigger bảo mật), sau đó commit. → **GATE 2**.

Chỉ dùng khi tính năng **đang hoạt động** nhưng cần hoạt động khác đi — không dùng cho
bug (`/orch-fix-defect`) hay năng lực hoàn toàn mới (`/orch-add-feature`).

Nếu `$ARGUMENTS` trống, hãy hỏi người dùng hành vi nào cần thay đổi.
