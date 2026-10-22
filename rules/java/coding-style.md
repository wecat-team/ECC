---
paths:
  - "**/*.java"
---
# Phong cách code Java

> File này mở rộng [common/coding-style.md](../common/coding-style.md) với nội dung dành riêng cho Java.

## Định dạng

- **google-java-format** hoặc **Checkstyle** (style của Google hoặc Sun) để ép buộc
- Mỗi file một top-level type public
- Thụt lề nhất quán: 2 hoặc 4 dấu cách (khớp với chuẩn của dự án)
- Thứ tự thành viên: hằng số, field, constructor, method public, protected, private

## Bất biến (Immutability)

- Ưu tiên `record` cho các value type (Java 16+)
- Mặc định đánh dấu field là `final` — chỉ dùng mutable state khi cần thiết
- Trả về bản sao phòng vệ (defensive copy) từ API public: `List.copyOf()`, `Map.copyOf()`, `Set.copyOf()`
- Copy-on-write: trả về instance mới thay vì mutate instance hiện có

```java
// GOOD — immutable value type
public record OrderSummary(Long id, String customerName, BigDecimal total) {}

// GOOD — final fields, no setters
public class Order {
    private final Long id;
    private final List<LineItem> items;

    public List<LineItem> getItems() {
        return List.copyOf(items);
    }
}
```

## Đặt tên

Tuân theo quy ước Java chuẩn:
- `PascalCase` cho class, interface, record, enum
- `camelCase` cho method, field, tham số, biến cục bộ
- `SCREAMING_SNAKE_CASE` cho hằng số `static final`
- Package: toàn bộ chữ thường, domain đảo ngược (`com.example.app.service`)

## Tính năng Java hiện đại

Dùng các tính năng ngôn ngữ hiện đại khi chúng giúp code rõ ràng hơn:
- **Record** cho DTO và value type (Java 16+)
- **Sealed class** cho hệ phân cấp type đóng (Java 17+)
- **Pattern matching** với `instanceof` — không cần ép kiểu tường minh (Java 16+)
- **Text block** cho chuỗi nhiều dòng — SQL, template JSON (Java 15+)
- **Switch expression** với cú pháp mũi tên (Java 14+)
- **Pattern matching trong switch** — xử lý đầy đủ sealed type (Java 21+)

```java
// Pattern matching instanceof
if (shape instanceof Circle c) {
    return Math.PI * c.radius() * c.radius();
}

// Sealed type hierarchy
public sealed interface PaymentMethod permits CreditCard, BankTransfer, Wallet {}

// Switch expression
String label = switch (status) {
    case ACTIVE -> "Active";
    case SUSPENDED -> "Suspended";
    case CLOSED -> "Closed";
};
```

## Sử dụng Optional

- Trả về `Optional<T>` từ các finder method có thể không có kết quả
- Dùng `map()`, `flatMap()`, `orElseThrow()` — KHÔNG BAO GIỜ gọi `get()` mà không có `isPresent()`
- KHÔNG BAO GIỜ dùng `Optional` làm kiểu field hoặc tham số method

```java
// GOOD
return repository.findById(id)
    .map(ResponseDto::from)
    .orElseThrow(() -> new OrderNotFoundException(id));

// BAD — Optional as parameter
public void process(Optional<String> name) {}
```

## Xử lý lỗi

- Ưu tiên unchecked exception cho lỗi domain
- Tạo exception riêng cho domain, kế thừa `RuntimeException`
- Tránh `catch (Exception e)` quá rộng trừ khi ở các handler cấp cao nhất
- Đưa ngữ cảnh vào thông báo exception

```java
public class OrderNotFoundException extends RuntimeException {
    public OrderNotFoundException(Long id) {
        super("Order not found: id=" + id);
    }
}
```

## Stream

- Dùng stream cho các phép biến đổi; giữ pipeline ngắn (tối đa 3-4 thao tác)
- Ưu tiên method reference khi dễ đọc: `.map(Order::getTotal)`
- Tránh side effect trong các thao tác stream
- Với logic phức tạp, ưu tiên vòng lặp hơn một stream pipeline rối rắm

## Tham chiếu

Xem skill: `java-coding-standards` để có đầy đủ tiêu chuẩn code kèm ví dụ.
Xem skill: `jpa-patterns` để có các pattern thiết kế entity JPA/Hibernate.
