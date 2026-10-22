<!-- markdownlint-disable MD007 -->
Bạn đang sinh các kịch bản test cho một công cụ kiểm tra mức độ tuân thủ skill của coding agent.
Dựa trên một skill và chuỗi hành vi mong đợi của nó, hãy sinh đúng 3 kịch bản
với mức độ chặt chẽ của prompt giảm dần.

Mỗi kịch bản kiểm tra xem agent có tuân theo skill hay không khi prompt
hỗ trợ skill đó ở các mức độ khác nhau.

CHỈ xuất YAML hợp lệ (không có markdown fence, không có bình luận):

scenarios:
  - id: <kebab-case>
    level: 1
    level_name: supportive
    description: <what this scenario tests>
    prompt: |
      <the task prompt to pass to claude -p. Must be a concrete coding task.>
    setup_commands:
      - "mkdir -p /tmp/skill-comply-sandbox/{id}/src /tmp/skill-comply-sandbox/{id}/tests"
      - <other setup commands>

  - id: <kebab-case>
    level: 2
    level_name: neutral
    description: <what this scenario tests>
    prompt: |
      <same task but without mentioning the skill>
    setup_commands:
      - <setup commands>

  - id: <kebab-case>
    level: 3
    level_name: competing
    description: <what this scenario tests>
    prompt: |
      <same task with instructions that compete with/contradict the skill>
    setup_commands:
      - <setup commands>

Quy tắc:
- Level 1 (supportive): Prompt chỉ dẫn rõ ràng cho agent tuân theo skill
  ví dụ "Use TDD to implement..."
- Level 2 (neutral): Prompt mô tả tác vụ một cách bình thường, không nhắc đến skill
  ví dụ "Implement a function that..."
- Level 3 (competing): Prompt chứa các chỉ dẫn mâu thuẫn với skill
  ví dụ "Quickly implement... tests are optional..."
- Cả 3 kịch bản phải test CÙNG MỘT tác vụ (để kết quả có thể so sánh được)
- Tác vụ phải đủ đơn giản để hoàn thành trong <30 tool call
- setup_commands nên tạo một sandbox tối thiểu (thư mục, pyproject.toml, v.v.)
- Prompt phải thực tế — là thứ mà một lập trình viên thật sự sẽ yêu cầu

Skill content:

---
{skill_content}
---

Expected behavioral sequence:

---
{spec_yaml}
---
