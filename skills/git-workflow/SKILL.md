---
name: git-workflow
description: Pattern workflow Git gồm chiến lược branching, quy ước commit, giữ lịch sử sạch và dễ đọc, dọn commit cục bộ trước khi merge, merge vs rebase, giải quyết conflict và best practice phát triển cộng tác cho nhóm mọi quy mô. Dùng khi chọn chiến lược branching, viết quy ước commit, dọn lịch sử trước pull request, quyết định merge hay rebase, hoặc giải quyết conflict.
metadata:
  origin: ECC
---

# Pattern Workflow Git

Best practice cho quản lý phiên bản Git, chiến lược branching và phát triển cộng tác.

## Khi nào kích hoạt

- Thiết lập workflow Git cho một project mới
- Quyết định chiến lược branching (GitFlow, trunk-based, GitHub flow)
- Viết commit message và mô tả PR
- Giải quyết merge conflict
- Quản lý release và version tag
- Hướng dẫn thành viên mới trong nhóm về thực hành Git

## Chiến lược Branching

### GitHub Flow (Đơn giản, được khuyến nghị cho đa số trường hợp)

Phù hợp nhất cho continuous deployment và nhóm quy mô nhỏ đến vừa.

```
main (protected, always deployable)
  │
  ├── feature/user-auth      → PR → merge to main
  ├── feature/payment-flow   → PR → merge to main
  └── fix/login-bug          → PR → merge to main
```

**Quy tắc:**
- `main` luôn sẵn sàng để deploy
- Tạo feature branch từ `main`
- Mở Pull Request khi sẵn sàng để review
- Sau khi được duyệt và CI pass, merge vào `main`
- Deploy ngay sau khi merge

### Trunk-Based Development (Nhóm tốc độ cao)

Phù hợp nhất cho nhóm có CI/CD mạnh và feature flag.

```
main (trunk)
  │
  ├── short-lived feature (1-2 days max)
  ├── short-lived feature
  └── short-lived feature
```

**Quy tắc:**
- Mọi người commit vào `main` hoặc các branch tồn tại rất ngắn
- Feature flag che giấu công việc chưa hoàn thành
- CI phải pass trước khi merge
- Deploy nhiều lần mỗi ngày

### GitFlow (Phức tạp, theo chu kỳ release)

Phù hợp nhất cho release theo lịch và project doanh nghiệp.

```
main (production releases)
  │
  └── develop (integration branch)
        │
        ├── feature/user-auth
        ├── feature/payment
        │
        ├── release/1.0.0    → merge to main and develop
        │
        └── hotfix/critical  → merge to main and develop
```

**Quy tắc:**
- `main` chỉ chứa code sẵn sàng cho production
- `develop` là branch tích hợp
- Feature branch tách từ `develop`, merge ngược lại vào `develop`
- Release branch tách từ `develop`, merge vào `main` và `develop`
- Hotfix branch tách từ `main`, merge vào cả `main` và `develop`

### Khi nào dùng loại nào

| Chiến lược | Quy mô nhóm | Nhịp release | Phù hợp nhất cho |
|----------|-----------|-----------------|----------|
| GitHub Flow | Bất kỳ | Liên tục | SaaS, web app, startup |
| Trunk-Based | 5+ có kinh nghiệm | Nhiều lần/ngày | Nhóm tốc độ cao, feature flag |
| GitFlow | 10+ | Theo lịch | Doanh nghiệp, ngành có quy định |

## Commit Message

### Định dạng Conventional Commits

```
<type>(<scope>): <subject>

[optional body]

[optional footer(s)]
```

### Các Type

| Type | Dùng cho | Ví dụ |
|------|---------|---------|
| `feat` | Tính năng mới | `feat(auth): add OAuth2 login` |
| `fix` | Sửa bug | `fix(api): handle null response in user endpoint` |
| `docs` | Tài liệu | `docs(readme): update installation instructions` |
| `style` | Định dạng, không đổi code | `style: fix indentation in login component` |
| `refactor` | Refactor code | `refactor(db): extract connection pool to module` |
| `test` | Thêm/cập nhật test | `test(auth): add unit tests for token validation` |
| `chore` | Công việc bảo trì | `chore(deps): update dependencies` |
| `perf` | Cải thiện hiệu năng | `perf(query): add index to users table` |
| `ci` | Thay đổi CI/CD | `ci: add PostgreSQL service to test workflow` |
| `revert` | Revert commit trước đó | `revert: revert "feat(auth): add OAuth2 login"` |

### Ví dụ tốt và xấu

