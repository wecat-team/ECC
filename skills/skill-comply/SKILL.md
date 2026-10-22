---
name: skill-comply
description: "Trực quan hóa việc skill, rule và agent definition có thực sự được tuân thủ hay không — tự động sinh kịch bản ở 3 mức độ chặt chẽ của prompt, chạy agent, phân loại chuỗi hành vi và báo cáo tỷ lệ tuân thủ (compliance) kèm timeline đầy đủ của tool call. Dùng khi cần kiểm tra agent có thực sự tuân theo các skill, rule và definition đã được giao hay không, thay vì mặc định là có."
metadata:
  origin: ECC
tools: Read, Bash
---

# skill-comply: Đo lường mức độ tuân thủ tự động

Đo xem coding agent có thực sự tuân theo skill, rule hoặc agent definition hay không bằng cách:
1. Tự động sinh chuỗi hành vi mong đợi (spec) từ bất kỳ file .md nào
2. Tự động sinh kịch bản với mức độ chặt chẽ của prompt giảm dần (supportive → neutral → competing)
3. Chạy `claude -p` và ghi lại trace của tool call qua stream-json
4. Phân loại tool call theo các bước của spec bằng LLM (không dùng regex)
5. Kiểm tra thứ tự thời gian một cách xác định (deterministic)
6. Tạo báo cáo tự chứa (self-contained) gồm spec, prompt và timeline

## Đối tượng được hỗ trợ

- **Skills** (`skills/*/SKILL.md`): Các skill dạng workflow như search-first, hướng dẫn TDD
- **Rules** (`rules/common/*.md`): Các rule bắt buộc như testing.md, security.md, git-workflow.md
- **Agent definitions** (`agents/*.md`): Kiểm tra agent có được gọi đúng lúc mong đợi hay không (chưa hỗ trợ xác minh workflow bên trong)

## Khi nào kích hoạt

- Người dùng chạy `/skill-comply <path>`
- Người dùng hỏi "rule này có thực sự được tuân thủ không?"
- Sau khi thêm rule/skill mới, để xác minh mức độ tuân thủ của agent
- Định kỳ như một phần của việc duy trì chất lượng

## Cách dùng

```bash
# Full run
uv run python -m scripts.run ~/.claude/rules/common/testing.md

# Dry run (no cost, spec + scenarios only)
uv run python -m scripts.run --dry-run ~/.claude/skills/search-first/SKILL.md

# Custom models
uv run python -m scripts.run --gen-model haiku --model sonnet <path>
```

## Khái niệm then chốt: Prompt Independence (độc lập với prompt)

Đo xem một skill/rule có được tuân thủ hay không ngay cả khi prompt không hỗ trợ nó một cách tường minh.

## Nội dung báo cáo

Báo cáo là tự chứa và bao gồm:
1. Chuỗi hành vi mong đợi (spec tự động sinh)
2. Prompt của các kịch bản (đã yêu cầu gì ở từng mức độ chặt chẽ)
3. Điểm tuân thủ theo từng kịch bản
4. Timeline của tool call kèm nhãn phân loại của LLM

### Nâng cao (tùy chọn)

Với người dùng đã quen với hook, báo cáo còn kèm các khuyến nghị nâng cấp thành hook cho những bước có mức tuân thủ thấp. Đây chỉ là thông tin tham khảo — giá trị chính là khả năng quan sát được mức độ tuân thủ.
