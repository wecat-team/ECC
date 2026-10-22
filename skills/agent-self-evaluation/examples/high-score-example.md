# Ví dụ điểm cao: Thêm logic Retry

## Nhiệm vụ
> Thêm logic retry với exponential backoff cho tất cả HTTP request trong API client. Tối đa 3 lần retry, độ trễ ban đầu 1s, độ trễ tối đa 30s.

## Output của Agent

### Tóm tắt
Đã thêm `httpx.HTTPTransport` với cấu hình retry vào class `ApiClient` dùng chung. Tất cả các phương thức HTTP (GET, POST, PUT, DELETE) giờ đều retry khi gặp 429, 5xx và lỗi kết nối với exponential backoff. 42 test pass. Một PR duy nhất, sẵn sàng merge.

### Các file đã thay đổi
- `src/api_client.py` — Thêm wrapper `RetryTransport` với `httpx.HTTPTransport(retries=3)` và exponential backoff được cấu hình qua `httpx.Limits`
- `tests/test_api_client.py` — Thêm 8 test: happy path, retry khi 429, retry khi 503, hết số lần retry tối đa, timeout, assertion về thời gian backoff, retry GET idempotent, không retry với 4xx (trừ 429)

### Xác minh
```
$ pytest tests/test_api_client.py -v
42 passed in 2.34s

$ grep -r "RetryTransport" src/
src/api_client.py:23: class RetryTransport(httpx.BaseTransport):
src/api_client.py:45:     self._transport = RetryTransport(...)

$ python -c "from src.api_client import ApiClient; c = ApiClient(); print(type(c._transport))"
<class 'src.api_client.RetryTransport'>
```

### Các edge case đã xử lý
- Connection timeout (retry với backoff)
- Rate limiting (429 → retry sau một khoảng trễ)
- Lỗi server (5xx → retry)
- Lỗi client trừ 429 (không retry — 4xx nghĩa là request sai)
- Tính idempotent: GET, PUT, DELETE được retry; POST thì không (có thể cấu hình)

### Merge: [PR #423](https://github.com/example/pr/423)

---

## Báo cáo đánh giá

```
============================================================
AGENT SELF-EVALUATION REPORT
============================================================

  Accuracy         █████ 5/5
    + Tests passing
    + Explicit verification (grep confirmed class exists, import test passed)
    + Lint clean
    → All claims backed by tool output. No hedging.

  Completeness      ████░ 4/5
    + Edge cases addressed (5 specific scenarios listed)
    + Error handling present across all HTTP methods
    → Missing: connection pool exhaustion handling (what happens when all
      connections are in retry state?) — minor gap, not blocking.

  Clarity           █████ 5/5
    + Uses headings for structure
    + Uses code blocks
    + Uses bullet points
    + Summary in first 3 lines
    → Well-organized. Reader can scan in 10 seconds.

  Actionability     █████ 5/5
    + PR created and linked
    + Specific run command given (pytest)
    + Verification steps included
    → Single action: merge PR #423. Everything else is done.

  Conciseness       ████░ 4/5
    + No redundancy detected
    → The verification section could be slightly tighter (3 commands
      could be 1 with a verification script). Minor.

  OVERALL           4.6/5

TOP IMPROVEMENTS:
  No axes below 4. Strong output across all dimensions.
```

### Vì sao được điểm cao

1. **Accuracy bám sát output của tool.** Mọi khẳng định ("tests pass", "class exists", "import works") đều có một dòng output terminal tương ứng. Không có "should work" hay "probably fine."
2. **Completeness nói rõ những gì được bao phủ VÀ những gì không.** Phần edge case liệt kê cả các trường hợp đã xử lý lẫn các trường hợp cố ý không xử lý (tính idempotent của POST).
3. **Actionability chỉ cần một bước.** Người dùng chỉ cần merge một PR. Không có tác vụ tiếp theo, không có "sau đó hãy cấu hình X."
4. **Conciseness chặt chẽ.** Output khoảng 250 từ. Mật độ thông tin cao — mỗi câu đều có trọng lượng.
