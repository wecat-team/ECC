---
description: Điều phối việc sửa một bug — tái hiện nó bằng một regression test thất bại, sửa đến khi xanh, review, commit có cổng kiểm soát. Wrapper cho skill orch-fix-defect.
---

# /orch-fix-defect

Khởi chạy thủ công orchestrator **orch-fix-defect**: chứng minh bug bằng một
test đỏ, rồi sửa đến khi xanh.

## Cách dùng

```
/orch-fix-defect <what is broken>
```

Ví dụ:

```
/orch-fix-defect poller crashes on empty NWS response
/orch-fix-defect login returns 500 when email has a plus sign
```

## Nó làm gì

Gọi skill `orch-fix-defect` với `$ARGUMENTS` làm yêu cầu. Skill
(thông qua engine dùng chung `orch-pipeline`) sẽ:

1. Phân loại quy mô (mức sàn mặc định: small, thường là trivial); xác định phạm vi nguyên nhân gốc bằng
   `code-explorer` nếu chưa rõ.
2. **Viết một regression test mới thất bại** tái hiện bug, rồi sửa cho đến khi
   nó xanh. (Chứng minh bug trước chính là điều biến việc này thành một bản sửa lỗi, không phải một tinh chỉnh.)
3. `code-reviewer` (+ `security-reviewer` nếu lỗi nằm trên đường dẫn nhạy cảm).
4. Commit dưới dạng một commit `fix:` theo conventional commit. → **GATE 2** (xác nhận trước khi commit).

Chỉ dùng khi hành vi bị **hỏng/sai** — không dùng cho các thay đổi có chủ đích
(`/orch-change-feature`) hay năng lực mới (`/orch-add-feature`).

Nếu `$ARGUMENTS` trống, hãy yêu cầu người dùng mô tả lỗi.
