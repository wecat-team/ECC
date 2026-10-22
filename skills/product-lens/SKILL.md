---
name: product-lens
description: Xác thực lý do (the why) trước khi build thông qua bốn chẩn đoán sản phẩm — chẩn đoán sản phẩm kiểu YC tạo ra PRODUCT-BRIEF.md kèm khuyến nghị go/no-go, founder review chấm điểm các tín hiệu product-market-fit, user journey audit đo time-to-value, và ICE feature prioritization. Dùng khi kiểm chứng hướng đi sản phẩm, chọn giữa các tính năng, kiểm tra lại trước khi launch, hoặc biến một ý tưởng mơ hồ thành product brief.
metadata:
  origin: ECC
---

# Product Lens — Nghĩ trước khi build

Lane này phụ trách chẩn đoán sản phẩm, không phải viết đặc tả sẵn sàng để triển khai.

Nếu người dùng cần artifact bền vững dạng PRD-to-SRS hoặc capability-contract, hãy chuyển giao cho `product-capability`.

## Khi nào dùng

- Trước khi bắt đầu bất kỳ tính năng nào — xác thực "why"
- Product review hằng tuần — chúng ta có đang build đúng thứ cần build không?
- Khi đang phân vân chọn giữa các tính năng
- Trước khi launch — kiểm tra lại user journey
- Khi biến một ý tưởng mơ hồ thành product brief trước khi bắt đầu lập kế hoạch kỹ thuật

## Cách hoạt động

### Chế độ 1: Product Diagnostic

Giống YC office hours nhưng được tự động hóa. Đặt ra những câu hỏi khó:

```
1. Who is this for? (specific person, not "developers")
2. What's the pain? (quantify: how often, how bad, what do they do today?)
3. Why now? (what changed that makes this possible/necessary?)
4. What's the 10-star version? (if money/time were unlimited)
5. What's the MVP? (smallest thing that proves the thesis)
6. What's the anti-goal? (what are you explicitly NOT building?)
7. How do you know it's working? (metric, not vibes)
```

Đầu ra: một file `PRODUCT-BRIEF.md` gồm các câu trả lời, rủi ro và khuyến nghị go/no-go.

Nếu kết quả là "có, hãy build cái này", lane tiếp theo là `product-capability`, không phải thêm founder-theater.

### Chế độ 2: Founder Review

Review project hiện tại dưới góc nhìn của founder:

```
1. Read README, CLAUDE.md, package.json, recent commits
2. Infer: what is this trying to be?
3. Score: product-market fit signals (0-10)
   - Usage growth trajectory
   - Retention indicators (repeat contributors, return users)
   - Revenue signals (pricing page, billing code, Stripe integration)
   - Competitive moat (what's hard to copy?)
4. Identify: the one thing that would 10x this
5. Flag: things you're building that don't matter
```

### Chế độ 3: User Journey Audit

Lập bản đồ trải nghiệm người dùng thực tế:

```
1. Clone/install the product as a new user
2. Document every friction point (confusing steps, errors, missing docs)
3. Time each step
4. Compare to competitor onboarding
5. Score: time-to-value (how long until the user gets their first win?)
6. Recommend: top 3 fixes for onboarding
```

### Chế độ 4: Feature Prioritization

Khi có 10 ý tưởng và cần chọn 2:

```
1. List all candidate features
2. Score each on: impact (1-5) × confidence (1-5) ÷ effort (1-5)
3. Rank by ICE score
4. Apply constraints: runway, team size, dependencies
5. Output: prioritized roadmap with rationale
```

## Đầu ra

Mọi chế độ đều xuất ra tài liệu có thể hành động ngay, không phải bài luận. Mỗi khuyến nghị đều có một bước tiếp theo cụ thể.

## Tích hợp

Kết hợp với:
- `/browser-qa` để xác minh các phát hiện của user journey audit
- `/design-system audit` để đánh giá độ hoàn thiện về mặt hình ảnh
- `/canary-watch` để giám sát sau launch
- `product-capability` khi product brief cần trở thành kế hoạch capability sẵn sàng để triển khai
