# Tích hợp Hook cho Self-Evaluation khi kết thúc Session

Thêm hook này vào `hooks/hooks.json` để nhắc agent tự đánh giá vào cuối mỗi session (hook chỉ echo một lời nhắc; nó không tự động chạy evaluator):

```json
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "echo '[Self-Eval] Session complete. Consider running agent-self-evaluation to rate your output.'"
          }
        ],
        "description": "Remind agent to self-evaluate at session end"
      }
    ]
  }
}
```

Các sự kiện `Stop` không yêu cầu trường `matcher` (nó là tùy chọn đối với `Stop`, `Notification`, `UserPromptSubmit` và `SubagentStop` theo `scripts/ci/validate-hooks.js`). Nếu bỏ qua, đối tượng hook chỉ cần `hooks` và metadata như `description`.

## Tích hợp với Python Evaluator

Script `scripts/evaluate.py` có thể được dùng như một công cụ độc lập:

```bash
# Pipe agent output directly
echo "Your agent response here" | python3 skills/agent-self-evaluation/scripts/evaluate.py

# From files
python3 skills/agent-self-evaluation/scripts/evaluate.py --task task.txt --output response.txt
```

Để tích hợp vào hook, hãy capture output cuối cùng của agent vào một file trước, rồi chạy evaluator. Với các lời nhắc nhẹ sau khi xác minh dựa trên shell, hãy dùng một chuỗi matcher đơn giản được hỗ trợ:

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "echo '[Self-Eval] If this command completed verification for a non-trivial task, consider running agent-self-evaluation.'"
          }
        ],
        "description": "Remind agent to self-evaluate after shell verification"
      }
    ]
  }
}
```

Cách này tránh việc tài liệu hóa cú pháp matcher dạng biểu thức lệnh không được hỗ trợ. Nếu harness của bạn hỗ trợ matcher dạng biểu thức ở cấp lệnh, hãy ưu tiên một regex có word-boundary như `\b(pytest|npm test|go test)\b` thay vì một chuỗi con `test` quá rộng.

Các hook này là opt-in. Hãy thêm chúng vào `hooks/hooks.json` cục bộ của bạn nếu muốn có các lời nhắc đánh giá tự động.

## Sử dụng thủ công (khuyến nghị)

Cách đáng tin cậy nhất là gọi thủ công — agent chạy self-evaluation như một phần của quy trình khi skill `agent-self-evaluation` đang hoạt động, mà không cần cấu hình hook. Phần "When to Activate" của skill đã bao gồm các điều kiện kích hoạt (thay đổi nhiều file, phiên debug, tài liệu thiết kế).
