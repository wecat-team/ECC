# Pattern thường dùng

## Skeleton Project

Khi triển khai chức năng mới:
1. Tìm các skeleton project đã được kiểm chứng thực tế
2. Dùng các agent song song để đánh giá các lựa chọn:
   - Đánh giá bảo mật
   - Phân tích khả năng mở rộng
   - Chấm điểm mức độ phù hợp
   - Lập kế hoạch triển khai
3. Clone lựa chọn phù hợp nhất làm nền tảng
4. Lặp lại (iterate) trong cấu trúc đã được kiểm chứng

## Design Pattern

### Repository Pattern

Đóng gói việc truy cập dữ liệu sau một interface nhất quán:
- Định nghĩa các thao tác chuẩn: findAll, findById, create, update, delete
- Các triển khai cụ thể xử lý chi tiết lưu trữ (database, API, file, v.v.)
- Business logic phụ thuộc vào interface trừu tượng, không phụ thuộc cơ chế lưu trữ
- Cho phép hoán đổi nguồn dữ liệu dễ dàng và đơn giản hóa việc test bằng mock

### Định dạng API Response

Dùng một envelope nhất quán cho mọi API response:
- Bao gồm chỉ báo thành công/trạng thái
- Bao gồm data payload (nullable khi có lỗi)
- Bao gồm trường thông báo lỗi (nullable khi thành công)
- Bao gồm metadata cho response có phân trang (total, page, limit)
