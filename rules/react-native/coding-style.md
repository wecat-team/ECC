---
paths:
  - "**/*.ts"
  - "**/*.tsx"
---
# Phong cách code React Native / Expo

> File này mở rộng [common/coding-style.md](../common/coding-style.md) với nội dung dành riêng cho React Native / Expo.

## Component

- Định nghĩa props bằng `interface` hoặc `type` có tên; không dùng `React.FC`.
- Giữ screen mỏng: một screen kết hợp hook + các presentational component, không chứa logic nặng.
- Mỗi file một component cho mọi thứ có thể tái sử dụng; đặt cùng chỗ các subcomponent private nhỏ.
- Ưu tiên function component và hook. Không dùng class component.

```tsx
interface AvatarProps {
  uri: string
  size?: number
  onPress?: () => void
}

export function Avatar({ uri, size = 40, onPress }: AvatarProps) {
  return (
    <Pressable onPress={onPress}>
      <Image source={{ uri }} style={{ width: size, height: size, borderRadius: size / 2 }} />
    </Pressable>
  )
}
```

## Styling

Chọn MỘT hệ thống styling cho mỗi dự án và giữ nhất quán. `StyleSheet.create()` là lựa chọn gốc của framework; các thư viện utility-class (ví dụ NativeWind) là một lựa chọn thay thế phổ biến. Rule này không phụ thuộc thư viện — điều quan trọng là sự nhất quán và tránh cấp phát inline.

- StyleSheet: định nghĩa style bằng `StyleSheet.create()` ở phạm vi module — KHÔNG BAO GIỜ dựng style object inline bên trong `render`/JSX ở các đường nóng (nó cấp phát lại mỗi lần render).
- Cách tiếp cận utility-class: tách các chuỗi class lặp lại thành hằng số dùng chung hoặc một variant helper.
- KHÔNG BAO GIỜ hardcode màu, spacing hay cỡ chữ thô rải rác trong nhiều file. Tập trung hóa design token (file theme hoặc config).

```tsx
// WRONG: inline style object recreated every render
<View style={{ padding: 16, backgroundColor: '#fff' }} />

// CORRECT (StyleSheet)
const styles = StyleSheet.create({ card: { padding: 16, backgroundColor: '#fff' } })
<View style={styles.card} />

// CORRECT (NativeWind)
<View className="p-4 bg-white" />
```

## Khác biệt giữa các nền tảng

- Dùng file riêng theo nền tảng (`Component.ios.tsx`, `Component.android.tsx`) khi có sự khác biệt đáng kể.
- Chỉ dùng `Platform.select()` / `Platform.OS` cho các khác biệt nhỏ.
- Xử lý safe area bằng `react-native-safe-area-context`; không hardcode offset của status bar / notch.

## Import & Bố cục dự án

- Dùng path alias của Expo/TS (ví dụ `@/components/...`) thay vì chuỗi đường dẫn tương đối dài.
- Tổ chức theo feature/domain, không theo loại. Giữ file tập trung (thông thường 200-400 dòng, tối đa 800).

## Logging

- Không có `console.log` trong code phát hành. Dùng logger và loại bỏ log trong bản build production.
- Hiển thị lỗi cho người dùng qua state của UI, không qua console.

## TypeScript

Mọi rule TypeScript trong `rules/typescript/` đều áp dụng (type tường minh trên API public, tránh `any`, dùng Zod để validate, cập nhật bất biến). File này chỉ bổ sung hướng dẫn riêng cho RN ở bên trên.
