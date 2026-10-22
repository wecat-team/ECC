---
description: Chạy vòng lặp build generator/evaluator cho các tác vụ triển khai với số vòng lặp giới hạn và chấm điểm.
---

Parse các mục sau từ $ARGUMENTS:
1. `brief` — mô tả một dòng của người dùng về thứ cần xây dựng
2. `--max-iterations N` — (tùy chọn, mặc định 15) số chu kỳ generator-evaluator tối đa
3. `--pass-threshold N` — (tùy chọn, mặc định 7.0) điểm có trọng số để đạt
4. `--skip-planner` — (tùy chọn) bỏ qua planner, giả định spec.md đã tồn tại
5. `--eval-mode MODE` — (tùy chọn, mặc định "playwright") một trong: playwright, screenshot, code-only

## GAN-Style Harness Build

Command này điều phối một vòng lặp build ba agent, lấy cảm hứng từ bài báo về thiết kế harness của Anthropic hồi tháng 3 năm 2026.

### Giai đoạn 0: Thiết lập
1. Tạo thư mục `gan-harness/` ở gốc dự án
2. Tạo các thư mục con: `gan-harness/feedback/`, `gan-harness/screenshots/`
3. Khởi tạo git nếu chưa được khởi tạo
4. Ghi log thời điểm bắt đầu và cấu hình

### Giai đoạn 1: Lập kế hoạch (Planner Agent)
Trừ khi đặt `--skip-planner`:
1. Khởi chạy agent `gan-planner` qua công cụ Task với brief của người dùng
2. Chờ nó tạo ra `gan-harness/spec.md` và `gan-harness/eval-rubric.md`
3. Hiển thị tóm tắt spec cho người dùng
4. Chuyển sang Giai đoạn 2

### Giai đoạn 2: Vòng lặp Generator-Evaluator
```
iteration = 1
while iteration <= max_iterations:

    # GENERATE
    Launch gan-generator agent via Task tool:
    - Read spec.md
    - If iteration > 1: read feedback/feedback-{iteration-1}.md
    - Build/improve the application
    - Ensure dev server is running
    - Commit changes

    # Wait for generator to finish

    # EVALUATE
    Launch gan-evaluator agent via Task tool:
    - Read eval-rubric.md and spec.md
    - Test the live application (mode: playwright/screenshot/code-only)
    - Score against rubric
    - Write feedback to feedback/feedback-{iteration}.md

    # Wait for evaluator to finish

    # CHECK SCORE
    Read feedback/feedback-{iteration}.md
    Extract weighted total score

    if score >= pass_threshold:
        Log "PASSED at iteration {iteration} with score {score}"
        Break

    if iteration >= 3 and score has not improved in last 2 iterations:
        Log "PLATEAU detected — stopping early"
        Break

    iteration += 1
```

### Giai đoạn 3: Tóm tắt
1. Đọc tất cả file feedback
2. Hiển thị điểm cuối cùng và lịch sử các vòng lặp
3. Hiển thị diễn biến điểm: `iteration 1: 4.2 → iteration 2: 5.8 → ... → iteration N: 7.5`
4. Liệt kê các vấn đề còn tồn tại từ lần đánh giá cuối
5. Báo cáo tổng thời gian và chi phí ước tính

### Output

```markdown
## GAN Harness Build Report

**Brief:** [original prompt]
**Result:** PASS/FAIL
**Iterations:** N / max
**Final Score:** X.X / 10

### Score Progression
| Iter | Design | Originality | Craft | Functionality | Total |
|------|--------|-------------|-------|---------------|-------|
| 1 | ... | ... | ... | ... | X.X |
| 2 | ... | ... | ... | ... | X.X |
| N | ... | ... | ... | ... | X.X |

### Remaining Issues
- [Any issues from final evaluation]

### Files Created
- gan-harness/spec.md
- gan-harness/eval-rubric.md
- gan-harness/feedback/feedback-001.md through feedback-NNN.md
- gan-harness/generator-state.md
- gan-harness/build-report.md
```

Ghi báo cáo đầy đủ vào `gan-harness/build-report.md`.
