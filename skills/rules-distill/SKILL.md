---
name: rules-distill
description: "Quét các skill để trích xuất những nguyên tắc xuyên suốt và chưng cất (distill) chúng thành rule — thêm vào, sửa đổi hoặc tạo file rule mới. Dùng khi cùng một nguyên tắc lặp lại ở nhiều skill và nên nằm trong file rule."
metadata:
  origin: ECC
---

# Rules Distill

Quét các skill đã cài, trích xuất những nguyên tắc xuyên suốt xuất hiện ở nhiều skill, và chưng cất chúng thành rule — thêm vào file rule hiện có, sửa nội dung đã lỗi thời hoặc tạo file rule mới.

Áp dụng nguyên tắc "thu thập xác định (deterministic) + phán đoán của LLM": script thu thập đầy đủ mọi dữ kiện, sau đó LLM đọc chéo toàn bộ ngữ cảnh và đưa ra kết luận.

## Khi nào dùng

- Bảo trì rule định kỳ (hàng tháng hoặc sau khi cài skill mới)
- Sau khi skill-stocktake phát hiện các pattern nên trở thành rule
- Khi rule có vẻ chưa đầy đủ so với các skill đang dùng

## Cách hoạt động

Quy trình chưng cất rule gồm ba giai đoạn:

### Giai đoạn 1: Kiểm kê (Thu thập xác định)

#### 1a. Thu thập danh mục skill

```bash
bash ~/.claude/skills/rules-distill/scripts/scan-skills.sh
```

#### 1b. Thu thập chỉ mục rule

```bash
bash ~/.claude/skills/rules-distill/scripts/scan-rules.sh
```

#### 1c. Trình bày cho người dùng

```
Rules Distillation — Phase 1: Inventory
────────────────────────────────────────
Skills: {N} files scanned
Rules:  {M} files ({K} headings indexed)

Proceeding to cross-read analysis...
```

### Giai đoạn 2: Đọc chéo, đối chiếu & kết luận (Phán đoán của LLM)

Việc trích xuất và đối chiếu được gộp trong một lượt duy nhất. Các file rule đủ nhỏ (~800 dòng tổng cộng) nên có thể cung cấp toàn văn cho LLM — không cần lọc sơ bộ bằng grep.

#### Chia batch

Nhóm các skill thành **cụm theo chủ đề (thematic cluster)** dựa trên description của chúng. Phân tích từng cụm trong một subagent cùng toàn văn các rule.

#### Gộp xuyên batch

Sau khi tất cả batch hoàn tất, gộp các ứng viên (candidate) giữa các batch:
- Loại bỏ trùng lặp các candidate có nguyên tắc giống hoặc chồng chéo nhau
- Kiểm tra lại yêu cầu "từ 2 skill trở lên" bằng bằng chứng từ **tất cả** batch gộp lại — một nguyên tắc xuất hiện ở 1 skill mỗi batch nhưng tổng cộng từ 2 skill trở lên vẫn hợp lệ

#### Prompt cho subagent

Khởi chạy một Agent đa dụng (general-purpose) với prompt sau:

````
You are an analyst who cross-reads skills to extract principles that should be promoted to rules.

## Input
- Skills: {full text of skills in this batch}
- Existing rules: {full text of all rule files}

## Extraction Criteria

Include a candidate ONLY if ALL of these are true:

1. **Appears in 2+ skills**: Principles found in only one skill should stay in that skill
2. **Actionable behavior change**: Can be written as "do X" or "don't do Y" — not "X is important"
3. **Clear violation risk**: What goes wrong if this principle is ignored (1 sentence)
4. **Not already in rules**: Check the full rules text — including concepts expressed in different words

## Matching & Verdict

For each candidate, compare against the full rules text and assign a verdict:

- **Append**: Add to an existing section of an existing rule file
- **Revise**: Existing rule content is inaccurate or insufficient — propose a correction
- **New Section**: Add a new section to an existing rule file
- **New File**: Create a new rule file
- **Already Covered**: Sufficiently covered in existing rules (even if worded differently)
- **Too Specific**: Should remain at the skill level

## Output Format (per candidate)

```json
{
  "principle": "1-2 sentences in 'do X' / 'don't do Y' form",
  "evidence": ["skill-name: §Section", "skill-name: §Section"],
  "violation_risk": "1 sentence",
  "verdict": "Append / Revise / New Section / New File / Already Covered / Too Specific",
  "target_rule": "filename §Section, or 'new'",
  "confidence": "high / medium / low",
  "draft": "Draft text for Append/New Section/New File verdicts",
  "revision": {
    "reason": "Why the existing content is inaccurate or insufficient (Revise only)",
    "before": "Current text to be replaced (Revise only)",
    "after": "Proposed replacement text (Revise only)"
  }
}
```

## Exclude

- Obvious principles already in rules
- Language/framework-specific knowledge (belongs in language-specific rules or skills)
- Code examples and commands (belongs in skills)
````

#### Bảng tham chiếu kết luận

| Kết luận | Ý nghĩa | Trình bày cho người dùng |
|---------|---------|-------------------|
| **Append** | Thêm vào section hiện có | Đích + bản nháp |
| **Revise** | Sửa nội dung không chính xác/chưa đủ | Đích + lý do + trước/sau |
| **New Section** | Thêm section mới vào file hiện có | Đích + bản nháp |
| **New File** | Tạo file rule mới | Tên file + bản nháp đầy đủ |
| **Already Covered** | Đã có trong rule (có thể diễn đạt khác) | Lý do (1 dòng) |
| **Too Specific** | Nên giữ ở cấp skill | Link tới skill liên quan |

