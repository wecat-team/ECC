---
description: Lưu trạng thái session hiện tại vào một file có ngày trong ~/.claude/session-data/ để có thể tiếp tục công việc ở session sau với đầy đủ context.
---

# Lệnh Save Session

Ghi lại mọi thứ đã xảy ra trong session này — đã xây dựng gì, cái gì hiệu quả, cái gì thất bại, còn lại gì — và ghi vào một file có ngày để session tiếp theo có thể tiếp tục chính xác từ chỗ session này dừng lại.

## Khi nào dùng

- Cuối một phiên làm việc trước khi đóng Claude Code
- Trước khi chạm giới hạn context (chạy lệnh này trước, rồi bắt đầu session mới)
- Sau khi giải quyết một vấn đề phức tạp mà bạn muốn ghi nhớ
- Bất cứ lúc nào cần bàn giao context cho session sau

## Quy trình

### Bước 1: Thu thập context

Trước khi ghi file, hãy thu thập:

- Đọc tất cả file đã sửa trong session này (dùng git diff hoặc nhớ lại từ cuộc hội thoại)
- Xem lại những gì đã thảo luận, đã thử và đã quyết định
- Ghi chú mọi lỗi gặp phải và cách chúng được giải quyết (hoặc chưa)
- Kiểm tra trạng thái test/build hiện tại nếu liên quan

### Bước 2: Tạo thư mục sessions nếu chưa tồn tại

Tạo thư mục sessions chuẩn trong thư mục home của Claude của người dùng:

```bash
mkdir -p ~/.claude/session-data
```

### Bước 3: Ghi file session

Tạo `~/.claude/session-data/YYYY-MM-DD-<short-id>-session.tmp`, dùng ngày thực tế của hôm nay và một short-id thỏa các quy tắc được `SESSION_FILENAME_REGEX` trong `session-manager.js` áp dụng:

- Ký tự tương thích: chữ cái `a-z` / `A-Z`, chữ số `0-9`, dấu gạch ngang `-`, dấu gạch dưới `_`
- Độ dài tối thiểu tương thích: 1 ký tự
- Phong cách khuyến nghị cho file mới: chữ thường, chữ số và dấu gạch ngang với 8+ ký tự để tránh trùng lặp

Ví dụ hợp lệ: `abc123de`, `a1b2c3d4`, `frontend-worktree-1`, `ChezMoi_2`
Tránh cho file mới: `A`, `test_id1`, `ABC123de`

Ví dụ tên file hợp lệ đầy đủ: `2024-01-15-abc123de-session.tmp`

Tên file legacy `YYYY-MM-DD-session.tmp` vẫn hợp lệ, nhưng các file session mới nên ưu tiên dạng short-id để tránh trùng lặp trong cùng ngày.

### Bước 4: Điền vào file tất cả các section bên dưới

Hãy viết trung thực từng section. Không bỏ qua section nào — hãy viết "Nothing yet" hoặc "N/A" nếu một section thực sự không có nội dung. Một file không đầy đủ còn tệ hơn một section rỗng nhưng trung thực.

### Bước 5: Hiển thị file cho người dùng

Sau khi ghi, hiển thị toàn bộ nội dung và hỏi:

```
Session saved to [actual resolved path to the session file]

Does this look accurate? Anything to correct or add before we close?
```

Chờ xác nhận. Chỉnh sửa nếu được yêu cầu.

---

## Định dạng file session

```markdown
# Session: YYYY-MM-DD

**Started:** [approximate time if known]
**Last Updated:** [current time]
**Project:** [project name or path]
**Topic:** [one-line summary of what this session was about]

---

## What We Are Building

[1-3 paragraphs describing the feature, bug fix, or task. Include enough
context that someone with zero memory of this session can understand the goal.
Include: what it does, why it's needed, how it fits into the larger system.]

---

## What WORKED (with evidence)

[List only things that are confirmed working. For each item include WHY you
know it works — test passed, ran in browser, Postman returned 200, etc.
Without evidence, move it to "Not Tried Yet" instead.]

- **[thing that works]** — confirmed by: [specific evidence]
- **[thing that works]** — confirmed by: [specific evidence]

If nothing is confirmed working yet: "Nothing confirmed working yet — all approaches still in progress or untested."

---

## What Did NOT Work (and why)

[This is the most important section. List every approach tried that failed.
For each failure write the EXACT reason so the next session doesn't retry it.
Be specific: "threw X error because Y" is useful. "didn't work" is not.]

- **[approach tried]** — failed because: [exact reason / error message]
- **[approach tried]** — failed because: [exact reason / error message]

If nothing failed: "No failed approaches yet."

---

## What Has NOT Been Tried Yet

[Approaches that seem promising but haven't been attempted. Ideas from the
conversation. Alternative solutions worth exploring. Be specific enough that
the next session knows exactly what to try.]

- [approach / idea]
- [approach / idea]

If nothing is queued: "No specific untried approaches identified."

---

## Current State of Files

[Every file touched this session. Be precise about what state each file is in.]

| File              | Status         | Notes                      |
| ----------------- | -------------- | -------------------------- |
| `path/to/file.ts` | PASS: Complete    | [what it does]             |
| `path/to/file.ts` |  In Progress | [what's done, what's left] |
| `path/to/file.ts` | FAIL: Broken      | [what's wrong]             |
| `path/to/file.ts` |  Not Started | [planned but not touched]  |

If no files were touched: "No files modified this session."

---

## Decisions Made

[Architecture choices, tradeoffs accepted, approaches chosen and why.
These prevent the next session from relitigating settled decisions.]

- **[decision]** — reason: [why this was chosen over alternatives]

If no significant decisions: "No major decisions made this session."

---

## Blockers & Open Questions

[Anything unresolved that the next session needs to address or investigate.
Questions that came up but weren't answered. External dependencies waiting on.]

- [blocker / open question]

If none: "No active blockers."

---

## Exact Next Step

[If known: The single most important thing to do when resuming. Be precise
enough that resuming requires zero thinking about where to start.]

[If not known: "Next step not determined — review 'What Has NOT Been Tried Yet'
and 'Blockers' sections to decide on direction before starting."]

---

## Environment & Setup Notes

[Only fill this if relevant — commands needed to run the project, env vars
required, services that need to be running, etc. Skip if standard setup.]

[If none: omit this section entirely.]
```

