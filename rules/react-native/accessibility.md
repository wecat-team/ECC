---
paths:
  - "**/*.ts"
  - "**/*.tsx"
---
# Khả năng truy cập (Accessibility) cho React Native / Expo

> Mở rộng chuẩn chất lượng của ECC sang khả năng truy cập (a11y). Hãy coi a11y là yêu cầu của bản release, không phải việc làm sau.
> Mục tiêu: dùng được với trình đọc màn hình (VoiceOver trên iOS, TalkBack trên Android) và ở cỡ chữ lớn.

## Gắn nhãn

- Mọi phần tử tương tác đều có `accessibilityRole` và `accessibilityLabel` (hoặc văn bản con có thể đọc được).
- Nút chỉ có icon PHẢI có `accessibilityLabel` — không có văn bản hiển thị nào để trình đọc thông báo.
- Chỉ dùng `accessibilityHint` khi hành động không hiển nhiên; giữ ngắn gọn.
- Nhóm các phần tử liên quan bằng `accessible` trên container để chúng được thông báo như một đơn vị khi phù hợp.

```tsx
<Pressable
  accessibilityRole="button"
  accessibilityLabel="Delete item"
  onPress={onDelete}
>
  <TrashIcon />
</Pressable>
```

## State & Live Region

- Truyền đạt state bằng `accessibilityState` (ví dụ `{ disabled, selected, checked, expanded }`).
- Thông báo các thay đổi bất đồng bộ/tạm thời (toast, lỗi validation) qua `accessibilityLiveRegion` (Android) và `AccessibilityInfo.announceForAccessibility` khi cần.
- Phản ánh trạng thái loading/error/empty bằng văn bản mà trình đọc tiếp cận được — không chỉ bằng spinner hay màu sắc.

## Vùng chạm & Bố cục

- Vùng chạm tối thiểu khoảng 44x44pt (iOS) / 48x48dp (Android); dùng `hitSlop` để mở rộng các điều khiển nhỏ.
- Tôn trọng Dynamic Type / font scaling — tránh chiều cao cố định làm cắt chữ khi phóng to; test ở cỡ chữ accessibility lớn nhất.
- Tôn trọng `prefers-reduced-motion` (`AccessibilityInfo.isReduceMotionEnabled`) — chặn các animation không thiết yếu.

## Màu sắc & Độ tương phản

- Không truyền đạt ý nghĩa chỉ bằng màu; kết hợp với văn bản, icon hoặc hình dạng.
- Đạt độ tương phản WCAG AA: 4.5:1 cho văn bản thường, 3:1 cho văn bản lớn và các phần tử UI/đồ họa có ý nghĩa.
- Kiểm tra cả theme sáng và tối.

## Focus & Điều hướng

- Thứ tự focus hợp lý; chuyển focus tới nội dung mới (modal, màn hình) khi mở và khôi phục khi đóng.
- Đảm bảo các component tùy chỉnh có thể tiếp cận và thao tác được bằng trình đọc màn hình, không chỉ bằng cảm ứng.

## Kiểm thử

- Test thủ công với VoiceOver và TalkBack trên thiết bị thật — kiểm tra tự động không bắt được mọi thứ.
- Trong component test, truy vấn theo role/label (xem testing.md) để a11y và test củng cố lẫn nhau.
- Đưa a11y vào cổng kiểm tra trước release: các flow chính phải qua được một lượt duyệt bằng trình đọc màn hình.
