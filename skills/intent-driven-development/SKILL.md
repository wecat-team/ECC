---
name: intent-driven-development
description: "Biến các thay đổi sản phẩm và kỹ thuật mơ hồ hoặc có tác động lớn thành tiêu chí chấp nhận (acceptance criteria) có phạm vi rõ ràng, kiểm chứng được trước hoặc song song với triển khai. Dùng khi người dùng yêu cầu làm rõ một tính năng, định nghĩa acceptance criteria, giảm rủi ro cho thay đổi liên quan đến security/data/migration/integration, chuẩn bị yêu cầu triển khai cho agent khác, hoặc làm cho một yêu cầu phức tạp trở nên kiểm thử được. Không kích hoạt cho các chỉnh sửa tầm thường, sửa lỗi đơn giản, debug đang diễn ra, code review, hoặc yêu cầu triển khai mà điều kiện chấp nhận đã rõ ràng, trừ khi người dùng gọi skill này một cách tường minh."
---

# Intent-Driven Development

Tạo ra acceptance criteria hữu ích mà không biến việc đặc tả thành nghi thức. Kiểm tra
context sẵn có trước, phơi bày sự mơ hồ thực sự, và chọn phương pháp xác minh phù hợp
với công việc và rủi ro của nó.

## Khi nào kích hoạt

- Người dùng yêu cầu làm rõ một tính năng, định nghĩa acceptance criteria, hoặc giảm rủi ro cho một thay đổi trước khi triển khai
- Yêu cầu động đến security, authentication, dữ liệu lưu trữ bền vững, migration, API bên ngoài hoặc compliance
- Người dùng muốn chuẩn bị một artifact bàn giao cho agent hoặc team khác
- Yêu cầu mơ hồ đến mức kết quả mong đợi chưa quan sát được hoặc chưa kiểm thử được
- Người dùng gọi skill này một cách tường minh bằng `/intent-driven-development`

Không kích hoạt cho các chỉnh sửa tầm thường, sửa lỗi một dòng đơn giản, phiên debug đang diễn ra,
yêu cầu code review, hoặc yêu cầu triển khai mà điều kiện chấp nhận đã rõ ràng.

## Cách hoạt động

1. **Kiểm tra context trước** — đọc repository, tài liệu, schema và hạ tầng test để lấy các sự kiện kỹ thuật trước khi hỏi bất kỳ câu nào, đồng thời coi các ràng buộc sản phẩm/nghiệp vụ là thứ chỉ người dùng hoặc một artifact sản phẩm mới cung cấp được
2. **Chọn độ sâu** — chọn Quick Capture (3-7 tiêu chí, rủi ro thấp/vừa) hoặc Full Acceptance Brief (thay đổi về security, dữ liệu, migration, liên hệ thống) dựa trên hồ sơ rủi ro
3. **Hỏi tối thiểu** — chỉ hỏi những câu mà đáp án không thể suy ra được và làm thay đổi đáng kể phạm vi hoặc hành vi
4. **Viết tiêu chí quan sát được** — mỗi AC-NNN mô tả điều kiện bắt đầu, trigger, kết quả mong đợi, side effect bị cấm, phương pháp xác minh và mức ưu tiên; không dùng các từ mơ hồ như "correctly" hay "securely" khi không có bằng chứng
5. **Tiếp tục hoặc bàn giao** — với yêu cầu rõ ràng không có rủi ro chặn, ghi lại tiêu chí và tiếp tục; với thay đổi rủi ro, trình bày các điểm chặn và chờ xác nhận
6. **Xử lý sửa đổi** — nếu một AC thất bại giữa chừng triển khai do ràng buộc kiến trúc, đánh dấu `[revised]`, cập nhật phạm vi hoặc phương pháp xác minh, tăng số revision và chỉ trình bày lại các tiêu chí đã thay đổi

## Ví dụ

**Quick Capture — "Add CSV export to the dashboard"**

```
Goal: Authenticated users can download dashboard data as a CSV file.
In scope: Export of currently filtered rows; filename includes date.
Out of scope: Scheduled exports, email delivery, Excel format.
Assumptions: Max row count is under 10k; no PII in exported fields.

AC-001: Export generates file with correct headers
- Scenario: authenticated user, at least one data row visible
- Action: click "Export CSV"
- Expected: browser downloads file with columns [id, name, created_at]
- Must not: expose internal fields or rows belonging to other users
- Verification: automated integration test + manual schema spot-check
- Priority: Required
```

