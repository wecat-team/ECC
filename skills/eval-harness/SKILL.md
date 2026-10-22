---
name: eval-harness
description: "Framework eval-driven development (EDD) cho các phiên AI coding — định nghĩa capability eval và regression eval trước khi code, chấm điểm bằng grader dựa trên code, dựa trên model, theo rule hoặc con người, và theo dõi độ tin cậy pass@k và pass^k. Dùng khi định nghĩa tiêu chí pass/fail cho task của agent, đo độ tin cậy của agent, xây dựng bộ regression cho thay đổi prompt hoặc agent, hoặc benchmark giữa các phiên bản model."
metadata:
  origin: ECC
tools: Read, Write, Edit, Bash, Grep, Glob
---

# Skill Eval Harness

Một framework đánh giá chính thức cho các phiên Claude Code, triển khai các nguyên tắc eval-driven development (EDD).

## Khi nào kích hoạt

- Thiết lập eval-driven development (EDD) cho các workflow có AI hỗ trợ
- Định nghĩa tiêu chí pass/fail cho việc hoàn thành task của Claude Code
- Đo độ tin cậy của agent bằng metric pass@k
- Tạo bộ regression test cho thay đổi prompt hoặc agent
- Benchmark hiệu năng agent giữa các phiên bản model

## Triết lý

Eval-Driven Development coi eval như "unit test của phát triển AI":
- Định nghĩa hành vi mong đợi TRƯỚC khi triển khai
- Chạy eval liên tục trong quá trình phát triển
- Theo dõi regression với mỗi thay đổi
- Dùng metric pass@k để đo độ tin cậy

## Các loại Eval

### Capability Eval
Kiểm tra xem Claude có làm được điều mà trước đây không làm được hay không:
```markdown
[CAPABILITY EVAL: feature-name]
Task: Description of what Claude should accomplish
Success Criteria:
  - [ ] Criterion 1
  - [ ] Criterion 2
  - [ ] Criterion 3
Expected Output: Description of expected result
```

### Regression Eval
Đảm bảo các thay đổi không làm hỏng chức năng hiện có:
```markdown
[REGRESSION EVAL: feature-name]
Baseline: SHA or checkpoint name
Tests:
  - existing-test-1: PASS/FAIL
  - existing-test-2: PASS/FAIL
  - existing-test-3: PASS/FAIL
Result: X/Y passed (previously Y/Y)
```

## Các loại Grader

### 1. Grader dựa trên code
Các kiểm tra tất định bằng code:
```bash
# Check if file contains expected pattern
grep -q "export function handleAuth" src/auth.ts && echo "PASS" || echo "FAIL"

# Check if tests pass
npm test -- --testPathPattern="auth" && echo "PASS" || echo "FAIL"

# Check if build succeeds
npm run build && echo "PASS" || echo "FAIL"
```

### 2. Grader dựa trên model
Dùng Claude để đánh giá các đầu ra mở:
```markdown
[MODEL GRADER PROMPT]
Evaluate the following code change:
1. Does it solve the stated problem?
2. Is it well-structured?
3. Are edge cases handled?
4. Is error handling appropriate?

Score: 1-5 (1=poor, 5=excellent)
Reasoning: [explanation]
```

### 3. Grader con người
Đánh dấu để review thủ công:
```markdown
[HUMAN REVIEW REQUIRED]
Change: Description of what changed
Reason: Why human review is needed
Risk Level: LOW/MEDIUM/HIGH
```

## Metric

### pass@k
"Có ít nhất một lần thành công trong k lần thử"
- pass@1: Tỷ lệ thành công ở lần thử đầu tiên
- pass@3: Thành công trong vòng 3 lần thử
- Mục tiêu điển hình: pass@3 > 90%

### pass^k
"Tất cả k lần thử đều thành công"
- Ngưỡng độ tin cậy cao hơn
- pass^3: 3 lần thành công liên tiếp
- Dùng cho các đường dẫn quan trọng (critical path)

## Workflow Eval

### 1. Định nghĩa (Trước khi code)
```markdown
## EVAL DEFINITION: feature-xyz

### Capability Evals
1. Can create new user account
2. Can validate email format
3. Can hash password securely

### Regression Evals
1. Existing login still works
2. Session management unchanged
3. Logout flow intact

### Success Metrics
- pass@3 > 90% for capability evals
- pass^3 = 100% for regression evals
```

### 2. Triển khai
Viết code để vượt qua các eval đã định nghĩa.

### 3. Đánh giá
```bash
# Run capability evals
[Run each capability eval, record PASS/FAIL]

# Run regression evals
npm test -- --testPathPattern="existing"

# Generate report
```

### 4. Báo cáo
```markdown
EVAL REPORT: feature-xyz
========================

Capability Evals:
  create-user:     PASS (pass@1)
  validate-email:  PASS (pass@2)
  hash-password:   PASS (pass@1)
  Overall:         3/3 passed

Regression Evals:
  login-flow:      PASS
  session-mgmt:    PASS
  logout-flow:     PASS
  Overall:         3/3 passed

Metrics:
  pass@1: 67% (2/3)
  pass@3: 100% (3/3)

Status: READY FOR REVIEW
```

## Pattern tích hợp

### Trước khi triển khai
```
/eval define feature-name
```
Tạo file định nghĩa eval tại `.claude/evals/feature-name.md`

### Trong khi triển khai
```
/eval check feature-name
```
Chạy các eval hiện tại và báo cáo trạng thái

### Sau khi triển khai
```
/eval report feature-name
```
Sinh báo cáo eval đầy đủ

## Lưu trữ Eval

