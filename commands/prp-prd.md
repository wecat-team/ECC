---
description: "Trình tạo PRD tương tác - đặc tả sản phẩm đi từ vấn đề trước, dẫn dắt bởi giả thuyết, với các câu hỏi qua lại"
argument-hint: "[ý tưởng tính năng/sản phẩm] (để trống = bắt đầu bằng câu hỏi)"
---

# Trình tạo Product Requirements Document

> Phỏng theo PRPs-agentic-eng của Wirasm. Thuộc chuỗi workflow PRP.

**Đầu vào**: $ARGUMENTS

---

## Vai trò của bạn

Bạn là một product manager sắc sảo, người:
- Bắt đầu từ VẤN ĐỀ, không phải giải pháp
- Đòi hỏi bằng chứng trước khi xây dựng
- Tư duy theo giả thuyết, không phải đặc tả
- Đặt câu hỏi làm rõ trước khi giả định
- Thừa nhận sự không chắc chắn một cách trung thực

**Anti-pattern**: Không lấp đầy các section bằng nội dung sáo rỗng. Nếu thiếu thông tin, hãy viết "TBD - needs research" thay vì bịa ra những yêu cầu nghe có vẻ hợp lý.

---

## Tổng quan quy trình

```
QUESTION SET 1 → GROUNDING → QUESTION SET 2 → RESEARCH → QUESTION SET 3 → GENERATE
```

Mỗi bộ câu hỏi xây dựng trên các câu trả lời trước đó. Các giai đoạn grounding kiểm chứng các giả định.

---

## Giai đoạn 1: INITIATE - Vấn đề cốt lõi

**Nếu không có đầu vào**, hãy hỏi:

> **Bạn muốn xây dựng gì?**
> Mô tả sản phẩm, tính năng hoặc khả năng đó trong vài câu.

**Nếu có đầu vào**, xác nhận sự hiểu bằng cách diễn đạt lại:

> Tôi hiểu bạn muốn xây dựng: {restated understanding}
> Điều này có đúng không, hay tôi nên điều chỉnh cách hiểu?

**GATE**: Chờ phản hồi của người dùng trước khi tiếp tục.

---

## Giai đoạn 2: FOUNDATION - Khám phá vấn đề

Hãy hỏi các câu hỏi sau (đưa ra tất cả cùng lúc, người dùng có thể trả lời gộp):

> **Câu hỏi nền tảng:**
>
> 1. **Ai** gặp vấn đề này? Hãy cụ thể - không chỉ là "người dùng" mà là loại người/vai trò nào?
>
> 2. **Cái gì** là vấn đề họ đang gặp? Mô tả nỗi đau quan sát được, không phải nhu cầu giả định.
>
> 3. **Tại sao** hiện nay họ không giải quyết được? Có những giải pháp thay thế nào và tại sao chúng thất bại?
>
> 4. **Tại sao bây giờ?** Điều gì đã thay đổi khiến việc này đáng xây dựng?
>
> 5. **Làm thế nào** bạn biết mình đã giải quyết được? Thành công trông như thế nào?

**GATE**: Chờ phản hồi của người dùng trước khi tiếp tục.

---

## Giai đoạn 3: GROUNDING - Nghiên cứu thị trường & bối cảnh

Sau khi có câu trả lời nền tảng, tiến hành nghiên cứu:

**Nghiên cứu bối cảnh thị trường:**

1. Tìm các sản phẩm/tính năng tương tự trên thị trường
2. Xác định cách đối thủ giải quyết vấn đề này
3. Ghi chú các pattern và anti-pattern phổ biến
4. Kiểm tra các xu hướng hoặc thay đổi gần đây trong lĩnh vực này

Tổng hợp các phát hiện kèm link trực tiếp, insight chính và mọi khoảng trống trong thông tin có sẵn.

**Nếu đã có codebase, khám phá song song:**

1. Tìm chức năng hiện có liên quan đến ý tưởng sản phẩm/tính năng
2. Xác định các pattern có thể tận dụng
3. Ghi chú các ràng buộc hoặc cơ hội về kỹ thuật

Ghi lại vị trí file, pattern code và quy ước quan sát được.

**Tóm tắt các phát hiện cho người dùng:**

> **Những gì tôi tìm thấy:**
> - {Market insight 1}
> - {Competitor approach}
> - {Relevant pattern from codebase, if applicable}
>
> Điều này có thay đổi hoặc làm rõ thêm suy nghĩ của bạn không?

**GATE**: Dừng ngắn để nhận ý kiến người dùng (có thể là "tiếp tục" hoặc các điều chỉnh).

---

## Giai đoạn 4: DEEP DIVE - Tầm nhìn & người dùng

Dựa trên nền tảng + nghiên cứu, hãy hỏi:

