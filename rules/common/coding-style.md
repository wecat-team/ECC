# Phong cách code

## Bất biến - Immutability (CRITICAL)

LUÔN LUÔN tạo object mới, KHÔNG BAO GIỜ mutate object hiện có:

```
// Pseudocode
WRONG:  modify(original, field, value) → changes original in-place
CORRECT: update(original, field, value) → returns new copy with change
```

Lý do: Dữ liệu bất biến (immutable) ngăn các side effect ẩn, giúp debug dễ hơn và cho phép xử lý đồng thời (concurrency) an toàn.

## Nguyên tắc cốt lõi

### KISS (Keep It Simple)

- Ưu tiên giải pháp đơn giản nhất mà thực sự hoạt động
- Tránh tối ưu hóa sớm
- Tối ưu cho sự rõ ràng thay vì sự khéo léo

### DRY (Don't Repeat Yourself)

- Tách logic lặp lại thành hàm hoặc utility dùng chung
- Tránh việc các bản triển khai copy-paste dần lệch nhau
- Chỉ đưa vào abstraction khi sự lặp lại là thật, không phải suy đoán

### YAGNI (You Aren't Gonna Need It)

- Không xây dựng tính năng hay abstraction trước khi cần
- Tránh tính tổng quát mang tính suy đoán
- Bắt đầu đơn giản, rồi refactor khi áp lực thực sự xuất hiện

## Tổ chức file

NHIỀU FILE NHỎ > ÍT FILE LỚN:
- Tính gắn kết cao (high cohesion), liên kết lỏng (low coupling)
- Thông thường 200-400 dòng, với 800 dòng là ngưỡng mềm về khả năng bảo trì cho file nguồn
- File test, file sinh tự động (generated) và file vendored có thể vượt ngưỡng khi kích thước được biện minh bởi vai trò của chúng
- Tách utility ra khỏi các module lớn
- Tổ chức theo feature/domain, không theo loại

## Xử lý lỗi

LUÔN LUÔN xử lý lỗi một cách toàn diện:
- Xử lý lỗi tường minh ở mọi tầng
- Cung cấp thông báo lỗi thân thiện với người dùng trong code hướng đến UI
- Log chi tiết ngữ cảnh lỗi ở phía server
- Không bao giờ nuốt lỗi một cách im lặng

## Kiểm tra đầu vào (Input Validation)

LUÔN LUÔN validate tại các ranh giới của hệ thống:
- Validate mọi input của người dùng trước khi xử lý
- Dùng validation dựa trên schema khi có thể
- Fail fast với thông báo lỗi rõ ràng
- Không bao giờ tin dữ liệu bên ngoài (API response, input người dùng, nội dung file)

## Quy ước đặt tên

> **Lưu ý về ngôn ngữ**: Rule này có thể bị ghi đè bởi các rule riêng của từng ngôn ngữ
> đối với những ngôn ngữ mà một pattern không phải là idiom. Quy tắc viết hoa/thường và
> các tiền tố riêng của framework thuộc về rule của ngôn ngữ hoặc package tương ứng.

Độc lập với ngôn ngữ:

- Tên mô tả rõ: tên cho biết thứ đó chứa gì hoặc làm gì, không cần comment.
- Tên boolean đọc lên như một mệnh đề rõ ràng theo quy ước của ngôn ngữ hoặc package áp dụng.
- Ở những ngôn ngữ có phân biệt, hằng số và type phải khác biệt về mặt hình thức so với các giá trị thông thường, theo dạng mà rule của ngôn ngữ hoặc package đó định nghĩa.

## Code Smell cần tránh

### Lồng sâu (Deep Nesting)

Ưu tiên early return thay cho điều kiện lồng nhau khi logic bắt đầu chồng chất.

### Magic Number

Dùng hằng số có tên cho các ngưỡng, độ trễ và giới hạn có ý nghĩa.

### Hàm dài (Long Functions)

Tách các hàm lớn thành những phần tập trung với trách nhiệm rõ ràng.

## Checklist chất lượng code

Trước khi đánh dấu công việc hoàn thành:
- [ ] Code dễ đọc và đặt tên tốt
- [ ] Hàm nhỏ (<50 dòng)
- [ ] File tập trung (<800 dòng)
- [ ] Không lồng sâu (>4 cấp)
- [ ] Xử lý lỗi đúng cách
- [ ] Không hardcode giá trị (dùng hằng số hoặc config)
- [ ] Không mutation (dùng các pattern bất biến)
