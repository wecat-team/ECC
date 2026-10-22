---
paths:
  - "**/*.css"
  - "**/*.scss"
  - "**/*.sass"
  - "**/*.less"
  - "**/*.html"
  - "**/*.tsx"
  - "**/*.jsx"
  - "**/*.vue"
  - "**/*.svelte"
---
> File này mở rộng [common/patterns.md](../common/patterns.md) với hướng dẫn chất lượng thiết kế riêng cho web.

# Tiêu chuẩn chất lượng thiết kế Web

## Chính sách chống Template

Không phát hành UI trông như template chung chung. Output frontend phải trông có chủ đích, có chính kiến và đặc thù cho sản phẩm.

### Các pattern bị cấm

- Lưới card mặc định với khoảng cách đồng đều và không có thứ bậc
- Hero section kiểu có sẵn với headline căn giữa, gradient blob và CTA chung chung
- Mặc định của thư viện không chỉnh sửa mà được coi như thiết kế hoàn chỉnh
- Layout phẳng không có lớp (layering), chiều sâu hay chuyển động
- Bo góc, khoảng cách và đổ bóng đồng nhất trên mọi component
- Phong cách xám-trên-trắng an toàn với một màu nhấn trang trí
- Layout dashboard làm theo công thức với sidebar + card + biểu đồ và không có quan điểm riêng
- Font stack mặc định được dùng mà không có lý do cân nhắc

### Các phẩm chất bắt buộc

Mỗi bề mặt frontend có ý nghĩa nên thể hiện ít nhất bốn trong số các điểm sau:

1. Thứ bậc rõ ràng thông qua tương phản về tỷ lệ (scale)
2. Nhịp điệu khoảng cách có chủ đích, không phải padding đồng đều ở mọi nơi
3. Chiều sâu hoặc lớp thông qua chồng lấp, đổ bóng, bề mặt hoặc chuyển động
4. Typography có cá tính và chiến lược phối font thực sự
5. Màu sắc được dùng có ngữ nghĩa, không chỉ để trang trí
6. Trạng thái hover, focus và active có cảm giác được thiết kế
7. Bố cục editorial hoặc bento phá lưới khi phù hợp
8. Texture, grain hoặc bầu không khí khi hợp với định hướng thị giác
9. Chuyển động làm rõ luồng thay vì gây xao nhãng
10. Trực quan hóa dữ liệu được xem là một phần của design system, không phải việc nghĩ sau

## Trước khi viết code Frontend

1. Chọn một định hướng phong cách cụ thể. Tránh các mặc định mơ hồ như "clean minimal".
2. Định nghĩa bảng màu có chủ đích.
3. Chọn typography một cách cân nhắc.
4. Thu thập ít nhất một tập nhỏ tham chiếu thực tế.
5. Dùng các skill thiết kế/frontend của ECC khi liên quan.

## Các định hướng phong cách đáng cân nhắc

- Editorial / magazine
- Neo-brutalism
- Glassmorphism với chiều sâu thực sự
- Dark luxury hoặc light luxury với độ tương phản có kỷ luật
- Layout bento
- Scrollytelling
- Tích hợp 3D
- Swiss / International
- Retro-futurism

Đừng mặc định chuyển sang dark mode. Hãy chọn định hướng thị giác mà sản phẩm thực sự cần.

## Checklist cho Component

- [ ] Nó có tránh trông như một template Tailwind hay shadcn mặc định không?
- [ ] Nó có các trạng thái hover/focus/active có chủ đích không?
- [ ] Nó có dùng thứ bậc thay vì nhấn mạnh đồng đều không?
- [ ] Nó có trông đáng tin trong ảnh chụp màn hình sản phẩm thật không?
- [ ] Nếu hỗ trợ cả hai theme, cả light và dark có cảm giác có chủ đích không?
