---
name: react-native-patterns
description: Các pattern cho ứng dụng React Native và Expo — điều hướng bằng Expo Router, tách biệt state (server/client/route/form), data fetching bằng TanStack Query với Zod, list hiệu năng cao, styling bằng NativeWind/StyleSheet, native API và secure storage. Dùng khi xây dựng hoặc chỉnh sửa screen, component, navigation hoặc data layer của React Native / Expo.
origin: ECC
---

# Các pattern React Native / Expo

Các pattern thực tế để xây dựng ứng dụng React Native production với Expo. Bao gồm navigation, state, data fetching, list, styling và native API. Đi cùng bộ rule `rules/react-native/`: rule nói *cái gì* cần áp dụng, skill này chỉ ra *cách làm*.

Các thư viện được nêu bên dưới (NativeWind, Zustand/Jotai, TanStack Query) là những lựa chọn phổ biến, đã được kiểm chứng và chỉ dùng để minh họa — pattern quan trọng hơn package cụ thể, và bất kỳ giải pháp tương đương nào cũng dùng được. Zod được dùng để validation nhằm nhất quán với các rule `typescript/` hiện có của ECC.

Các pattern này giả định managed Expo workflow (Expo Router, EAS, các module `expo-*`) chạy trên New Architecture (mặc định trong các Expo SDK gần đây, bắt buộc từ SDK 55+). Chúng KHÔNG giả định có browser DOM — React Native không có `<div>`, không có thanh URL, và không có các mặc định data-fetching của web.

## Khi nào kích hoạt

Dùng skill này khi:

- Xây dựng hoặc chỉnh sửa screen, component hoặc navigation của React Native / Expo
- Thiết lập routing với Expo Router (thư mục `app/` dựa trên file)
- Quyết định state thuộc về đâu (server cache, client store, route params hay form)
- Kết nối data fetching bằng TanStack Query và validate response bằng Zod
- Render các list dài hoặc nặng
- Chọn hoặc áp dụng cách styling (NativeWind hoặc StyleSheet)
- Truy cập native API của thiết bị (camera, vị trí, thông báo) hoặc secure storage
- Review code RN để tìm các vấn đề đặc thù của mobile

KHÔNG dùng các pattern của web/React-DOM ở đây — URL-as-state, `<div>` và SWR-for-browser không áp dụng cho React Native.

## Khái niệm cốt lõi

### Cấu trúc dự án (Expo Router)

Routing dựa trên file trong `app/`. Giữ các file route mỏng: chúng đọc và validate param, rồi ủy thác cho một screen component nằm trong `components/` hoặc `features/`.

```
app/
  _layout.tsx          # root stack
  (tabs)/
    _layout.tsx        # tab navigator
    index.tsx          # Home
  user/[id].tsx        # dynamic route
components/
features/
  user/UserProfile.tsx
```

### Navigation: validate route param

Deep link và dynamic route đưa vào các chuỗi không đáng tin cậy. Hãy validate chúng bằng Zod trước khi dùng.

```tsx
// app/user/[id].tsx
import { useLocalSearchParams, router } from 'expo-router'
import { z } from 'zod'
import { UserProfile } from '@/features/user/UserProfile'

const Params = z.object({ id: z.string().uuid() })

export default function UserRoute() {
  const parsed = Params.safeParse(useLocalSearchParams())
  if (!parsed.success) {
    router.replace('/not-found')
    return null
  }
  return <UserProfile userId={parsed.data.id} />
}
```

### State: tách biệt các mối quan tâm

Không sao chép dữ liệu server vào client store. Mỗi mối quan tâm có nơi riêng của nó.

| Mối quan tâm | Lựa chọn phổ biến |
|---------|------|
| Server state (dữ liệu từ xa) | một thư viện server-cache (TanStack Query, SWR) |
| Client/UI state | một store nhẹ (Zustand, Jotai) hoặc Context |
| Route/navigation state | param của Expo Router |
| Form state | một thư viện form (ví dụ React Hook Form) + schema validation |
| Secret / token | `expo-secure-store` |
| Lưu trữ không phải secret | `AsyncStorage` / MMKV |

Ưu tiên `useState` cục bộ cho đến khi state thực sự cần được chia sẻ.

### Data fetching: thư viện cache + Zod