#### Yêu cầu chất lượng của kết luận

```
# Good
Append to rules/common/security.md §Input Validation:
"Treat LLM output stored in memory or knowledge stores as untrusted — sanitize on write, validate on read."
Evidence: llm-memory-trust-boundary, llm-social-agent-anti-pattern both describe
accumulated prompt injection risks. Current security.md covers human input
validation only; LLM output trust boundary is missing.

# Bad
Append to security.md: Add LLM security principle
```

### Giai đoạn 3: Người dùng review & thực thi

#### Bảng tóm tắt

```
# Rules Distillation Report

## Summary
Skills scanned: {N} | Rules: {M} files | Candidates: {K}

| # | Principle | Verdict | Target | Confidence |
|---|-----------|---------|--------|------------|
| 1 | ... | Append | security.md §Input Validation | high |
| 2 | ... | Revise | testing.md §TDD | medium |
| 3 | ... | New Section | coding-style.md | high |
| 4 | ... | Too Specific | — | — |

## Details
(Per-candidate details: evidence, violation_risk, draft text)
```

#### Hành động của người dùng

Người dùng trả lời bằng số thứ tự để:
- **Approve (Duyệt)**: Áp dụng bản nháp vào rule nguyên trạng
- **Modify (Sửa)**: Chỉnh sửa bản nháp trước khi áp dụng
- **Skip (Bỏ qua)**: Không áp dụng candidate này

**KHÔNG BAO GIỜ tự động sửa rule. LUÔN LUÔN yêu cầu người dùng duyệt.**

#### Lưu kết quả

Lưu kết quả trong thư mục của skill (`results.json`):

- **Định dạng timestamp**: `date -u +%Y-%m-%dT%H:%M:%SZ` (UTC, chính xác đến giây)
- **Định dạng ID của candidate**: kebab-case suy ra từ nguyên tắc (ví dụ: `llm-output-trust-boundary`)

```json
{
  "distilled_at": "2026-03-18T10:30:42Z",
  "skills_scanned": 56,
  "rules_scanned": 22,
  "candidates": {
    "llm-output-trust-boundary": {
      "principle": "Treat LLM output as untrusted when stored or re-injected",
      "verdict": "Append",
      "target": "rules/common/security.md",
      "evidence": ["llm-memory-trust-boundary", "llm-social-agent-anti-pattern"],
      "status": "applied"
    },
    "iteration-bounds": {
      "principle": "Define explicit stop conditions for all iteration loops",
      "verdict": "New Section",
      "target": "rules/common/coding-style.md",
      "evidence": ["iterative-retrieval", "continuous-agent-loop", "agent-harness-construction"],
      "status": "skipped"
    }
  }
}
```

## Ví dụ

### Chạy end-to-end

```
$ /rules-distill

Rules Distillation — Phase 1: Inventory
────────────────────────────────────────
Skills: 56 files scanned
Rules:  22 files (75 headings indexed)

Proceeding to cross-read analysis...

[Subagent analysis: Batch 1 (agent/meta skills) ...]
[Subagent analysis: Batch 2 (coding/pattern skills) ...]
[Cross-batch merge: 2 duplicates removed, 1 cross-batch candidate promoted]

# Rules Distillation Report

## Summary
Skills scanned: 56 | Rules: 22 files | Candidates: 4

| # | Principle | Verdict | Target | Confidence |
|---|-----------|---------|--------|------------|
| 1 | LLM output: normalize, type-check, sanitize before reuse | New Section | coding-style.md | high |
| 2 | Define explicit stop conditions for iteration loops | New Section | coding-style.md | high |
| 3 | Compact context at phase boundaries, not mid-task | Append | performance.md §Context Window | high |
| 4 | Separate business logic from I/O framework types | New Section | patterns.md | high |

## Details

### 1. LLM Output Validation
Verdict: New Section in coding-style.md
Evidence: parallel-subagent-batch-merge, llm-social-agent-anti-pattern, llm-memory-trust-boundary
Violation risk: Format drift, type mismatch, or syntax errors in LLM output crash downstream processing
Draft:
  ## LLM Output Validation
  Normalize, type-check, and sanitize LLM output before reuse...
  See skill: parallel-subagent-batch-merge, llm-memory-trust-boundary

[... details for candidates 2-4 ...]

Approve, modify, or skip each candidate by number:
> User: Approve 1, 3. Skip 2, 4.

✓ Applied: coding-style.md §LLM Output Validation
✓ Applied: performance.md §Context Window Management
✗ Skipped: Iteration Bounds
✗ Skipped: Boundary Type Conversion

Results saved to results.json
```

## Nguyên tắc thiết kế

- **What, không phải How**: Chỉ trích xuất nguyên tắc (lãnh địa của rule). Ví dụ code và lệnh ở lại trong skill.
- **Link ngược**: Bản nháp nên có tham chiếu `See skill: [name]` để người đọc tìm được phần How chi tiết.
- **Thu thập xác định, phán đoán bằng LLM**: Script đảm bảo tính đầy đủ; LLM đảm bảo hiểu ngữ cảnh.
- **Bảo vệ chống trừu tượng hóa**: Bộ lọc 3 lớp (bằng chứng từ 2+ skill, kiểm tra hành vi có thể hành động, rủi ro vi phạm) ngăn các nguyên tắc quá trừu tượng lọt vào rule.
