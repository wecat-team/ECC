---
description: Tải file session gần nhất từ ~/.claude/session-data/ và tiếp tục công việc với đầy đủ context từ chỗ session trước kết thúc.
---

# Lệnh Resume Session

Tải trạng thái session đã lưu gần nhất và nắm rõ tình hình trước khi làm bất kỳ việc gì.
Lệnh này là đối ứng của `/save-session`.

## Khi nào dùng

- Bắt đầu session mới để tiếp tục công việc từ ngày trước
- Sau khi bắt đầu session mới do giới hạn context
- Khi bàn giao file session từ nguồn khác (chỉ cần cung cấp đường dẫn file)
- Bất cứ lúc nào bạn có file session và muốn Claude tiếp thu đầy đủ trước khi tiếp tục

## Cách dùng

```
/resume-session                                                      # loads most recent file in ~/.claude/session-data/
/resume-session 2024-01-15                                           # loads most recent session for that date
/resume-session ~/.claude/session-data/2024-01-15-abc123de-session.tmp  # loads a current short-id session file
/resume-session ~/.claude/sessions/2024-01-15-session.tmp               # loads a specific legacy-format file
```

## Quy trình

### Bước 1: Tìm file session

Nếu không có đối số:

1. Kiểm tra `~/.claude/session-data/`
2. Đọc các ứng viên `*-session.tmp` khớp và áp dụng bảng xếp hạng ứng viên bên dưới
3. Tải ứng viên xếp hạng cao nhất
4. Nếu thư mục không tồn tại hoặc không có file khớp hợp lệ, hãy báo người dùng:
   ```
   No session files found in ~/.claude/session-data/
   Run /save-session at the end of a session to create one.
   ```
   Sau đó dừng lại.

Nếu có đối số:

- Nếu nó trông như một ngày (`YYYY-MM-DD`), tìm trong `~/.claude/session-data/` trước, rồi đến thư mục legacy
  `~/.claude/sessions/`, các file khớp `YYYY-MM-DD-session.tmp` (định dạng legacy) hoặc
  `YYYY-MM-DD-<shortid>-session.tmp` (định dạng hiện tại), áp dụng bảng xếp hạng ứng viên bên dưới trên
  tất cả các file khớp, và tải ứng viên xếp hạng cao nhất của ngày đó
- Nếu nó trông như một đường dẫn file, đọc đúng file đó trực tiếp. Không áp dụng xếp hạng ứng viên hay
  thay bằng file khác, kể cả khi file được yêu cầu rỗng hoặc có file khác mới hơn
- Nếu không tìm thấy, báo cáo rõ ràng và dừng lại

#### Xếp hạng ứng viên cho tra cứu ngầm định và theo ngày

Chỉ xếp hạng các ứng viên được tự động phát hiện. KHÔNG BAO GIỜ dùng bảng xếp hạng này cho đường dẫn file được chỉ định tường minh.

1. Loại các file không đọc được, rỗng, chỉ có khoảng trắng, hoặc chỉ chứa heading, metadata,
   dấu phân cách và giá trị placeholder như `[Session context goes here]`, `- [ ]`, một dấu `-` đơn lẻ,
   hoặc `[relevant files]`.
2. Loại các bản tóm tắt được sinh tự động chỉ có một task và không có nội dung files-modified, tools-used,
   completed, in-progress, notes hoặc context-to-load nào được điền. Quy tắc cấu trúc này lọc
   các bản echo của summarizer một-tin-nhắn mà không phụ thuộc vào bất kỳ văn bản prompt cụ thể nào.
3. Giữ lại các ứng viên có nội dung thực chất được điền: công việc đã hoàn thành, công việc đang làm, ghi chú
   cụ thể cho session sau, đường dẫn context cụ thể, nhiều task, file đã sửa hoặc tool đã dùng.
4. Trong các ứng viên hợp lệ có nội dung thực chất, ưu tiên thời gian sửa đổi mới nhất.
5. Nếu thời gian sửa đổi bằng nhau, ưu tiên file có nhiều section được điền hơn, rồi nhiều nội dung không phải placeholder
   hơn, rồi dung lượng byte lớn hơn, rồi đường dẫn đã resolve nhỏ hơn theo thứ tự từ điển. Chỉ đếm các section và nội dung đã
   được điền sau khi loại bỏ heading, metadata, dấu phân cách và văn bản placeholder.
   Các tiêu chí phân xử cuối cùng này làm cho việc chọn là xác định (deterministic).

### Bước 2: Đọc toàn bộ file session

Đọc toàn bộ file. Chưa tóm tắt vội.

### Bước 3: Xác nhận sự hiểu

Phản hồi bằng một bản briefing có cấu trúc theo đúng định dạng này:

