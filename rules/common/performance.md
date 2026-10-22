# Tối ưu hiệu năng

## Chiến lược chọn Model

**Haiku** (90% năng lực của Sonnet, tiết kiệm chi phí gấp 3 lần):
- Các agent nhẹ được gọi thường xuyên
- Pair programming và sinh code
- Worker agent trong hệ thống multi-agent

**Sonnet** (Model code tốt nhất):
- Công việc phát triển chính
- Điều phối các workflow multi-agent
- Các task code phức tạp

**Opus** (Suy luận sâu nhất):
- Các quyết định kiến trúc phức tạp
- Yêu cầu suy luận ở mức tối đa
- Các task nghiên cứu và phân tích

## Quản lý Context Window

Tránh 20% cuối của context window cho:
- Refactor quy mô lớn
- Triển khai tính năng trải rộng nhiều file
- Debug các tương tác phức tạp

Các task ít nhạy cảm với context hơn:
- Sửa một file
- Tạo utility độc lập
- Cập nhật tài liệu
- Sửa bug đơn giản

## Extended Thinking + Plan Mode

Trong Claude Code, adaptive reasoning cho phép model tự chọn mức độ suy nghĩ cho từng task.
Với các model Fable, Sonnet 5 trở lên và Opus 4.7 trở lên, dùng effort để điều khiển suy luận
thay vì ngân sách token cố định. Các mức khả dụng phụ thuộc vào model.

Điều khiển thinking qua:
- **Effort**: Dùng `/effort` trong phiên, `--effort <level>` khi khởi chạy, hoặc `CLAUDE_CODE_EFFORT_LEVEL`. Lưu mức theo từng model trong `modelSettings` ở `~/.claude/settings.json`; key `effortLevel` cấp người dùng cũ không áp dụng cho Opus 5.5 hoặc các model mới hơn.
- **Toggle**: Option+T (macOS) / Alt+T (Windows/Linux), hoặc `alwaysThinkingEnabled` trong settings. Các cách này không thể tắt thinking trên Opus 5.5, Sonnet 5.5 hoặc các model Fable.
- **Ngân sách cố định**: Claude Code bỏ qua các giá trị `MAX_THINKING_TOKENS` dương trên các model adaptive reasoning. Trên Opus 4.6 hoặc Sonnet 4.6, đặt `CLAUDE_CODE_DISABLE_ADAPTIVE_THINKING=1` để dùng ngân sách cố định với `MAX_THINKING_TOKENS`.
- **Verbose mode**: Ctrl+O để xem output của thinking

Xem [Claude Code model configuration](https://code.claude.com/docs/en/model-config#adjust-effort-level)
và [environment variables](https://code.claude.com/docs/en/env-vars) để biết các tùy chọn điều khiển được hỗ trợ.

Với các task phức tạp cần suy luận sâu:
1. Chọn mức effort cao hơn được hỗ trợ, như `/effort high`
2. Bật **Plan Mode** để có cách tiếp cận có cấu trúc
3. Dùng nhiều vòng phản biện (critique) để phân tích kỹ lưỡng
4. Dùng các sub-agent chia theo vai trò để có nhiều góc nhìn đa dạng

## Xử lý sự cố Build

Nếu build thất bại:
1. Dùng agent **build-error-resolver**
2. Phân tích thông báo lỗi
3. Sửa từng bước một
4. Xác minh sau mỗi lần sửa
