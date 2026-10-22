# Hướng dẫn bảo mật

## Các kiểm tra bảo mật bắt buộc

Trước BẤT KỲ commit nào:
- [ ] Không hardcode secret (API key, mật khẩu, token)
- [ ] Mọi input của người dùng đã được validate
- [ ] Ngăn SQL injection (truy vấn tham số hóa)
- [ ] Ngăn XSS (HTML đã được sanitize)
- [ ] Bật bảo vệ CSRF
- [ ] Đã xác minh authentication/authorization
- [ ] Rate limiting trên mọi endpoint
- [ ] Thông báo lỗi không làm rò rỉ dữ liệu nhạy cảm

## Quản lý Secret

- KHÔNG BAO GIỜ hardcode secret trong source code
- LUÔN LUÔN dùng biến môi trường hoặc secret manager
- Kiểm tra các secret bắt buộc đã có mặt khi khởi động
- Xoay vòng (rotate) mọi secret có thể đã bị lộ

## Quy trình phản ứng bảo mật

Nếu phát hiện vấn đề bảo mật:
1. DỪNG ngay lập tức
2. Dùng agent **security-reviewer**
3. Sửa các vấn đề CRITICAL trước khi tiếp tục
4. Rotate mọi secret đã bị lộ
5. Review toàn bộ codebase để tìm các vấn đề tương tự
