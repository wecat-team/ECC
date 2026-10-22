---
name: santa-method
description: "Xác minh đối kháng (adversarial verification) đa agent: hai reviewer độc lập dùng cùng một rubric phải cùng pass thì đầu ra mới được phát hành, kèm vòng lặp hội tụ sửa-và-review-lại và giới hạn chuyển lên người xử lý (human escalation). Dùng để chặn cổng (gating) khi publish, deploy production, nội dung nhạy cảm về compliance hoặc thương hiệu, hay các tuyên bố dễ bị hallucination trước khi phát hành."
metadata:
  origin: "Ronald Skelton - Founder, RapportScore.ai"
---

# Santa Method

Framework xác minh đối kháng đa agent. Lập danh sách, kiểm tra hai lần. Nếu hư (naughty), sửa cho đến khi ngoan (nice).

Điểm mấu chốt: một agent tự review đầu ra của chính mình sẽ mang cùng những thiên kiến, lỗ hổng kiến thức và sai sót hệ thống đã tạo ra đầu ra đó. Hai reviewer độc lập không chia sẻ context sẽ phá vỡ kiểu thất bại này.

## Khi nào kích hoạt

Gọi skill này khi:
- Đầu ra sẽ được publish, deploy hoặc đến tay người dùng cuối
- Phải thực thi các ràng buộc về compliance, quy định pháp lý hoặc thương hiệu
- Code được đưa lên production mà không có con người review
- Độ chính xác của nội dung quan trọng (tài liệu kỹ thuật, tài liệu giáo dục, nội dung hướng tới khách hàng)
- Sinh hàng loạt ở quy mô lớn mà kiểm tra ngẫu nhiên sẽ bỏ sót các pattern mang tính hệ thống
- Rủi ro hallucination cao (tuyên bố, số liệu thống kê, tham chiếu API, ngôn ngữ pháp lý)

KHÔNG dùng cho bản nháp nội bộ, nghiên cứu khám phá, hoặc các tác vụ có thể xác minh một cách xác định (deterministic) (hãy dùng pipeline build/test/lint cho những việc đó).

## Kiến trúc

```
┌─────────────┐
│  GENERATOR   │  Phase 1: Make a List
│  (Agent A)   │  Produce the deliverable
└──────┬───────┘
       │ output
       ▼
┌──────────────────────────────┐
│     DUAL INDEPENDENT REVIEW   │  Phase 2: Check It Twice
│                                │
│  ┌───────────┐ ┌───────────┐  │  Two agents, same rubric,
│  │ Reviewer B │ │ Reviewer C │  │  no shared context
│  └─────┬─────┘ └─────┬─────┘  │
│        │              │        │
└────────┼──────────────┼────────┘
         │              │
         ▼              ▼
┌──────────────────────────────┐
│        VERDICT GATE           │  Phase 3: Naughty or Nice
│                                │
│  B passes AND C passes → NICE  │  Both must pass.
│  Otherwise → NAUGHTY           │  No exceptions.
└──────┬──────────────┬─────────┘
       │              │
    NICE           NAUGHTY
       │              │
       ▼              ▼
   [ SHIP ]    ┌─────────────┐
               │  FIX CYCLE   │  Phase 4: Fix Until Nice
               │              │
               │ iteration++  │  Collect all flags.
               │ if i > MAX:  │  Fix all issues.
               │   escalate   │  Re-run both reviewers.
               │ else:        │  Loop until convergence.
               │   goto Ph.2  │
               └──────────────┘
```

## Chi tiết từng giai đoạn

### Giai đoạn 1: Lập danh sách (Generate)

Thực hiện tác vụ chính. Không thay đổi workflow sinh nội dung thông thường của bạn. Santa Method là một lớp xác minh sau khi sinh, không phải một chiến lược sinh nội dung.

```python
# The generator runs as normal
output = generate(task_spec)
```

### Giai đoạn 2: Kiểm tra hai lần (Review kép độc lập)

Khởi chạy hai agent review song song. Các bất biến (invariant) quan trọng:

