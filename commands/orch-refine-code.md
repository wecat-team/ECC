---
description: Điều phối một refactor bảo toàn hành vi — xác nhận test xanh, tái cấu trúc mà không đổi hành vi, giữ xanh, review, commit có cổng kiểm soát. Wrapper cho skill orch-refine-code.
---

# /orch-refine-code

Khởi chạy thủ công orchestrator **orch-refine-code**: cải thiện cấu trúc trong khi
hành vi giữ nguyên, với bộ test hiện có làm lưới an toàn.

## Cách dùng

```
/orch-refine-code <what to restructure>
```

Ví dụ:

```
/orch-refine-code extract the NWS HTTP client out of poller.py
/orch-refine-code remove dead code and duplication in the dashboard module
```

## Nó làm gì

Gọi skill `orch-refine-code` với `$ARGUMENTS` làm yêu cầu. Skill
(thông qua engine dùng chung `orch-pipeline`) sẽ:

1. Phân loại quy mô (mức sàn mặc định: standard — việc tái cấu trúc chạm nhiều file).
2. Xác nhận các test liên quan tồn tại và **xanh trước khi** đụng vào code; thêm
   characterization test trước nếu coverage còn mỏng. Lập kế hoạch tái cấu trúc. → **GATE 1**.
3. Tái cấu trúc theo các bước nhỏ, chạy lại test sau mỗi bước (không thêm test
   hành vi mới — bộ test hiện có chứng minh hành vi không đổi). Việc quét dead code/trùng lặp
   được ủy quyền cho `refactor-cleaner`.
4. `code-reviewer`, sau đó commit dưới dạng `refactor:` (diff phải trung lập về hành vi). → **GATE 2**.

Chỉ dùng khi hành vi **không** được thay đổi. Nếu hành vi cần thay đổi dù chỉ một chút,
hãy dùng `/orch-change-feature` hoặc `/orch-fix-defect`.

Nếu `$ARGUMENTS` trống, hãy hỏi người dùng cần tinh chỉnh gì.