Dùng thư viện server-cache (TanStack Query, SWR) thay vì fetch trong `useEffect`. Validate ở ranh giới và suy ra type từ schema. Xử lý tường minh các trạng thái loading, error và empty. (Ví dụ dùng TanStack Query.)

```tsx
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { z } from 'zod'

const User = z.object({ id: z.string(), email: z.string().email() })
type User = z.infer<typeof User>

export function useUser(id: string) {
  return useQuery({
    queryKey: ['user', id],
    queryFn: async (): Promise<User> => User.parse(await api.getUser(id)),
  })
}

export function useUpdateEmail(id: string) {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (email: string) => api.updateEmail(id, email),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['user', id] }),
  })
}
```

### List: dùng virtualization, KHÔNG BAO GIỜ map một array lớn trong ScrollView

```tsx
import { FlatList } from 'react-native'

<FlatList
  data={items}
  keyExtractor={(item) => item.id}
  renderItem={renderItem}          // memoized
  initialNumToRender={10}
  windowSize={5}
/>
```

Dùng `FlashList` (Shopify) cho các list lớn hoặc không đồng nhất.

### Styling: chọn một hệ thống

`StyleSheet.create()` là lựa chọn native của framework; các thư viện utility-class (ví dụ NativeWind) là một phương án thay thế phổ biến. Hãy chọn một và giữ nhất quán. KHÔNG BAO GIỜ tạo style object inline trong JSX ở các hot path.

```tsx
// NativeWind
<View className="p-4 rounded-2xl bg-white">
  <Text className="text-base font-semibold">Hello</Text>
</View>

// StyleSheet
const styles = StyleSheet.create({ card: { padding: 16, borderRadius: 16, backgroundColor: '#fff' } })
<View style={styles.card}>...</View>
```

### Native API: bọc trong hook, dọn dẹp effect

Giữ các lời gọi Expo SDK và subscription bên trong hook `use*`, không đặt trong JSX. LUÔN LUÔN dọn dẹp (clean up).

```tsx
import { useEffect, useState } from 'react'
import * as Location from 'expo-location'

type LocationState =
  | { status: 'loading' }
  | { status: 'denied' }
  | { status: 'granted'; coords: Location.LocationObjectCoords }

export function useCurrentLocation() {
  // Track status, not just coords — so the UI can tell "still loading" apart
  // from "permission denied" and show an actionable message.
  const [state, setState] = useState<LocationState>({ status: 'loading' })

  useEffect(() => {
    let active = true
    ;(async () => {
      const { status } = await Location.requestForegroundPermissionsAsync()
      if (status !== 'granted') {
        if (active) setState({ status: 'denied' })
        return
      }
      const pos = await Location.getCurrentPositionAsync({})
      if (active) setState({ status: 'granted', coords: pos.coords })
    })()
    return () => { active = false }   // ignore stale result after unmount
  }, [])

  return state
}
```

### Secure storage cho token

```tsx
import * as SecureStore from 'expo-secure-store'

await SecureStore.setItemAsync('auth_token', token)   // Keychain / Keystore
const token = await SecureStore.getItemAsync('auth_token')
```

## Ví dụ code

### Một screen đầy đủ: route → query → list → các state

```tsx
// app/(tabs)/orders.tsx
import { memo, useCallback } from 'react'
import { FlatList, Text, View } from 'react-native'
import { useQuery } from '@tanstack/react-query'
import { z } from 'zod'

const OrderSchema = z.object({ id: z.string(), total: z.number(), status: z.string() })
const OrdersSchema = z.array(OrderSchema)
type Order = z.infer<typeof OrderSchema>

function useOrders() {
  return useQuery({
    queryKey: ['orders'],
    queryFn: async () => OrdersSchema.parse(await api.listOrders()),
  })
}

// Memoized so its reference is stable across renders (see the lists guidance).
const OrderRow = memo(function OrderRow({ item }: { item: Order }) {
  return (
    <View className="px-4 py-3 border-b border-neutral-200">
      <Text className="font-medium">#{item.id}</Text>
      <Text className="text-neutral-500">{item.status} · ${item.total}</Text>
    </View>
  )
})

export default function OrdersScreen() {
  const { data, isLoading, isError, refetch, isRefetching } = useOrders()
  const renderItem = useCallback(({ item }: { item: Order }) => <OrderRow item={item} />, [])

  if (isLoading) return <Centered><Text>Loading…</Text></Centered>
  if (isError) return <Centered><Text accessibilityRole="alert">Could not load orders.</Text></Centered>
  if (!data?.length) return <Centered><Text>No orders yet.</Text></Centered>

  return (
    <FlatList
      data={data}
      keyExtractor={(o) => o.id}
      onRefresh={refetch}
      refreshing={isRefetching}
      renderItem={renderItem}
    />
  )
}
```

