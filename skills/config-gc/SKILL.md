---
name: config-gc
description: Garbage collection cho cấu hình Claude Code của bạn. Định kỳ quét ~/.claude (skill, memory, hook, permission, MCP server, cache) để tìm các mục thừa, lỗi thời, mồ côi hoặc ít giá trị, rồi hướng dẫn người dùng dọn dẹp theo kiểu xác nhận từng mục trước khi xóa. Dùng khi người dùng nói "clean up my config", "config GC", "too many skills", "audit my setup", "my .claude is bloated", hoặc yêu cầu review config định kỳ.
metadata:
  origin: ECC
---

# Config GC — Garbage Collection cho các thiết lập Claude Code

Mượn ý tưởng từ runtime garbage collection: định kỳ quét các đối tượng không còn được tham chiếu, dư thừa, hết hạn hoặc ít giá trị, rồi thu hồi không gian. Khác biệt then chốt: **ở đây, việc thu gom cần có con người trong vòng lặp. KHÔNG BAO GIỜ tự động xóa.**

## Khi nào kích hoạt

- Người dùng yêu cầu dọn dẹp, audit hoặc thu gọn cấu hình Claude Code của họ
- Người dùng phàn nàn về quá nhiều skill, hook gây nhiễu hoặc session khởi động chậm
- Đến hạn review config hằng tháng/định kỳ
- Sau khi cài một skill pack lớn (ví dụ repo này), để đối chiếu các phần chồng lấn với thiết lập hiện có

KHÔNG kích hoạt cho: dọn source code của dự án (đó là refactoring), xóa lịch sử chat, hoặc gỡ cài đặt chính Claude Code.

## Triết lý thiết kế

1. **Config chỉ-thêm sẽ bị rò rỉ.** Skill, file memory, hook và permission entry chỉ ngày càng được thêm vào. Không review định kỳ thì chúng mục nát một cách âm thầm.
2. **Audit đều đặn tốt hơn dọn một lần.** Quét mỗi ~30 ngày, mỗi lần đề xuất một lô nhỏ ứng viên.
3. **Chiến lược theo từng kênh.** Mỗi loại tích tụ (skill, hook, permission, ...) có tín hiệu lỗi thời riêng — đừng áp một rule cho mọi nơi.
4. **Soft-delete trước.** Đổi tên thành `.disabled` > chuyển vào `~/.claude/_gc_trash/` > xóa thật. Luôn giữ đường hoàn tác.
5. **Bắt buộc có con người trong vòng lặp.** Mỗi ứng viên có xác nhận `[y/n/skip]` riêng. Không có lối tắt "yes to all".
6. **Ghi log.** Mỗi lần chạy GC ghi nối tiếp vào `~/.claude/gc_log.md`: đã động vào gì, vì sao, và cách hoàn tác.

## Các kênh quét

| # | Kênh | Đường dẫn | Tín hiệu lỗi thời / dư thừa |
|---|------|-----------|-----------------------------|
| 1 | Skill | `~/.claude/skills/*/` | Tên chồng lấn nhiều; không bao giờ được kích hoạt trong transcript gần đây; lệch domain so với công việc thực tế của người dùng; SKILL.md hỏng hoặc rỗng |
| 2 | Memory | `~/.claude/**/memory/*.md` + index của nó | Nhiều index entry cho một chủ đề; nội dung mâu thuẫn với các entry mới hơn; ngày tháng đã qua; file mồ côi không có trong index; mảnh dưới 100 từ nên được gộp |
| 3 | Hook | `~/.claude/hooks/` + settings | Script có trên đĩa nhưng không hook config nào tham chiếu; phiên bản cũ đã bị bản viết lại thay thế |
| 4 | Permission | `permissions.allow` trong `settings.json` / `settings.local.json` | Entry trùng lặp; entry cụ thể đã được wildcard bao phủ (ví dụ `Bash(git push)` khi `Bash(*)` đã được cho phép); các grant một lần từ những thử nghiệm trong quá khứ |
| 5 | MCP server | `~/.claude.json` hoặc `.mcp.json` của dự án | Server không kết nối được; trùng lặp về chức năng; lâu không dùng |
| 6 | Reminder / job đã lên lịch | nơi người dùng lưu chúng | One-shot đã chạy cách đây hơn 30 ngày; job có script đích không còn tồn tại |
| 7 | Lịch sử dự án | `~/.claude/projects/*/` | Snapshot handoff cũ; bản ghi session đã bị trạng thái mới hơn thay thế |
| 8 | Runtime cache | `cache/`, `file-history/`, `logs/`, `shell-snapshots/` | Sắp xếp theo kích thước và mtime; đề xuất các mục >30 ngày tuổi và lớn |

## Workflow

