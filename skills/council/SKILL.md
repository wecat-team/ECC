---
name: council
description: Triệu tập một council bốn tiếng nói cho các quyết định mơ hồ, đánh đổi (tradeoff) và go/no-go. Dùng khi tồn tại nhiều con đường hợp lệ và bạn cần sự bất đồng có cấu trúc trước khi chọn.
metadata:
  origin: ECC
---

# Council

Triệu tập bốn cố vấn cho các quyết định mơ hồ:
- tiếng nói Claude trong context hiện tại
- một subagent Skeptic
- một subagent Pragmatist
- một subagent Critic

Skill này dành cho **ra quyết định trong điều kiện mơ hồ**, không phải code review, lập kế hoạch triển khai hay thiết kế kiến trúc.

## Khi nào dùng

Dùng council khi:
- một quyết định có nhiều con đường đáng tin và không có người thắng hiển nhiên
- bạn cần làm lộ rõ các tradeoff
- người dùng yêu cầu ý kiến thứ hai, phản biện hoặc nhiều góc nhìn
- việc bị neo bởi cuộc hội thoại (conversational anchoring) là rủi ro thực sự
- một quyết định go / no-go sẽ được lợi từ sự thách thức mang tính đối kháng

Ví dụ:
- monorepo vs polyrepo
- ship ngay vs chờ trau chuốt thêm
- feature flag vs rollout đầy đủ
- đơn giản hóa phạm vi vs giữ bề rộng chiến lược

## Khi nào KHÔNG dùng

| Thay vì council | Dùng |
| --- | --- |
| Xác minh output có đúng không | `santa-method` |
| Chia nhỏ một tính năng thành các bước triển khai | `planner` |
| Thiết kế kiến trúc hệ thống | `architect` |
| Review code về bug hoặc bảo mật | `code-reviewer` hoặc `santa-method` |
| Câu hỏi thực tế đơn giản | cứ trả lời trực tiếp |
| Tác vụ thực thi hiển nhiên | cứ làm tác vụ đó |

## Vai trò

| Tiếng nói | Góc nhìn |
| --- | --- |
| Architect | tính đúng đắn, khả năng bảo trì, hệ quả dài hạn |
| Skeptic | thách thức tiền đề, đơn giản hóa, phá vỡ giả định |
| Pragmatist | tốc độ ship, tác động đến người dùng, thực tế vận hành |
| Critic | edge case, rủi ro tiêu cực, các failure mode |

Ba tiếng nói bên ngoài nên được khởi chạy dưới dạng subagent mới với **chỉ câu hỏi và context liên quan**, không phải toàn bộ cuộc hội thoại đang diễn ra. Đó là cơ chế chống neo (anti-anchoring).

## Workflow

### 1. Rút ra câu hỏi thực sự

Rút gọn quyết định thành một prompt tường minh:
- chúng ta đang quyết định điều gì?
- ràng buộc nào quan trọng?
- thế nào được coi là thành công?

Nếu câu hỏi mơ hồ, hãy hỏi một câu làm rõ trước khi triệu tập council.

### 2. Chỉ thu thập context cần thiết

Nếu quyết định gắn với codebase cụ thể:
- thu thập các file, snippet, nội dung issue hoặc metric liên quan
- giữ nó gọn
- chỉ đưa vào context cần để ra quyết định

Nếu quyết định mang tính chiến lược/tổng quát:
- bỏ qua các snippet repo trừ khi chúng thay đổi đáng kể câu trả lời

### 3. Hình thành lập trường Architect trước

Trước khi đọc các tiếng nói khác, hãy viết ra:
- lập trường ban đầu của bạn
- ba lý do mạnh nhất cho nó
- rủi ro chính trong con đường bạn ưu tiên

Làm việc này trước để bản tổng hợp không đơn thuần phản chiếu các tiếng nói bên ngoài.

### 4. Khởi chạy ba tiếng nói độc lập song song

Mỗi subagent nhận được:
- câu hỏi quyết định
- context gọn nếu cần
- một vai trò nghiêm ngặt
- không có lịch sử hội thoại không cần thiết

Dạng prompt:

```text
You are the [ROLE] on a four-voice decision council.

Question:
[decision question]

Context:
[only the relevant snippets or constraints]

Respond with:
1. Position — 1-2 sentences
2. Reasoning — 3 concise bullets
3. Risk — biggest risk in your recommendation
4. Surprise — one thing the other voices may miss

Be direct. No hedging. Keep it under 300 words.
```