**Trigger cho Full Acceptance Brief — "Migrate user auth to OAuth"**

Thay đổi auth + dependency bên ngoài + dữ liệu session hiện có → Full Brief với bảng Risk Review,
các quyết định chặn về chiến lược vô hiệu hóa session, và AC rollback tường minh.

**Review đặc tả hiện có — người dùng dán một PRD**

Skill review nó để tìm các ranh giới phạm vi còn thiếu, các yêu cầu không kiểm chứng được ("the system shall be fast"),
và các giả định ngầm, rồi trả về các tiêu chí đã sửa hoặc bổ sung mà không bắt đầu lại giai đoạn khám phá.

## Quy tắc vận hành

1. Kiểm tra context của repository, tài liệu, issue, thiết kế và test sẵn có trước khi
   hỏi về các sự kiện kỹ thuật có thể khám phá được tại chỗ.
2. Không suy ra các ràng buộc sản phẩm hay nghiệp vụ từ code. Business rule, nghĩa vụ compliance
   và quy định pháp lý, SLA theo hợp đồng, giá cả, chính sách lưu giữ dữ liệu, thứ tự ưu tiên,
   và người dùng mục tiêu không thể đọc được từ repository. Coi chúng là chưa biết cho đến khi người dùng
   cung cấp hoặc một artifact sản phẩm có thẩm quyền (PRD, hợp đồng, tài liệu chính sách) nêu rõ.
   Ghi chúng như các giả định được đánh dấu cần xác nhận, KHÔNG BAO GIỜ như sự kiện đã khám phá. Repository
   cho bạn biết hệ thống hành xử thế nào hiện nay, không phải doanh nghiệp yêu cầu nó làm gì.
3. Chỉ hỏi những câu mà đáp án là bắt buộc và không thể suy ra an toàn. Gom nhóm các câu hỏi ngắn,
   liên quan khi điều đó tiết kiệm được các lượt không cần thiết.
4. Không chặn triển khai theo mặc định. Khi người dùng đã yêu cầu triển khai một thay đổi đủ rõ ràng,
   hãy ghi ngắn gọn các giả định chính và acceptance criteria, rồi tiếp tục hoặc chuyển chúng
   cho workflow triển khai.
5. Chỉ yêu cầu người dùng xác nhận tường minh trước khi tiếp tục khi một quyết định chưa giải quyết có thể
   gây ra rủi ro security đáng kể, mất dữ liệu, migration không thể đảo ngược, phá vỡ hợp đồng/API,
   chi phí đáng kể, hoặc hành động phá hủy bên ngoài.
6. Không ghi tài liệu acceptance vào repository, không sửa file dự án, không tạo branch,
   commit, hay gọi skill khác trừ khi người dùng yêu cầu hoặc workflow của repository đang dùng
   yêu cầu tường minh.
7. Coi test tự động là bằng chứng, không phải sự thật. Ưu tiên tự động hóa khi đáng tin cậy và
   tương xứng; cho phép xác minh thủ công về UX, accessibility, security, pháp lý hoặc vận hành
   khi tự động hóa không thể xác lập kết quả.
8. KHÔNG BAO GIỜ đưa secret thật, credential, token, private key, dữ liệu cá nhân, hay payload production
   nhạy cảm vào acceptance criteria, fixture, ví dụ hoặc artifact được lưu. Dùng giá trị đã che
   (redacted) hoặc giá trị tổng hợp.
9. Không chạy test phá hủy, migration, security probe, load test, lệnh gọi bên ngoài có tính phí,
   hay thao tác trên dữ liệu production/live nếu không có ủy quyền tường minh và một môi trường
   an toàn đã được xác định.
10. Khi một acceptance criterion không thể thỏa mãn do ràng buộc về kiến trúc, nền tảng hoặc
   bên ngoài được phát hiện trong quá trình triển khai, không được âm thầm bỏ hoặc né tránh nó.
   Cập nhật tiêu chí bị ảnh hưởng (đánh dấu `[revised]`, nêu ràng buộc, và điều chỉnh phạm vi hoặc
   phương pháp xác minh), tăng số revision, và chỉ trình bày lại các tiêu chí đã thay đổi
   cho người dùng trước khi tiếp tục. Chỉ yêu cầu xác nhận tường minh nếu bản sửa đổi thay đổi
   một quyết định chặn hoặc làm giảm đáng kể các đảm bảo về an toàn hoặc tính đúng đắn.

## Chọn độ sâu

