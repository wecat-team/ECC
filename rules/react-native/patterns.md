---
paths:
  - "**/*.ts"
  - "**/*.tsx"
---
# Pattern React Native / Expo

> File này mở rộng [common/patterns.md](../common/patterns.md) với các pattern riêng cho React Native / Expo.
> Lưu ý: KHÔNG cài bộ rule `web/` trong dự án React Native — các pattern đó giả định có DOM (ví dụ URL-as-state) và không áp dụng ở đây.

## Điều hướng (Expo Router)

Expo Router là router tích hợp sẵn của Expo, dựa trên file (thư mục `app/`); React Navigation là lựa chọn thay thế đã được thiết lập vững chắc. Các ví dụ bên dưới dùng Expo Router; các nguyên tắc áp dụng cho cả hai.

- Giữ các route file (`app/**`) mỏng — chúng nối params + hook vào một screen component nằm trong `components/` hoặc `features/`.
- Định kiểu cho route param; validate các param không đáng tin (ví dụ từ deep link) bằng Zod trước khi dùng.
- Dùng các helper điều hướng có kiểu (`useLocalSearchParams`, `Link`, `router.push`).
- Tập trung hóa cấu hình linking; KHÔNG BAO GIỜ tin param của deep link khi chưa validate.

```tsx
// app/user/[id].tsx
import { useLocalSearchParams, router } from 'expo-router'
import { z } from 'zod'

const Params = z.object({ id: z.string().uuid() })

export default function UserScreen() {
  // Use safeParse, not parse: a malformed deep link would otherwise throw
  // during render and crash the screen. Redirect instead of throwing.
  const parsed = Params.safeParse(useLocalSearchParams())
  if (!parsed.success) {
    router.replace('/not-found')
    return null
  }
  return <UserProfile userId={parsed.data.id} />
}
```

## Quản lý State

Quy tắc là tách biệt các mối quan tâm này và không sao chép dữ liệu server vào client store. Các công cụ liệt kê là lựa chọn phổ biến, không bắt buộc — hãy chọn thứ phù hợp với dự án của bạn.

| Mối quan tâm | Lựa chọn phổ biến |
|---------|---------|
| Server state | một thư viện server-cache (TanStack Query, SWR) |
| Client/UI state | một store nhẹ (Zustand, Jotai) hoặc Context |
| Navigation/route state | param của Expo Router (KHÔNG phải global store) |
| Form state | một thư viện form (ví dụ React Hook Form) kèm schema validation |
| Lưu trữ bảo mật | `expo-secure-store` |
| Lưu trữ không bảo mật | `AsyncStorage` / MMKV |

- Dẫn xuất giá trị thay vì lưu state tính toán dư thừa.
- Giữ global client state ở mức tối thiểu; ưu tiên `useState` cục bộ cho đến khi thực sự cần chia sẻ.

## Lấy dữ liệu (Data Fetching)

Dùng thư viện server-cache (TanStack Query, SWR) thay vì fetch tùy tiện trong `useEffect`. Các ví dụ dùng TanStack Query.

- Đưa các lần đọc từ server đi qua cache (ví dụ `useQuery`) và các mutation cũng đi qua nó (ví dụ `useMutation`) kèm vô hiệu hóa cache.
- Validate API response bằng Zod tại ranh giới; suy ra type từ schema. (Zod đã là mặc định để validate trong các rule `typescript/` của ECC.)
- Xử lý tường minh ba trạng thái trong UI: loading, error, empty.
- Dùng optimistic update cho các tương tác nhanh: snapshot, áp dụng, rollback khi thất bại kèm phản hồi hiển thị.
- Fetch song song các dữ liệu độc lập; tránh request waterfall giữa cha và con.

```tsx
function useUser(id: string) {
  return useQuery({
    queryKey: ['user', id],
    queryFn: async () => userSchema.parse(await api.getUser(id)),
  })
}
```

## Danh sách

- Dùng `FlatList`/`SectionList` (hoặc `FlashList` cho danh sách lớn/nặng) — KHÔNG BAO GIỜ `.map()` một mảng lớn bên trong `ScrollView`.
- Cung cấp `keyExtractor` ổn định; memoize `renderItem`.
- Phân trang hoặc ảo hóa (virtualize) các tập dữ liệu dài.

## Custom Hook

- Tách logic tái sử dụng (dữ liệu, permission, API thiết bị) thành các hook `use*`.
- Giữ side effect (lời gọi Expo SDK, subscription) bên trong hook, không đặt trong JSX.

## Async & Effect

- Dọn dẹp subscription, timer và listener trong hàm return của effect.
- Hủy hoặc bỏ qua kết quả async đã cũ khi unmount để tránh setState-after-unmount.