1. **Quét** tất cả các kênh (hoặc tập con mà người dùng nêu tên). Thu thập ứng viên kèm: đường dẫn, kênh, tín hiệu đã gắn cờ, kích thước, thời điểm sửa đổi cuối.
2. **Xếp hạng** theo độ tin cậy (hỏng/mồ côi = cao; chỉ cũ = thấp) và trình bày dưới dạng bảng đánh số. Giới hạn mỗi lần chạy ở ~20 ứng viên — GC mang tính định kỳ, không phải toàn diện.
3. **Xác nhận từng mục một.** Với mỗi ứng viên, hiển thị bằng chứng rồi hỏi `[y/n/skip]`. Người dùng có thể dừng bất cứ lúc nào.
4. **Soft-delete các mục đã xác nhận**: ưu tiên đổi tên `.disabled` cho skill/hook và chuyển vào `_gc_trash/<date>/` cho file. Permission entry nằm trong JSON (không thể có comment): sao lưu file settings, ghi từng entry bị xóa nguyên văn vào `gc_log.md`, rồi xóa nó khỏi mảng `allow` bằng `jq`. Chỉ hard-delete khi người dùng yêu cầu rõ ràng.
5. **Ghi log** lần chạy vào `~/.claude/gc_log.md`: timestamp, các mục đã xử lý, hướng dẫn hoàn tác.
6. **Báo cáo**: dung lượng thu hồi, các kênh vẫn khỏe mạnh, ngày review tiếp theo được đề xuất.

## Ví dụ lệnh quét

Script hook mồ côi (kênh 3) — script trên đĩa mà không hook config nào tham chiếu:

```bash
for f in ~/.claude/hooks/*; do
  name=$(basename "$f")
  grep -rq "$name" ~/.claude/settings.json ~/.claude/settings.local.json 2>/dev/null \
    || echo "ORPHAN: $f"
done
```

Permission entry dư thừa (kênh 4) — trùng lặp, và các grant cụ thể bị wildcard che khuất:

```bash
jq -r '.permissions.allow[]' ~/.claude/settings.local.json | sort | uniq -d
if jq -e '.permissions.allow | index("Bash(*)")' ~/.claude/settings.local.json >/dev/null; then
  jq -r '.permissions.allow[]' ~/.claude/settings.local.json \
    | grep '^Bash(' | grep -vF 'Bash(*)'
fi
```

Các cache cũ lớn nhất (kênh 8) — dùng `du -k` thay vì `find -printf` chỉ có ở GNU, nên cũng chạy được trên macOS/BSD:

```bash
find ~/.claude/file-history ~/.claude/shell-snapshots -type f -mtime +30 \
  -exec du -k {} + 2>/dev/null | sort -rn | head -20
```

Soft-delete với đường hoàn tác (lấy ngày một lần để log không thể lệch với tên thư mục):

```bash
gc_date=$(date +%Y-%m-%d)
mkdir -p ~/.claude/_gc_trash/$gc_date
mv ~/.claude/skills/dead-skill ~/.claude/_gc_trash/$gc_date/
echo "$(date -Iseconds) moved skills/dead-skill -> _gc_trash/$gc_date/ (undo: mv back)" >> ~/.claude/gc_log.md
```

Xóa một permission entry đã xác nhận là dư thừa (JSON không có comment — sao lưu, ghi log, rồi mới sửa):

```bash
cp ~/.claude/settings.local.json ~/.claude/settings.local.json.bak
echo "$(date -Iseconds) removed permission entry: Bash(git push) (undo: restore from .bak or re-add)" >> ~/.claude/gc_log.md
jq '.permissions.allow -= ["Bash(git push)"]' ~/.claude/settings.local.json.bak \
  > ~/.claude/settings.local.json
```

## Anti-Pattern

- **Phê duyệt hàng loạt.** Hỏi "delete all 15? [y/n]" phá vỡ thiết kế. Một mục, một quyết định.
- **Hard-delete ngay lần đầu.** Nếu không có bản sao trong `_gc_trash/` hoặc đổi tên `.disabled`, bạn đã làm sai.
- **Coi "cũ" là "chết".** Một skill không được đụng tới 60 ngày có thể mang tính theo mùa (mùa thuế, review hằng quý). Tuổi là một tín hiệu, không phải bản án — đó là lý do cần con người xác nhận.
- **Dọn memory bằng cách cắt bớt.** Gộp hai file memory mâu thuẫn đòi hỏi đọc cả hai và giữ sự thật mới hơn, chứ không phải xóa file dài hơn.
- **Đụng vào bất cứ thứ gì ngoài `~/.claude`** (hoặc `.claude/` của dự án). Config GC không bao giờ lang thang vào cây source.

## Best Practice

- Chạy sau những lần bổ sung lớn, không chỉ theo lịch: cài một pack 50 skill chính là lúc xuất hiện chồng lấn với các skill hiện có.
- Khi hai skill chồng lấn, ưu tiên vô hiệu hóa skill có mô tả trigger yếu hơn — đó có lẽ là skill vốn dĩ chưa bao giờ được kích hoạt.
- Dọn permission là kênh có giá trị cao nhất trên mỗi phút bỏ ra: các allow-entry dư thừa khiến security review khó hơn.
- Giữ `gc_log.md` mãi mãi. Nó rất nhỏ, và câu hỏi "khi nào và vì sao tôi tắt hook đó" xuất hiện thường xuyên hơn bạn nghĩ.

## Skill liên quan

- `skill-stocktake` — audit *chất lượng* skill; config-gc audit *sự tồn tại* của skill. Chạy stocktake trên những gì còn sống sót sau GC.
- `workspace-surface-audit` — đối trọng theo hướng thêm: đề xuất nên cài gì. config-gc là nửa theo hướng bớt của cùng một vòng đời.
- `configure-ecc` — sau khi cài skill bằng nó, hãy chạy config-gc để đối chiếu các phần chồng lấn với thiết lập sẵn có của bạn.
- `continuous-learning` — tạo ra các file memory mà skill này sau đó audit.
- `security-review` — kết hợp tốt với kênh permission.
