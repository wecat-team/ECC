---
name: architecture-decision-records
description: Ghi lại các quyết định kiến trúc thành các file markdown ADR có đánh số trong docs/adr/ với context, các phương án đã cân nhắc, hệ quả, và một README làm mục lục. Dùng khi người dùng nói 'record this decision' hoặc 'ADR this', chọn giữa các framework hoặc database, thảo luận trade-off, hoặc hỏi vì sao codebase có hình hài như hiện tại.
metadata:
  origin: ECC
---

# Architecture Decision Record

Ghi lại các quyết định kiến trúc ngay khi chúng xảy ra trong các phiên coding. Thay vì để quyết định chỉ tồn tại trong các thread Slack, comment PR hoặc trí nhớ của ai đó, skill này tạo ra các tài liệu ADR có cấu trúc nằm cạnh code.

## Khi nào kích hoạt

- Người dùng nói tường minh "let's record this decision" hoặc "ADR this"
- Người dùng chọn giữa các phương án quan trọng (framework, library, pattern, database, thiết kế API)
- Người dùng nói "we decided to..." hoặc "the reason we're doing X instead of Y is..."
- Người dùng hỏi "why did we choose X?" (đọc các ADR hiện có)
- Trong các giai đoạn lập kế hoạch khi thảo luận các trade-off kiến trúc

## Định dạng ADR

Dùng định dạng ADR gọn nhẹ do Michael Nygard đề xuất, được điều chỉnh cho phát triển có AI hỗ trợ:

```markdown
# ADR-NNNN: [Decision Title]

**Date**: YYYY-MM-DD
**Status**: proposed | accepted | deprecated | superseded by ADR-NNNN
**Deciders**: [who was involved]

## Context

What is the issue that we're seeing that is motivating this decision or change?

[2-5 sentences describing the situation, constraints, and forces at play]

## Decision

What is the change that we're proposing and/or doing?

[1-3 sentences stating the decision clearly]

## Alternatives Considered

### Alternative 1: [Name]
- **Pros**: [benefits]
- **Cons**: [drawbacks]
- **Why not**: [specific reason this was rejected]

### Alternative 2: [Name]
- **Pros**: [benefits]
- **Cons**: [drawbacks]
- **Why not**: [specific reason this was rejected]

## Consequences

What becomes easier or more difficult to do because of this change?

### Positive
- [benefit 1]
- [benefit 2]

### Negative
- [trade-off 1]
- [trade-off 2]

### Risks
- [risk and mitigation]
```

## Workflow

### Ghi lại một ADR mới

Khi phát hiện một thời điểm đưa ra quyết định:

1. **Khởi tạo (chỉ lần đầu)** — nếu `docs/adr/` chưa tồn tại, hãy hỏi người dùng xác nhận trước khi tạo thư mục, một `README.md` có sẵn header bảng mục lục (xem Định dạng mục lục ADR bên dưới), và một `template.md` trống để dùng thủ công. KHÔNG tạo file khi chưa có sự đồng ý tường minh.
2. **Xác định quyết định** — trích xuất lựa chọn kiến trúc cốt lõi đang được đưa ra
3. **Thu thập context** — vấn đề nào dẫn đến quyết định này? Có những ràng buộc gì?
4. **Ghi lại các phương án** — đã cân nhắc những lựa chọn nào khác? Vì sao chúng bị loại?
5. **Nêu hệ quả** — các trade-off là gì? Điều gì trở nên dễ hơn/khó hơn?
6. **Gán số thứ tự** — quét các ADR hiện có trong `docs/adr/` rồi tăng thêm một
7. **Xác nhận và ghi** — đưa bản nháp ADR cho người dùng review. Chỉ ghi vào `docs/adr/NNNN-decision-title.md` sau khi được chấp thuận tường minh. Nếu người dùng từ chối, hãy bỏ bản nháp mà không ghi file nào.
8. **Cập nhật mục lục** — thêm vào cuối `docs/adr/README.md`

### Đọc các ADR hiện có

Khi người dùng hỏi "why did we choose X?":

1. Kiểm tra `docs/adr/` có tồn tại không — nếu không, trả lời: "No ADRs found in this project. Would you like to start recording architectural decisions?"
2. Nếu có, quét mục lục `docs/adr/README.md` để tìm các mục liên quan
3. Đọc các file ADR khớp và trình bày các phần Context và Decision
4. Nếu không tìm thấy kết quả khớp, trả lời: "No ADR found for that decision. Would you like to record one now?"