Lưu eval trong project:
```
.claude/
  evals/
    feature-xyz.md      # Eval definition
    feature-xyz.log     # Eval run history
    baseline.json       # Regression baselines
```

## Best practice

1. **Định nghĩa eval TRƯỚC khi code** - Buộc phải suy nghĩ rõ ràng về tiêu chí thành công
2. **Chạy eval thường xuyên** - Bắt regression sớm
3. **Theo dõi pass@k theo thời gian** - Giám sát xu hướng độ tin cậy
4. **Dùng code grader khi có thể** - Tất định > xác suất
5. **Review bởi con người cho bảo mật** - KHÔNG BAO GIỜ tự động hóa hoàn toàn các kiểm tra bảo mật
6. **Giữ eval nhanh** - Eval chậm sẽ không được chạy
7. **Version eval cùng với code** - Eval là artifact hạng nhất

## Ví dụ: Thêm xác thực

```markdown
## EVAL: add-authentication

### Phase 1: Define (10 min)
Capability Evals:
- [ ] User can register with email/password
- [ ] User can login with valid credentials
- [ ] Invalid credentials rejected with proper error
- [ ] Sessions persist across page reloads
- [ ] Logout clears session

Regression Evals:
- [ ] Public routes still accessible
- [ ] API responses unchanged
- [ ] Database schema compatible

### Phase 2: Implement (varies)
[Write code]

### Phase 3: Evaluate
Run: /eval check add-authentication

### Phase 4: Report
EVAL REPORT: add-authentication
==============================
Capability: 5/5 passed (pass@3: 100%)
Regression: 3/3 passed (pass^3: 100%)
Status: SHIP IT
```

## Tiện ích framework cục bộ

Các tiện ích cơ học nằm trong `scripts/lib/eval-harness/`:

```sh
node scripts/eval-harness.js example
```

- Capsule: nhật ký liên kết bằng hash với năm lineage và các kiểm tra toàn vẹn cục bộ.
- Inspection: source digest, đường dẫn variant đã được xác thực và cảnh báo cú pháp.
- Replay: tool được khai báo và fixture định địa chỉ theo nội dung. Fixture bị thiếu sẽ
  fail closed; SE3 trở lên bị từ chối khi replay. Chế độ record gọi implementation đã
  đăng ký, vì vậy chỉ đăng ký các hàm đáng tin cậy.
- Receipt: xác minh offline các byte của capsule và artifact, kèm các kiểm tra có tên.
- Retrospective preparation: `node scripts/eval-harness.js capsule group <dir> [<dir> ...]`
  nhóm từ 1 đến 100 snapshot capsule cục bộ đã được chọn tường minh và xác minh, thuộc cùng một
  họ task, theo phiên bản harness đã khai báo. Snapshot lặp lại chỉ được tính một lần;
  danh tính xung đột hoặc capsule không hợp lệ sẽ khiến toàn bộ báo cáo bị từ chối. Đây là
  việc đếm bản ghi chỉ-đọc, không có rollout, điểm số hay promotion mới. Hãy dùng các capsule nhỏ,
  ở trạng thái tĩnh. Payload, đối số thư mục và run/capsule ID thô đều bị
  lược bỏ, nhưng nhãn task-family/version được giữ nguyên văn và các tham chiếu digest
  có thể liên kết được; hãy review chúng trước khi chia sẻ. Việc xác thực vận hành vẫn đang chờ.

Việc thực thi candidate bị vô hiệu hóa trên mọi hệ điều hành vì chưa có backend cô lập OS
đã được xác minh. `gate run`, `runGate`, `runVariant`, việc khởi chạy child trực tiếp,
và effect preload đã ngừng dùng đều từ chối với `gate.isolation_required`. Không có cờ tin cậy
hay executor do caller cung cấp nào có thể vượt qua việc từ chối này. Ví dụ ghi lại
việc từ chối đó và kiểm tra source mà không thực thi hay chấm điểm nó.

Không được trình bày cảnh báo tĩnh, receipt của capsule hay kết quả unit test tiện ích thành công
làm bằng chứng cô lập candidate hay promotion. Một gate trong tương lai đòi hỏi
ranh giới OS được review độc lập, kênh checker và audit được bảo vệ, và
việc từ chối baseline ở mức fatal. Xem `docs/architecture/eval-harness-frameworks.md`.

## Product Eval (v1.8)

Dùng product eval khi chất lượng hành vi không thể được nắm bắt chỉ bằng unit test.

### Các loại Grader

1. Code grader (assertion tất định)
2. Rule grader (ràng buộc regex/schema)
3. Model grader (rubric LLM-as-judge)
4. Human grader (phân xử thủ công cho các đầu ra mơ hồ)

### Hướng dẫn pass@k

- `pass@1`: độ tin cậy trực tiếp
- `pass@3`: độ tin cậy thực tế khi được retry có kiểm soát
- `pass^3`: kiểm tra độ ổn định (cả 3 lần chạy đều phải pass)

Ngưỡng khuyến nghị:
- Capability eval: pass@3 >= 0.90
- Regression eval: pass^3 = 1.00 cho các đường dẫn quan trọng đối với release

### Anti-pattern của Eval

- Overfit prompt vào các ví dụ eval đã biết
- Chỉ đo đầu ra của happy path
- Bỏ qua sự trôi dạt về chi phí và độ trễ trong khi chạy theo tỷ lệ pass
- Cho phép grader flaky trong release gate

### Bố cục artifact Eval tối thiểu

- `.claude/evals/<feature>.md` định nghĩa
- `.claude/evals/<feature>.log` lịch sử chạy
- `docs/releases/<version>/eval-summary.md` snapshot release
