---
description: Chạy vòng lặp thiết kế generator/evaluator cho công việc frontend hoặc trực quan với số vòng lặp giới hạn và chấm điểm.
---

Parse các mục sau từ $ARGUMENTS:
1. `brief` — mô tả của người dùng về thiết kế cần tạo
2. `--max-iterations N` — (tùy chọn, mặc định 10) số chu kỳ design-evaluate tối đa
3. `--pass-threshold N` — (tùy chọn, mặc định 7.5) điểm có trọng số để đạt (mặc định cao hơn cho design)

## GAN-Style Design Harness

Một vòng lặp hai agent (Generator + Evaluator) tập trung vào chất lượng thiết kế frontend. Không có planner — brief CHÍNH LÀ spec.

Đây là chế độ giống với chế độ Anthropic đã dùng cho các thử nghiệm thiết kế frontend, nơi họ thấy những đột phá sáng tạo như bảo tàng nghệ thuật Hà Lan 3D với CSS perspective và điều hướng qua ô cửa.

### Thiết lập
1. Tạo thư mục `gan-harness/`
2. Ghi brief trực tiếp thành `gan-harness/spec.md`
3. Ghi một `gan-harness/eval-rubric.md` tập trung vào thiết kế, với trọng số cao hơn cho Design Quality và Originality

### Eval Rubric dành riêng cho thiết kế
```markdown
### Design Quality (weight: 0.35)
### Originality (weight: 0.30)
### Craft (weight: 0.25)
### Functionality (weight: 0.10)
```

Lưu ý: Trọng số Originality cao hơn (0.30 so với 0.20) để thúc đẩy các đột phá sáng tạo. Trọng số Functionality thấp hơn vì chế độ design tập trung vào chất lượng trực quan.

### Vòng lặp
Giống Giai đoạn 2 của `/project:gan-build`, nhưng:
- Bỏ qua planner
- Dùng rubric tập trung vào thiết kế
- Prompt của Generator nhấn mạnh chất lượng trực quan hơn là sự hoàn chỉnh của tính năng
- Prompt của Evaluator nhấn mạnh "liệu cái này có giành được giải thiết kế không?" hơn là "mọi tính năng có hoạt động không?"

### Khác biệt chính so với gan-build
Generator được dặn: "Your PRIMARY goal is visual excellence. A stunning half-finished app beats a functional ugly one. Push for creative leaps — unusual layouts, custom animations, distinctive color work."
