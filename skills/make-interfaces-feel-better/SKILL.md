---
name: make-interfaces-feel-better
description: Áp dụng các chi tiết design-engineering cụ thể giúp giao diện trông trau chuốt. Dùng khi review hoặc cải thiện UI spacing, typography, border, shadow, motion, hit area, icon, text wrapping và các trạng thái tương tác.
metadata:
  origin: community
---

# Make Interfaces Feel Better

Dùng skill này cho những chi tiết design-engineering nhỏ cộng dồn lại thành một giao diện
trau chuốt hơn.

Nguồn: được cứu lại từ PR cộng đồng cũ #1659 của `linus707`.

## Khi nào dùng

- Người dùng nói UI có cảm giác sai sai, phẳng, chung chung, chật chội, giật hoặc chưa hoàn thiện.
- Bạn đang xây control, card, list, dashboard, điều hướng, form hoặc
  toolbar.
- Một component cần các trạng thái hover, active, focus, enter, exit, loading hoặc empty.
- Một lần review frontend cần các khuyến nghị before/after cụ thể.

## Nguyên tắc cốt lõi

### Concentric Radius

Với các bề mặt bo góc lồng nhau ở gần nhau:

```text
outer radius = inner radius + padding
```

Nếu padding lớn, hãy coi các lớp là những bề mặt riêng thay vì ép theo
công thức. Điều quan trọng là sự nhất quán về thị giác, không phải sùng bái công thức.

### Optical Alignment

Căn giữa theo hình học không phải lúc nào cũng là căn giữa theo thị giác. Nút icon, tam giác
play, mũi tên, ngôi sao và các icon bất đối xứng thường cần một độ lệch nhỏ. Hãy sửa
SVG nếu có thể; nếu không thì điều chỉnh bằng margin hoặc padding ở mức pixel.

### Shadow và Border

Dùng border để phân tách và cho focus ring. Dùng shadow nhiều lớp khi một card,
button, dropdown hoặc popover cần chiều sâu. Shadow nên trong suốt và
đủ tinh tế để hoạt động trên nhiều màu nền.

### Text Wrapping

- Dùng `text-wrap: balance` cho heading và tiêu đề ngắn.
- Dùng `text-wrap: pretty` cho văn bản thân bài ngắn đến vừa, caption, mô tả
  và mục danh sách.
- Tránh dùng cả hai cho văn xuôi dài, code và nội dung định dạng sẵn.
- Dùng `font-variant-numeric: tabular-nums` cho bộ đếm, timer, giá, bảng
  và các số được cập nhật liên tục khác.

### Font Smoothing

Trên macOS, áp dụng antialiased font smoothing ở layout gốc khi dự án
chưa làm vậy:

```css
html {
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
}
```

### Image Outline

Ảnh thường cần một outline inset tinh tế để cạnh của chúng không bị nhòe vào
bề mặt.

```css
img {
  outline: 1px solid rgba(0, 0, 0, 0.1);
  outline-offset: -1px;
}

@media (prefers-color-scheme: dark) {
  img {
    outline-color: rgba(255, 255, 255, 0.1);
  }
}
```

Dùng outline alpha trung tính đen hoặc trắng. Không nhuộm outline của ảnh bằng
bảng màu thương hiệu.

### Motion

Dùng CSS transition cho các thay đổi trạng thái tương tác vì chúng có thể đổi
hướng khi người dùng đổi ý giữa chừng chuyển động. Dành keyframe cho các hiệu ứng
xuất hiện một lần theo từng giai đoạn hoặc các chuỗi loading.

Các mặc định motion tốt:

- Enter: kết hợp opacity, `translateY` nhỏ, và tùy chọn blur.
- Exit: ngắn hơn và nhẹ hơn enter, thường là 150ms.
- Press: `scale(0.96)` cho các button cần cảm giác chạm, kèm cách tắt nó khi
  chuyển động gây xao nhãng.
- Đổi icon: cross-fade bằng opacity, scale và blur thay vì bật/tắt
  visibility tức thì.

### Transition Scope

Không bao giờ dùng `transition: all`. Hãy chỉ định các property thay đổi:

```css
.button {
  transition-property: transform, background-color, box-shadow;
  transition-duration: 150ms;
  transition-timing-function: ease-out;
}
```

Chỉ dùng `will-change` cho hiện tượng giật ở khung hình đầu trên các
property thân thiện với compositor như `transform`, `opacity` và `filter`. Không bao giờ dùng
`will-change: all`.

### Hit Area

Các control tương tác nên có hit area ít nhất 40x40px, lý tưởng là 44x44px
khi layout cho phép. Mở rộng bằng pseudo-element khi icon hiển thị
nhỏ hơn, nhưng không để các hit area đã mở rộng chồng lên nhau.

## Output của Review

Khi review một lượt trau chuốt UI, hãy báo cáo các thay đổi cụ thể theo từng dòng before/after:

| Nguyên tắc | Before | After |
| --- | --- | --- |
| Concentric radius | Cùng radius ở parent và child | Radius của parent tính đến padding |
| Tabular numbers | Bộ đếm xô lệch khi chữ số thay đổi | Bộ đếm dùng `tabular-nums` |
| Transition scope | `transition: all` | Các transition property tường minh |

Hãy kèm đường dẫn file và property khi chúng không hiển nhiên từ snippet.
Bỏ qua các nguyên tắc mà bạn đã kiểm tra nhưng không thay đổi.

## Checklist

- Các phần tử bo góc lồng nhau nhất quán về thị giác.
- Icon được căn giữa theo thị giác.
- Button, card và popover dùng border hoặc shadow vì đúng lý do.
- Heading và văn bản ngắn tránh xuống dòng vụng về.
- Số động dùng chữ số tabular.
- Ảnh có outline trung tính khi cần.
- Animation enter và exit được tách riêng, tinh tế, và có thể bị ngắt giữa chừng khi
  phù hợp.
- Button có trạng thái active tạo cảm giác chạm mà không cường điệu chuyển động.
- Không có `transition: all` và `will-change: all`.
- Các control nhỏ vẫn có hit area dùng được.