Dùng đầu ra nhỏ nhất mà hữu ích.

### Quick Capture

Dùng cho thay đổi rõ ràng nhưng không tầm thường với rủi ro thấp hoặc vừa. Tạo ra:

- Goal
- In scope / out of scope
- Assumptions
- 3-7 acceptance criteria kèm phương pháp xác minh
- Các câu hỏi chặn, nếu có

Không trì hoãn triển khai để chờ phê duyệt trừ khi tồn tại một rủi ro chặn theo các quy tắc vận hành
hoặc người dùng yêu cầu cụ thể một bản đặc tả trước.

### Full Acceptance Brief

Dùng cho thay đổi mơ hồ, liên hệ thống, nhạy cảm về security, thay đổi dữ liệu, migration, compliance,
hoặc chi phí cao, hoặc khi người dùng yêu cầu một artifact bàn giao. Tạo ra template đầy đủ
bên dưới và yêu cầu xác nhận cho các quyết định chặn chưa giải quyết trước khi triển khai rủi ro.

### Review đặc tả hiện có

Khi người dùng đã cung cấp một PRD, issue, kế hoạch hoặc acceptance criteria:

1. Review nó thay vì bắt đầu lại giai đoạn khám phá.
2. Xác định các ranh giới phạm vi còn thiếu, giả định không an toàn, mâu thuẫn và các yêu cầu
   không kiểm chứng được.
3. Trả về các tiêu chí đã sửa hoặc bổ sung.

## Workflow

### 1. Xác lập Goal và rủi ro

Trích xuất hoặc hỏi về:

- Kết quả quan sát được đối với người dùng hoặc hệ thống.
- Các tác nhân (actor) bị ảnh hưởng.
- Hậu quả thất bại chính.
- Các chiều rủi ro thực sự áp dụng: security/privacy, dữ liệu lưu trữ bền vững, compatibility/API,
  migration, dependency bên ngoài, chi phí, concurrency, hiệu năng, usability/accessibility.

Tránh hỏi các câu chung chung về những rủi ro không liên quan.

### 2. Khám phá context

Khi có sẵn các artifact cục bộ hoặc đã kết nối, chỉ kiểm tra những gì cần thiết:

- Hành vi hiện có và các file hoặc interface liên quan trực tiếp.
- Convention của repository, tài liệu sản phẩm, API contract, schema dữ liệu hoặc lịch sử migration.
- Hạ tầng xác minh hiện có và các lệnh thực tế.
- Dependency bên ngoài và liệu chúng có thể test cô lập hay không.

Ghi các sự kiện đã khám phá tách biệt với các giả định do người dùng cung cấp. Nếu không thể
kiểm tra context, hãy nêu điều gì chưa biết và hỏi các câu hỏi có trọng tâm.

Repository tiết lộ các sự kiện kỹ thuật — hệ thống hành xử thế nào hiện nay, convention và
contract của nó. Nó không tiết lộ các ràng buộc sản phẩm hay nghiệp vụ: business rule, nghĩa vụ
compliance và quy định pháp lý, SLA theo hợp đồng, giá cả, chính sách lưu giữ dữ liệu, thứ tự ưu tiên,
và người dùng mục tiêu. KHÔNG BAO GIỜ dựng lại những thứ này từ code hay cách đặt tên. Chỉ ghi nhận chúng từ người dùng
hoặc một artifact sản phẩm có thẩm quyền, và liệt kê chúng như các giả định cần xác nhận cho đến lúc đó.

### 3. Xác định phạm vi

Nêu rõ:

- Goal: một câu mô tả kết quả dự định.
- In scope: hành vi mà thay đổi này phải mang lại.
- Out of scope: công việc liền kề hấp dẫn nhưng bị loại trừ tường minh.
- Assumptions: các khẳng định chưa được chứng minh.
- Blocking decisions: các lựa chọn chưa giải quyết ảnh hưởng đáng kể đến an toàn hoặc hành vi.

### 4. Viết Acceptance Criteria

Dùng `AC-001`, `AC-002`, v.v. Mỗi tiêu chí phải mô tả hành vi quan sát được và một
phương pháp xác minh phù hợp; tiêu chí và test không bắt buộc ánh xạ một-một.

Với mỗi tiêu chí áp dụng được, bao gồm:

