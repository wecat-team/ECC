---
paths:
  - "**/*.ts"
  - "**/*.tsx"
---
# Hiệu năng React Native / Expo

> File này mở rộng [common/performance.md](../common/performance.md) với nội dung dành riêng cho React Native / Expo.

## Rendering

- Memoize các component tốn kém bằng `React.memo`; chỉ memoize callback/giá trị truyền cho component con bằng `useCallback`/`useMemo` ở nơi chúng thực sự ngăn được re-render.
- Giữ state của component ở cục bộ và hẹp — nâng state lên quá cao sẽ re-render các cây con lớn.
- Tránh tạo object/array/function mới inline trong props ở các đường nóng; chúng phá vỡ memoization.
- Tách các màn hình lớn để một thay đổi state chỉ re-render cây con nhỏ nhất có thể.

## Danh sách

- Dùng `FlatList`/`SectionList`, hoặc `FlashList` (Shopify) cho danh sách lớn hoặc không đồng nhất.
- Cung cấp `keyExtractor`, `renderItem` đã memoize, và chiều cao item ổn định khi có thể (`getItemLayout`).
- Tinh chỉnh `initialNumToRender`, `windowSize`, `maxToRenderPerBatch` cho các hàng nặng.
- KHÔNG BAO GIỜ render tập dữ liệu lớn bằng `.map()` bên trong `ScrollView`.

## Hình ảnh & Asset

- Dùng `expo-image` để có caching, priority và placeholder; phục vụ hình ảnh có kích thước phù hợp.
- Tránh tải ảnh độ phân giải đầy đủ vào các thumbnail nhỏ.

## Animation

- Ưu tiên `react-native-reanimated` (chạy trên UI thread) hơn API `Animated` chạy bằng JS.
- Với `Animated` cũ, đặt `useNativeDriver: true` ở nơi được hỗ trợ.
- Giữ các tính toán nặng ra khỏi JS thread; chuyển sang Reanimated worklet hoặc native module.

## Runtime & Build

- Build trên **New Architecture** (Fabric + TurboModules). Nó là mặc định trong các Expo SDK gần đây (vẫn có thể opt-out trên SDK 53–54) và là bắt buộc — không thể tắt — từ SDK 55+. Xác minh mọi dependency native đều tương thích New-Arch trước khi phát hành.
- Đảm bảo **Hermes** được bật (mặc định trong Expo hiện đại) để khởi động nhanh hơn và dùng ít bộ nhớ hơn.
- Hoãn công việc không quan trọng sau first paint; lazy-load các màn hình/module nặng.
- Dùng `InteractionManager.runAfterInteractions` cho công việc có thể chờ đến khi animation kết thúc.

## Đo lường

- Profile bằng React DevTools profiler, Hermes sampling profiler và performance monitor trong app. (Tránh Flipper — nó đã deprecated và không được hỗ trợ trên New Architecture.)
- Chú ý: danh sách dài không ảo hóa, hình ảnh quá lớn, re-render toàn cây thường xuyên, và công việc đồng bộ trên JS thread.