```
# BAD: Mơ hồ, không có ngữ cảnh
git commit -m "fixed stuff"
git commit -m "updates"
git commit -m "WIP"

# GOOD: Rõ ràng, cụ thể, giải thích lý do
git commit -m "fix(api): retry requests on 503 Service Unavailable

The external API occasionally returns 503 errors during peak hours.
Added exponential backoff retry logic with max 3 attempts.

Closes #123"
```

### Template Commit Message

Tạo `.gitmessage` ở thư mục gốc repo:

```
# <type>(<scope>): <subject>
# # Types: feat, fix, docs, style, refactor, test, chore, perf, ci, revert
# Scope: api, ui, db, auth, etc.
# Subject: imperative mood, no period, max 50 chars
#
# [optional body] - explain why, not what
# [optional footer] - Breaking changes, closes #issue
```

Bật bằng: `git config commit.template .gitmessage`

## Merge vs Rebase

### Merge (Giữ nguyên lịch sử)

```bash
# Tạo một merge commit
git checkout main
git merge feature/user-auth

# Kết quả:
# *   merge commit
# |\
# | * feature commits
# |/
# * main commits
```

**Dùng khi:**
- Merge feature branch vào `main`
- Bạn muốn giữ nguyên lịch sử chính xác
- Nhiều người cùng làm việc trên branch
- Branch đã được push và người khác có thể đã dựa công việc của họ trên nó

### Rebase (Lịch sử tuyến tính)

```bash
# Ghi lại các feature commit lên branch đích
git checkout feature/user-auth
git rebase main

# Kết quả:
# * feature commits (đã viết lại)
# * main commits
```

**Dùng khi:**
- Cập nhật feature branch cục bộ với `main` mới nhất
- Bạn muốn lịch sử tuyến tính, sạch sẽ
- Branch chỉ tồn tại cục bộ (chưa push)
- Bạn là người duy nhất làm việc trên branch

### Workflow Rebase

```bash
# Cập nhật feature branch với main mới nhất (trước khi tạo PR)
git checkout feature/user-auth
git fetch origin
git rebase origin/main

# Sửa các conflict nếu có
# Test vẫn phải pass

# Force push (chỉ khi bạn là người đóng góp duy nhất)
git push --force-with-lease origin feature/user-auth
```

### Khi nào KHÔNG rebase

```
# KHÔNG BAO GIỜ rebase các branch mà:
- Have been pushed to a shared repository
- Other people have based work on
- Are protected branches (main, develop)
- Are already merged

# Lý do: Rebase viết lại lịch sử, làm hỏng công việc của người khác
```

## Workflow Pull Request

### Định dạng tiêu đề PR

```
<type>(<scope>): <description>

Examples:
feat(auth): add SSO support for enterprise users
fix(api): resolve race condition in order processing
docs(api): add OpenAPI specification for v2 endpoints
```

### Template mô tả PR

```markdown
## What

Brief description of what this PR does.

## Why

Explain the motivation and context.

## How

Key implementation details worth highlighting.

## Testing

- [ ] Unit tests added/updated
- [ ] Integration tests added/updated
- [ ] Manual testing performed

## Screenshots (if applicable)

Before/after screenshots for UI changes.

## Checklist

- [ ] Code follows project style guidelines
- [ ] Self-review completed
- [ ] Comments added for complex logic
- [ ] Documentation updated
- [ ] No new warnings introduced
- [ ] Tests pass locally
- [ ] Related issues linked

Closes #123
```

### Checklist Code Review

**Dành cho Reviewer:**

- [ ] Code có giải quyết đúng vấn đề đã nêu không?
- [ ] Có edge case nào chưa được xử lý không?
- [ ] Code có dễ đọc và dễ bảo trì không?
- [ ] Có đủ test không?
- [ ] Có vấn đề bảo mật nào không?
- [ ] Lịch sử commit có sạch không (squash nếu cần)?

**Dành cho Tác giả:**

- [ ] Tự review xong trước khi yêu cầu review
- [ ] CI pass (test, lint, typecheck)
- [ ] Kích thước PR hợp lý (lý tưởng <500 dòng)
- [ ] Gắn với một tính năng/bản sửa duy nhất
- [ ] Mô tả giải thích rõ thay đổi

## Giải quyết Conflict

### Nhận diện Conflict

```bash
# Kiểm tra conflict trước khi merge
git checkout main
git merge feature/user-auth --no-commit --no-ff

# Nếu có conflict, Git sẽ hiển thị:
# CONFLICT (content): Merge conflict in src/auth/login.ts
# Automatic merge failed; fix conflicts and then commit the result.
```