- Kịch bản hoặc điều kiện bắt đầu.
- Hành động hoặc trigger.
- Hành vi quan sát được mong đợi.
- Side effect bị cấm khi có ý nghĩa.
- Phương pháp xác minh: test tự động, kiểm tra integration, review UX thủ công, kiểm tra
  accessibility, security review, kiểm tra vận hành, hoặc stakeholder chấp nhận.
- Ràng buộc môi trường/an toàn khi việc xác minh có thể ảnh hưởng đến dữ liệu, dịch vụ, chi phí hoặc secret.
- Ưu tiên: required, important, hoặc optional.

Không dùng các từ như "correctly", "securely", "fast", "intuitive", hay "robust" nếu không
định nghĩa bằng chứng quan sát được hoặc ghi chúng như một phán đoán do con người review.

### 5. Chỉ bao phủ các ranh giới liên quan

Xem xét các danh mục này, nhưng chỉ đưa vào những danh mục áp dụng:

| Danh mục | Đưa vào khi | Bằng chứng điển hình |
| --- | --- | --- |
| Happy path | Hành vi mới hoặc thay đổi mà người dùng nhìn thấy | Workflow thành công hoặc chuyển trạng thái |
| Validation | Thay đổi nhận đầu vào | Từ chối giá trị sai định dạng hoặc ở biên mà không biến đổi dữ liệu |
| Authorization/privacy | Dữ liệu hoặc hành động có ranh giới truy cập | Truy cập bị từ chối và không rò rỉ thông tin nhạy cảm |
| Persistence/migration | Dữ liệu lưu trữ hoặc schema thay đổi | Đọc ngược tương thích, migration, hành vi rollback hoặc backup |
| Compatibility | API công khai, file, event hoặc client có thể bị phá vỡ | Contract hoặc fixture hiện có vẫn hợp lệ |
| Failure recovery | Tồn tại lỗi mạng, dịch vụ hoặc bất đồng bộ | Không có trạng thái dở dang hoặc hành vi retry/suy giảm rõ ràng |
| Idempotency/concurrency | Có khả năng lặp lại hoặc ghi đồng thời | Không có side effect trùng lặp hoặc trạng thái cuối không hợp lệ |
| Performance | Ngưỡng của người dùng hoặc dịch vụ là quan trọng | Điều kiện đo lường và ngưỡng được định nghĩa |
| UX/accessibility | Một người tương tác với kết quả | Bàn phím, phản hồi, khôi phục lỗi, review trực quan/thủ công |

### 6. Trình bày và tiếp tục

- Với yêu cầu làm rõ/đặc tả, trình bày brief và chỉ xin quyết định cho các điểm chặn
  đã liệt kê.
- Với yêu cầu triển khai không có điểm chặn, trình bày bản tóm tắt tiêu chí gọn như một phần của
  công việc và tiếp tục triển khai.
- Với việc bàn giao cho agent hoặc team khác, đưa vào đủ context và chi tiết xác minh để họ
  hành động mà không phải tự bịa ra yêu cầu.
- Chỉ lưu brief vào file khi được yêu cầu. Dùng đường dẫn đã được repository chấp thuận nếu có;
  nếu không, hãy hỏi hoặc nêu nơi lưu đã chọn trước khi ghi.

## Template đầu ra

Dùng template này cho Full Acceptance Brief. Bỏ qua các mục không liên quan cho Quick Capture.

```markdown
# Acceptance Brief: <Change Name>

**Status:** Draft | Approved | Implemented | Verified
**Revision:** <number>
**Prepared for:** <user/team/agent, when known>
**Approval required before risky work:** Yes | No - <reason>

## Revision Log

| Rev | Date | Changed criteria | Reason |
| --- | --- | --- | --- |
| 1 | <date> | — | Initial draft |

## Goal

<One observable outcome sentence.>

## Scope

**In scope**
- <behavior included>

**Out of scope**
- <adjacent work excluded>

## Context

**Discovered facts** (technical, verified from repository or artifact)
- <how the system behaves today, conventions, contracts>

**Product/business constraints** (supplied by user or product artifact, never inferred from code)
- <business rule, compliance/SLA obligation, retention policy, priority, target user — or "none supplied yet">

**Assumptions**
- <unverified claim to confirm or validate>

**Dependencies and constraints**
- <external service, local convention, compatibility obligation, environment limit>

## Risk Review

| Risk area | Applies? | Required handling |
| --- | --- | --- |
| Security/privacy | Yes/No | <redaction, authorization, review, etc.> |
| Persistent data/migration | Yes/No | <compatibility, backup, rollback, etc.> |
| External effects/cost | Yes/No | <sandbox/test environment/authorization> |
| Compatibility/API | Yes/No | <contract to preserve or version> |
| UX/accessibility | Yes/No | <manual or automated evidence> |

## Acceptance Criteria

### AC-001: <observable behavior>
- **Scenario:** <starting condition>
- **Action:** <single trigger>
- **Expected:** <observable result>
- **Must not:** <prohibited side effect, if applicable>
- **Verification:** <method and intended evidence>
- **Environment/safety:** <constraints, if applicable>
- **Priority:** Required | Important | Optional

## Blocking Decisions

- [ ] <only decisions that prevent safe or correct progress>

## Verification Plan

| Criterion | Verification evidence | Status |
| --- | --- | --- |
| AC-001 | <test/check/review command or evidence type> | Pending |
```

