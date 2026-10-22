---
name: strategic-compact
description: Gợi ý compact context thủ công tại các điểm hợp lý để giữ context xuyên suốt các giai đoạn của tác vụ, thay vì auto-compaction tùy tiện. Dùng khi một phiên làm việc sắp chạm giới hạn context và một giai đoạn của tác vụ là thời điểm tự nhiên để compact.
metadata:
  origin: ECC
---

# Skill Strategic Compact

Gợi ý chạy `/compact` thủ công tại các điểm chiến lược trong workflow của bạn thay vì dựa vào auto-compaction tùy tiện.

## Khi nào kích hoạt

- Chạy các phiên dài sắp chạm giới hạn context (200K+ token)
- Làm việc trên các tác vụ nhiều giai đoạn (research → plan → implement → test)
- Chuyển đổi giữa các tác vụ không liên quan trong cùng một phiên
- Sau khi hoàn thành một cột mốc lớn và bắt đầu công việc mới
- Khi phản hồi chậm lại hoặc kém mạch lạc hơn (áp lực context)

## Vì sao cần Strategic Compaction?

Auto-compaction kích hoạt ở những thời điểm tùy ý:
- Thường là giữa chừng một tác vụ, làm mất context quan trọng
- Không nhận biết được ranh giới logic của tác vụ
- Có thể làm gián đoạn các thao tác nhiều bước phức tạp

Strategic compaction tại các ranh giới logic:
- **Sau khi khám phá, trước khi thực thi** — Compact context nghiên cứu, giữ lại kế hoạch triển khai
- **Sau khi hoàn thành một cột mốc** — Khởi đầu mới cho giai đoạn tiếp theo
- **Trước những chuyển dịch context lớn** — Xóa context khám phá trước khi sang một tác vụ khác

## Cách hoạt động

Script `suggest-compact.js` chạy ở PreToolUse (Edit/Write) và kết hợp hai tín hiệu:

1. **Kích thước context (chính)** — Đọc bản ghi `usage` mới nhất từ transcript của phiên (`transcript_path` trong payload của hook) và cộng `input_tokens + cache_read_input_tokens + cache_creation_input_tokens` (kích thước context thực sự của lượt đó). Gợi ý `/compact` tại ngưỡng co giãn theo cửa sổ — 160k token với cửa sổ 200k, 250k với cửa sổ 1M (phát hiện từ marker model `[1m]`, hoặc suy ra khi số token quan sát được đã vượt 200k) — và nhắc lại sau mỗi 60k token context tăng thêm
2. **Số lần gọi tool (phụ)** — Đếm số lần gọi tool trong phiên; gợi ý tại một ngưỡng có thể cấu hình (mặc định: 50 lần gọi), sau đó cứ mỗi 25 lần gọi

Chỉ riêng số lần gọi tool là một chỉ báo yếu cho áp lực cửa sổ: vài lần đọc file lớn hoặc phản hồi MCP có thể lấp đầy cửa sổ chỉ trong rất ít lần gọi, trong khi nhiều lần gọi nhỏ có thể vượt 50 mà cửa sổ gần như trống. Tín hiệu kích thước context sẽ kích hoạt khi điều đó thực sự quan trọng.

## Thiết lập Hook

**Cài dưới dạng plugin?** Không cần thiết lập gì. `hooks/hooks.json` của plugin đã đăng ký `suggest-compact.js` (hook id `pre:edit-write:suggest-compact`, hoạt động trong các hook profile `standard` và `strict`). KHÔNG sao chép khối bên dưới vào `~/.claude/settings.json` — `~/.claude/scripts/` không tồn tại khi cài plugin, và nhân đôi một plugin hook sẽ gây thực thi hai lần.

