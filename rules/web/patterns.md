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
> File này mở rộng [common/patterns.md](../common/patterns.md) với các pattern riêng cho web.

# Pattern Web

## Composition của Component

### Compound Component

Dùng compound component khi các UI liên quan chia sẻ state và ngữ nghĩa tương tác:

```tsx
<Tabs defaultValue="overview">
  <Tabs.List>
    <Tabs.Trigger value="overview">Overview</Tabs.Trigger>
    <Tabs.Trigger value="settings">Settings</Tabs.Trigger>
  </Tabs.List>
  <Tabs.Content value="overview">...</Tabs.Content>
  <Tabs.Content value="settings">...</Tabs.Content>
</Tabs>
```

- Component cha sở hữu state
- Component con dùng qua context
- Ưu tiên cách này hơn prop drilling cho các widget phức tạp

### Render Props / Slot

- Dùng pattern render props hoặc slot khi hành vi được chia sẻ nhưng markup phải khác nhau
- Giữ xử lý bàn phím, ARIA và logic focus trong tầng headless

### Tách Container / Presentational

- Container component sở hữu việc tải dữ liệu và side effect
- Presentational component nhận props và render UI
- Presentational component nên giữ thuần (pure)

## Quản lý State

Hãy xử lý các loại sau một cách riêng biệt:

| Mối quan tâm | Công cụ |
|---------|---------|
| Server state | TanStack Query, SWR, tRPC |
| Client state | Zustand, Jotai, signals |
| URL state | search params, route segment |
| Form state | React Hook Form hoặc tương đương |

- Không nhân đôi server state vào client store
- Suy ra giá trị thay vì lưu computed state dư thừa

## URL như là State

Lưu state có thể chia sẻ trong URL:
- bộ lọc
- thứ tự sắp xếp
- phân trang
- tab đang hoạt động
- truy vấn tìm kiếm

## Fetch dữ liệu

### Stale-While-Revalidate

- Trả về dữ liệu đã cache ngay lập tức
- Revalidate ở chế độ nền
- Ưu tiên dùng thư viện có sẵn thay vì tự viết tay

### Optimistic Update

- Chụp snapshot state hiện tại
- Áp dụng optimistic update
- Rollback khi thất bại
- Hiển thị phản hồi lỗi rõ ràng khi rollback

### Tải song song

- Fetch dữ liệu độc lập song song
- Tránh waterfall request cha-con
- Prefetch các route hoặc state có khả năng là bước tiếp theo khi có lý do chính đáng