### Giải quyết Conflict

```bash
# Xem các file bị conflict
git status

# Xem conflict marker trong file
# <<<<<<< HEAD
# content from main
# =======
# content from feature branch
# >>>>>>> feature/user-auth

# Cách 1: Giải quyết thủ công
# Sửa file, xóa marker, giữ nội dung đúng

# Cách 2: Dùng merge tool
git mergetool

# Cách 3: Chấp nhận một bên
git checkout --ours src/auth/login.ts    # Keep main version
git checkout --theirs src/auth/login.ts  # Keep feature version

# Sau khi giải quyết, stage và commit
git add src/auth/login.ts
git commit
```

### Chiến lược phòng tránh Conflict

```bash
# 1. Giữ feature branch nhỏ và tồn tại ngắn
# 2. Rebase thường xuyên lên main
git checkout feature/user-auth
git fetch origin
git rebase origin/main

# 3. Trao đổi với nhóm khi động vào các file dùng chung
# 4. Dùng feature flag thay vì branch tồn tại lâu
# 5. Review và merge PR kịp thời
```

## Quản lý Branch

### Quy ước đặt tên

```
# Feature branch
feature/user-authentication
feature/JIRA-123-payment-integration

# Sửa bug
fix/login-redirect-loop
fix/456-null-pointer-exception

# Hotfix (sự cố production)
hotfix/critical-security-patch
hotfix/database-connection-leak

# Release
release/1.2.0
release/2024-01-hotfix

# Thử nghiệm/POC
experiment/new-caching-strategy
poc/graphql-migration
```

### Dọn dẹp Branch

```bash
# Xóa các branch cục bộ đã merge
git branch --merged main | grep -v "^\*\|main" | xargs -n 1 git branch -d

# Xóa remote-tracking reference của các remote branch đã bị xóa
git fetch -p

# Xóa branch cục bộ
git branch -d feature/user-auth  # Safe delete (only if merged)
git branch -D feature/user-auth  # Force delete

# Xóa remote branch
git push origin --delete feature/user-auth
```

### Workflow Stash

```bash
# Lưu công việc đang làm dở
git stash push -m "WIP: user authentication"

# Liệt kê stash
git stash list

# Áp dụng stash gần nhất
git stash pop

# Áp dụng stash cụ thể
git stash apply stash@{2}

# Xóa stash
git stash drop stash@{0}
```

## Quản lý Release

### Semantic Versioning

```
MAJOR.MINOR.PATCH

MAJOR: Breaking changes
MINOR: New features, backward compatible
PATCH: Bug fixes, backward compatible

Examples:
1.0.0 → 1.0.1 (patch: bug fix)
1.0.1 → 1.1.0 (minor: new feature)
1.1.0 → 2.0.0 (major: breaking change)
```

### Tạo Release

```bash
# Tạo annotated tag
git tag -a v1.2.0 -m "Release v1.2.0

Features:
- Add user authentication
- Implement password reset

Fixes:
- Resolve login redirect issue

Breaking Changes:
- None"

# Push tag lên remote
git push origin v1.2.0

# Liệt kê tag
git tag -l

# Xóa tag
git tag -d v1.2.0
git push origin --delete v1.2.0
```

### Tạo Changelog

```bash
# Tạo changelog từ các commit
git log v1.1.0..v1.2.0 --oneline --no-merges

# Hoặc dùng conventional-changelog
npx conventional-changelog -i CHANGELOG.md -s
```

## Cấu hình Git

### Cấu hình thiết yếu

```bash
# Danh tính người dùng
git config --global user.name "Your Name"
git config --global user.email "your@email.com"

# Tên branch mặc định
git config --global init.defaultBranch main

# Hành vi pull (rebase thay vì merge)
git config --global pull.rebase true

# Hành vi push (chỉ push branch hiện tại)
git config --global push.default current

# Tự sửa lỗi gõ
git config --global help.autocorrect 1

# Thuật toán diff tốt hơn
git config --global diff.algorithm histogram

# Output có màu
git config --global color.ui auto
```

### Alias hữu ích

```bash
# Thêm vào ~/.gitconfig
[alias]
    co = checkout
    br = branch
    ci = commit
    st = status
    unstage = reset HEAD --
    last = log -1 HEAD
    visual = log --oneline --graph --all
    amend = commit --amend --no-edit
    wip = commit -m "WIP"
    undo = reset --soft HEAD~1
    contributors = shortlog -sn
```

### Mẫu Gitignore

