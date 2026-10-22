# Template báo cáo Agent Self-Evaluation

Sao chép template này và điền vào sau khi hoàn thành một tác vụ. Định dạng khớp với output của `scripts/evaluate.py`.

```
============================================================
AGENT SELF-EVALUATION REPORT
============================================================
Summary: Overall score X.X/5 across 5 quality axes.

  Accuracy         █████ 5/5    or    ███░░ 3/5
    + [Evidence: passing tests, verified claims]
    - [Gaps: unverified claims, hedging language]
    → [Improvement if score < 5]

  Completeness      █████ 5/5
    + [What's covered: all requirements + edge cases]
    - [What's missing: explicitly acknowledge gaps]
    → [Improvement if score < 5]

  Clarity           █████ 5/5
    + [Structure: headings, code blocks, bullet points]
    - [Issues: undefined terms, wall of text, no summary]
    → [Improvement if score < 5]

  Actionability     █████ 5/5
    + [User can: merge PR, run command, review file]
    - [Blockers: missing steps, vague suggestions]
    → [Improvement if score < 5]

  Conciseness       █████ 5/5
    + [Tight: no repetition, high information density]
    - [Bloat: filler, meta-commentary, repeated points]
    → [Improvement if score < 5]

  OVERALL           X.X/5

CRITICAL ISSUES (axes ≤ 2):
  [Axis] Score N/5 — specific fix needed
  (or "None" if no axis ≤ 2)

Self-check: Would the user agree with this assessment? [Yes/No + brief justification]

TOP IMPROVEMENTS:
  1. [Highest impact fix]
  2. [Second highest]
  (Only list axes scoring < 4, ranked by user impact)

VERDICT: [Deliver as-is / Fix N issues then deliver / Redo from scratch]
```

## Tham khảo nhanh: Các tác nhân chấm điểm

| Nếu bạn thấy điều này... | Accuracy | Completeness | Clarity | Actionability | Conciseness |
|---|---|---|---|---|---|
| "should work" / "probably fine" | ≤4 | — | — | — | — |
| "I think" / "I believe" | ≤4 | — | — | — | — |
| Không trích dẫn output của test | ≤4 | — | — | — | — |
| "TODO" / "FIXME" bị bỏ lại | ≤3 | ≤3 | — | ≤3 | — |
| Thiếu xử lý lỗi | — | ≤3 | — | — | — |
| Chỉ bao phủ happy path | — | ≤3 | — | — | — |
| Đoạn văn dạng khối chữ (>200 từ) | — | — | ≤3 | — | — |
| Không có heading hay cấu trúc | — | — | ≤3 | — | — |
| "You should..." mà không có chi tiết cụ thể | — | — | — | ≤3 | — |
| Không tạo PR hay file | — | — | — | ≤3 | — |
| Người dùng phải tự tìm ra bước tiếp theo | — | — | — | ≤2 | — |
| Ý bị lặp (3+ lần) | — | — | — | — | ≤3 |
| "Let me explain..." / "To summarize..." x3+ | — | — | — | — | ≤3 |
| Output dài hơn tác vụ >15 lần | — | — | — | — | ≤3 |

## Khi nào bỏ qua

Bỏ qua việc đánh giá nếu:
- Tác vụ chỉ là một lần gọi tool (ví dụ "read this file" — không có gì để đánh giá)
- Người dùng nói rõ "don't evaluate" hoặc "just do it"
- Tác vụ hoàn toàn mang tính hội thoại (chào hỏi, nói chuyện phiếm)
- Bạn đang ở giữa workflow và người dùng sẽ đánh giá output cuối cùng, không phải các bước trung gian

## Hành động sau đánh giá

| Điểm tổng | Cần làm gì |
|---|---|
| ≥4.5 | Giao nguyên trạng. Không cần thay đổi. |
| 3.5–4.4 | Đánh dấu cải thiện hàng đầu nhưng vẫn giao. Sửa nếu <30 giây. |
| 2.5–3.4 | Nêu những gì bạn sẽ thay đổi. Hỏi người dùng: "Should I redo [axis] or deliver as-is?" |
| <2.5 | Không giao. Nói: "This scored [score] because [evidence]. Let me redo this with [specific fix]." Sau đó làm lại. |
