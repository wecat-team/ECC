---
name: frontend-slides
description: Tạo bài thuyết trình HTML ấn tượng, giàu animation từ đầu hoặc bằng cách chuyển đổi file PowerPoint. Dùng khi người dùng muốn xây dựng presentation, chuyển PPT/PPTX sang web, hoặc tạo slide cho bài talk/pitch. Giúp người không phải designer khám phá phong cách thẩm mỹ của mình qua khám phá trực quan thay vì các lựa chọn trừu tượng.
metadata:
  origin: ECC
---

# Frontend Slides

Tạo bài thuyết trình HTML không dependency, giàu animation, chạy hoàn toàn trong trình duyệt.

Lấy cảm hứng từ cách tiếp cận khám phá trực quan được thể hiện trong tác phẩm của zarazhangrui (ghi công: @zarazhangrui).

## Khi nào kích hoạt

- Tạo talk deck, pitch deck, workshop deck hoặc bài thuyết trình nội bộ
- Chuyển slide `.ppt` hoặc `.pptx` thành bài thuyết trình HTML
- Cải thiện layout, chuyển động hoặc typography của bài thuyết trình HTML hiện có
- Khám phá các phong cách thuyết trình cùng người dùng chưa biết sở thích thiết kế của mình

## Nguyên tắc bất di bất dịch

1. **Không dependency**: mặc định là một file HTML tự chứa với CSS và JS inline.
2. **Vừa khít viewport là bắt buộc**: mọi slide phải nằm gọn trong một viewport, không có cuộn bên trong.
3. **Show, don't tell**: dùng bản xem trước trực quan thay vì bảng câu hỏi phong cách trừu tượng.
4. **Thiết kế khác biệt**: tránh các deck gradient tím chung chung, Inter-trên-nền-trắng, trông như template.
5. **Chất lượng production**: giữ code có comment, accessible, responsive và hiệu năng tốt.

Trước khi tạo, hãy đọc `STYLE_PRESETS.md` để nắm CSS nền an toàn cho viewport, giới hạn mật độ, danh mục preset và các cạm bẫy CSS.

## Workflow

### 1. Xác định chế độ

Chọn một hướng:
- **Bài thuyết trình mới**: người dùng có chủ đề, ghi chú hoặc bản nháp đầy đủ
- **Chuyển đổi PPT**: người dùng có `.ppt` hoặc `.pptx`
- **Cải tiến**: người dùng đã có slide HTML và muốn cải thiện

### 2. Khám phá nội dung

Chỉ hỏi những gì tối thiểu cần thiết:
- mục đích: pitch, giảng dạy, talk hội nghị, cập nhật nội bộ
- độ dài: ngắn (5-10), vừa (10-20), dài (20+)
- trạng thái nội dung: copy hoàn chỉnh, ghi chú thô, chỉ có chủ đề

Nếu người dùng đã có nội dung, hãy yêu cầu họ dán vào trước khi tạo kiểu.

### 3. Khám phá phong cách

Mặc định là khám phá trực quan.

Nếu người dùng đã biết preset mong muốn, bỏ qua bản xem trước và dùng thẳng.

Nếu không:
1. Hỏi deck nên tạo ra cảm giác gì: ấn tượng, tràn năng lượng, tập trung, truyền cảm hứng.
2. Tạo **3 file xem trước một-slide** trong `.ecc-design/slide-previews/`.
3. Mỗi bản xem trước phải tự chứa, thể hiện rõ typography/màu sắc/chuyển động, và giữ dưới khoảng 100 dòng nội dung slide.
4. Hỏi người dùng muốn giữ bản xem trước nào hoặc muốn trộn những yếu tố nào.

Dùng hướng dẫn preset trong `STYLE_PRESETS.md` khi ánh xạ tâm trạng sang phong cách.

### 4. Xây dựng bài thuyết trình

Đầu ra là một trong hai:
- `presentation.html`
- `[presentation-name].html`

Chỉ dùng thư mục `assets/` khi deck chứa ảnh đã trích xuất hoặc do người dùng cung cấp.

Cấu trúc bắt buộc:
- các section slide ngữ nghĩa
- CSS nền an toàn cho viewport từ `STYLE_PRESETS.md`
- CSS custom property cho các giá trị theme
- một class presentation controller cho điều hướng bằng bàn phím, wheel và touch
- Intersection Observer cho animation reveal
- hỗ trợ reduced-motion

### 5. Bắt buộc vừa khít Viewport

Hãy coi đây là cổng kiểm soát cứng.

