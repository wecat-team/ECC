---
description: "Bí danh của /pr cho chuỗi workflow PRP. Dùng khi tạo pull request giữa chừng workflow PRP; ngoài ra hãy dùng /pr."
argument-hint: "[base-branch] (mặc định: main)"
---

# Tạo Pull Request

> Phỏng theo PRPs-agentic-eng của Wirasm. Thuộc chuỗi workflow PRP.

**Đầu vào**: `$ARGUMENTS` — tùy chọn, có thể chứa tên base branch và/hoặc các flag (ví dụ: `--draft`).

**Parse `$ARGUMENTS`**:
- Trích xuất các flag được nhận diện (`--draft`)
- Coi phần văn bản không phải flag còn lại là tên base branch
- Mặc định base branch là `main` nếu không chỉ định

---

## Giai đoạn 1 — VALIDATE

Kiểm tra các điều kiện tiên quyết:

```bash
git branch --show-current
git status --short
git log origin/<base>..HEAD --oneline
```

| Kiểm tra | Điều kiện | Hành động nếu thất bại |
|---|---|---|
| Không ở base branch | Branch hiện tại ≠ base | Dừng: "Switch to a feature branch first." |
| Working directory sạch | Không có thay đổi chưa commit | Cảnh báo: "You have uncommitted changes. Commit or stash first. Use `/prp-commit` to commit." |
| Có commit đi trước | `git log origin/<base>..HEAD` không rỗng | Dừng: "No commits ahead of `<base>`. Nothing to PR." |
| Chưa có PR | `gh pr list --head <branch> --json number` rỗng | Dừng: "PR already exists: #<number>. Use `gh pr view <number> --web` to open it." |

Nếu tất cả kiểm tra đều đạt, tiếp tục.

---

## Giai đoạn 2 — DISCOVER

### PR Template

Tìm PR template theo thứ tự:

1. Thư mục `.github/PULL_REQUEST_TEMPLATE/` — nếu tồn tại, liệt kê các file và để người dùng chọn (hoặc dùng `default.md`)
2. `.github/PULL_REQUEST_TEMPLATE.md`
3. `.github/pull_request_template.md`
4. `docs/pull_request_template.md`

Nếu tìm thấy, đọc nó và dùng cấu trúc của nó cho phần body của PR.

### Phân tích Commit

```bash
git log origin/<base>..HEAD --format="%h %s" --reverse
```

Phân tích các commit để xác định:
- **Tiêu đề PR**: Dùng định dạng conventional commit với tiền tố type — `feat: ...`, `fix: ...`, v.v.
  - Nếu có nhiều type, dùng type chiếm ưu thế
  - Nếu chỉ có một commit, dùng nguyên message của nó
- **Tóm tắt thay đổi**: Nhóm các commit theo type/khu vực

### Phân tích File

```bash
git diff origin/<base>..HEAD --stat
git diff origin/<base>..HEAD --name-only
```

Phân loại các file đã thay đổi: source, test, docs, config, migration.

### PRP Artifact

Kiểm tra các PRP artifact liên quan:
- `.claude/PRPs/reports/` — Báo cáo triển khai
- `.claude/PRPs/plans/` — Các plan đã được thực thi
- `.claude/PRPs/prds/` — Các PRD liên quan

Tham chiếu chúng trong body của PR nếu có.

---

## Giai đoạn 3 — PUSH

```bash
git push -u origin HEAD
```

Nếu push thất bại do phân kỳ (divergence):
```bash
git fetch origin
git rebase origin/<base>
git push -u origin HEAD
```

Nếu rebase xảy ra conflict, hãy dừng lại và thông báo cho người dùng.

---

## Giai đoạn 4 — CREATE

### Có Template

Nếu tìm thấy PR template ở Giai đoạn 2, điền từng section dựa trên phân tích commit và file. Giữ nguyên tất cả section của template — để section là "N/A" nếu không áp dụng thay vì xóa chúng.

### Không có Template

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

## Giai đoạn 5 — VERIFY

```bash
gh pr view --json number,url,title,state,baseRefName,headRefName,additions,deletions,changedFiles
gh pr checks --json name,status,conclusion 2>/dev/null || true
```

---

## Giai đoạn 6 — OUTPUT

Báo cáo cho người dùng:

```
PR #<number>: <title>
URL: <url>
Branch: <head> → <base>
Changes: +<additions> -<deletions> across <changedFiles> files

CI Checks: <status summary or "pending" or "none configured">

Artifacts referenced:
  - <any PRP reports/plans linked in PR body>

Next steps:
  - gh pr view <number> --web   → open in browser
  - /code-review <number>       → review the PR
  - gh pr merge <number>        → merge when ready
```

---

## Edge Case

- **Không có `gh` CLI**: Dừng với thông báo: "GitHub CLI (`gh`) is required. Install: <https://cli.github.com/>"
- **Chưa xác thực**: Dừng với thông báo: "Run `gh auth login` first."
- **Cần force push**: Nếu remote đã phân kỳ và đã rebase, dùng `git push --force-with-lease` (KHÔNG BAO GIỜ dùng `--force`).
- **Nhiều PR template**: Nếu `.github/PULL_REQUEST_TEMPLATE/` có nhiều file, liệt kê chúng và yêu cầu người dùng chọn.
- **PR lớn (>20 file)**: Cảnh báo về kích thước PR. Đề xuất tách nhỏ nếu các thay đổi có thể tách riêng một cách hợp lý.
