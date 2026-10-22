---
description: Trả lời nhanh một câu hỏi phụ mà không làm gián đoạn hay mất context của tác vụ hiện tại. Tự động tiếp tục công việc sau khi trả lời.
---

# Lệnh Aside

Đặt câu hỏi giữa chừng khi đang làm tác vụ và nhận câu trả lời tập trung ngay lập tức — rồi tiếp tục đúng chỗ đã dừng. Tác vụ, file và context hiện tại không bao giờ bị thay đổi.

## Khi nào dùng

- Bạn tò mò về điều gì đó trong lúc Claude đang làm việc và không muốn mất đà
- Bạn cần một lời giải thích nhanh về đoạn code Claude đang chỉnh sửa
- Bạn muốn một ý kiến thứ hai hoặc làm rõ một quyết định mà không làm lệch tác vụ
- Bạn cần hiểu một lỗi, khái niệm hoặc pattern trước khi Claude tiếp tục
- Bạn muốn hỏi điều không liên quan đến tác vụ hiện tại mà không phải mở session mới

## Cách dùng

```
/aside <your question>
/aside what does this function actually return?
/aside is this pattern thread-safe?
/aside why are we using X instead of Y here?
/aside what's the difference between foo() and bar()?
/aside should we be worried about the N+1 query we just added?
```

## Quy trình

### Bước 1: Đóng băng trạng thái tác vụ hiện tại

Trước khi trả lời bất cứ điều gì, hãy ghi nhớ:
- Tác vụ đang thực hiện là gì? (file, tính năng hoặc vấn đề nào đang được xử lý)
- Bước nào đang diễn ra tại thời điểm `/aside` được gọi?
- Điều gì sắp xảy ra tiếp theo?

KHÔNG chạm vào, chỉnh sửa, tạo hoặc xóa bất kỳ file nào trong lúc aside.

### Bước 2: Trả lời trực tiếp câu hỏi

Trả lời câu hỏi dưới dạng ngắn gọn nhất mà vẫn đầy đủ và hữu ích.

- Mở đầu bằng câu trả lời, không phải lập luận
- Giữ ngắn gọn — nếu cần giải thích đầy đủ, đề nghị đi sâu hơn sau khi xong tác vụ
- Nếu câu hỏi liên quan đến file hoặc code đang làm việc, hãy tham chiếu chính xác (đường dẫn file và số dòng nếu liên quan)
- Nếu để trả lời cần đọc một file, hãy đọc — nhưng chỉ đọc, không bao giờ ghi

Định dạng phản hồi như sau:

```
ASIDE: [restate the question briefly]

[Your answer here]

— Back to task: [one-line description of what was being done]
```

### Bước 3: Tiếp tục tác vụ chính

Sau khi đưa ra câu trả lời, hãy tiếp tục ngay tác vụ đang làm từ đúng điểm đã tạm dừng. Không xin phép để tiếp tục, trừ khi câu trả lời aside làm lộ ra một blocker hoặc lý do để cân nhắc lại cách tiếp cận hiện tại (xem Edge Case).

---

## Edge Case

**Không có câu hỏi (`/aside` không kèm gì phía sau):**
Hãy phản hồi:
```
ASIDE: no question provided

What would you like to know? (ask your question and I'll answer without losing the current task context)

— Back to task: [one-line description of what was being done]
```

**Câu hỏi làm lộ một vấn đề tiềm ẩn với tác vụ hiện tại:**
Hãy đánh dấu rõ ràng trước khi tiếp tục:
```
ASIDE: [answer]

WARNING: Note: This answer suggests [issue] with the current approach. Want to address this before continuing, or proceed as planned?
```
Chờ quyết định của người dùng trước khi tiếp tục.

**Câu hỏi thực chất là chuyển hướng tác vụ (không phải câu hỏi phụ):**
Nếu câu hỏi ngụ ý thay đổi thứ đang được xây dựng (ví dụ `/aside actually, let's use Redis instead`), hãy làm rõ:
```
ASIDE: That sounds like a direction change, not just a side question.
Do you want to:
  (a) Answer this as information only and keep the current plan
  (b) Pause the current task and change approach
```
Chờ câu trả lời của người dùng — không tự đưa ra giả định.

**Câu hỏi về file hoặc code đang mở:**
Trả lời từ context hiện có. Nếu file đã được đọc trước đó trong session, tham chiếu trực tiếp. Nếu chưa, đọc ngay bây giờ (chỉ đọc) và trả lời kèm tham chiếu file:dòng.

**Không có tác vụ đang chạy (không có gì đang tiến hành khi gọi `/aside`):**
Vẫn dùng khung chuẩn để hình thức phản hồi nhất quán:
```
ASIDE: [restate the question briefly]

[Your answer here]

— Back to task: no active task to resume
```

**Câu hỏi cần câu trả lời dài:**
Đưa ra câu trả lời thiết yếu một cách ngắn gọn, rồi đề nghị:
```
That's the short version. Want a deeper explanation after we finish [current task]?
```

**Nhiều câu hỏi `/aside` liên tiếp:**
Trả lời lần lượt từng câu. Sau câu trả lời cuối cùng, tiếp tục tác vụ chính. Không làm mất trạng thái tác vụ qua một chuỗi aside.

**Câu trả lời aside ngụ ý cần thay đổi code:**
Ghi nhận thay đổi cần thiết nhưng không thực hiện trong lúc aside:
```
ASIDE: [answer]

 Worth fixing: [what should be changed]. I'll flag this after the current task unless you want to address it now.
```

**Câu hỏi mơ hồ hoặc quá chung chung:**
Hỏi một câu làm rõ — câu ngắn nhất để lấy được thông tin cần thiết để trả lời. Không hỏi nhiều câu.

---

## Ví dụ đầu ra

```
User: /aside what does fetchWithRetry() actually do?

ASIDE: what does fetchWithRetry() do?

fetchWithRetry() (src/api/retry.ts:12) attempts the request up to 3 times with
exponential backoff (250ms → 500ms → 1s). It only retries on 5xx responses and
network errors — 4xx errors are treated as final and not retried.

— Back to task: refactoring the auth middleware in src/middleware/auth.ts
```

```
User: /aside is the approach we're taking thread-safe?

ASIDE: is the current approach thread-safe?

No — the shared cache object in src/cache/store.ts:34 is mutated without locking.
Under concurrent requests this is a race condition. It's low risk in a single-process
Node.js server but would be a real problem with worker threads or clustering.

WARNING: Note: This could affect the feature we're building. Want to address this now or continue and fix it in a follow-up?
```

---

## Ghi chú

- KHÔNG BAO GIỜ sửa file trong lúc aside — chỉ có quyền đọc
- Aside là một khoảng tạm dừng hội thoại, không phải tác vụ mới — tác vụ ban đầu phải luôn được tiếp tục
- Giữ câu trả lời tập trung: mục tiêu là gỡ vướng cho người dùng nhanh chóng, không phải giảng bài
- Nếu một aside gợi ra thảo luận lớn hơn, hãy hoàn tất tác vụ hiện tại trước, trừ khi aside làm lộ một blocker
- Aside không được lưu vào file session trừ khi liên quan rõ ràng đến kết quả của tác vụ
