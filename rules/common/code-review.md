# Tiêu chuẩn Code Review

## Mục đích

Code review đảm bảo chất lượng, bảo mật và khả năng bảo trì trước khi code được merge. Rule này định nghĩa khi nào và cách thực hiện code review.

## Khi nào cần review

**Các tình huống BẮT BUỘC review:**

- Sau khi viết hoặc sửa code
- Trước mọi commit lên các branch dùng chung
- Khi thay đổi code nhạy cảm về bảo mật (xác thực, thanh toán, dữ liệu người dùng)
- Khi có thay đổi kiến trúc
- Trước khi merge pull request

**Yêu cầu trước khi review:**

Trước khi yêu cầu review, hãy đảm bảo:

- Mọi kiểm tra tự động (CI/CD) đều pass
- Merge conflict đã được giải quyết
- Branch đã cập nhật so với branch đích

## Checklist review

Trước khi đánh dấu code hoàn thành:

- [ ] Code dễ đọc và đặt tên tốt
- [ ] Hàm tập trung vào một việc (<50 dòng)
- [ ] File nguồn có tính gắn kết cao (dưới ngưỡng mềm 800 dòng về khả năng bảo trì, hoặc kèm lý do cho ngoại lệ có chủ đích)
- [ ] Không lồng sâu (>4 cấp)
- [ ] Lỗi được xử lý tường minh
- [ ] Không hardcode secret hoặc credential
- [ ] Không có console.log hoặc câu lệnh debug
- [ ] Có test cho chức năng mới
- [ ] Test coverage đạt tối thiểu 80%

## Các tình huống cần security review

**DỪNG LẠI và dùng agent security-reviewer khi:**

- Code xác thực (authentication) hoặc phân quyền (authorization)
- Xử lý input của người dùng
- Truy vấn database
- Thao tác với hệ thống file
- Gọi API bên ngoài
- Thao tác mật mã (cryptographic)
- Code thanh toán hoặc tài chính

## Mức độ nghiêm trọng của review

| Mức | Ý nghĩa | Hành động |
|-----|---------|-----------|
| CRITICAL | Lỗ hổng bảo mật hoặc rủi ro mất dữ liệu | **BLOCK** - PHẢI sửa trước khi merge |
| HIGH | Bug hoặc vấn đề chất lượng đáng kể | **WARN** - Nên sửa trước khi merge |
| MEDIUM | Vấn đề về khả năng bảo trì, bao gồm file nguồn vượt ngưỡng mềm 800 dòng mà không có giải thích | **INFO** - Cân nhắc sửa |
| LOW | Style hoặc gợi ý nhỏ | **NOTE** - Tùy chọn |

## Sử dụng Agent

Dùng các agent sau cho code review:

| Agent | Mục đích |
|-------|---------|
| **code-reviewer** | Chất lượng code chung, pattern, best practice |
| **security-reviewer** | Lỗ hổng bảo mật, OWASP Top 10 |
| **typescript-reviewer** | Các vấn đề riêng của TypeScript/JavaScript |
| **python-reviewer** | Các vấn đề riêng của Python |
| **go-reviewer** | Các vấn đề riêng của Go |
| **rust-reviewer** | Các vấn đề riêng của Rust |

## Quy trình review

```
1. Run git diff to understand changes
2. Check security checklist first
3. Review code quality checklist
4. Run relevant tests
5. Verify coverage >= 80%
6. Use appropriate agent for detailed review
```

## Các vấn đề thường gặp cần bắt

### Bảo mật

- Credential bị hardcode (API key, mật khẩu, token)
- SQL injection (nối chuỗi trong truy vấn)
- Lỗ hổng XSS (input người dùng chưa được escape)
- Path traversal (đường dẫn file chưa được sanitize)
- Thiếu bảo vệ CSRF
- Authentication bypass

### Chất lượng code

- Hàm lớn (>50 dòng) - tách thành các hàm nhỏ hơn
- File lớn (>800 dòng) - tách thành các module
- Lồng sâu (>4 cấp) - dùng early return
- Thiếu xử lý lỗi - xử lý tường minh
- Pattern mutation - ưu tiên các thao tác bất biến (immutable)
- Thiếu test - bổ sung test coverage

### Hiệu năng

- Truy vấn N+1 - dùng JOIN hoặc batching
- Thiếu phân trang - thêm LIMIT cho truy vấn
- Truy vấn không giới hạn - thêm ràng buộc
- Thiếu caching - cache các thao tác tốn kém

## Tiêu chí phê duyệt

- **Approve**: Không có vấn đề CRITICAL hoặc HIGH
- **Warning**: Chỉ có vấn đề HIGH (merge một cách thận trọng)
- **Block**: Phát hiện vấn đề CRITICAL

## Tích hợp với các Rule khác

Rule này phối hợp với:

- [testing.md](testing.md) - Yêu cầu test coverage
- [security.md](security.md) - Checklist bảo mật
- [git-workflow.md](git-workflow.md) - Tiêu chuẩn commit
- [agents.md](agents.md) - Ủy quyền cho agent
