---
description: Code review — các thay đổi local chưa commit hoặc GitHub PR (truyền số PR/URL để vào chế độ PR). Dùng cho review theo checklist từng bước kiểu PRP; để chạy nhiều agent dùng /review-pr, và để chạy Workflow có xác minh đối kháng (adversarially-verified) dùng /orch-review.
argument-hint: "[pr-number | pr-url | blank for local review]"
---

# Code Review

> Chế độ PR review được phỏng theo PRPs-agentic-eng của Wirasm. Thuộc chuỗi workflow PRP.

**Đầu vào**: $ARGUMENTS

---

## Chọn chế độ

Nếu `$ARGUMENTS` chứa số PR, URL PR hoặc `--pr`:
→ Chuyển đến **PR Review Mode** bên dưới.

Nếu không:
→ Dùng **Local Review Mode**.

---

## Local Review Mode

Review toàn diện về bảo mật và chất lượng cho các thay đổi chưa commit.

### Giai đoạn 1 — GATHER

```bash
git diff --name-only HEAD
```

Nếu không có file thay đổi, hãy dừng: "Nothing to review."

### Giai đoạn 2 — REVIEW

Đọc toàn bộ từng file đã thay đổi. Kiểm tra:

**Vấn đề bảo mật (CRITICAL):**
- Thông tin xác thực, API key, token bị hardcode
- Lỗ hổng SQL injection
- Lỗ hổng XSS
- Thiếu kiểm tra đầu vào (input validation)
- Dependency không an toàn
- Rủi ro path traversal

**Chất lượng code (HIGH):**
- Function > 50 dòng
- File > 800 dòng
- Độ sâu lồng > 4 cấp
- Thiếu xử lý lỗi
- Câu lệnh console.log
- Comment TODO/FIXME
- Thiếu JSDoc cho public API

**Best Practice (MEDIUM):**
- Pattern mutation (dùng bất biến (immutable) thay thế)
- Dùng emoji trong code/comment
- Thiếu test cho code mới
- Vấn đề accessibility (a11y)

### Giai đoạn 3 — REPORT

Tạo báo cáo gồm:
- Mức độ nghiêm trọng: CRITICAL, HIGH, MEDIUM, LOW
- Vị trí file và số dòng
- Mô tả vấn đề
- Đề xuất cách sửa

Chặn commit nếu phát hiện issue CRITICAL hoặc HIGH.
KHÔNG BAO GIỜ phê duyệt code có lỗ hổng bảo mật.

---

## PR Review Mode

Review GitHub PR toàn diện — lấy diff, đọc toàn bộ file, chạy validation, đăng review.

### Giai đoạn 1 — FETCH

Phân tích đầu vào để xác định PR:

| Đầu vào | Hành động |
|---|---|
| Số (ví dụ `42`) | Dùng làm số PR |
| URL (`github.com/.../pull/42`) | Trích xuất số PR |
| Tên branch | Tìm PR qua `gh pr list --head <branch>` |

```bash
gh pr view <NUMBER> --json number,title,body,author,baseRefName,headRefName,changedFiles,additions,deletions
gh pr diff <NUMBER>
```

Nếu không tìm thấy PR, hãy dừng và báo lỗi. Lưu metadata của PR cho các giai đoạn sau.

### Giai đoạn 2 — CONTEXT

Dựng context cho review:

1. **Quy tắc dự án** — Đọc `CLAUDE.md`, `.claude/docs/` và mọi hướng dẫn đóng góp (contributing guideline)
2. **Artifact lập kế hoạch** — Kiểm tra `.claude/prds/`, `.claude/plans/`, `.claude/reviews/` và `.claude/PRPs/{prds,plans,reports,reviews}/` cũ để lấy context liên quan đến PR này
3. **Ý định của PR** — Phân tích mô tả PR để lấy mục tiêu, issue được liên kết, kế hoạch test
4. **File đã thay đổi** — Liệt kê mọi file đã sửa và phân loại theo kiểu (source, test, config, docs)

### Giai đoạn 3 — REVIEW

Đọc **toàn bộ** từng file đã thay đổi (không chỉ các hunk của diff — bạn cần context xung quanh).

Với PR review, lấy toàn bộ nội dung file tại revision head của PR:
```bash
gh pr diff <NUMBER> --name-only | while IFS= read -r file; do
  gh api "repos/{owner}/{repo}/contents/$file?ref=<head-branch>" --jq '.content' | base64 -d
done
```

Áp dụng checklist review qua 7 hạng mục:

| Hạng mục | Cần kiểm tra gì |
|---|---|
| **Correctness** | Lỗi logic, off-by-one, xử lý null, edge case, race condition |
| **Type Safety** | Type không khớp, ép kiểu không an toàn, dùng `any`, thiếu generic |
| **Pattern Compliance** | Khớp quy ước dự án (đặt tên, cấu trúc file, xử lý lỗi, import) |
| **Security** | Injection, lỗ hổng auth, lộ secret, SSRF, path traversal, XSS |
| **Performance** | N+1 query, thiếu index, vòng lặp không giới hạn, rò rỉ bộ nhớ, payload lớn |
| **Completeness** | Thiếu test, thiếu xử lý lỗi, migration chưa hoàn chỉnh, thiếu tài liệu |
| **Maintainability** | Dead code, magic number, lồng sâu, đặt tên không rõ, thiếu type |

Gán mức độ nghiêm trọng cho từng phát hiện:

| Mức độ nghiêm trọng | Ý nghĩa | Hành động |
|---|---|---|
| **CRITICAL** | Lỗ hổng bảo mật hoặc rủi ro mất dữ liệu | Phải sửa trước khi merge |
| **HIGH** | Bug hoặc lỗi logic có khả năng gây vấn đề | Nên sửa trước khi merge |
| **MEDIUM** | Vấn đề chất lượng code hoặc thiếu best practice | Khuyến nghị sửa |
| **LOW** | Góp ý nhỏ về style hoặc gợi ý nhỏ | Tùy chọn |

### Giai đoạn 4 — VALIDATE

Chạy các lệnh validation có sẵn:

Phát hiện loại dự án từ các file config (`package.json`, `Cargo.toml`, `go.mod`, `pyproject.toml`, v.v.), rồi chạy các lệnh phù hợp:

**Node.js / TypeScript** (có `package.json`):
```bash
npm run typecheck 2>/dev/null || npx tsc --noEmit 2>/dev/null  # Type check
npm run lint                                                    # Lint
npm test                                                        # Tests
npm run build                                                   # Build
```

**Rust** (có `Cargo.toml`):
```bash
cargo clippy -- -D warnings  # Lint
cargo test                   # Tests
cargo build                  # Build
```

**Go** (có `go.mod`):
```bash
go vet ./...    # Lint
go test ./...   # Tests
go build ./...  # Build
```

**Python** (có `pyproject.toml` / `setup.py`):
```bash
pytest  # Tests
```

Chỉ chạy các lệnh áp dụng cho loại dự án đã phát hiện. Ghi lại pass/fail cho từng lệnh.

### Giai đoạn 5 — DECIDE

Đưa ra khuyến nghị dựa trên các phát hiện:

| Điều kiện | Quyết định |
|---|---|
| Không có issue CRITICAL/HIGH, validation pass | **APPROVE** |
| Chỉ có issue MEDIUM/LOW, validation pass | **APPROVE** kèm comment |
| Có bất kỳ issue HIGH hoặc validation thất bại | **REQUEST CHANGES** |
| Có bất kỳ issue CRITICAL | **BLOCK** — phải sửa trước khi merge |

Trường hợp đặc biệt:
- Draft PR → Luôn dùng **COMMENT** (không approve/block)
- Chỉ thay đổi docs/config → Review nhẹ hơn, tập trung vào tính đúng đắn
- Flag `--approve` hoặc `--request-changes` tường minh → Ghi đè quyết định (nhưng vẫn báo cáo mọi phát hiện)

### Giai đoạn 6 — REPORT

Tạo artifact review tại `.claude/reviews/pr-<NUMBER>-review.md` trừ khi repo đã dùng `.claude/PRPs/reviews/` cũ cho workstream này:

```markdown
# PR Review: #<NUMBER> — <TITLE>

**Reviewed**: <date>
**Author**: <author>
**Branch**: <head> → <base>
**Decision**: APPROVE | REQUEST CHANGES | BLOCK

## Summary
<1-2 sentence overall assessment>

## Findings

### CRITICAL
<findings or "None">

### HIGH
<findings or "None">

### MEDIUM
<findings or "None">

### LOW
<findings or "None">

## Validation Results

| Check | Result |
|---|---|
| Type check | Pass / Fail / Skipped |
| Lint | Pass / Fail / Skipped |
| Tests | Pass / Fail / Skipped |
| Build | Pass / Fail / Skipped |

## Files Reviewed
<list of files with change type: Added/Modified/Deleted>
```

### Giai đoạn 7 — PUBLISH

Đăng review lên GitHub:

```bash
# If APPROVE
gh pr review <NUMBER> --approve --body "<summary of review>"

# If REQUEST CHANGES
gh pr review <NUMBER> --request-changes --body "<summary with required fixes>"

# If COMMENT only (draft PR or informational)
gh pr review <NUMBER> --comment --body "<summary>"
```

Với comment inline trên các dòng cụ thể, dùng API review comments của GitHub:
```bash
gh api "repos/{owner}/{repo}/pulls/<NUMBER>/comments" \
  -f body="<comment>" \
  -f path="<file>" \
  -F line=<line-number> \
  -f side="RIGHT" \
  -f commit_id="$(gh pr view <NUMBER> --json headRefOid --jq .headRefOid)"
```

Hoặc đăng một review duy nhất với nhiều comment inline cùng lúc:
```bash
gh api "repos/{owner}/{repo}/pulls/<NUMBER>/reviews" \
  -f event="COMMENT" \
  -f body="<overall summary>" \
  --input comments.json  # [{"path": "file", "line": N, "body": "comment"}, ...]
```

### Giai đoạn 8 — OUTPUT

Báo cáo cho người dùng:

```
PR #<NUMBER>: <TITLE>
Decision: <APPROVE|REQUEST_CHANGES|BLOCK>

Issues: <critical_count> critical, <high_count> high, <medium_count> medium, <low_count> low
Validation: <pass_count>/<total_count> checks passed

Artifacts:
  Review: .claude/reviews/pr-<NUMBER>-review.md
  GitHub: <PR URL>

Next steps:
  - <contextual suggestions based on decision>
```

---

## Edge Case

- **Không có `gh` CLI**: Dự phòng bằng review chỉ ở local (đọc diff, bỏ qua bước đăng lên GitHub). Cảnh báo người dùng.
- **Branch bị phân kỳ (diverged)**: Gợi ý `git fetch origin && git rebase origin/<base>` trước khi review.
- **PR lớn (>50 file)**: Cảnh báo về phạm vi review. Tập trung vào thay đổi source trước, rồi test, rồi config/docs.
