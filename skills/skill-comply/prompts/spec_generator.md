<!-- markdownlint-disable MD007 -->
Bạn đang phân tích một file skill/rule dành cho coding agent (Claude Code).
Nhiệm vụ của bạn: trích xuất **chuỗi hành vi quan sát được (observable behavioral sequence)** mà agent cần tuân theo khi skill này đang hoạt động.

Mỗi bước nên được mô tả bằng ngôn ngữ tự nhiên. KHÔNG dùng regex pattern.

CHỈ xuất YAML hợp lệ theo đúng định dạng sau (không có markdown fence, không có bình luận):

id: <kebab-case-id>
name: <Human readable name>
source_rule: <file path provided>
version: "1.0"

steps:
  - id: <snake_case>
    description: <what the agent should do>
    required: true|false
    detector:
      description: <natural language description of what tool call to look for>
      after_step: <step_id this must come after, optional — omit if not needed>
      before_step: <step_id this must come before, optional — omit if not needed>

scoring:
  threshold_promote_to_hook: 0.6

Quy tắc:
- detector.description phải mô tả Ý NGHĨA của tool call, không phải pattern
  Good: "Write or Edit a test file (not an implementation file)"
  Bad: "Write|Edit with input matching test.*\\.py"
- Dùng before_step/after_step cho các skill mà THỨ TỰ quan trọng (ví dụ TDD: test trước, triển khai sau)
- Bỏ các ràng buộc về thứ tự đối với các skill chỉ cần SỰ HIỆN DIỆN
- Chỉ đánh dấu step là required: false khi skill nói "optionally" hoặc "if applicable"
- Lý tưởng là 3-7 bước. Đừng chia nhỏ quá mức
- QUAN TRỌNG: Đặt mọi giá trị chuỗi YAML có chứa dấu hai chấm trong dấu nháy kép
  Good: description: "Use conventional commit format (type: description)"
  Bad: description: Use conventional commit format (type: description)

Skill file to analyze:

---
{skill_content}
---
