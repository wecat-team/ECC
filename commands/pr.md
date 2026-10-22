---
description: "Tạo một GitHub PR từ branch hiện tại có các commit chưa push — tìm template, phân tích thay đổi, push"
argument-hint: "[base-branch] (mặc định: main)"
---

# Tạo Pull Request

**Input**: `$ARGUMENTS` — tùy chọn, có thể chứa tên base branch và/hoặc các flag (ví dụ `--draft`).

**Parse `$ARGUMENTS`**:
- Trích xuất mọi flag được nhận diện (`--draft`)
- Coi phần văn bản còn lại không phải flag là tên base branch
- Mặc định base branch là `main` nếu không chỉ định

---

## Phase 1 — VALIDATE

Kiểm tra các điều kiện tiên quyết:

```bash
git branch --show-current
git status --short
git log origin/<base>..HEAD --oneline
```

| Kiểm tra | Điều kiện | Hành động nếu thất bại |
|---|---|---|
| Không ở base branch | Branch hiện tại ≠ base | Dừng: "Hãy chuyển sang một feature branch trước." |
| Working directory sạch | Không có thay đổi chưa commit | Cảnh báo: "Bạn có thay đổi chưa commit. Hãy commit hoặc stash trước." |
| Có commit đi trước | `git log origin/<base>..HEAD` không rỗng | Dừng: "Không có commit nào đi trước `<base>`. Không có gì để tạo PR." |
| Chưa có PR | `gh pr list --head <branch> --json number` rỗng | Dừng: "PR đã tồn tại: #<number>. Dùng `gh pr view <number> --web` để mở." |

Nếu mọi kiểm tra đều đạt, tiếp tục.

---

## Phase 2 — DISCOVER

### Template PR

Tìm template PR theo thứ tự:

1. Thư mục `.github/PULL_REQUEST_TEMPLATE/` — nếu có, liệt kê các file và để người dùng chọn (hoặc dùng `default.md`)
2. `.github/PULL_REQUEST_TEMPLATE.md`
3. `.github/pull_request_template.md`
4. `docs/pull_request_template.md`

Nếu tìm thấy, hãy đọc nó và dùng cấu trúc của nó cho phần body của PR.

### Phân tích commit

```bash
git log origin/<base>..HEAD --format="%h %s" --reverse
```

Phân tích các commit để xác định:
- **Tiêu đề PR**: Dùng định dạng conventional commit với tiền tố type — `feat: ...`, `fix: ...`, v.v.
  - Nếu có nhiều type, dùng type chiếm ưu thế
  - Nếu chỉ có một commit, dùng nguyên message của nó
- **Tóm tắt thay đổi**: Nhóm các commit theo type/khu vực

### Phân tích file

```bash
git diff origin/<base>..HEAD --stat
git diff origin/<base>..HEAD --name-only
```

Phân loại các file thay đổi: source, test, docs, config, migration.

### Planning Artifact

Kiểm tra các artifact liên quan do `/plan-prd`, `/plan` hoặc workflow PRP legacy tạo ra:
- `.claude/prds/` — các PRD mà PR này triển khai một milestone
- `.claude/plans/` — các kế hoạch được PR này thực thi
- `.claude/PRPs/prds/` — các PRD PRP legacy
- `.claude/PRPs/plans/` — các kế hoạch triển khai PRP legacy
- `.claude/PRPs/reports/` — các báo cáo triển khai PRP legacy

Hãy tham chiếu chúng trong body của PR nếu có.

---

## Phase 3 — PUSH

```bash
git push -u origin HEAD
```

Nếu push thất bại do phân kỳ (divergence):
```bash
git fetch origin
git rebase origin/<base>
git push -u origin HEAD
```

Nếu xảy ra conflict khi rebase, hãy dừng lại và thông báo cho người dùng.

---

## Phase 4 — CREATE

### Có template

Nếu đã tìm thấy template PR ở Phase 2, hãy điền từng mục dựa trên phân tích commit và file. Giữ nguyên mọi mục của template — để các mục không áp dụng là "N/A" thay vì xóa chúng.

### Không có template

Dùng định dạng mặc định này:

```markdown
## Summary

<1-2 sentence description of what this PR does and why>

## Changes

<bulleted list of changes grouped by area>

## Files Changed

<table or list of changed files with change type: Added/Modified/Deleted>

## Testing

<description of how changes were tested, or "Needs testing">

## Related Issues

<linked issues with Closes/Fixes/Relates to #N, or "None">
```

### Tạo PR

```bash
gh pr create \
  --title "<PR title>" \
  --base <base-branch> \
  --body "<PR body>"
  # Add --draft if the --draft flag was parsed from $ARGUMENTS
```

---

## Phase 5 — VERIFY

```bash
gh pr view --json number,url,title,state,baseRefName,headRefName,additions,deletions,changedFiles
gh pr checks --json name,status,conclusion 2>/dev/null || true
```

---

## Phase 6 — OUTPUT

Báo cáo cho người dùng:

```
PR #<number>: <title>
URL: <url>
Branch: <head> → <base>
Changes: +<additions> -<deletions> across <changedFiles> files

CI Checks: <status summary or "pending" or "none configured">

Artifacts referenced:
  - <any PRDs/plans linked in PR body>

Next steps:
  - gh pr view <number> --web   → open in browser
  - /code-review <number>       → review the PR
  - gh pr merge <number>        → merge when ready
```

---

## Edge Case

- **Không có `gh` CLI**: Dừng với thông báo: "Cần GitHub CLI (`gh`). Cài đặt: <https://cli.github.com/>"
- **Chưa xác thực**: Dừng với thông báo: "Hãy chạy `gh auth login` trước."
- **Cần force push**: Nếu remote đã phân kỳ và đã rebase, dùng `git push --force-with-lease` (KHÔNG BAO GIỜ dùng `--force`).
- **Nhiều template PR**: Nếu `.github/PULL_REQUEST_TEMPLATE/` có nhiều file, liệt kê chúng và yêu cầu người dùng chọn.
- **PR lớn (>20 file)**: Cảnh báo về kích thước PR. Đề xuất chia nhỏ nếu các thay đổi có thể tách theo logic.
