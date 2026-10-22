---
paths:
  - "**/*.kt"
  - "**/*.kts"
---
# Phong cách code Kotlin

> File này mở rộng [common/coding-style.md](../common/coding-style.md) với nội dung dành riêng cho Kotlin.

## Định dạng

- **ktlint** hoặc **Detekt** để ép buộc style
- Code style chính thức của Kotlin (`kotlin.code.style=official` trong `gradle.properties`)

## Bất biến (Immutability)

- Ưu tiên `val` hơn `var` — mặc định dùng `val` và chỉ dùng `var` khi cần mutate
- Dùng `data class` cho value type; dùng collection bất biến (`List`, `Map`, `Set`) trong API public
- Copy-on-write cho cập nhật state: `state.copy(field = newValue)`

## Đặt tên

Tuân theo quy ước Kotlin:
- `camelCase` cho hàm và property
- `PascalCase` cho class, interface, object và type alias
- `SCREAMING_SNAKE_CASE` cho hằng số (`const val` hoặc `@JvmStatic`)
- Đặt tên interface theo hành vi, không thêm tiền tố `I`: `Clickable` chứ không phải `IClickable`

## Null Safety

- KHÔNG BAO GIỜ dùng `!!` — ưu tiên `?.`, `?:`, `requireNotNull()` hoặc `checkNotNull()`
- Dùng `?.let {}` cho các thao tác null-safe có phạm vi
- Trả về kiểu nullable từ các hàm có thể hợp lệ không có kết quả

```kotlin
// BAD
val name = user!!.name

// GOOD
val name = user?.name ?: "Unknown"
val name = requireNotNull(user) { "User must be set before accessing name" }.name
```

## Sealed Type

Dùng sealed class/interface để mô hình hóa các hệ phân cấp state đóng:

```kotlin
sealed interface UiState<out T> {
    data object Loading : UiState<Nothing>
    data class Success<T>(val data: T) : UiState<T>
    data class Error(val message: String) : UiState<Nothing>
}
```

Luôn dùng `when` đầy đủ (exhaustive) với sealed type — không có nhánh `else`.

## Extension Function

Dùng extension function cho các thao tác tiện ích, nhưng giữ cho chúng dễ tìm:
- Đặt trong file được đặt tên theo receiver type (`StringExt.kt`, `FlowExt.kt`)
- Giữ phạm vi hạn chế — không thêm extension cho `Any` hoặc các type quá chung chung

## Scope Function

Dùng đúng scope function:
- `let` — kiểm tra null + biến đổi: `user?.let { greet(it) }`
- `run` — tính toán kết quả dùng receiver: `service.run { fetch(config) }`
- `apply` — cấu hình một object: `builder.apply { timeout = 30 }`
- `also` — side effect: `result.also { log(it) }`
- Tránh lồng sâu các scope function (tối đa 2 cấp)

## Xử lý lỗi

- Dùng `Result<T>` hoặc sealed type tùy chỉnh
- Dùng `runCatching {}` để bọc code có thể throw
- KHÔNG BAO GIỜ catch `CancellationException` — luôn rethrow nó
- Tránh `try-catch` để điều khiển luồng

```kotlin
// BAD — using exceptions for control flow
val user = try { repository.getUser(id) } catch (e: NotFoundException) { null }

// GOOD — nullable return
val user: User? = repository.findUser(id)
```
