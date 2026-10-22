---
name: agent-self-evaluation
description: Dùng sau khi hoàn thành bất kỳ tác vụ không tầm thường nào. Agent tự chấm output của mình trên 5 trục — accuracy, completeness, clarity, actionability, conciseness — kèm bằng chứng cụ thể cho từng tiêu chí. Tạo scorecard có cấu trúc thang 1-5 cùng các gợi ý cải thiện cụ thể.
origin: ECC
---

# Agent Self-Evaluation

Sau khi hoàn thành một tác vụ phức tạp, agent dừng lại để chấm output của chính mình theo một rubric 5 trục có cấu trúc. Đây KHÔNG phải cổng pass/fail — đó là một bước phản tỉnh có chủ đích, giúp bắt các thiếu sót, chỉ ra sự tự tin thái quá, và làm lộ ra các điểm cần cải thiện trước khi người dùng phải làm việc đó.

## Khi nào kích hoạt

- Sau khi viết code trải rộng 3+ file hoặc 50+ dòng
- Sau khi hoàn thành một workflow nhiều bước (implement → test → review)
- Sau một phiên debug đã trải qua 3+ lần thử
- Sau khi tạo tài liệu thiết kế, quyết định kiến trúc hoặc bản phân tích bằng văn bản
- Khi người dùng hỏi "how good was that?" hoặc "rate yourself"
- Ở cuối mọi session thông qua Stop hook (nếu được cấu hình — xem `references/hook-integration.md`)

## Khái niệm cốt lõi

### 5 trục đánh giá

| Trục | Câu hỏi | Bắt được gì |
|---|---|---|
| **Accuracy** | Các sự kiện, khẳng định và output có đúng không? | Hallucination, tên API sai, cú pháp sai, phát biểu sai sự thật |
| **Completeness** | Có bao phủ mọi thứ người dùng yêu cầu không? | Edge case bị bỏ sót, đường dẫn lỗi không được xử lý, yêu cầu bị quên, subtask bị bỏ qua |
| **Clarity** | Lời giải thích có dễ hiểu và có cấu trúc tốt không? | Giải thích gây khó hiểu, thuật ngữ không định nghĩa, thiếu ngữ cảnh, lan man |
| **Actionability** | Người dùng có thể hành động ngay trên output không? | Gợi ý mơ hồ, thiếu bước, "you should X" mà không chỉ cách làm, không có đường xác minh |
| **Conciseness** | Có dùng số từ/token tối thiểu cần thiết không? | Dư thừa, giải thích quá mức, lặp nguyên văn câu hỏi của người dùng, nội dung độn |

### Thang điểm

```
5 — Exceptional: no reasonable improvement possible
4 — Good: minor nits only, no substantive gaps
3 — Adequate: meets the request but has a notable weakness on at least one axis
2 — Weak: has a clear gap that affects usability or correctness
1 — Poor: fundamentally misses the request or contains significant errors
```

### Quy tắc bằng chứng (Evidence Rule)

Mọi điểm dưới 5 PHẢI trích dẫn bằng chứng cụ thể. Điểm 3 không thể chỉ nói "could be better" — nó phải nói chính xác điều gì còn thiếu hoặc sai. Phương châm: **"Show the gap, don't just name it."** (Chỉ ra khoảng thiếu, đừng chỉ gọi tên nó.)

## Quy trình

### Bước 1: Thu thập nguyên liệu thô

Gom những thứ bạn sẽ đánh giá:

```
- The original user request (read back from conversation)
- Your final response/output (the deliverable)
- Any tool outputs that verify correctness (test results, exit codes, lint output)
- Any user feedback received during the task (corrections, "try again", "that's not right")
```

### Bước 2: Chấm từng trục một cách độc lập

Lần lượt đi qua 5 trục, từng trục một. Với mỗi trục:

1. Đọc câu hỏi của trục
2. Tìm bằng chứng (hoặc việc thiếu bằng chứng) trong output
3. Gán điểm 1-5
4. Nếu điểm < 5, viết một ghi chú cải thiện một câu, trích dẫn khoảng thiếu

KHÔNG nhẩm trước điểm trung bình trong đầu rồi suy ngược lại. Hãy chấm mỗi trục từ đầu.

### Bước 3: Tạo báo cáo đánh giá

Dùng template từ `templates/evaluation-report.md`. Báo cáo phải bao gồm:

```
- One-line summary
- 5-axis scorecard (score + evidence per axis)
- Overall score (simple average, rounded to 1 decimal)
- 1-3 specific improvements ranked by impact
- Self-check: "Would the user agree with this assessment?"
```

### Bước 4: Áp dụng cải thiện

Nếu bất kỳ trục nào đạt 3 điểm trở xuống:

1. Nêu những gì bạn sẽ làm khác đi
2. Nếu khoảng thiếu có thể sửa trong < 30 giây (thiếu link, cách diễn đạt chưa rõ), hãy sửa ngay
3. Nếu khoảng thiếu đòi hỏi làm lại, hãy đánh dấu tường minh: "This axis scored [reason] because [evidence]. Re-running with [specific fix] would likely raise it to [score]."

## Ví dụ code

### Ví dụ: Đánh giá tốt (điểm 4+)

```
Task: Add retry logic to HTTP client

Scorecard:
  Accuracy:    5 — All API calls correct. Verified: retries use
                  exponential backoff. No hallucinated methods.
  Completeness: 4 — Covered happy path + 3 error cases. Missing:
                  timeout handling for hung connections.
  Clarity:      5 — Code comments explain backoff formula.
                  PR description links to incident that motivated this.
  Actionability:5 — Single merge. No follow-up tasks. Tests pass.
  Conciseness:  4 — 47 lines total. The retry loop could be extracted
                  into a helper to drop ~8 lines.

Overall: 4.6 — One gap (timeout handling). Fix before merging.
```

### Ví dụ: Đánh giá yếu (điểm 2-3)

```
Task: Add retry logic to HTTP client

Scorecard:
  Accuracy:    2 — Used urllib3 which doesn't match our
                  httpx-based codebase. Wrong library.
  Completeness: 3 — Works for GET. POST/PUT not handled (user
                  said "all HTTP requests").
  Clarity:      4 — Code is readable. Good variable names.
  Actionability:2 — "Add tests" mentioned but no test file created.
                  User has to write tests before merging.
  Conciseness:  3 — 120 lines. The retry config is duplicated in
                  3 places instead of one shared RetryConfig object.

Overall: 2.8 — Wrong library used. Needs httpx rewrite.
  Fix accuracy first (switch to httpx), then extend to all
  HTTP methods, then consolidate config.
```

## Anti-Pattern

### "Everything is a 5"

```
FAIL: Accuracy:    5 — All good.
   Completeness: 5 — Everything covered.
   Clarity:      5 — Clear.
```

Không trích dẫn bằng chứng. Đây là tự khen, không phải đánh giá. Một điểm 5 thực sự đòi hỏi chứng minh rằng không còn gì để cải thiện.

### Trừ điểm quá mức vì scope creep

```
FAIL: Completeness: 2 — Didn't handle WebSocket connections or
   gRPC streaming (user didn't ask for these)
```

Chỉ đánh giá dựa trên những gì người dùng thực sự yêu cầu, không phải những gì bạn có thể đã xây thêm.

### Dùng đánh giá để tranh cãi lại

```
FAIL: "As I said earlier, this approach is wrong. Score: 1"
```

Đánh giá là về output đã giao, không phải để tranh luận lại các quyết định thiết kế đã được đưa ra. Nếu cách tiếp cận sai, lẽ ra điều đó phải được phát hiện trước khi giao.

### Trộn sở thích cá nhân với khoảng thiếu khách quan

```
FAIL: "Score: 3. I don't like Python decorators."
```

"Don't like" không phải là bằng chứng. Hãy trích dẫn một mối lo cụ thể về độ dễ đọc, khả năng test hoặc tính đúng đắn, hoặc giữ điểm ở mức 4+.

## Thực hành tốt

- **Đánh giá output, không đánh giá quá trình.** Người dùng quan tâm bạn đã giao gì, không phải bạn mất bao nhiêu lần lặp.
- **Một cải thiện cho mỗi trục yếu.** Đừng liệt kê 5 điều cho một trục — hãy chọn khoảng thiếu có tác động lớn nhất.
- **Gắn cải thiện với tác động lên người dùng.** "Missing error handling means the user's API call will crash silently" tốt hơn "add error handling."
- **Nêu cụ thể 'đã sửa' trông như thế nào.** "Re-run with httpx transport configured for retries" tốt hơn "fix the library issue."
- **Dùng output của tool làm bằng chứng.** Nếu test pass, hãy trích dẫn. Nếu lint sạch, hãy trích dẫn. Đừng đoán — hãy grep để tìm bằng chứng.
- **Nếu bạn không tìm thấy khoảng thiếu nào, hãy cố gắng hơn.** Điểm tuyệt đối ở cả 5 trục rất hiếm. Hãy tự hỏi: "Nếu tôi là người dùng, điều gì ở output này sẽ làm tôi khó chịu?"

## Skill liên quan

- `agent-eval` — So sánh đối đầu giữa các coding agent khác nhau trên các tác vụ benchmark
- `verification-loop` — Xác minh có hệ thống các output so với kết quả kỳ vọng
- `security-review` — Checklist code review tập trung vào bảo mật