Quy tắc:
- mọi `.slide` phải dùng `height: 100vh; height: 100dvh; overflow: hidden;`
- mọi cỡ chữ và khoảng cách phải co giãn bằng `clamp()`
- khi nội dung không vừa, hãy tách thành nhiều slide
- không bao giờ xử lý tràn bằng cách thu nhỏ chữ dưới kích thước đọc được
- không bao giờ cho phép thanh cuộn bên trong slide

Dùng giới hạn mật độ và khối CSS bắt buộc trong `STYLE_PRESETS.md`.

### 6. Xác thực

Kiểm tra deck hoàn chỉnh ở các kích thước sau:
- 1920x1080
- 1280x720
- 768x1024
- 375x667
- 667x375

Nếu có browser automation, hãy dùng nó để xác minh không slide nào bị tràn và điều hướng bàn phím hoạt động.

### 7. Bàn giao

Khi bàn giao:
- xóa các file xem trước tạm thời trừ khi người dùng muốn giữ
- mở deck bằng lệnh mở phù hợp với nền tảng khi hữu ích
- tóm tắt đường dẫn file, preset đã dùng, số lượng slide và các điểm tùy chỉnh theme dễ dàng

Dùng lệnh mở đúng cho hệ điều hành hiện tại:
- macOS: `open file.html`
- Linux: `xdg-open file.html`
- Windows: `start "" file.html`

## Chuyển đổi PPT / PPTX

Với việc chuyển đổi PowerPoint:
1. Ưu tiên `python3` với `python-pptx` để trích xuất văn bản, ảnh và ghi chú.
2. Nếu không có `python-pptx`, hãy hỏi xem có nên cài nó hay chuyển sang workflow thủ công/dựa trên export.
3. Giữ nguyên thứ tự slide, speaker note và các asset đã trích xuất.
4. Sau khi trích xuất, chạy cùng workflow chọn phong cách như với bài thuyết trình mới.

Giữ việc chuyển đổi đa nền tảng. Không dựa vào công cụ chỉ có trên macOS khi Python làm được việc đó.

## Yêu cầu triển khai

### HTML / CSS

- Dùng CSS và JS inline trừ khi người dùng muốn rõ ràng một project nhiều file.
- Font có thể đến từ Google Fonts hoặc Fontshare.
- Ưu tiên nền khí quyển, phân cấp chữ mạnh và định hướng thị giác rõ ràng.
- Dùng hình khối trừu tượng, gradient, lưới, noise và hình học thay vì hình minh họa.

### JavaScript

Bao gồm:
- điều hướng bằng bàn phím
- điều hướng touch / swipe
- điều hướng bằng wheel chuột
- chỉ báo tiến độ hoặc chỉ mục slide
- trigger animation reveal-on-enter

### Accessibility

- dùng cấu trúc ngữ nghĩa (`main`, `section`, `nav`)
- giữ độ tương phản dễ đọc
- hỗ trợ điều hướng chỉ bằng bàn phím
- tôn trọng `prefers-reduced-motion`

## Giới hạn mật độ nội dung

Dùng các mức tối đa này trừ khi người dùng yêu cầu rõ ràng slide dày hơn và khả năng đọc vẫn đảm bảo:

| Loại slide | Giới hạn |
|------------|-------|
| Title | 1 heading + 1 subtitle + tagline tùy chọn |
| Content | 1 heading + 4-6 bullet hoặc 2 đoạn ngắn |
| Feature grid | tối đa 6 card |
| Code | tối đa 8-10 dòng |
| Quote | 1 trích dẫn + ghi nguồn |
| Image | 1 ảnh bị giới hạn bởi viewport |

## Anti-Pattern

- gradient startup chung chung không có bản sắc thị giác
- deck dùng system font trừ khi cố ý theo phong cách biên tập
- tường bullet dài
- khối code cần cuộn
- hộp nội dung chiều cao cố định bị vỡ trên màn hình thấp
- hàm CSS phủ định không hợp lệ như `-clamp(...)`

## Skill ECC liên quan

- `frontend-patterns` cho pattern component và tương tác quanh deck
- `liquid-glass-design` khi bài thuyết trình cố ý mượn thẩm mỹ kính của Apple
- `e2e-testing` nếu bạn cần browser verification tự động cho deck cuối cùng

## Checklist bàn giao

- bài thuyết trình chạy từ file cục bộ trong trình duyệt
- mọi slide vừa viewport mà không cần cuộn
- phong cách khác biệt và có chủ đích
- animation có ý nghĩa, không gây nhiễu
- reduced motion được tôn trọng
- đường dẫn file và các điểm tùy chỉnh được giải thích khi bàn giao
