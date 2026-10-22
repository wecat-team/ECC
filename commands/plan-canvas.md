---
description: Mở một plan hoặc artifact HTML trong Plan Canvas trên trình duyệt để review kiểu annotate-and-approve. Đây là điểm vào slash command mỏng bên trên skill plan-canvas, skill này bao quát toàn bộ workflow và quy tắc.
argument-hint: "[path/to/artifact.plan.md | path/to/artifact.html]"
---

# Lệnh Plan Canvas

Mở một artifact cục bộ trong Plan Canvas — bề mặt review trên trình duyệt của ECC —
nơi người dùng chú thích các phần tử, trò chuyện với bạn, và phê duyệt kế hoạch hoặc
yêu cầu thay đổi mà không cần rời khỏi trang.

Command này là một điểm vào mỏng bên trên skill `plan-canvas`. Hãy làm theo skill đó
để có toàn bộ workflow và quy tắc.

## Command này làm gì

1. Xác định artifact: đường dẫn được cung cấp, nếu không thì
   `.claude/plans/*.plan.md` được sửa gần nhất, nếu không nữa thì hỏi cần review gì.
2. `ecc-plan-canvas open <artifact>` — mở trình duyệt của người dùng.
3. `ecc-plan-canvas await <artifact>` — chặn cho đến khi có phản hồi,
   verdict hoặc kết thúc phiên; để nó tiếp tục chạy.
4. Áp dụng phản hồi vào file artifact (canvas tự reload trực tiếp), trả lời bằng
   `await <artifact> --reply "..."`, và lặp lại cho đến khi người dùng phê duyệt hoặc
   kết thúc phiên.

Verdict `approve` được tính là xác nhận kế hoạch cho các cổng kiểu `/plan`:
dừng polling, `end` phiên và bắt đầu triển khai.

## Ví dụ

```
User: /plan-canvas .claude/plans/notifications.plan.md

Assistant: (runs open + await, browser opens)
...user clicks "Request changes" with two annotations...
Assistant: (edits the plan, replies in-canvas, awaits again)
...user clicks "Approve plan"...
Assistant: Plan approved in the canvas — starting implementation.
```

## Liên quan

- skill `plan-canvas` — workflow đầy đủ, hình dạng JSON của phản hồi, quy tắc
- `/plan` — tạo ra các plan artifact mà command này review
- Nguồn: `scripts/plan-canvas.js`, `scripts/lib/plan-canvas/`
