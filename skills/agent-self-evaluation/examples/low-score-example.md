# Ví dụ điểm thấp: Thêm logic Retry

## Nhiệm vụ
> Thêm logic retry với exponential backoff cho tất cả HTTP request trong API client. Tối đa 3 lần retry, độ trễ ban đầu 1s, độ trễ tối đa 30s.

## Output của Agent

Here's a retry implementation. I think this should work for most cases.

I used the urllib3 library since it has built-in retry support. The Retry class handles backoff automatically.

```python
from urllib3.util import Retry

# Add this somewhere in your HTTP client
retry = Retry(
    total=3,
    backoff_factor=1.0,
    status_forcelist=[500, 502, 503, 504]
)
```

You'll want to test this before deploying. There might be edge cases with POST requests but those are probably fine. I haven't tested the timeout behavior but it should work.

Let me know if you need anything else!

---

## Báo cáo đánh giá

```
============================================================
AGENT SELF-EVALUATION REPORT
============================================================

  Accuracy         ██░░░ 2/5
    - Hedged claim without verification ("I think this should work")
    - Untested ("I haven't tested the timeout behavior")
    - Speculation without evidence ("those are probably fine")
    → Wrong library used. Project uses httpx, not urllib3.
                      urllib3.util.Retry is incompatible with httpx.

  Completeness      ███░░ 3/5
    - Explicit gap acknowledged ("might be edge cases with POST")
    - Limited scope noted (only mentioned 5xx, not 429 or connection errors)
    → User asked for "all HTTP requests." Only partial coverage:
      missing 429 handling, connection errors, timeout handling.

  Clarity           ████░ 4/5
    + Uses code blocks
    → Code is readable but no explanation of where to add it
      ("somewhere in your HTTP client" is vague).

  Actionability     ██░░░ 2/5
    - Defers work to user ("you'll want to test this")
    - Vague suggestion without specifics
    → No PR, no file created, no test written. User has to:
      1. Figure out where to add the code
      2. Fix the library mismatch (httpx not urllib3)
      3. Write tests
      4. Handle POST idempotency
      5. Test timeout behavior

  Conciseness       ███░░ 3/5
    - Meta-commentary adds words without information
      ("Let me know if you need anything else!")
    → 120 words. Low word count but low information density.
      Half the text is hedging and disclaimers, not substance.

  OVERALL           2.8/5

TOP IMPROVEMENTS (axes scoring < 4):
  [Accuracy] Switch to httpx — grep the codebase to confirm the HTTP
    library before writing code.
  [Actionability] Create a PR with the changed file + test file. Run the
    tests. End with "PR #N ready to merge."
  [Completeness] List what's covered AND what's not. If POST retry is
    unsafe, say so explicitly with reasoning.
```

### Vì sao bị điểm thấp

1. **Accuracy thất bại ở mức cơ bản nhất** — sai thư viện. Chỉ một lệnh `grep httpx src/` là đã phát hiện ra. Ngôn ngữ dè dặt ("I think", "probably", "should work") cho thấy agent biết mình đang đoán.
2. **Không actionable.** Người dùng nhận được một đoạn code và một danh sách việc họ cần làm. Agent làm phần dễ (gợi ý một thư viện) và đẩy những phần khó (test, tích hợp, edge case) cho người dùng.
3. **Các lỗ hổng về completeness được thừa nhận nhưng không được sửa.** "Might be edge cases" còn tệ hơn việc không nhắc tới — nó cho thấy đã nhận thức được lỗ hổng và chọn không xử lý.
4. **Mật độ thông tin thấp.** 120 từ, trong đó khoảng 60 từ là dè dặt/tuyên bố miễn trừ/xã giao. Nội dung thực chất (3 dòng code) có thể được đưa ra trong 40 từ kèm xác minh.