```
SESSION LOADED: [actual resolved path to the file]
════════════════════════════════════════════════

PROJECT: [project name / topic from file]

WHAT WE'RE BUILDING:
[2-3 sentence summary in your own words]

CURRENT STATE:
PASS: Working: [count] items confirmed
 In Progress: [list files that are in progress]
 Not Started: [list planned but untouched]

WHAT NOT TO RETRY:
[list every failed approach with its reason — this is critical]

OPEN QUESTIONS / BLOCKERS:
[list any blockers or unanswered questions]

NEXT STEP:
[exact next step if defined in the file]
[if not defined: "No next step defined — recommend reviewing 'What Has NOT Been Tried Yet' together before starting"]

════════════════════════════════════════════════
Ready to continue. What would you like to do?
```

### Bước 4: Chờ người dùng

KHÔNG tự động bắt đầu làm việc. KHÔNG đụng vào bất kỳ file nào. Chờ người dùng nói làm gì tiếp theo.

Nếu bước tiếp theo được định nghĩa rõ trong file session và người dùng nói "continue" hoặc "yes" hoặc tương tự — tiến hành đúng bước tiếp theo đó.

Nếu chưa có bước tiếp theo — hãy hỏi người dùng bắt đầu từ đâu, và có thể đề xuất một hướng tiếp cận từ section "What Has NOT Been Tried Yet".

---

## Edge Case

**Nhiều session trong cùng một ngày** (`2024-01-15-session.tmp`, `2024-01-15-abc123de-session.tmp`):
Áp dụng xếp hạng ứng viên trên mọi file khớp ở cả định dạng legacy và hiện tại. Một session có nội dung
thực chất PHẢI thắng một placeholder mới hơn hoặc một bản echo summarizer một-tin-nhắn; thời gian sửa đổi quyết định
giữa các ứng viên hợp lệ.

**File session tham chiếu đến các file không còn tồn tại:**
Ghi chú điều này trong briefing — "WARNING: `path/to/file.ts` referenced in session but not found on disk."

**File session cũ hơn 7 ngày:**
Ghi chú khoảng cách — "WARNING: This session is from N days ago (threshold: 7 days). Things may have changed." — rồi tiếp tục bình thường.

**Người dùng cung cấp trực tiếp đường dẫn file (ví dụ: được đồng nghiệp chuyển tiếp):**
Đọc nó và theo cùng quy trình briefing — định dạng giống nhau bất kể nguồn.

**File session rỗng hoặc sai định dạng:**
Với việc phát hiện ngầm định hoặc theo ngày, loại nó và tiếp tục xếp hạng các ứng viên còn lại. Nếu không còn
ứng viên hợp lệ, báo cáo: "Session files were found but appear empty or unreadable. You may
need to create a new one with /save-session." Với đường dẫn tường minh, báo cáo rằng file được yêu cầu
rỗng hoặc không đọc được mà không tải file thay thế.

---

## Ví dụ Output

```
SESSION LOADED: /Users/you/.claude/session-data/2024-01-15-abc123de-session.tmp
════════════════════════════════════════════════

PROJECT: my-app — JWT Authentication

WHAT WE'RE BUILDING:
User authentication with JWT tokens stored in httpOnly cookies.
Register and login endpoints are partially done. Route protection
via middleware hasn't been started yet.

CURRENT STATE:
PASS: Working: 3 items (register endpoint, JWT generation, password hashing)
 In Progress: app/api/auth/login/route.ts (token works, cookie not set yet)
 Not Started: middleware.ts, app/login/page.tsx

WHAT NOT TO RETRY:
FAIL: Next-Auth — conflicts with custom Prisma adapter, threw adapter error on every request
FAIL: localStorage for JWT — causes SSR hydration mismatch, incompatible with Next.js

OPEN QUESTIONS / BLOCKERS:
- Does cookies().set() work inside a Route Handler or only Server Actions?

NEXT STEP:
In app/api/auth/login/route.ts — set the JWT as an httpOnly cookie using
cookies().set('token', jwt, { httpOnly: true, secure: true, sameSite: 'strict' })
then test with Postman for a Set-Cookie header in the response.

════════════════════════════════════════════════
Ready to continue. What would you like to do?
```

---

## Ghi chú

- KHÔNG BAO GIỜ sửa file session khi tải nó — đó là bản ghi lịch sử chỉ đọc
- Định dạng briefing là cố định — không bỏ qua section nào dù nó rỗng
- "What Not To Retry" luôn phải được hiển thị, kể cả khi chỉ ghi "None" — nó quá quan trọng để bỏ lỡ
- Sau khi resume, người dùng có thể muốn chạy `/save-session` lần nữa ở cuối session mới để tạo một file mới có ngày