1. **Cô lập context** — không reviewer nào thấy đánh giá của reviewer kia
2. **Rubric giống hệt nhau** — cả hai nhận cùng tiêu chí đánh giá
3. **Cùng đầu vào** — cả hai nhận spec gốc VÀ đầu ra đã sinh
4. **Đầu ra có cấu trúc** — mỗi reviewer trả về một verdict có kiểu rõ ràng, không phải văn xuôi

```python
REVIEWER_PROMPT = """
You are an independent quality reviewer. You have NOT seen any other review of this output.

## Task Specification
{task_spec}

## Output Under Review
{output}

## Evaluation Rubric
{rubric}

## Instructions
Evaluate the output against EACH rubric criterion. For each:
- PASS: criterion fully met, no issues
- FAIL: specific issue found (cite the exact problem)

Return your assessment as structured JSON:
{
  "verdict": "PASS" | "FAIL",
  "checks": [
    {"criterion": "...", "result": "PASS|FAIL", "detail": "..."}
  ],
  "critical_issues": ["..."],   // blockers that must be fixed
  "suggestions": ["..."]         // non-blocking improvements
}

Be rigorous. Your job is to find problems, not to approve.
"""
```

```python
# Spawn reviewers in parallel (Claude Code subagents)
review_b = Agent(prompt=REVIEWER_PROMPT.format(...), description="Santa Reviewer B")
review_c = Agent(prompt=REVIEWER_PROMPT.format(...), description="Santa Reviewer C")

# Both run concurrently — neither sees the other
```

### Thiết kế Rubric

Rubric là đầu vào quan trọng nhất. Rubric mơ hồ sinh ra review mơ hồ. Mỗi tiêu chí phải có điều kiện pass/fail khách quan.

| Tiêu chí | Điều kiện pass | Dấu hiệu thất bại |
|-----------|---------------|----------------|
| Độ chính xác thực tế | Mọi tuyên bố đều kiểm chứng được với tài liệu nguồn hoặc kiến thức phổ thông | Số liệu bịa, số phiên bản sai, API không tồn tại |
| Không hallucination | Không có thực thể, trích dẫn, URL hay tham chiếu bịa đặt | Link tới trang không tồn tại, trích dẫn gán tác giả nhưng không có nguồn |
| Tính đầy đủ | Mọi yêu cầu trong spec đều được đáp ứng | Thiếu section, bỏ qua edge case, coverage chưa đủ |
| Compliance | Đáp ứng mọi ràng buộc riêng của dự án | Dùng từ bị cấm, sai giọng điệu, vi phạm quy định pháp lý |
| Nhất quán nội tại | Không có mâu thuẫn trong đầu ra | Section A nói X, section B nói không-X |
| Tính đúng đắn về kỹ thuật | Code compile/chạy được, thuật toán đúng đắn | Lỗi cú pháp, bug logic, khẳng định sai về độ phức tạp |

#### Mở rộng rubric theo lĩnh vực

**Nội dung/Marketing:**
- Tuân thủ giọng điệu thương hiệu
- Đáp ứng yêu cầu SEO (mật độ từ khóa, meta tag, cấu trúc)
- Không lạm dụng nhãn hiệu của đối thủ
- Có CTA và được liên kết đúng

**Code:**
- An toàn kiểu (không rò rỉ `any`, xử lý null đúng cách)
- Độ phủ xử lý lỗi
- Bảo mật (không có secret trong code, kiểm tra đầu vào, chống injection)
- Test coverage cho các nhánh mới

**Nhạy cảm về compliance (quy định, pháp lý, tài chính):**
- Không cam kết kết quả hoặc đưa ra tuyên bố thiếu căn cứ
- Có đủ các tuyên bố miễn trừ trách nhiệm (disclaimer) bắt buộc
- Chỉ dùng thuật ngữ đã được phê duyệt
- Ngôn ngữ phù hợp với khu vực pháp lý

### Giai đoạn 3: Naughty hay Nice (Cổng Verdict)

