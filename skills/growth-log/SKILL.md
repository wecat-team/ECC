---
name: growth-log
description: "Viết mục growth log (nhật ký học hỏi) rút ra các pattern tái sử dụng được từ công việc đã hoàn thành — nguyên nhân gốc, quy tắc có thể áp dụng lại và tín hiệu nhận biết — thay vì kể lại sự kiện kiểu nhật ký, với template 4-8 câu và kỷ luật gộp mục trùng lặp. Dùng khi ghi lại những gì đã học sau một task phức tạp, phiên debug, thất bại hoặc rollback, khi xem lại tiến bộ trong một khoảng thời gian, hoặc khi delivery gate hỏi đã học được gì."
metadata:
  version: 1.1.0
  origin: ECC
---

# Kỹ năng Growth Log

> **Vấn đề:** Hầu hết mọi người viết "đã sửa bug ở X" làm nhật ký học tập. Đó là một mục nhật ký, không phải một sản phẩm học tập. Một growth log thực sự rút ra *pattern* để lần sau bạn nhận ra nó.
>
> **Skill này dạy:** Cách viết các mục học tập tích lũy qua nhiều phiên làm việc. Dùng được với mọi hệ thống ghi chú — file Markdown, Notion, Obsidian, văn bản thuần. Template mang tính tổng quát; hãy điều chỉnh cho phù hợp với cách bạn làm việc.

## Khi nào kích hoạt

- Sau khi hoàn thành một task phức tạp (nhiều file, tính năng mới, thay đổi kiến trúc)
- Sau một thất bại, sai sót, hoặc khoảnh khắc "việc này khó hơn dự kiến"
- Khi bạn muốn xem lại những gì đã học trong một khoảng thời gian

**Khi nào KHÔNG kích hoạt:** Các thay đổi tầm thường (sửa lỗi chính tả, chỉnh một dòng, đổi giá trị config mà không cần debug). Ngưỡng quyết định: *task này có liên quan đến debug, làm lại, rollback hoặc một quyết định không hiển nhiên không?* Nếu có → viết một mục. Nếu không → bỏ qua.

## Ba quy tắc

### Quy tắc 1: Thất bại > Thành tựu

Một thất bại giàu "dinh dưỡng" hơn một thành công. Một bug mất 2 giờ để tìm ra dạy được nhiều hơn 3 tính năng chạy được ngay lần đầu.

**Tệ:** "Đã triển khai thành công luồng đăng nhập."
**Tốt (web dev):** "Luồng đăng nhập: session token không được lưu vì cookie `SameSite` mặc định là `Lax` trong Chrome 128+. Pattern: luôn đặt tường minh `SameSite=None; Secure` khi cross-origin. Tín hiệu nhận biết: auth hỏng sau khi nâng cấp trình duyệt hoặc khi vượt qua ranh giới origin."
**Tốt (data pipeline):** "Import CSV thất bại âm thầm trên các dòng rỗng vì `pandas.read_csv(dropna=False)` giữ lại các dòng có độ rộng bằng 0 mà `len()` vẫn đếm là hợp lệ. Pattern: luôn `df.dropna(how='all', inplace=True)` trước khi kiểm tra số dòng."

### Quy tắc 2: Nguyên tắc Bá Nhạc (伯乐原则)

Trước khi viết một mục mới, hãy tự hỏi: *"Về bản chất, điều này có giống với thứ tôi đã ghi lại không?"*

Cùng nguyên nhân gốc, khác triệu chứng → **gộp**, đừng nhân đôi. Nguyên nhân gốc mới → mục mới.

**Cách kiểm tra:** Tìm trong các mục hiện có theo từ khóa của nguyên nhân gốc trước khi viết. Nếu tìm thấy mục khớp, hãy thêm triệu chứng mới của bạn như một ví dụ bổ sung bên dưới mục hiện có thay vì tạo bản trùng lặp.

**Ví dụ:** "Quên cập nhật output index sau khi tạo file" và "Quên cập nhật skill rating sau một task" — cùng nguyên nhân gốc (không có trigger tự động để ghi nhận). Gộp thành một mục về "các lỗ hổng ghi nhận sau task".

### Quy tắc 3: Phải có thể áp dụng lại (Transferable)

Mỗi mục phải trả lời được: *"Lần sau gặp tình huống tương tự, tôi sẽ làm gì khác đi?"*

Nếu bạn không viết được câu đó, nghĩa là bạn chưa rút ra được pattern.

**Cách rút pattern từ một sự kiện cụ thể:**
1. Nêu điều đã xảy ra trong một câu
2. Hỏi "tại sao?" lặp lại cho đến khi chạm tới nguyên nhân gốc (thường 3-5 lần "tại sao")
3. Khái quát hóa: "Đây là lớp vấn đề nào?" (không phải "bug của Chrome 128" mà là "thay đổi mặc định của trình duyệt làm hỏng hành vi hiện có")
4. Diễn đạt thành: "Lần sau khi thấy [tín hiệu], tôi sẽ [hành động]."
5. Đặt tên cho tín hiệu: quan sát cụ thể nào cho bạn biết pattern này đang hoạt động?