## Ví dụ Pass/Fail

Dùng các ví dụ này để đánh giá liệu skill có thực sự tạo ra một brief kiểm chứng được hay chỉ là văn xuôi kế hoạch.

**Một acceptance criterion thất bại**

```
AC-001: The export works correctly and is secure.
```

Thất bại — "works correctly" và "secure" không quan sát được, không có kịch bản, trigger,
kết quả mong đợi hay phương pháp xác minh, và không có gì nêu điều gì không được xảy ra. Người đọc
không thể biết liệu bản triển khai có thỏa mãn nó hay không.

**Một acceptance criterion đạt**

```
AC-001: Export generates file with correct headers
- Scenario: authenticated user, at least one data row visible
- Action: click "Export CSV"
- Expected: browser downloads file with columns [id, name, created_at]
- Must not: expose internal fields or rows belonging to other users
- Verification: automated integration test + manual schema spot-check
- Priority: Required
```

Đạt — có kết quả quan sát được cụ thể, một side effect bị cấm, và một phương pháp xác minh
được nêu tên. Hai người sẽ đồng ý về việc nó có được đáp ứng hay không.

**Một mục context thất bại**

```
Discovered facts: Users on the free tier are limited to 100 exports per month.
```

Thất bại — giới hạn theo từng tier là một business rule. Nó không được xuất hiện dưới discovered facts
suy ra từ code; nó thuộc về Product/business constraints, do người dùng cung cấp, hoặc được liệt kê như
một giả định cần xác nhận.

### Thang đánh giá Pass/Fail

Một brief chỉ đạt khi mọi câu trả lời đều là "có". Bất kỳ "không" nào có nghĩa là phải sửa trước khi trả về.

- [ ] Mỗi tiêu chí required có một kịch bản, một kết quả mong đợi quan sát được và một phương pháp xác minh được nêu tên?
- [ ] Mọi từ mơ hồ ("correctly", "secure", "fast", "robust") đã được thay bằng bằng chứng quan sát được hoặc đánh dấu là phán đoán của con người?
- [ ] Các ràng buộc sản phẩm/nghiệp vụ được liệt kê là do người dùng cung cấp/giả định, không cái nào bị âm thầm suy ra từ code?
- [ ] Phạm vi tường minh, với các mục out-of-scope được nêu tên?
- [ ] Các quyết định chặn chỉ giới hạn ở những lựa chọn thực sự ảnh hưởng đến an toàn hoặc tính đúng đắn, không phải sở thích?

## Kiểm tra chất lượng

Trước khi trả về brief, hãy kiểm tra:

- Goal mô tả một kết quả chứ không phải một lựa chọn triển khai.
- Ranh giới phạm vi và giả định tường minh.
- Mỗi tiêu chí required quan sát được hoặc được đánh dấu rõ ràng cho phán đoán của con người.
- Các rủi ro về security, privacy, dữ liệu, compatibility, tác động bên ngoài và UX chỉ được xem xét
  khi liên quan và không bị âm thầm bỏ qua.
- Các phương pháp xác minh xác định môi trường an toàn cho các thao tác rủi ro.
- Không có secret hay thông tin nhạy cảm của production nào bị sao chép vào đầu ra.
- Không áp đặt thay đổi repository hay chặn triển khai mà không có lý do chính đáng hoặc yêu cầu.

## Bàn giao

Khi có sẵn một workflow lập kế hoạch hoặc triển khai khác, hãy truyền acceptance brief hoặc
các ID tiêu chí cho nó. Khi không có workflow chuyên dụng, hãy cung cấp trực tiếp brief như
tài liệu tham chiếu triển khai. Không giả định bất kỳ skill hay tool nào có tên đã được cài đặt.