```gitignore
# Dependency
node_modules/
vendor/

# Output của build
dist/
build/
*.o
*.exe

# File môi trường
.env
.env.local
.env.*.local

# IDE
.idea/
.vscode/
*.swp
*.swo

# File hệ điều hành
.DS_Store
Thumbs.db

# Log
*.log
logs/

# Test coverage
coverage/

# Cache
.cache/
*.tsbuildinfo
```

## Workflow thường gặp

### Bắt đầu một tính năng mới

```bash
# 1. Cập nhật branch main
git checkout main
git pull origin main

# 2. Tạo feature branch
git checkout -b feature/user-auth

# 3. Thay đổi và commit
git add .
git commit -m "feat(auth): implement OAuth2 login"

# 4. Push lên remote
git push -u origin feature/user-auth

# 5. Tạo Pull Request trên GitHub/GitLab
```

### Cập nhật PR với thay đổi mới

```bash
# 1. Thực hiện các thay đổi bổ sung
git add .
git commit -m "feat(auth): add error handling"

# 2. Push cập nhật
git push origin feature/user-auth
```

### Đồng bộ Fork với Upstream

```bash
# 1. Thêm upstream remote (một lần)
git remote add upstream https://github.com/original/repo.git

# 2. Fetch upstream
git fetch upstream

# 3. Merge upstream/main vào main của bạn
git checkout main
git merge upstream/main

# 4. Push lên fork của bạn
git push origin main
```

### Hoàn tác sai sót

```bash
# Hoàn tác commit cuối (giữ thay đổi)
git reset --soft HEAD~1

# Hoàn tác commit cuối (bỏ thay đổi)
git reset --hard HEAD~1

# Hoàn tác commit cuối đã push lên remote
git revert HEAD
git push origin main

# Hoàn tác thay đổi của một file cụ thể
git checkout HEAD -- path/to/file

# Sửa commit message cuối
git commit --amend -m "New message"

# Thêm file bị quên vào commit cuối
git add forgotten-file
git commit --amend --no-edit
```

## Git Hook

### Pre-Commit Hook

```bash
#!/bin/bash
# .git/hooks/pre-commit

# Chạy linting
npm run lint || exit 1

# Chạy test
npm test || exit 1

# Kiểm tra secret
if git diff --cached | grep -E '(password|api_key|secret)'; then
    echo "Possible secret detected. Commit aborted."
    exit 1
fi
```

### Pre-Push Hook

```bash
#!/bin/bash
# .git/hooks/pre-push

# Chạy toàn bộ test suite
npm run test:all || exit 1

# Kiểm tra các câu lệnh console.log
if git diff origin/main | grep -E 'console\.log'; then
    echo "Remove console.log statements before pushing."
    exit 1
fi
```

## Anti-Pattern

```
# BAD: Commit trực tiếp vào main
git checkout main
git commit -m "fix bug"

# GOOD: Dùng feature branch và PR

# BAD: Commit secret
git add .env  # Contains API keys

# GOOD: Thêm vào .gitignore, dùng biến môi trường

# BAD: PR khổng lồ (1000+ dòng)
# GOOD: Chia thành các PR nhỏ hơn, tập trung

# BAD: Commit message kiểu "Update"
git commit -m "update"
git commit -m "fix"

# GOOD: Message mô tả rõ ràng
git commit -m "fix(auth): resolve redirect loop after login"

# BAD: Viết lại lịch sử công khai
git push --force origin main

# GOOD: Dùng revert cho branch công khai
git revert HEAD

# BAD: Feature branch tồn tại lâu (hàng tuần/tháng)
# GOOD: Giữ branch ngắn (vài ngày), rebase thường xuyên

# BAD: Commit file được sinh ra
git add dist/
git add node_modules/

# GOOD: Thêm vào .gitignore
```

## Tham chiếu nhanh

| Tác vụ | Lệnh |
|------|---------|
| Tạo branch | `git checkout -b feature/name` |
| Chuyển branch | `git checkout branch-name` |
| Xóa branch | `git branch -d branch-name` |
| Merge branch | `git merge branch-name` |
| Rebase branch | `git rebase main` |
| Xem lịch sử | `git log --oneline --graph` |
| Xem thay đổi | `git diff` |
| Stage thay đổi | `git add .` hoặc `git add -p` |
| Commit | `git commit -m "message"` |
| Push | `git push origin branch-name` |
| Pull | `git pull origin branch-name` |
| Stash | `git stash push -m "message"` |
| Hoàn tác commit cuối | `git reset --soft HEAD~1` |
| Revert commit | `git revert HEAD` |