### Cấu trúc thư mục ADR

```
docs/
└── adr/
    ├── README.md              ← index of all ADRs
    ├── 0001-use-nextjs.md
    ├── 0002-postgres-over-mongo.md
    ├── 0003-rest-over-graphql.md
    └── template.md            ← blank template for manual use
```

### Định dạng mục lục ADR

```markdown
# Architecture Decision Records

| ADR | Title | Status | Date |
|-----|-------|--------|------|
| [0001](0001-use-nextjs.md) | Use Next.js as frontend framework | accepted | 2026-01-15 |
| [0002](0002-postgres-over-mongo.md) | PostgreSQL over MongoDB for primary datastore | accepted | 2026-01-20 |
| [0003](0003-rest-over-graphql.md) | REST API over GraphQL | accepted | 2026-02-01 |
```

## Tín hiệu nhận biết quyết định

Hãy để ý các pattern sau trong hội thoại cho thấy một quyết định kiến trúc:

**Tín hiệu tường minh**
- "Let's go with X"
- "We should use X instead of Y"
- "The trade-off is worth it because..."
- "Record this as an ADR"

**Tín hiệu ngầm** (gợi ý ghi một ADR — KHÔNG tự động tạo khi chưa có xác nhận của người dùng)
- So sánh hai framework hoặc library và đi đến kết luận
- Đưa ra lựa chọn thiết kế database schema kèm lý do được nêu rõ
- Chọn giữa các architectural pattern (monolith so với microservices, REST so với GraphQL)
- Quyết định chiến lược authentication/authorization
- Chọn hạ tầng deployment sau khi đánh giá các phương án

## Điều gì làm nên một ADR tốt

### Nên làm
- **Cụ thể** — "Use Prisma ORM" chứ không phải "use an ORM"
- **Ghi lại lý do** — lý do quan trọng hơn nội dung quyết định
- **Bao gồm các phương án bị loại** — các developer sau này cần biết đã cân nhắc những gì
- **Nêu hệ quả một cách trung thực** — mọi quyết định đều có trade-off
- **Giữ ngắn gọn** — một ADR nên đọc được trong 2 phút
- **Dùng thì hiện tại** — "We use X" chứ không phải "We will use X"

### Không nên làm
- Ghi lại các quyết định tầm thường — việc đặt tên biến hay chọn định dạng không cần ADR
- Viết thành bài luận — nếu phần context dài quá 10 dòng thì là quá dài
- Bỏ qua các phương án thay thế — "we just picked it" không phải là lý do hợp lệ
- Điền bổ sung (backfill) mà không đánh dấu — nếu ghi lại một quyết định trong quá khứ, hãy ghi chú ngày gốc
- Để ADR lỗi thời — các quyết định bị thay thế phải tham chiếu tới quyết định thay thế chúng

## Vòng đời ADR

```
proposed → accepted → [deprecated | superseded by ADR-NNNN]
```

- **proposed**: quyết định đang được thảo luận, chưa cam kết
- **accepted**: quyết định đang có hiệu lực và được tuân theo
- **deprecated**: quyết định không còn phù hợp (ví dụ: tính năng đã bị gỡ)
- **superseded**: một ADR mới hơn thay thế ADR này (luôn liên kết tới ADR thay thế)

## Các nhóm quyết định đáng ghi lại

| Nhóm | Ví dụ |
|----------|---------|
| **Lựa chọn công nghệ** | Framework, ngôn ngữ, database, cloud provider |
| **Architecture pattern** | Monolith so với microservices, event-driven, CQRS |
| **Thiết kế API** | REST so với GraphQL, chiến lược versioning, cơ chế auth |
| **Mô hình hóa dữ liệu** | Thiết kế schema, quyết định chuẩn hóa, chiến lược cache |
| **Hạ tầng** | Mô hình deployment, CI/CD pipeline, monitoring stack |
| **Bảo mật** | Chiến lược auth, cách tiếp cận mã hóa, quản lý secret |
| **Testing** | Test framework, mục tiêu coverage, cân bằng E2E so với integration |
| **Quy trình** | Chiến lược branching, quy trình review, nhịp release |

## Tích hợp với các Skill khác

- **Planner agent**: khi planner đề xuất thay đổi kiến trúc, hãy gợi ý tạo một ADR
- **Code reviewer agent**: đánh dấu các PR đưa vào thay đổi kiến trúc mà không có ADR tương ứng
