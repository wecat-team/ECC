---
name: inherit-legacy-style
description: "Ngăn AI lệch phong cách (style drift) trên các dự án legacy bằng cách quét codebase để tìm các convention ngầm định, giải quyết xung đột với operator từng cái một, và viết một file .ai-style-rules.md có thể thực thi (Golden Files, quy tắc đặt tên, DONTs) cùng một CLAUDE.md hook tùy chọn. Dùng khi đưa AI agent vào một codebase legacy viết tay hoặc trích xuất các quy tắc code bất thành văn của dự án."
metadata:
  origin: community
allowed-tools: Read, Glob, Grep, Bash, Edit, Write, AskUserQuestion
---

# Inherit Legacy Style

Ngăn AI lệch phong cách code trong các dự án legacy bằng cách quét codebase để tìm các convention ngầm định trên 4 chiều meta-architecture, giải quyết xung đột với người dùng từng cái một, và kết tinh sự đồng thuận thành một file `.ai-style-rules.md` có thể thực thi. Hoàn toàn không phụ thuộc ngôn ngữ và framework.

## Khi nào kích hoạt

- Người dùng gõ `/inherit-legacy-style`
- Người dùng đề cập đến việc đưa AI vào một dự án legacy viết tay
- Người dùng lo ngại code do AI sinh ra "lệch" (drift) khỏi các convention hiện có của dự án
- Người dùng muốn trích xuất và hệ thống hóa các quy tắc code ngầm định của dự án

## Khi nào dùng

Dùng skill này khi bạn cần giữ nguyên phong cách dự án legacy và ngăn AI sinh code lệch phong cách. Xem **Khi nào kích hoạt** ở trên để biết điều kiện kích hoạt.

## Điều kiện tiên quyết

- Git (khuyến nghị; dự án không dùng Git sẽ dùng timestamp của file cho chế độ incremental)
- Quyền Read/Write tại thư mục gốc dự án (sinh ra `.ai-style-rules.md` và tùy chọn `CLAUDE.md`)

## Workflow

### Bước 0 — Tự động phát hiện chế độ

Kiểm tra âm thầm xem có `.ai-style-rules.md` ở thư mục gốc dự án hay không:

| File tồn tại? | Chế độ |
|---|---|
| Không | **Nhánh A — Quét toàn bộ lần đầu (First-time Full-Scan)** |
| Có | **Nhánh B — Dò tăng dần (Incremental Sniff)** |

Thông báo chế độ trong một dòng rồi tiếp tục — KHÔNG BAO GIỜ yêu cầu người dùng chọn.

### Nhánh A — Quét toàn bộ lần đầu

**1. Đo quy mô, chọn tầng quét**

```bash
git ls-files | grep -cE '\.(js|ts|jsx|tsx|vue|py|go|rs|java|kt|rb|php|cs|swift|c|cpp|h)$'
```

| Tầng | File nguồn | Chiến lược |
|---|---|---|
| Nhỏ | ≲ 50 | Đọc kỹ toàn bộ mọi file nguồn |
| Vừa | 50–500 | Tầng hạ tầng = đọc toàn bộ; tầng nghiệp vụ = lấy mẫu 2–3 file cho mỗi chiều |
| Lớn | ≳ 500 | Lấy mẫu nghiêm ngặt + giới hạn ngân sách; tóm tắt `--stat` trước, sau đó đọc có mục tiêu |

**2. Quét theo 4 chiều**

1. **File Anatomy** — thứ tự khai báo trong file (imports → types → main logic → helpers → export)
2. **State & Control Flow** — quy ước đặt tên cho async state, phân trang, flag
3. **Infrastructure** — nơi đặt các util cross-cutting (interceptor, formatter, middleware)
4. **Error Handling** — try/catch so với global interceptor so với trả về Result; thói quen kiểm tra null

**3. Áp dụng giảm nhiễu theo ngưỡng tín hiệu**

