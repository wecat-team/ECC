---
name: skill-scout
description: Tìm kiếm các nguồn skill sẵn có (local, marketplace, GitHub và web) trước khi tạo skill mới. Dùng khi người dùng muốn tạo, xây dựng, fork hoặc tìm một skill cho một workflow.
metadata:
  origin: community
---

# Skill Scout

Dùng skill này trước khi tạo một skill mới. Mục tiêu là tránh trùng lặp
công sức của cộng đồng hoặc marketplace, đồng thời vẫn kiểm định (vet) mọi thứ
từ bên ngoài trước khi áp dụng.

Nguồn: được cứu lại từ PR cộng đồng cũ #1232 của `redminwang`.

## Khi nào dùng

- Người dùng nói "create a skill", "build a skill", "make a skill" hoặc "new
  skill".
- Người dùng hỏi "is there a skill for X?" hoặc "does a skill exist that does Y?"
- Người dùng mô tả một workflow và bạn sắp đề xuất tạo một skill
  mới.
- Người dùng muốn fork hoặc mở rộng một skill hiện có.

Nếu người dùng nói rõ là bỏ qua bước tìm kiếm hoặc tạo từ đầu, hãy ghi nhận
điều đó và tiếp tục với workflow tạo skill được yêu cầu.

## Cách hoạt động

### Bước 1 - Nắm bắt ý định

Trích xuất:

- Tác vụ mà skill cần thực hiện.
- Các điều kiện kích hoạt để dùng nó.
- Domain, công cụ, framework hoặc nguồn dữ liệu liên quan.
- Ba đến năm từ khóa tìm kiếm cùng các từ đồng nghĩa hữu ích.

### Bước 2 - Tìm trong các nguồn local

Tìm theo tên skill đã cài và skill trên marketplace trước. Ưu tiên nguồn local
vì chúng đã là một phần của môi trường người dùng.

```bash
find ~/.claude/skills -maxdepth 2 -name SKILL.md 2>/dev/null | grep -iE "keyword|synonym"
find ~/.claude/plugins/marketplaces -path '*/skills/*/SKILL.md' 2>/dev/null | grep -iE "keyword|synonym"
```

Sau đó tìm trong phần description của frontmatter:

```bash
grep -RilE "keyword|synonym" ~/.claude/skills ~/.claude/plugins/marketplaces 2>/dev/null
```

### Bước 3 - Tìm trong các nguồn từ xa

Dùng các công cụ tìm kiếm GitHub và web hiện có. Ưu tiên truy vấn ngắn gọn:

```bash
gh search repos "claude code skill keyword" --limit 10 --sort stars
gh search code "name: keyword" --filename SKILL.md --limit 10
```

Với tìm kiếm web, dùng tối đa ba truy vấn có mục tiêu như:

```text
"claude code skill" keyword
"SKILL.md" keyword
"affaan-m/ECC" keyword
```

### Bước 4 - Kiểm định các kết quả bên ngoài

Trước khi đề xuất áp dụng hoặc fork bất kỳ skill bên ngoài nào:

- Đọc frontmatter và phần hướng dẫn của `SKILL.md`.
- Tìm các lệnh shell bất thường, thao tác ghi file, lệnh gọi mạng, xử lý
  credential hoặc cài đặt package.
- Kiểm tra repository có vẻ còn được duy trì hay không.
- Ưu tiên sao chép vào một branch local mới và review diff thay vì chỉnh sửa
  bản gốc trên marketplace.

### Bước 5 - Xếp hạng kết quả

Xếp hạng các ứng viên theo:

1. Khớp chính xác từ khóa trong tên skill.
2. Khớp từ khóa hoặc từ đồng nghĩa trong description.
3. Nguồn local đã cài hoặc từ marketplace.
4. Nguồn GitHub còn được duy trì với hoạt động gần đây.
5. Chỉ được nhắc đến trên web.

Giới hạn danh sách cuối cùng ở 10 kết quả.

### Bước 6 - Trình bày các lựa chọn quyết định

Đưa cho người dùng một bảng ngắn:

| Lựa chọn | Ý nghĩa |
| --- | --- |
| Use existing | Gọi hoặc cài một skill khớp nguyên trạng. |
| Fork or extend | Sao chép skill gần nhất và chỉnh sửa. |
| Create fresh | Xây dựng skill mới sau khi xác nhận không có skill nào gần giống. |

Chỉ tạo skill mới sau khi người dùng chọn hướng đó hoặc sau khi việc tìm kiếm
không thấy skill nào gần giống.

## Ví dụ

### Bảng kết quả

```markdown
| # | Skill | Source | Why it matches | Gap |
| --- | --- | --- | --- | --- |
| 1 | article-writing | Local ECC | Drafts articles and guides | Not focused on release notes |
| 2 | content-engine | Local ECC | Multi-format content workflow | Heavier than needed |
| 3 | blog-writer | GitHub | Blog writing skill with recent commits | Needs security review |
```

### Tóm tắt gửi người dùng

```markdown
I found two close local matches and one external candidate. The closest fit is
`article-writing`; it covers drafting and revision, but it does not include the
release-note checklist you asked for. I can either use it as-is, fork it into a
release-note variant, or create a fresh skill.
```

## Anti-Pattern

- Không nhảy thẳng vào việc tạo skill mới khi việc tìm kiếm là hợp lý.
- Không cài skill bên ngoài khi chưa đọc chúng.
- Không đưa ra một danh sách dài, không xếp hạng gồm các kết quả khớp yếu.
- Không coi các lần chỉ được nhắc đến trên web là nguồn đáng tin cậy.
- Không chỉnh sửa trực tiếp các bản gốc đã cài từ marketplace.

## Liên quan

- `search-first` - Workflow tìm kiếm trước khi xây dựng nói chung.
- `skill-stocktake` - Audit các skill đã cài về độ lành mạnh, trùng lặp và khoảng trống.
- `agent-sort` - Phân loại và tổ chức các agent và skill hiện có.