---

## Ví dụ Output

```markdown
# Session: 2024-01-15

**Started:** ~2pm
**Last Updated:** 5:30pm
**Project:** my-app
**Topic:** Building JWT authentication with httpOnly cookies

---

## What We Are Building

User authentication system for the Next.js app. Users register with email/password,
receive a JWT stored in an httpOnly cookie (not localStorage), and protected routes
check for a valid token via middleware. The goal is session persistence across browser
refreshes without exposing the token to JavaScript.

---

## What WORKED (with evidence)

- **`/api/auth/register` endpoint** — confirmed by: Postman POST returns 200 with user
  object, row visible in Supabase dashboard, bcrypt hash stored correctly
- **JWT generation in `lib/auth.ts`** — confirmed by: unit test passes
  (`npm test -- auth.test.ts`), decoded token at jwt.io shows correct payload
- **Password hashing** — confirmed by: `bcrypt.compare()` returns true in test

---

## What Did NOT Work (and why)

- **Next-Auth library** — failed because: conflicts with our custom Prisma adapter,
  threw "Cannot use adapter with credentials provider in this configuration" on every
  request. Not worth debugging — too opinionated for our setup.
- **Storing JWT in localStorage** — failed because: SSR renders happen before
  localStorage is available, caused React hydration mismatch error on every page load.
  This approach is fundamentally incompatible with Next.js SSR.

---

## What Has NOT Been Tried Yet

- Store JWT as httpOnly cookie in the login route response (most likely solution)
- Use `cookies()` from `next/headers` to read token in server components
- Write middleware.ts to protect routes by checking cookie existence

---

## Current State of Files

| File                             | Status         | Notes                                           |
| -------------------------------- | -------------- | ----------------------------------------------- |
| `app/api/auth/register/route.ts` | PASS: Complete    | Works, tested                                   |
| `app/api/auth/login/route.ts`    |  In Progress | Token generates but not setting cookie yet      |
| `lib/auth.ts`                    | PASS: Complete    | JWT helpers, all tested                         |
| `middleware.ts`                  |  Not Started | Route protection, needs cookie read logic first |
| `app/login/page.tsx`             |  Not Started | UI not started                                  |

---

## Decisions Made

- **httpOnly cookie over localStorage** — reason: prevents XSS token theft, works with SSR
- **Custom auth over Next-Auth** — reason: Next-Auth conflicts with our Prisma setup, not worth the fight

---

## Blockers & Open Questions

- Does `cookies().set()` work inside a Route Handler or only in Server Actions? Need to verify.

---

## Exact Next Step

In `app/api/auth/login/route.ts`, after generating the JWT, set it as an httpOnly
cookie using `cookies().set('token', jwt, { httpOnly: true, secure: true, sameSite: 'strict' })`.
Then test with Postman — the response should include a `Set-Cookie` header.
```

---

## Ghi chú

- Mỗi session có file riêng — KHÔNG BAO GIỜ ghi nối vào file của session trước
- Section "What Did NOT Work" là quan trọng nhất — nếu thiếu nó, các session sau sẽ thử lại một cách mù quáng những cách tiếp cận đã thất bại
- Nếu người dùng yêu cầu lưu giữa chừng session (không chỉ ở cuối), hãy lưu những gì đã biết đến lúc đó và đánh dấu rõ các mục đang thực hiện
- File này được thiết kế để Claude đọc ở đầu session tiếp theo qua `/resume-session`
- Dùng session store global chuẩn: `~/.claude/session-data/`
- Ưu tiên dạng tên file short-id (`YYYY-MM-DD-<short-id>-session.tmp`) cho mọi file session mới
