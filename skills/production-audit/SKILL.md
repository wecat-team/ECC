---
name: production-audit
description: Audit mức độ sẵn sàng cho production dựa trên bằng chứng cục bộ, dành cho app đã ship, review trước launch, kiểm tra sau merge, và các câu hỏi "cái gì sẽ hỏng trên prod?" mà không gửi dữ liệu repo tới dịch vụ audit bên ngoài. Dùng khi audit production readiness trước launch, sau một merge, hoặc khi được hỏi cái gì sẽ hỏng trên prod.
metadata:
  origin: community
---

# Production Audit

Dùng skill này khi người dùng hỏi một ứng dụng đã sẵn sàng để ship chưa, cái gì
có thể hỏng trên production, hoặc cần sửa gì trước khi launch. Đây là bản viết lại
an toàn cho maintainer của ý tưởng production-audit cũ trong cộng đồng: giữ lại
góc nhìn production-readiness hữu ích và loại bỏ việc thực thi bên ngoài không
ghim phiên bản (unpinned) cũng như chia sẻ dữ liệu cho bên thứ ba.

## Khi nào dùng

- Người dùng hỏi "is this production-ready", "what would break in prod", "what
  did we miss", "audit this repo", hoặc "ready to ship?"
- Một tính năng vừa được merge và cần một lượt rà soát rủi ro trước deploy hoặc sau merge.
- Sắp có public launch, demo, rollout cho khách hàng hoặc buổi trình bày cho nhà đầu tư.
- CI đã xanh nhưng người dùng muốn biết rủi ro production, không chỉ trạng thái test.
- Có sẵn URL đã deploy, release branch, PR hoặc checkout hiện tại để thu thập
  bằng chứng.

## Khi nào không dùng

- Trong lúc đang triển khai (implementation) khi góc nhìn phù hợp là secure coding
  ở mức từng dòng; hãy dùng `security-review` trước.
- Với thư viện thuần, template, repo chỉ có tài liệu hoặc scaffold, trừ khi người dùng
  muốn đánh giá packaging/release readiness thay vì application readiness.
- Khi người dùng yêu cầu audit tuân thủ (compliance) chính thức. Skill này là
  phân loại (triage) về kỹ thuật, không phải chứng nhận pháp lý, tài chính, y tế hay quy định.
- Khi bằng chứng duy nhất có được chỉ là một ý tưởng sản phẩm, không có repo,
  deployment, CI hay runtime.

## Cách hoạt động

Xây dựng audit từ bằng chứng cục bộ và bằng chứng được người dùng cho phép. KHÔNG chạy
remote code không ghim phiên bản, KHÔNG upload nội dung repo lên dịch vụ bên thứ ba,
và KHÔNG gọi scanner bên ngoài trừ khi người dùng chấp thuận rõ ràng đúng công cụ và
luồng dữ liệu đó.

Theo thứ tự sau:

1. Xác định phạm vi release (release surface).
2. Đọc các thay đổi gần đây và trạng thái branch hiện tại.
3. Kiểm tra các ranh giới runtime, auth, dữ liệu, thanh toán, background-job, AI và
   deployment thực sự tồn tại trong repo.
4. Kiểm tra CI, test, migration, tài liệu môi trường và đường rollback.
5. Đưa ra khuyến nghị ship/block ngắn gọn kèm các bản sửa cụ thể.

## Checklist bằng chứng

Bắt đầu với các tín hiệu cục bộ, chi phí thấp:

```text
git status --short --branch
git log --oneline --decorate -20
git diff --stat origin/main...HEAD
```

Sau đó kiểm tra phần đặc thù của dự án:

- Package script, CI workflow, release script, Docker file và deployment
  manifest.
- API route, webhook, auth middleware, background worker, cron job và
  database migration.
- Tài liệu biến môi trường và các kiểm tra khi khởi động.
- Observability hook, báo cáo lỗi, log, health check và dashboard.
- Hướng dẫn rollback, seed, migration và backfill.
- Độ phủ E2E cho các luồng người dùng quan trọng nhất.

Nếu có URL đã deploy trong phạm vi, chỉ dùng kiểm tra bằng browser hoặc HTTP đối với
đúng URL đó và tránh các hành động cần credential trừ khi người dùng cung cấp tài khoản
test an toàn.

## Các góc nhìn rủi ro

### Bảo mật và Auth

- Các route công khai, API route và admin route có được tách biệt rõ ràng không?
- Auth và phân quyền (authorization) có được thực thi ở phía server không?
- Secret có được giữ ngoài client bundle, log, output ví dụ và các file đã
  commit không?
- Rate limit, bảo vệ CSRF, chính sách CORS và kiểm tra upload có mặt ở
  những nơi app cần không?
- Phần AI hoặc agent có phòng thủ trước prompt injection, lạm dụng tool và
  nội dung không tin cậy lọt vào các hành động đặc quyền không?

### Tính toàn vẹn dữ liệu