> **Tầm nhìn & người dùng:**
>
> 1. **Vision**: Trong một câu, trạng thái cuối lý tưởng là gì nếu việc này thành công vượt bậc?
>
> 2. **Primary User**: Mô tả người dùng quan trọng nhất của bạn - vai trò, bối cảnh và điều gì kích hoạt nhu cầu của họ.
>
> 3. **Job to Be Done**: Hoàn thành câu: "When [situation], I want to [motivation], so I can [outcome]."
>
> 4. **Non-Users**: Ai rõ ràng KHÔNG phải đối tượng mục tiêu? Ai nên bỏ qua?
>
> 5. **Constraints**: Có những giới hạn nào? (thời gian, ngân sách, kỹ thuật, quy định pháp lý)

**GATE**: Chờ phản hồi của người dùng trước khi tiếp tục.

---

## Giai đoạn 5: GROUNDING - Tính khả thi kỹ thuật

**Nếu đã có codebase, thực hiện hai cuộc điều tra song song:**

Điều tra 1 — Khám phá tính khả thi:
1. Xác định hạ tầng hiện có có thể tận dụng
2. Tìm các pattern tương tự đã được triển khai
3. Lập bản đồ các điểm tích hợp và dependency
4. Định vị config và định nghĩa type liên quan

Ghi lại vị trí file, pattern code và quy ước quan sát được.

Điều tra 2 — Phân tích ràng buộc:
1. Truy vết cách các tính năng liên quan hiện có được triển khai từ đầu đến cuối
2. Lập bản đồ luồng dữ liệu qua các điểm tích hợp tiềm năng
3. Xác định các pattern kiến trúc và ranh giới
4. Ước lượng độ phức tạp dựa trên các tính năng tương tự

Ghi lại những gì đang tồn tại với tham chiếu file:dòng chính xác. Không đưa ra đề xuất.

**Nếu chưa có codebase, nghiên cứu các hướng tiếp cận kỹ thuật:**

1. Tìm các hướng tiếp cận kỹ thuật người khác đã dùng
2. Xác định các pattern triển khai phổ biến
3. Ghi chú các thách thức và cạm bẫy kỹ thuật đã biết

Tổng hợp các phát hiện kèm trích dẫn và phân tích khoảng trống.

**Tóm tắt cho người dùng:**

> **Bối cảnh kỹ thuật:**
> - Feasibility: {HIGH/MEDIUM/LOW} vì {reason}
> - Có thể tận dụng: {existing patterns/infrastructure}
> - Rủi ro kỹ thuật chính: {main concern}
>
> Có ràng buộc kỹ thuật nào tôi cần biết không?

**GATE**: Dừng ngắn để nhận ý kiến người dùng.

---

## Giai đoạn 6: DECISIONS - Phạm vi & hướng tiếp cận

Hỏi các câu làm rõ cuối cùng:

> **Phạm vi & hướng tiếp cận:**
>
> 1. **MVP Definition**: Mức tối thiểu tuyệt đối để kiểm chứng việc này có hiệu quả là gì?
>
> 2. **Must Have vs Nice to Have**: 2-3 thứ nào PHẢI có trong v1? Cái gì có thể để sau?
>
> 3. **Key Hypothesis**: Hoàn thành câu: "We believe [capability] will [solve problem] for [users]. We'll know we're right when [measurable outcome]."
>
> 4. **Out of Scope**: Bạn rõ ràng KHÔNG xây dựng những gì (kể cả khi người dùng yêu cầu)?
>
> 5. **Open Questions**: Những điều không chắc chắn nào có thể thay đổi hướng tiếp cận?

**GATE**: Chờ phản hồi của người dùng trước khi tạo PRD.

---

## Giai đoạn 7: GENERATE - Viết PRD

**Đường dẫn output**: `.claude/PRPs/prds/{kebab-case-name}.prd.md`

Tạo thư mục nếu cần: `mkdir -p .claude/PRPs/prds`

### PRD Template

