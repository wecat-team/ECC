---
description: "Commit nhanh với việc chọn file bằng ngôn ngữ tự nhiên — mô tả cần commit gì bằng lời thường"
argument-hint: "[mô tả mục tiêu] (để trống = tất cả thay đổi)"
---

# Smart Commit

> Phỏng theo PRPs-agentic-eng của Wirasm. Thuộc chuỗi workflow PRP.

**Đầu vào**: $ARGUMENTS

---

## Giai đoạn 1 — ASSESS

```bash
git status --short
```

Nếu đầu ra rỗng → dừng: "Nothing to commit."

Hiển thị cho người dùng bản tóm tắt những gì đã thay đổi (thêm mới, sửa đổi, xóa, chưa được theo dõi).

---

## Giai đoạn 2 — INTERPRET & STAGE

Diễn giải `$ARGUMENTS` để xác định cần stage những gì:

| Đầu vào | Diễn giải | Lệnh Git |
|---|---|---|
| *(trống / rỗng)* | Stage tất cả | `git add -A` |
| `staged` | Dùng những gì đã được stage sẵn | *(không git add)* |
| `*.ts` hoặc `*.py` v.v. | Stage các file khớp glob | `git add '*.ts'` |
| `except tests` | Stage tất cả, sau đó unstage test | `git add -A && git reset -- '**/*.test.*' '**/*.spec.*' '**/test_*' 2>/dev/null \|\| true` |
| `only new files` | Chỉ stage các file chưa được theo dõi | `git ls-files --others --exclude-standard \| grep . && git ls-files --others --exclude-standard \| xargs git add` |
| `the auth changes` | Diễn giải từ status/diff — tìm các file liên quan đến auth | `git add <matched files>` |
| Tên file cụ thể | Stage các file đó | `git add <files>` |

Với đầu vào ngôn ngữ tự nhiên (như "the auth changes"), hãy đối chiếu đầu ra của `git status` và `git diff` để xác định các file liên quan. Hiển thị cho người dùng những file bạn đang stage và lý do.

```bash
git add <determined files>
```

Sau khi stage, hãy xác minh:
```bash
git diff --cached --stat
```

Nếu chưa có gì được stage, dừng: "No files matched your description."

---

## Giai đoạn 3 — COMMIT

Soạn commit message một dòng ở thể mệnh lệnh (imperative mood):

```
{type}: {description}
```

Các type:
- `feat` — Tính năng hoặc khả năng mới
- `fix` — Sửa lỗi
- `refactor` — Tái cấu trúc code không đổi hành vi
- `docs` — Thay đổi tài liệu
- `test` — Thêm hoặc cập nhật test
- `chore` — Build, config, dependency
- `perf` — Cải thiện hiệu năng
- `ci` — Thay đổi CI/CD

Quy tắc:
- Thể mệnh lệnh ("add feature" chứ không phải "added feature")
- Viết thường sau tiền tố type
- Không có dấu chấm ở cuối
- Dưới 72 ký tự
- Mô tả CÁI GÌ đã thay đổi, không phải thay đổi NHƯ THẾ NÀO

```bash
git commit -m "{type}: {description}"
```

---

## Giai đoạn 4 — OUTPUT

Báo cáo cho người dùng:

```
Committed: {hash_short}
Message:   {type}: {description}
Files:     {count} file(s) changed

Next steps:
  - git push           → push to remote
  - /prp-pr            → create a pull request
  - /code-review       → review before pushing
```

---

## Ví dụ

| Bạn nói | Điều xảy ra |
|---|---|
| `/prp-commit` | Stage tất cả, tự sinh message |
| `/prp-commit staged` | Chỉ commit những gì đã được stage |
| `/prp-commit *.ts` | Stage tất cả file TypeScript, rồi commit |
| `/prp-commit except tests` | Stage mọi thứ trừ các file test |
| `/prp-commit the database migration` | Tìm các file DB migration từ status, stage chúng |
| `/prp-commit only new files` | Chỉ stage các file chưa được theo dõi |