Điểm nhấn của từng vai trò:
- Skeptic: thách thức cách đặt vấn đề, đặt câu hỏi về giả định, đề xuất phương án thay thế đáng tin đơn giản nhất
- Pragmatist: tối ưu cho tốc độ, sự đơn giản và thực thi trong thế giới thực
- Critic: làm lộ rủi ro tiêu cực, edge case và những lý do khiến kế hoạch có thể thất bại

### 5. Tổng hợp với các rào chắn chống thiên kiến

Bạn vừa là người tham gia vừa là người tổng hợp, vì vậy hãy dùng các quy tắc sau:
- không bác bỏ một quan điểm bên ngoài mà không giải thích vì sao
- nếu một tiếng nói bên ngoài đã thay đổi khuyến nghị của bạn, hãy nói rõ điều đó
- luôn đưa vào phản biện mạnh nhất, ngay cả khi bạn bác bỏ nó
- nếu hai tiếng nói cùng chống lại lập trường ban đầu của bạn, hãy coi đó là một tín hiệu thực sự
- giữ các lập trường thô hiển thị trước phần kết luận

### 6. Trình bày một kết luận gọn

Dùng dạng output này:

```markdown
## Council: [short decision title]

**Architect:** [1-2 sentence position]
[1 line on why]

**Skeptic:** [1-2 sentence position]
[1 line on why]

**Pragmatist:** [1-2 sentence position]
[1 line on why]

**Critic:** [1-2 sentence position]
[1 line on why]

### Verdict
- **Consensus:** [where they align]
- **Strongest dissent:** [most important disagreement]
- **Premise check:** [did the Skeptic challenge the question itself?]
- **Recommendation:** [the synthesized path]
```

Giữ cho nó dễ quét trên màn hình điện thoại.

## Quy tắc lưu trữ (Persistence)

KHÔNG ghi ghi chú ad-hoc vào `~/.claude/notes` hay các đường dẫn bóng (shadow path) khác từ skill này.

Nếu council thay đổi đáng kể khuyến nghị:
- dùng `knowledge-ops` để lưu bài học vào đúng nơi bền vững
- hoặc dùng `/save-session` nếu kết quả thuộc về bộ nhớ session
- hoặc cập nhật trực tiếp issue GitHub / Linear liên quan nếu quyết định thay đổi sự thật thực thi đang hoạt động

Chỉ lưu một quyết định khi nó thay đổi điều gì đó có thật.

## Theo dõi nhiều vòng (Multi-Round Follow-up)

Mặc định là một vòng.

Nếu người dùng muốn thêm một vòng nữa:
- giữ câu hỏi mới tập trung
- chỉ đưa kết luận trước đó vào nếu thật sự cần thiết
- giữ Skeptic càng "sạch" càng tốt để bảo toàn giá trị chống neo

## Anti-Pattern

- dùng council cho code review
- dùng council khi tác vụ chỉ là công việc triển khai
- đưa cho các subagent toàn bộ transcript hội thoại
- che giấu bất đồng trong kết luận cuối cùng
- lưu mọi quyết định thành ghi chú bất kể mức độ quan trọng

## Skill liên quan

- `santa-method` — xác minh mang tính đối kháng
- `knowledge-ops` — lưu đúng các delta quyết định bền vững
- `search-first` — thu thập tài liệu tham khảo bên ngoài trước council nếu cần
- `architecture-decision-records` — chính thức hóa kết quả khi quyết định trở thành chính sách hệ thống dài hạn

## Ví dụ

Câu hỏi:

```text
Should we ship ECC 2.0 as alpha now, or hold until the control-plane UI is more complete?
```

Dạng council có khả năng xảy ra:
- Architect đẩy mạnh tính toàn vẹn cấu trúc và tránh một bề mặt gây nhầm lẫn
- Skeptic đặt câu hỏi liệu UI có thực sự là yếu tố chặn hay không
- Pragmatist hỏi cái gì có thể ship ngay mà không làm tổn hại niềm tin
- Critic tập trung vào gánh nặng hỗ trợ, nợ kỳ vọng và sự nhầm lẫn khi rollout

Giá trị không nằm ở sự đồng thuận tuyệt đối. Giá trị nằm ở việc làm cho sự bất đồng trở nên rõ ràng trước khi chọn.