Trước khi làm gián đoạn người dùng, hãy đánh giá cường độ tín hiệu:

- **Tín hiệu yếu** → tự động bỏ qua: thiểu số <5% VÀ số lượng <10 → đa số thắng, thiểu số đưa vào DONTs
- **Tín hiệu mạnh** → grill (hỏi dồn): chia gần đều, hoặc rẽ nhánh ngữ nghĩa trên một chiều cốt lõi
- **Ngoại lệ dự án nhỏ**: file nguồn ≲50, "3 so với 2" KHÔNG phải đa số → hãy grill

**4. Giải quyết xung đột từng cái một (Grilling Protocol)**

Với mỗi xung đột tín hiệu mạnh, đưa ra đúng MỘT câu hỏi với 4 lựa chọn:

> Evidence: `pathA` uses style X, `pathB` uses style Y
> WARNING: Risk: mixing both fractures the project style
> Choose: `1` follow X  `2` follow Y  `3` this is evolution, update rules  `4` I have a new rule

Tạm dừng cho đến khi người dùng trả lời, sau đó mới chuyển sang xung đột tiếp theo. KHÔNG BAO GIỜ chồng nhiều câu hỏi.

**5. Sinh `.ai-style-rules.md`** với ba mục bắt buộc:
- **[Golden Files]** — đường dẫn mẫu mực thực tế, chú thích những gì chúng minh họa
- **[Naming & State-Control Rules]** — các convention cụ thể, kiểm tra được
- **[DONTs]** — các anti-pattern không được phép lan truyền

**6. Cài đặt hook bền vững**

Hỏi người dùng về mức độ cưỡng chế (dùng `AskUserQuestion`):

| Lựa chọn | Cơ chế |
|---|---|
| **1** Soft hook (khuyến nghị) | Ghi tham chiếu `@.ai-style-rules.md` vào `CLAUDE.md` của dự án |
| **2** Hard hook | Soft hook + Hook `PreToolUse[Write\|Edit\|MultiEdit]` trong `settings.json` |
| **3** Không hook | Giữ file rules; người dùng tham chiếu thủ công |

### Nhánh B — Dò tăng dần

1. Đọc `.ai-style-rules.md` hiện có; nếu nó có commit fingerprint, chạy `git diff <last_hash> HEAD --stat` để xác định chính xác phần delta
2. Đọc các thay đổi Git gần đây (`git log -3 --stat` → kiểm tra các file đáng ngờ khi cần)
3. Với diff quá lớn (>hàng trăm file): chỉ tóm tắt `--stat` + lấy mẫu các thay đổi lớn nhất
4. So sánh code mới với các rule đã ghi → xung đột đi qua Grilling Protocol
5. Nối thêm evolution log vào cuối `.ai-style-rules.md` (KHÔNG BAO GIỜ ghi đè các rule cũ)

### Cưỡng chế ở mỗi lượt (Per-Turn Enforcement)

Khi `.ai-style-rules.md` có trong context (được nạp qua CLAUDE.md), mọi task viết code phải mở đầu bằng một **tuyên bố tuân thủ (compliance declaration)** trong chuỗi suy luận, nêu rõ exemplar đang được theo và các DONTs đang được tránh.

## Cách hoạt động

Skill này tự động phát hiện lần chạy là lần đầu hay tăng dần dựa vào sự hiện diện của `.ai-style-rules.md`:

- **Lần đầu (Nhánh A)** — Đo quy mô dự án, quét codebase trên 4 chiều meta-architecture (File Anatomy, State & Control Flow, Infrastructure, Error Handling), áp dụng giảm nhiễu theo ngưỡng tín hiệu để loại bỏ các xung đột yếu, giải quyết các xung đột tín hiệu mạnh từng cái một cùng người dùng, sinh `.ai-style-rules.md` với Golden Files / Naming Rules / DONTs, và đề xuất các hook cưỡng chế tùy chọn.
- **Tăng dần (Nhánh B)** — Đọc các rule hiện có, kiểm tra các Git diff gần đây để tìm pattern mới hoặc xung đột, chạy cùng grilling protocol từng cái một cho mọi xung đột tìm thấy, và nối thêm evolution log mà không ghi đè các rule hiện có.
- **Cưỡng chế ở mỗi lượt** — Khi được hook qua `CLAUDE.md`, mọi task viết code mở đầu bằng một tuyên bố tuân thủ nêu rõ exemplar đã theo và các DONTs đã tránh.

## Đặc tả đầu ra

- `.ai-style-rules.md` ở thư mục gốc dự án (có commit fingerprint + tầng quy mô trong header)
- Tùy chọn `CLAUDE.md` có tham chiếu `@.ai-style-rules.md`
- Evolution log được nối thêm dưới dạng các mục `### [YYYY-MM-DD] Style Evolution Log`

## Anti-Pattern

- FAIL: KHÔNG bỏ qua bước đo quy mô — lấy mẫu một dự án 30 file sẽ "bỏ đói" nó; quét toàn bộ một repo 5.000 file sẽ làm bùng nổ
- FAIL: KHÔNG chồng nhiều câu hỏi xung đột cùng lúc — grilling nghiêm ngặt là từng cái một
- FAIL: KHÔNG ghi đè các rule cũ ở chế độ incremental — luôn nối thêm evolution log
- FAIL: KHÔNG mặc định dùng "hard hook" mà không hỏi — mức độ cưỡng chế là quyết định của người dùng
- FAIL: KHÔNG đánh giá chất lượng cú pháp hay tech stack — skill này chỉ căn chỉnh meta-architecture
- FAIL: KHÔNG sao chép bug từ các file exemplar — tái sử dụng cấu trúc, đánh dấu khuyết điểm

## Best Practice

- Thông báo chế độ đã phát hiện (lần đầu so với incremental) và tầng quy mô trong một dòng trước khi quét
- Với dự án lớn, đọc tóm tắt `--stat` trước, sau đó `Read` có mục tiêu trên các file đáng ngờ
- Để ngưỡng tín hiệu xử lý nhiễu — một phân chia đặt tên 843-so-với-8 nên tự động giải quyết mà không làm gián đoạn người dùng
- Khi nghi ngờ về cường độ tín hiệu, hãy nghiêng về phía hỏi
- Soft hook trong CLAUDE.md (`@.ai-style-rules.md`) thường là đủ; chỉ dùng hard hook khi người dùng muốn cưỡng chế cơ học

## Skill liên quan

- `init` — khởi tạo CLAUDE.md mới với tài liệu codebase
- `code-review` — review diff về tính đúng đắn và các vấn đề style
- `simplify` — review code để tìm cơ hội tái sử dụng và đơn giản hóa

## Ví dụ

1. **Onboarding lần đầu**
   - User: "Help me onboard AI to this older codebase without changing its style."
   - Hành động: Chạy full-scan Nhánh A → đo quy mô → quét 4 chiều → grill các xung đột → sinh `.ai-style-rules.md` → đề xuất mức độ hook (soft/hard/none).

2. **Cập nhật tăng dần sau khi team thay đổi**
   - User: "We added a new module; keep existing style rules intact."
   - Hành động: Chạy incremental sniff Nhánh B → so sánh Git delta với các rule đã ghi → grill mọi xung đột mới → nối thêm evolution log mà không ghi đè.

3. **Cưỡng chế DONTs qua CLAUDE.md**
   - User: "Make sure all new code stays consistent with the project's rules."
   - Hành động: Cài soft hook → `.ai-style-rules.md` được nạp tự động mỗi phiên → mọi task viết code mở đầu bằng tuyên bố tuân thủ, tái sử dụng các pattern exemplar và tránh DONTs.
