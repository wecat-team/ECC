---
description: Điều phối việc xây dựng một tính năng hoàn toàn mới từ đầu đến cuối — nghiên cứu, lập kế hoạch, TDD, review, commit có cổng kiểm soát. Wrapper khởi chạy skill orch-add-feature.
---

# /orch-add-feature

Khởi chạy thủ công orchestrator **orch-add-feature**: một pipeline có cổng kiểm soát
Research → Plan → TDD → Review → Commit cho năng lực hoàn toàn mới.

## Cách dùng

```
/orch-add-feature <what to add>
```

Ví dụ:

```
/orch-add-feature add OAuth2 login to nws-poller
/orch-add-feature support CSV export in the dashboard
```

## Nó làm gì

Gọi skill `orch-add-feature` với `$ARGUMENTS` làm yêu cầu. Skill
(thông qua engine dùng chung `orch-pipeline`) sẽ:

1. Phân loại quy mô và nêu rõ tier trong một dòng.
2. Nghiên cứu các thư viện/pattern hiện có, rồi lập `task_list`. → **GATE 1** (duyệt kế hoạch).
3. TDD từng task (test mới thất bại → xanh), sau đó `code-reviewer`
   (+ `security-reviewer` nếu chạm vào một trigger bảo mật).
4. Commit dưới dạng các commit `feat:` theo conventional commit. → **GATE 2** (xác nhận trước khi commit).

Tuân thủ cả hai gate — không viết phần triển khai trước Gate 1, không commit trước Gate 2.

Nếu `$ARGUMENTS` trống, hãy hỏi người dùng cần thêm năng lực gì.