```python
def santa_verdict(review_b, review_c):
    """Both reviewers must pass. No partial credit."""
    if review_b.verdict == "PASS" and review_c.verdict == "PASS":
        return "NICE"  # Ship it

    # Merge flags from both reviewers, deduplicate
    all_issues = dedupe(review_b.critical_issues + review_c.critical_issues)
    all_suggestions = dedupe(review_b.suggestions + review_c.suggestions)

    return "NAUGHTY", all_issues, all_suggestions
```

Vì sao cả hai phải pass: nếu chỉ một reviewer phát hiện ra vấn đề thì vấn đề đó là có thật. Điểm mù của reviewer còn lại chính là kiểu thất bại mà Santa Method sinh ra để loại bỏ.

### Giai đoạn 4: Sửa đến khi Nice (Vòng lặp hội tụ)

```python
MAX_ITERATIONS = 3

for iteration in range(MAX_ITERATIONS):
    verdict, issues, suggestions = santa_verdict(review_b, review_c)

    if verdict == "NICE":
        log_santa_result(output, iteration, "passed")
        return ship(output)

    # Fix all critical issues (suggestions are optional)
    output = fix_agent.execute(
        output=output,
        issues=issues,
        instruction="Fix ONLY the flagged issues. Do not refactor or add unrequested changes."
    )

    # Re-run BOTH reviewers on fixed output (fresh agents, no memory of previous round)
    review_b = Agent(prompt=REVIEWER_PROMPT.format(output=output, ...))
    review_c = Agent(prompt=REVIEWER_PROMPT.format(output=output, ...))

# Exhausted iterations — escalate
log_santa_result(output, MAX_ITERATIONS, "escalated")
escalate_to_human(output, issues)
```

Quan trọng: mỗi vòng review dùng **agent mới hoàn toàn**. Reviewer không được mang theo bộ nhớ từ các vòng trước, vì context cũ tạo ra thiên kiến neo (anchoring bias).

## Pattern triển khai

### Pattern A: Subagent của Claude Code (Khuyến nghị)

Subagent cung cấp khả năng cô lập context thực sự. Mỗi reviewer là một process riêng biệt, không chia sẻ state.

```bash
# In a Claude Code session, use the Agent tool to spawn reviewers
# Both agents run in parallel for speed
```

```python
# Pseudocode for Agent tool invocation
reviewer_b = Agent(
    description="Santa Review B",
    prompt=f"Review this output for quality...\n\nRUBRIC:\n{rubric}\n\nOUTPUT:\n{output}"
)
reviewer_c = Agent(
    description="Santa Review C",
    prompt=f"Review this output for quality...\n\nRUBRIC:\n{rubric}\n\nOUTPUT:\n{output}"
)
```

### Pattern B: Tuần tự inline (Phương án dự phòng)

Khi không có subagent, hãy mô phỏng sự cô lập bằng cách reset context một cách tường minh:

1. Sinh đầu ra
2. Context mới: "You are Reviewer 1. Evaluate ONLY against this rubric. Find problems."
3. Ghi lại nguyên văn các phát hiện
4. Xóa sạch context hoàn toàn
5. Context mới: "You are Reviewer 2. Evaluate ONLY against this rubric. Find problems."
6. So sánh hai review, sửa, lặp lại

Pattern dùng subagent hoàn toàn vượt trội — mô phỏng inline có nguy cơ rò rỉ context giữa các reviewer.

### Pattern C: Lấy mẫu theo batch

Với batch lớn (100+ mục), chạy Santa đầy đủ cho từng mục là quá tốn kém. Hãy dùng lấy mẫu phân tầng (stratified sampling):

1. Chạy Santa trên một mẫu ngẫu nhiên (10-15% của batch, tối thiểu 5 mục)
2. Phân loại lỗi theo loại (hallucination, compliance, tính đầy đủ, v.v.)
3. Nếu xuất hiện pattern mang tính hệ thống, áp dụng bản sửa có mục tiêu cho toàn bộ batch
4. Lấy mẫu lại và xác minh lại batch đã sửa
5. Tiếp tục cho đến khi một mẫu sạch pass