**Nếu cài thủ công** (`./install.sh`), thêm vào `~/.claude/settings.json` của bạn:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Edit",
        "hooks": [{ "type": "command", "command": "node ~/.claude/scripts/hooks/suggest-compact.js" }]
      },
      {
        "matcher": "Write",
        "hooks": [{ "type": "command", "command": "node ~/.claude/scripts/hooks/suggest-compact.js" }]
      }
    ]
  }
}
```

## Cấu hình

Biến môi trường:
- `COMPACT_THRESHOLD` — Số lần gọi tool trước lần gợi ý đầu tiên (mặc định: 50)
- `COMPACT_CONTEXT_THRESHOLD` — Số token context trước khi gợi ý theo kích thước context (mặc định: 160000 với cửa sổ 200k, 250000 với cửa sổ 1M; `0` tắt tín hiệu context)
- `COMPACT_CONTEXT_INTERVAL` — Số token context tăng thêm trước khi gợi ý được lặp lại (mặc định: 60000)
- `COMPACT_STATE_TTL_DAYS` — Số ngày trước khi các file state cũ của từng phiên trong thư mục temp bị dọn (mặc định: 14)
- `ECC_CONTEXT_WINDOW_TOKENS` — Kích thước cửa sổ context tường minh, tính bằng token, ghi đè việc tự phát hiện. Hãy đặt biến này cho các model cửa sổ lớn mà id được báo cáo không có marker `[1m]` (ví dụ Opus 4.x 400k, hoặc một dòng model cửa sổ 1M mới) để ngưỡng co giãn theo cửa sổ thực thay vì mặc định 200k và phóng đại mức sử dụng context.
- `CLAUDE_CODE_AUTO_COMPACT_WINDOW` — Biến ghi đè kích thước cửa sổ gốc của Claude Code, tính bằng token; được dùng làm phương án dự phòng khi `ECC_CONTEXT_WINDOW_TOKENS` chưa được đặt.

> Cửa sổ context ngoài ra được tự phát hiện từ marker model `[1m]` hoặc suy ra khi số token quan sát được đã vượt 200k. Với model cửa sổ lớn không có tín hiệu nào trong hai tín hiệu đó, hãy đặt một trong các biến ghi đè ở trên để gợi ý `/compact` kích hoạt đúng thời điểm.

## Hướng dẫn quyết định Compaction

Dùng bảng này để quyết định khi nào nên compact:

| Chuyển giai đoạn | Compact? | Vì sao |
|-----------------|----------|-----|
| Research → Planning | Có | Context nghiên cứu cồng kềnh; kế hoạch là đầu ra đã được chắt lọc |
| Planning → Implementation | Có | Kế hoạch đã được ghi lại (vào một file, hoặc danh sách task nếu có); giải phóng context cho code |
| Implementation → Testing | Có thể | Giữ lại nếu test tham chiếu code gần đây; compact nếu chuyển trọng tâm |
| Debugging → Tính năng tiếp theo | Có | Dấu vết debug làm ô nhiễm context cho công việc không liên quan |
| Giữa chừng implementation | Không | Mất tên biến, đường dẫn file và state dở dang là rất tốn kém |
| Sau một hướng tiếp cận thất bại | Có | Xóa suy luận ngõ cụt trước khi thử hướng tiếp cận mới |

## Điều gì tồn tại sau Compaction

Hiểu điều gì được giữ lại giúp bạn compact một cách tự tin:

| Được giữ lại | Bị mất |
|----------|------|
| Chỉ dẫn trong CLAUDE.md | Suy luận và phân tích trung gian |
| File trên đĩa | Nội dung file mà bạn đã đọc trước đó |
| File memory (`~/.claude/memory/`) | Context hội thoại nhiều bước |
| Trạng thái Git (commit, branch) | Lịch sử và số lần gọi tool |
| Danh sách task — **chỉ khi bạn có các tool todo** (xem bên dưới) | Các sở thích tinh tế của người dùng được nói bằng lời |

> ### Đừng dựa vào việc danh sách task còn tồn tại — nó có thể không có
>
> Claude Code **2.1.233 đã gỡ các tool todo/task theo mặc định** trên Opus 4.8, Sonnet 5,
> Fable 5, Mythos 5 và các model mới hơn (`TodoWrite`, `TaskCreate/Get/Update/List`).
> `CLAUDE_CODE_ENABLE_TODO_TOOLS=1` đưa chúng trở lại, nhưng đó là một thiết lập
> môi trường theo từng máy — **nó không đi kèm với skill này**, nên bạn không thể giả định
> người đọc có nó.
>
> Điều này quan trọng vì "todo list của tôi vẫn còn sau compaction" là lý do khiến người ta compact
> *thay vì* ghi state ra. Nếu các tool vắng mặt thì không có danh sách nào để mà tồn tại,
> và kế hoạch đơn giản là biến mất. **Hãy ghi kế hoạch vào một file trước khi compact** — một file
> tồn tại trên mọi phiên bản và mọi model. Hãy coi danh sách task là một tiện ích
> có thể thiếu, không bao giờ là bản ghi bền vững của bạn.

## Best Practice

1. **Compact sau khi lập kế hoạch** — Khi kế hoạch đã được chốt **và ghi vào một file**, hãy compact để bắt đầu mới
2. **Compact sau khi debug** — Xóa context xử lý lỗi trước khi tiếp tục
3. **Không compact giữa chừng implementation** — Giữ context cho các thay đổi liên quan
4. **Đọc gợi ý** — Hook cho bạn biết *khi nào*, bạn quyết định *có nên không*
5. **Ghi trước khi compact** — Lưu context quan trọng vào file hoặc memory trước khi compact
6. **Dùng `/compact` kèm bản tóm tắt** — Thêm một thông điệp tùy chỉnh: `/compact Focus on implementing auth middleware next`

## Pattern tối ưu Token

### Lazy Loading bằng bảng Trigger
Thay vì nạp toàn bộ nội dung skill khi bắt đầu phiên, hãy dùng một bảng trigger ánh xạ từ khóa tới đường dẫn skill. Skill chỉ được nạp khi được kích hoạt, giúp giảm context nền (baseline) hơn 50%:

| Trigger | Skill | Nạp khi |
|---------|-------|-----------|
| "test", "tdd", "coverage" | tdd-workflow | Người dùng nhắc đến testing |
| "security", "auth", "xss" | security-review | Công việc liên quan đến bảo mật |
| "deploy", "ci/cd" | deployment-patterns | Bối cảnh deployment |

### Nhận biết thành phần của Context
Theo dõi những gì đang tiêu tốn cửa sổ context của bạn:
- **File CLAUDE.md** — Luôn được nạp, hãy giữ gọn
- **Skill đã nạp** — Mỗi skill thêm 1-5K token
- **Lịch sử hội thoại** — Tăng theo mỗi lượt trao đổi
- **Kết quả tool** — Đọc file, kết quả tìm kiếm làm tăng khối lượng

### Phát hiện chỉ dẫn trùng lặp
Các nguồn phổ biến gây trùng lặp context:
- Cùng một rule ở cả `~/.claude/rules/` và `.claude/rules/` của dự án
- Skill lặp lại các chỉ dẫn trong CLAUDE.md
- Nhiều skill bao phủ các domain chồng lấn nhau

### Công cụ tối ưu Context
- MCP `token-optimizer` — Giảm token tự động trên 95% thông qua loại bỏ nội dung trùng lặp
- `context-mode` — Ảo hóa context (đã minh chứng từ 315KB xuống 5.4KB)

## Liên quan

- [The Longform Guide](https://x.com/affaanmustafa/status/2014040193557471352) — Phần Token optimization
- Hook lưu trữ bền vững memory — Cho state cần tồn tại qua compaction
- Skill `continuous-learning` — Trích xuất pattern trước khi phiên kết thúc