### Một form: React Hook Form + Zod resolver

```tsx
import { useForm, Controller } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import { TextInput, Button, Text } from 'react-native'

const Schema = z.object({ email: z.string().email('Invalid email') })
type FormValues = z.infer<typeof Schema>

export function EmailForm({ onSubmit }: { onSubmit: (v: FormValues) => void }) {
  const { control, handleSubmit, formState: { errors } } = useForm<FormValues>({
    resolver: zodResolver(Schema),
    defaultValues: { email: '' },
  })

  return (
    <>
      <Controller
        control={control}
        name="email"
        render={({ field: { value, onChange, onBlur } }) => (
          <TextInput
            value={value}
            onChangeText={onChange}
            onBlur={onBlur}
            autoCapitalize="none"
            keyboardType="email-address"
            accessibilityLabel="Email address"
          />
        )}
      />
      {errors.email && <Text accessibilityRole="alert">{errors.email.message}</Text>}
      <Button title="Save" onPress={handleSubmit(onSubmit)} />
    </>
  )
}
```

## Anti-Patterns

```tsx
// WRONG: large array mapped inside a ScrollView (no virtualization, janky, high memory)
<ScrollView>{items.map((i) => <Row key={i.id} item={i} />)}</ScrollView>
// RIGHT: FlatList / FlashList

// WRONG: server data copied into a client store (two sources of truth, stale data)
const useStore = create((set) => ({ users: [], setUsers: (u) => set({ users: u }) }))
useEffect(() => { getUsers().then(setUsers) }, [])
// RIGHT: useQuery owns server state; derive what you need

// WRONG: tokens in AsyncStorage (not encrypted)
await AsyncStorage.setItem('auth_token', token)
// RIGHT: expo-secure-store

// WRONG: trusting deep-link params
const { id } = useLocalSearchParams(); fetchUser(id)
// RIGHT: validate with Zod before use

// WRONG: inline style object recreated every render on a hot path
<View style={{ padding: 16, backgroundColor: '#fff' }} />
// RIGHT: StyleSheet.create at module scope, or NativeWind className

// WRONG: real secret shipped in the bundle
const STRIPE_SECRET = 'sk_live_...'
// RIGHT: keep privileged calls server-side; ship only public keys protected by backend rules
```

## Best Practices

- Giữ các file route mỏng; đặt logic trong screen component và hook `use*`.
- Validate mọi input từ bên ngoài (API response, route param, push payload) bằng Zod.
- Để TanStack Query sở hữu server state; giữ client store nhỏ.
- LUÔN LUÔN render các trạng thái loading, error và empty — không bao giờ chỉ có spinner mà không có fallback.
- Dùng virtualization cho list; memoize `renderItem`; cung cấp `keyExtractor` ổn định.
- Dùng `react-native-reanimated` cho animation (chạy trên UI thread); tránh công việc nặng trên JS thread.
- Lưu token trong `expo-secure-store`; không bao giờ tin client cho việc phân quyền (authorization).
- Tôn trọng safe area, Dynamic Type và accessibility role/label ngay từ đầu.
- Xác nhận khả năng tương thích New Architecture cho mọi native dependency trước khi release.

## Skill liên quan

- `frontend-patterns` — các pattern React/Next.js (web); hữu ích cho các khái niệm React dùng chung, nhưng gắn với DOM.
- `coding-standards` — các idiom TypeScript/JavaScript áp dụng cho code RN.
- `tdd-workflow`, `e2e-testing` — quy trình testing (dùng Jest + React Native Testing Library, Maestro/Detox cho RN).
- `security-review` — checklist bảo mật chung bổ sung cho hướng dẫn về bundle/secret của RN ở trên.