```python
import random

def santa_batch(items, rubric, sample_rate=0.15):
    sample = random.sample(items, max(5, int(len(items) * sample_rate)))

    for item in sample:
        result = santa_full(item, rubric)
        if result.verdict == "NAUGHTY":
            pattern = classify_failure(result.issues)
            items = batch_fix(items, pattern)  # Fix all items matching pattern
            return santa_batch(items, rubric)   # Re-sample

    return items  # Clean sample → ship batch
```

## Các kiểu thất bại và cách giảm thiểu

| Kiểu thất bại | Triệu chứng | Cách giảm thiểu |
|-------------|---------|------------|
| Vòng lặp vô hạn | Reviewer liên tục tìm ra vấn đề mới sau mỗi lần sửa | Giới hạn số vòng lặp tối đa (3). Chuyển lên người xử lý. |
| Đóng dấu cho qua | Cả hai reviewer cho pass mọi thứ | Prompt đối kháng: "Your job is to find problems, not approve." |
| Trôi sang chủ quan | Reviewer đánh dấu sở thích về phong cách chứ không phải lỗi | Rubric chặt chẽ chỉ gồm tiêu chí pass/fail khách quan |
| Hồi quy khi sửa | Sửa vấn đề A lại gây ra vấn đề B | Reviewer mới ở mỗi vòng sẽ bắt được hồi quy |
| Thiên kiến đồng thuận của reviewer | Cả hai reviewer cùng bỏ sót một thứ | Giảm thiểu nhờ tính độc lập, nhưng không loại bỏ hoàn toàn. Với đầu ra quan trọng, thêm reviewer thứ ba hoặc để con người kiểm tra chọn lọc. |
| Chi phí bùng nổ | Quá nhiều vòng lặp trên đầu ra lớn | Pattern lấy mẫu theo batch. Giới hạn ngân sách cho mỗi chu kỳ xác minh. |

## Tích hợp với các skill khác

| Skill | Mối quan hệ |
|-------|-------------|
| Verification Loop | Dùng cho kiểm tra xác định (build, lint, test). Santa dùng cho kiểm tra ngữ nghĩa (độ chính xác, hallucination). Chạy verification-loop trước, Santa sau. |
| Eval Harness | Kết quả của Santa Method cung cấp cho các chỉ số eval. Theo dõi pass@k qua các lần chạy Santa để đo chất lượng generator theo thời gian. |
| Continuous Learning v2 | Các phát hiện của Santa trở thành instinct. Thất bại lặp lại trên cùng một tiêu chí → hành vi học được để tránh pattern đó. |
| Strategic Compact | Chạy Santa TRƯỚC khi compact. Đừng làm mất context review giữa chừng quá trình xác minh. |

## Chỉ số

Theo dõi các chỉ số sau để đo hiệu quả của Santa Method:

- **Tỷ lệ pass ngay lần đầu**: % đầu ra pass Santa ngay vòng 1 (mục tiêu: >70%)
- **Số vòng lặp trung bình để hội tụ**: số vòng trung bình để đạt NICE (mục tiêu: <1.5)
- **Phân loại vấn đề**: phân bố các loại thất bại (hallucination so với tính đầy đủ so với compliance)
- **Mức đồng thuận của reviewer**: % vấn đề được cả hai reviewer đánh dấu so với chỉ một người (đồng thuận thấp = rubric cần chặt chẽ hơn)
- **Tỷ lệ lọt lưới**: vấn đề được phát hiện sau khi phát hành mà Santa lẽ ra phải bắt được (mục tiêu: 0)

## Phân tích chi phí

Santa Method tốn khoảng 2-3 lần chi phí token của riêng việc sinh nội dung cho mỗi chu kỳ xác minh. Với hầu hết đầu ra có mức rủi ro cao, đây là một món hời:

```
Cost of Santa = (generation tokens) + 2×(review tokens per round) × (avg rounds)
Cost of NOT Santa = (reputation damage) + (correction effort) + (trust erosion)
```

Với các thao tác theo batch, pattern lấy mẫu giảm chi phí xuống còn ~15-20% so với xác minh đầy đủ mà vẫn bắt được >90% vấn đề mang tính hệ thống.