## Template mục nhật ký

**Phạm vi:** Một mục cho mỗi nguyên nhân gốc riêng biệt. Độ dài điển hình: 4-8 câu. Nếu mất hơn 2 phút để viết, bạn đang kể lại sự kiện. Nếu dưới 30 giây, bạn chưa đào đủ sâu.

```markdown
## [Title: the pattern, not the event]

### Context
- What was I trying to do?
- What went wrong / what worked surprisingly well?

### Root Cause / Core Insight
- The underlying mechanism, not just the symptom

### The Pattern (transferable)
- Next time [similar situation], I will [specific action].
- Signal to recognize: [what observable tells me this pattern is active?]

### Related
- [entry-name](../path/to/related-entry.md)
```

## Các loại mục

Cả bốn loại đều dùng template ở trên. Loại mục quyết định phần nào mang trọng lượng lớn nhất:

| Loại | Khi nào dùng | Trọng tâm | Tiêu đề ví dụ |
|------|------------|----------|---------------|
| **Failure** | Có thứ bị hỏng, cần debug hoặc phải làm lại | Root Cause | "Config inheritance ≠ behavior inheritance across sessions" |
| **Methodology** | Một quy trình lặp lại được hình thành từ công việc | Context / Pattern | "PPT → open-book exam study guide: three-layer structure" |
| **Pattern Discovery** | Một hiểu biết tái sử dụng được về công cụ, hệ thống hoặc cách tư duy | Phần Pattern | "PR description template: describe the gap, not the feature" |
| **Capability Change** | Một cải thiện kỹ năng đo lường được | Context (trước so với sau) | "Git: from clone/push to independent PR with 12 commits" |

## Checklist chất lượng

Trước khi hoàn tất một mục growth log:

- [ ] Tiêu đề có nêu *pattern*, không phải sự kiện?
- [ ] Có câu "Next time I will..." (Lần sau tôi sẽ...)?
- [ ] "Signal to recognize" (tín hiệu nhận biết) có đủ cụ thể để kích hoạt pattern vào lần sau?
- [ ] Đã tìm trong các mục hiện có để tránh trùng lặp trước khi viết? (Nguyên tắc Bá Nhạc)
- [ ] Nguyên nhân gốc có được phân biệt với triệu chứng?
- [ ] Các ghi nhớ liên quan đã được liên kết chéo?
- [ ] Mục có 4-8 câu? Ngắn hơn = quá nông; dài hơn = đang kể lại sự kiện.

## Anti-Pattern

- Tránh: "Fixed bug in payment module" (là sự kiện, không phải pattern)
- Tránh: Sao chép nguyên văn commit message của git (commit mô tả cái gì đã thay đổi; log rút ra vì sao nó quan trọng)
- Tránh: Viết một mục cho mỗi commit (chỉ viết khi có pattern xuất hiện)
- Tránh: Bỏ qua câu có thể áp dụng lại (thiếu nó thì chỉ là nhật ký — điều này không thể thương lượng)
- Tránh: Nhân đôi cùng một pattern dưới nhiều tiêu đề khác nhau (vi phạm Nguyên tắc Bá Nhạc — hãy tìm trước khi viết)

## Lưu trữ

Lưu các mục ở bất cứ nơi nào bạn giữ ghi chú. Các cách phổ biến:
- File Markdown trong thư mục `growth-log/` (mỗi ngày một file: `YYYY-MM-DD.md`)
- Một mục riêng trong Notion, Obsidian hoặc ứng dụng ghi chú của bạn
- File văn bản thuần với quy ước đặt tên nhất quán

Chọn một quy ước và bám theo nó. Khả năng tìm kiếm quan trọng hơn định dạng.

## Nếu bạn dùng Delivery Gate

Stop hook `delivery-gate` kiểm tra xem các file học tập có được sửa trong ngày hôm nay hay không thông qua timestamp của filesystem. Skill này dạy *viết gì* — để file mà delivery-gate kiểm tra thực sự chứa các pattern hữu ích, chứ không phải chỉ có timestamp rỗng.

```
Task completes → delivery-gate checks: was the learning file touched today?
  → Stale (no file modified): block — "what did you learn?"
  → Fresh (file touched): pass — this skill ensures the content is useful
```

Có cưỡng chế mà không có phương pháp → mục rỗng. Có phương pháp mà không có cưỡng chế → quên ghi nhận. Mỗi thứ đều hữu ích độc lập; kết hợp lại thì khép kín vòng lặp.
