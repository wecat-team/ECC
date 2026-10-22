---
description: "Tạo một PRD gọn, đặt vấn đề lên trước, và bàn giao cho /plan để lập kế hoạch triển khai."
argument-hint: "[ý tưởng sản phẩm/tính năng] (để trống = bắt đầu bằng các câu hỏi)"
---

# Lệnh PRD

Tạo ra một **Product Requirements Document (PRD)** — artifact của giai đoạn yêu cầu trong SDLC. Ghi lại *điều gì* phải đúng để thành công và *vì sao*, và dừng lại trước *cách làm*. Việc phân rã triển khai được giao cho `/plan`.

**Input**: `$ARGUMENTS`

## Phạm vi của command này

| Command này làm | Command này KHÔNG làm |
|---|---|
| Đóng khung vấn đề và người dùng | Thiết kế kiến trúc |
| Ghi lại tiêu chí thành công và phạm vi | Chọn file hay viết pattern |
| Liệt kê câu hỏi mở và rủi ro | Liệt kê các task triển khai |
| Ghi `.claude/prds/{name}.prd.md` | Tạo kế hoạch triển khai — đó là việc của `/plan` |

Nếu bạn thấy mình đang viết chi tiết triển khai, hãy dừng lại và cắt bỏ. Nó thuộc về `/plan`.

**Quy tắc chống hời hợt (Anti-fluff)**: Khi thiếu thông tin, hãy viết `TBD — needs validation via {method}`. KHÔNG BAO GIỜ bịa ra các yêu cầu nghe có vẻ hợp lý.

## Workflow

Bốn giai đoạn. Mỗi giai đoạn là một cổng duy nhất — đặt câu hỏi, chờ người dùng, rồi chuyển tiếp. Không vòng lặp lồng nhau, không nghi thức nghiên cứu song song.

### Phase 1 — FRAME

Nếu `$ARGUMENTS` trống, hãy hỏi:

> Bạn muốn xây dựng gì? Một hoặc hai câu.

Nếu đã có, hãy diễn đạt lại trong một câu và hỏi:

> Tôi hiểu là: *{restated}*. Đúng không, hay tôi cần điều chỉnh?

Sau đó đặt các câu hỏi đóng khung trong một bộ duy nhất:

> 1. **Ai** gặp vấn đề này? (vai trò hoặc phân khúc cụ thể)
> 2. **Cái gì** là nỗi đau quan sát được? (mô tả hành vi, không phải nhu cầu giả định)
> 3. **Vì sao** họ không thể giải quyết nó bằng những gì đang có hiện nay?
> 4. **Vì sao bây giờ?** — điều gì đã thay đổi khiến việc này đáng làm?

Chờ người dùng. Không tiếp tục nếu chưa có câu trả lời (hoặc "skip" tường minh).

### Phase 2 — GROUND

Hỏi về bằng chứng. Đây là giai đoạn ngắn nhất và quan trọng nhất:

> Bạn có bằng chứng nào cho thấy vấn đề này có thật và đáng giải quyết? (trích dẫn người dùng, support ticket, số liệu, hành vi quan sát được, các workaround đã thất bại — bất cứ thứ gì cụ thể)

Nếu người dùng không có, hãy ghi mục Evidence của PRD là `Assumption — needs validation via {user research | analytics | prototype}`. Điều này giữ cho PRD trung thực.

### Phase 3 — DECIDE

Phạm vi và giả thuyết trong một bộ duy nhất:

> 1. **Giả thuyết (Hypothesis)** — Hoàn chỉnh: *We believe **{capability}** will **{solve problem}** for **{users}**. We'll know we're right when **{measurable outcome}**.*
> 2. **MVP** — Mức tối thiểu cần để kiểm chứng giả thuyết là gì?
> 3. **Ngoài phạm vi (Out of scope)** — Bạn tường minh **không** xây dựng gì (kể cả khi người dùng yêu cầu)?
> 4. **Câu hỏi mở** — Những điều chưa chắc chắn có thể thay đổi cách tiếp cận?

Chờ phản hồi.

### Phase 4 — GENERATE & HAND OFF

Tạo thư mục nếu cần, ghi PRD, và báo cáo.

```bash
mkdir -p .claude/prds
```

**Đường dẫn output**: `.claude/prds/{kebab-case-name}.prd.md`

#### Template PRD

```markdown
# {Product / Feature Name}

## Problem
{2–3 sentences: who has what problem, and what's the cost of leaving it unsolved?}

## Evidence
- {User quote, data point, or observation}
- {OR: "Assumption — needs validation via {method}"}

## Users
- **Primary**: {role, context, what triggers the need}
- **Not for**: {who this explicitly excludes}

## Hypothesis
We believe **{capability}** will **{solve problem}** for **{users}**.
We'll know we're right when **{measurable outcome}**.

## Success Metrics
| Metric | Target | How measured |
|---|---|---|
| {primary} | {number} | {method} |

## Scope
**MVP** — {the minimum to test the hypothesis}

**Out of scope**
- {item} — {why deferred}

## Delivery Milestones
<!-- Business outcomes, not engineering tasks. /plan turns each into a plan. -->
<!-- Status: pending | in-progress | complete -->

| # | Milestone | Outcome | Status | Plan |
|---|---|---|---|---|
| 1 | {name} | {user-visible change} | pending | — |
| 2 | {name} | {user-visible change} | pending | — |

## Open Questions
- [ ] {question that could change scope or approach}

## Risks
| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|

---
*Status: DRAFT — requirements only. Implementation planning pending via /plan.*
```

#### Báo cáo cho người dùng

```
PRD created: .claude/prds/{name}.prd.md

Problem:    {one line}
Hypothesis: {one line}
MVP:        {one line}

Validation status:
  Problem  {validated | assumption}
  Users    {concrete | generic — refine}
  Metrics  {defined | TBD}

Open questions: {count}

Next step: /plan .claude/prds/{name}.prd.md
  → /plan will pick the next pending milestone and produce an implementation plan.
```

## Tích hợp

- `/plan <prd-path>` — tiêu thụ PRD và tạo kế hoạch triển khai cho milestone pending kế tiếp.
- skill `tdd-workflow` — triển khai kế hoạch theo hướng test-first.
- `/pr` — mở một PR tham chiếu tới PRD và kế hoạch.

## Tiêu chí thành công

- **PROBLEM_CLEAR**: vấn đề cụ thể và có bằng chứng (hoặc được đánh dấu là giả định).
- **USER_CONCRETE**: người dùng chính là một vai trò cụ thể, không phải "người dùng" chung chung.
- **HYPOTHESIS_TESTABLE**: có kết quả đo lường được.
- **SCOPE_BOUNDED**: MVP tường minh và ngoài phạm vi tường minh.
- **NO_IMPLEMENTATION_DETAIL**: không có đường dẫn file, thư viện hay phân rã task — nếu chúng xuất hiện, hãy chuyển sang bước `/plan`.

Thông tin nền về luồng markdown theo giai đoạn: [docs/PLAN-PRD-PATTERN.md](../docs/PLAN-PRD-PATTERN.md).