- Migration có chạy tiến (forward) sạch sẽ và có kế hoạch rollback hoặc khôi phục không?
- Các migration phá hủy dữ liệu, backfill và import dữ liệu có được triển khai theo từng giai đoạn an toàn không?
- Database policy, grant và ranh giới service-role có khớp với mô hình tenancy
  của app không?
- Việc retry có idempotent đối với ghi dữ liệu, job và webhook handler không?

### Thanh toán và Webhook

- Chữ ký webhook có được xác minh trước khi parse các field payload được tin cậy không?
- Mỗi webhook thanh toán, subscription hoặc fulfillment có idempotent không?
- Replay, giao trùng (duplicate delivery) và giao sai thứ tự có được xử lý không?
- Credential của test-mode và live-mode có được tách biệt không?

### Vận hành

- App có khởi động được từ một checkout sạch bằng các lệnh đã được ghi lại không?
- Các biến môi trường bắt buộc có được đặt tên, validate và fail-fast không?
- Có health check chứng minh các dependency truy cập được không?
- Đường deploy, rollback và người phụ trách incident có được ghi lại không?
- Log có hữu ích mà không làm lộ secret hay dữ liệu cá nhân không?

### Trải nghiệm người dùng

- Các luồng quan trọng cho launch có được phủ trên desktop và mobile không?
- Form có dùng được trên mobile mà không bị zoom input, chồng layout hoặc trạng thái
  submit bị chặn không?
- Các trạng thái loading, rỗng, lỗi và bị từ chối quyền có cho người dùng biết điều
  gì đã xảy ra không?
- Có đường hỗ trợ hoặc khôi phục khi một thao tác quan trọng thất bại không?

## Chấm điểm

Dùng điểm số để buộc phải ưu tiên, không phải để ngụ ý sự chắc chắn về mặt toán học.

| Mức | Điểm | Ý nghĩa |
| --- | --- | --- |
| Blocked | 0-49 | Không ship cho đến khi các rủi ro hàng đầu được sửa |
| Risky | 50-69 | Chỉ ship với rollout nhỏ hoặc internal beta |
| Launchable With Caveats | 70-84 | Ship nếu các owner chấp nhận các rủi ro đã liệt kê |
| Strong | 85-100 | Không có blocker rõ ràng cho launch dựa trên bằng chứng hiện có |

Giới hạn điểm tối đa ở `69` nếu có bất kỳ điều nào sau đây:

- Thiếu authentication hoặc authorization trên dữ liệu nhạy cảm.
- Webhook thanh toán hoặc fulfillment không idempotent.
- Các migration bắt buộc không thể chạy an toàn.
- Secret bị lộ trong client bundle, log hoặc file đã commit.
- Không có đường rollback cho một release có tác động lớn.

Giới hạn điểm tối đa ở `84` nếu CI chưa xanh hoặc luồng quan trọng cho launch chưa
được test end to end.

## Định dạng đầu ra

Mở đầu bằng một câu:

```text
Production audit: 76/100, launchable with caveats, with webhook idempotency and rollback docs as the two risks to fix before public launch.
```

Sau đó liệt kê:

- `Blockers`: các mục bắt buộc sửa trước khi deploy.
- `High-value fixes`: các bản sửa tiếp theo nếu người dùng muốn cải thiện điểm số.
- `Evidence checked`: file, lệnh, CI, URL đã deploy hoặc PR đã kiểm tra.
- `Evidence missing`: những gì sẽ thay đổi mức độ tin cậy nếu được cung cấp.
- `Next action`: một bản sửa hoặc bước xác minh cụ thể.

Phần điểm mạnh nên ngắn gọn. Người dùng hỏi về mức độ sẵn sàng, nên câu trả lời hữu ích
là rủi ro còn lại và hành động tiếp theo.

## Ví dụ

Người dùng:

```text
is this ready to ship?
```

Phản hồi:

```text
Production audit: 68/100, risky, because Stripe webhooks are verified but not idempotent and there is no rollback note for the pending migration.

Blockers:
- Add idempotency for `checkout.session.completed` before fulfilling orders.
- Write and test the rollback path for `20260511_add_billing_state.sql`.

High-value fixes:
- Add a health check that verifies database and payment-provider reachability.
- Add one E2E path for upgrade, webhook fulfillment, and billing-page refresh.

Evidence checked:
- `api/stripe/webhook.ts`
- `db/migrations/20260511_add_billing_state.sql`
- GitHub Actions run for the release branch

Next action: Want me to patch webhook idempotency first?
```

## Anti-Patterns

- Chạy `npx <package>@latest` hoặc một remote scanner làm đường audit mặc định.
- Upload source, secret, dữ liệu khách hàng hoặc topology riêng tư lên dịch vụ
  audit bên ngoài mà không có sự chấp thuận rõ ràng.
- Đưa ra điểm số mà không nêu bằng chứng đã kiểm tra.
- Coi CI xanh là production readiness.
- Kết thúc bằng câu chung chung kiểu "let me know what you want to do."

## Xem thêm

- Skill: `security-review`
- Skill: `deployment-patterns`
- Skill: `e2e-testing`
- Skill: `tdd-workflow`
- Skill: `verification-loop`
