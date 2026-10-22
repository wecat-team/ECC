# Điều phối Agent

## Các Agent khả dụng

Các agent của ECC đến từ plugin `ecc@ecc` (tên có phạm vi plugin, `ecc:<name>`) hoặc từ cài đặt thủ công vào `~/.claude/agents/` (tên trần, `<name>`). Hãy dùng tên khớp với cách bạn đã cài; trình cài đặt thủ công sẽ loại bỏ tiền tố `ecc:` khỏi các file được sao chép.
Chúng được gọi qua tool Agent với `subagent_type` tương ứng:

```text
Agent(subagent_type: "ecc:planner", prompt: "...")
```

| Agent | Mục đích | Khi nào dùng |
|-------|---------|-------------|
| ecc:planner | Lập kế hoạch triển khai | Tính năng phức tạp, refactor |
| ecc:architect | Thiết kế hệ thống | Quyết định kiến trúc |
| ecc:tdd-guide | Phát triển hướng kiểm thử (TDD) | Tính năng mới, sửa bug |
| ecc:code-reviewer | Code review | Sau khi viết code |
| ecc:security-reviewer | Phân tích bảo mật | Trước khi commit |
| ecc:build-error-resolver | Sửa lỗi build | Khi build thất bại |
| ecc:e2e-runner | Kiểm thử E2E | Các luồng người dùng quan trọng |
| ecc:refactor-cleaner | Dọn dẹp dead code | Bảo trì code |
| ecc:doc-updater | Tài liệu | Cập nhật tài liệu |
| ecc:rust-reviewer | Code review Rust | Dự án Rust |
| ecc:harmonyos-app-resolver | Phát triển ứng dụng HarmonyOS | Dự án HarmonyOS/ArkTS |

Để xem danh sách đầy đủ 69 agent, dùng `/ecc:ecc-guide`.

## Dùng Agent ngay lập tức

Không cần người dùng nhắc:
1. Yêu cầu tính năng phức tạp - Dùng agent **ecc:planner**
2. Code vừa được viết/sửa - Dùng agent **ecc:code-reviewer**
3. Sửa bug hoặc tính năng mới - Dùng agent **ecc:tdd-guide**
4. Quyết định kiến trúc - Dùng agent **ecc:architect**

## Thực thi Task song song

LUÔN LUÔN dùng thực thi Task song song cho các thao tác độc lập:

```markdown
# GOOD: Parallel execution
Launch 3 agents in parallel:
1. Agent 1: Security analysis of auth module
2. Agent 2: Performance review of cache system
3. Agent 3: Type checking of utilities

# BAD: Sequential when unnecessary
First agent 1, then agent 2, then agent 3
```

## Hợp đồng hoàn tất khi ủy quyền (Delegation Completion Contract)

Áp dụng cho mọi agent ở mọi độ sâu (cha, con, cháu):

1. **Tin nhắn cuối cùng của bạn CHÍNH LÀ sản phẩm bàn giao.** KHÔNG BAO GIỜ kết thúc lượt bằng "đang chờ các agent chạy nền" — một task đã được khởi tạo không phải là task đã hoàn thành. Kết thúc lượt trong khi các agent con vẫn đang chạy sẽ khiến kết quả của chúng bị bỏ rơi (agent con hoàn thành không thể thông báo cho agent cha đã kết thúc lượt).
2. **Nếu bạn ủy quyền, bạn chịu trách nhiệm thu thập kết quả.** Chờ kết quả, tổng hợp chúng, rồi mới trả về. Ủy quyền kiểu "bắn rồi bỏ" (fire-and-forget) bị cấm.
3. **Chỉ chia nhỏ khi công việc không thể nằm gọn trong một context.** Không ủy quyền lại một task đã có kích thước vừa cho một agent — độ sâu là kết quả, không phải kế hoạch.

> Lý do: failure mode đã quan sát được — các agent nghiên cứu làm theo "Thực thi Task song song" ở trên, tạo ra agent con, rồi trả về "đang chờ" làm câu trả lời cuối cùng. Mọi agent con đều hoàn thành thành công nhưng kết quả của chúng bị bỏ rơi. Quy tắc song song mà không có hợp đồng hoàn tất sẽ tạo ra các task zombie.

## Phân tích đa góc nhìn

Với các vấn đề phức tạp, dùng các sub-agent chia theo vai trò:
- Người review tính xác thực (factual reviewer)
- Kỹ sư cấp cao (senior engineer)
- Chuyên gia bảo mật
- Người review tính nhất quán (consistency reviewer)
- Người kiểm tra trùng lặp (redundancy checker)
