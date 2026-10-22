---
description: Lập kế hoạch và thực thi một chiến dịch marketing đầy đủ. Nhận product brief và trả về định vị (positioning), copy cho landing page, chuỗi email, bài đăng mạng xã hội, các biến thể quảng cáo, kịch bản video và lịch nội dung. Cũng có thể review copy hiện có về chất lượng chuyển đổi. Đây là điểm vào dạng slash command, ủy quyền cho marketing-agent; ưu tiên skill marketing-campaign cho cùng workflow end-to-end trong hội thoại.
allowed-tools: ["Read", "Grep", "Glob", "WebSearch", "WebFetch", "Write"]
---

# /marketing-campaign

Lập kế hoạch và thực thi một chiến dịch marketing từ brief đến bộ nội dung đầy đủ.

## Cách dùng

```
/marketing-campaign                          # Prompt for brief interactively
/marketing-campaign [product brief]          # Full campaign from inline brief
/marketing-campaign copy [type]              # Single deliverable only
/marketing-campaign review [file-or-brief]   # Copy audit for conversion and brand consistency
```

## Nó làm gì

1. **Nghiên cứu** — Lập hồ sơ đối tượng mục tiêu và vẽ bản đồ đối thủ trước khi viết bất cứ thứ gì
2. **Định vị (Positioning)** — Chốt góc tiếp cận chiến dịch và hồ sơ giọng điệu trước
3. **Sản xuất copy** — Tạo bộ nội dung đầy đủ theo đúng thứ tự (landing page → email → social → quảng cáo → kịch bản video → lịch)
4. **Review** — Kiểm soát toàn bộ output qua checklist về chuyển đổi và tính nhất quán thương hiệu

## Các chế độ

### Chế độ Full Campaign

Cung cấp một product brief gồm:
- Tên và mô tả sản phẩm
- Đối tượng mục tiêu (cụ thể, không chung chung)
- Vấn đề cốt lõi mà sản phẩm giải quyết
- Lợi ích / kết quả cốt lõi
- Hướng dẫn về giọng điệu
- Các kênh cần có
- Mục tiêu hoặc mốc thời gian ra mắt

Agent trả về tất cả deliverable của chiến dịch theo thứ tự, kèm bản tóm tắt review copy ở cuối.

### Chế độ Single Deliverable

```
/marketing-campaign copy landing-page
/marketing-campaign copy email-sequence
/marketing-campaign copy social-posts
/marketing-campaign copy ads
/marketing-campaign copy video-scripts
```

Yêu cầu positioning được xác định trước. Hãy chạy chế độ đầy đủ hoặc cung cấp góc tiếp cận trước khi yêu cầu một deliverable đơn lẻ.

### Chế độ Copy Review

```
/marketing-campaign review path/to/copy.md
/marketing-campaign review "paste copy here"
```

Trả về bản audit có cấu trúc theo:
- Bài test độ rõ ràng trong 5 giây (copy above-fold)
- Chất lượng CTA (cụ thể, có cơ sở, một CTA cho mỗi sản phẩm nội dung)
- Tính nhất quán giọng điệu thương hiệu
- Tính cụ thể và khả năng chứng minh của các tuyên bố
- Độ phù hợp với đặc thù nền tảng (platform-native)
- Tính nhất quán xuyên kênh

## Template Brief

```markdown
Product: [name]
Description: [1-3 sentences on what it does]
Audience: [who, specifically]
Problem: [the specific pain the product solves]
Benefit: [the outcome the user gets]
Tone: [adjectives + what to avoid]
Channels: [landing page, email, LinkedIn, X, ads, video]
Goal: [launch, waitlist, signups, awareness — and timeline]
```

## Vị trí output

Khi lưu tài sản chiến dịch, quy ước là `.claude/campaigns/{campaign-name}/`:

```
.claude/campaigns/product-launch/
├── positioning.md
├── landing-page.md
├── email-sequence.md
├── social-posts.md
├── ad-copy.md
├── video-scripts.md
└── content-calendar.md
```

Xác nhận vị trí lưu trước khi ghi file.

## Ví dụ

```
/marketing-campaign Build a 7-day launch campaign for an AI career platform for UK university students.
```

```
/marketing-campaign copy landing-page
```

```
/marketing-campaign review .claude/campaigns/the-key/landing-page.md
```

## Ủy quyền cho agent

Command này gọi:
- `marketing-agent` — lập kế hoạch chiến dịch và sản xuất copy
- `brand-voice` — nắm bắt giọng điệu khi cần chốt tone xuyên suốt nhiều output
- `content-engine` — sản xuất nội dung social đúng đặc thù nền tảng
- `crosspost` — phân phối đa nền tảng
- `market-research` — thông tin chuyên sâu về đối tượng hoặc đối thủ

## Các command liên quan

- `/plan` — Lập kế hoạch chiến lược trước một chiến dịch
- `/plan-prd` — Tài liệu yêu cầu sản phẩm trước khi viết brief cho chiến dịch
- `/code-review` — Review code đằng sau việc triển khai landing page

---

*Một phần của [ECC](https://github.com/affaan-m/ECC)*