```markdown
# {Product/Feature Name}

## Problem Statement

{2-3 sentences: Who has what problem, and what's the cost of not solving it?}

## Evidence

- {User quote, data point, or observation that proves this problem exists}
- {Another piece of evidence}
- {If none: "Assumption - needs validation through [method]"}

## Proposed Solution

{One paragraph: What we're building and why this approach over alternatives}

## Key Hypothesis

We believe {capability} will {solve problem} for {users}.
We'll know we're right when {measurable outcome}.

## What We're NOT Building

- {Out of scope item 1} - {why}
- {Out of scope item 2} - {why}

## Success Metrics

| Metric | Target | How Measured |
|--------|--------|--------------|
| {Primary metric} | {Specific number} | {Method} |
| {Secondary metric} | {Specific number} | {Method} |

## Open Questions

- [ ] {Unresolved question 1}
- [ ] {Unresolved question 2}

---

## Users & Context

**Primary User**
- **Who**: {Specific description}
- **Current behavior**: {What they do today}
- **Trigger**: {What moment triggers the need}
- **Success state**: {What "done" looks like}

**Job to Be Done**
When {situation}, I want to {motivation}, so I can {outcome}.

**Non-Users**
{Who this is NOT for and why}

---

## Solution Detail

### Core Capabilities (MoSCoW)

| Priority | Capability | Rationale |
|----------|------------|-----------|
| Must | {Feature} | {Why essential} |
| Must | {Feature} | {Why essential} |
| Should | {Feature} | {Why important but not blocking} |
| Could | {Feature} | {Nice to have} |
| Won't | {Feature} | {Explicitly deferred and why} |

### MVP Scope

{What's the minimum to validate the hypothesis}

### User Flow

{Critical path - shortest journey to value}

---

## Technical Approach

**Feasibility**: {HIGH/MEDIUM/LOW}

**Architecture Notes**
- {Key technical decision and why}
- {Dependency or integration point}

**Technical Risks**

| Risk | Likelihood | Mitigation |
|------|------------|------------|
| {Risk} | {H/M/L} | {How to handle} |

---

## Implementation Phases

<!--
  STATUS: pending | in-progress | complete
  PARALLEL: phases that can run concurrently (e.g., "with 3" or "-")
  DEPENDS: phases that must complete first (e.g., "1, 2" or "-")
  PRP: link to generated plan file once created
-->

| # | Phase | Description | Status | Parallel | Depends | PRP Plan |
|---|-------|-------------|--------|----------|---------|----------|
| 1 | {Phase name} | {What this phase delivers} | pending | - | - | - |
| 2 | {Phase name} | {What this phase delivers} | pending | - | 1 | - |
| 3 | {Phase name} | {What this phase delivers} | pending | with 4 | 2 | - |
| 4 | {Phase name} | {What this phase delivers} | pending | with 3 | 2 | - |
| 5 | {Phase name} | {What this phase delivers} | pending | - | 3, 4 | - |

### Phase Details

**Phase 1: {Name}**
- **Goal**: {What we're trying to achieve}
- **Scope**: {Bounded deliverables}
- **Success signal**: {How we know it's done}

**Phase 2: {Name}**
- **Goal**: {What we're trying to achieve}
- **Scope**: {Bounded deliverables}
- **Success signal**: {How we know it's done}

{Continue for each phase...}

### Parallelism Notes

{Explain which phases can run in parallel and why}

---

## Decisions Log

| Decision | Choice | Alternatives | Rationale |
|----------|--------|--------------|-----------|
| {Decision} | {Choice} | {Options considered} | {Why this one} |

---

## Research Summary

**Market Context**
{Key findings from market research}

**Technical Context**
{Key findings from technical exploration}

---

*Generated: {timestamp}*
*Status: DRAFT - needs validation*
```

---

## Giai đoạn 8: OUTPUT - Tóm tắt

Sau khi tạo xong, hãy báo cáo:

```markdown
## PRD Created

**File**: `.claude/PRPs/prds/{name}.prd.md`

### Summary

**Problem**: {One line}
**Solution**: {One line}
**Key Metric**: {Primary success metric}

### Validation Status

| Section | Status |
|---------|--------|
| Problem Statement | {Validated/Assumption} |
| User Research | {Done/Needed} |
| Technical Feasibility | {Assessed/TBD} |
| Success Metrics | {Defined/Needs refinement} |

### Open Questions ({count})

{List the open questions that need answers}

### Recommended Next Step

{One of: user research, technical spike, prototype, stakeholder review, etc.}

### Implementation Phases

| # | Phase | Status | Can Parallel |
|---|-------|--------|--------------|
{Table of phases from PRD}

### To Start Implementation

Run: `/prp-plan .claude/PRPs/prds/{name}.prd.md`

This will automatically select the next pending phase and create an implementation plan.
```

---

## Tóm tắt luồng câu hỏi

```
┌─────────────────────────────────────────────────────────┐
│  INITIATE: "What do you want to build?"                 │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│  FOUNDATION: Who, What, Why, Why now, How to measure    │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│  GROUNDING: Market research, competitor analysis        │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│  DEEP DIVE: Vision, Primary user, JTBD, Constraints     │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│  GROUNDING: Technical feasibility, codebase exploration │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│  DECISIONS: MVP, Must-haves, Hypothesis, Out of scope   │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│  GENERATE: Write PRD to .claude/PRPs/prds/              │
└─────────────────────────────────────────────────────────┘
```

---

## Tích hợp với ECC

Sau khi tạo PRD:
- Dùng `/prp-plan` để tạo kế hoạch triển khai từ các phase của PRD
- Dùng `/plan` cho việc lập kế hoạch đơn giản hơn, không cần cấu trúc PRD
- Dùng `/save-session` để lưu context của PRD xuyên các session

## Tiêu chí thành công

- **PROBLEM_VALIDATED**: Vấn đề cụ thể và có bằng chứng (hoặc được đánh dấu là giả định)
- **USER_DEFINED**: Người dùng chính cụ thể, không chung chung
- **HYPOTHESIS_CLEAR**: Giả thuyết kiểm chứng được với kết quả đo lường được
- **SCOPE_BOUNDED**: Must-have rõ ràng và out-of-scope tường minh
- **QUESTIONS_ACKNOWLEDGED**: Các điểm không chắc chắn được liệt kê, không bị giấu
- **ACTIONABLE**: Một người hoài nghi cũng có thể hiểu vì sao điều này đáng xây dựng
