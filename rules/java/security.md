---
paths:
  - "**/*.java"
---
# Bảo mật Java

> File này mở rộng [common/security.md](../common/security.md) với nội dung dành riêng cho Java.

## Quản lý Secret

- KHÔNG BAO GIỜ hardcode API key, token hoặc credential trong source code
- Dùng biến môi trường: `System.getenv("API_KEY")`
- Dùng secret manager (Vault, AWS Secrets Manager) cho secret production
- Đưa các file cấu hình cục bộ chứa secret vào `.gitignore`

```java
// BAD
private static final String API_KEY = "sk-abc123...";

// GOOD — environment variable
String apiKey = System.getenv("PAYMENT_API_KEY");
Objects.requireNonNull(apiKey, "PAYMENT_API_KEY must be set");
```

## Phòng chống SQL Injection

- Luôn dùng truy vấn tham số hóa — KHÔNG BAO GIỜ nối input của người dùng vào SQL
- Dùng `PreparedStatement` hoặc API truy vấn tham số hóa của framework
- Validate và sanitize mọi input dùng trong native query

```java
// BAD — SQL injection via string concatenation
Statement stmt = conn.createStatement();
String sql = "SELECT * FROM orders WHERE name = '" + name + "'";
stmt.executeQuery(sql);

// GOOD — PreparedStatement with parameterized query
PreparedStatement ps = conn.prepareStatement("SELECT * FROM orders WHERE name = ?");
ps.setString(1, name);

// GOOD — JDBC template
jdbcTemplate.query("SELECT * FROM orders WHERE name = ?", mapper, name);
```

## Kiểm tra đầu vào (Input Validation)

- Validate mọi input của người dùng tại ranh giới hệ thống trước khi xử lý
- Dùng Bean Validation (`@NotNull`, `@NotBlank`, `@Size`) trên DTO khi dùng validation framework
- Sanitize đường dẫn file và chuỗi do người dùng cung cấp trước khi dùng
- Từ chối input không qua validation kèm thông báo lỗi rõ ràng

```java
// Validate manually in plain Java
public Order createOrder(String customerName, BigDecimal amount) {
    if (customerName == null || customerName.isBlank()) {
        throw new IllegalArgumentException("Customer name is required");
    }
    if (amount == null || amount.compareTo(BigDecimal.ZERO) <= 0) {
        throw new IllegalArgumentException("Amount must be positive");
    }
    return new Order(customerName, amount);
}
```

## Authentication và Authorization

- KHÔNG BAO GIỜ tự triển khai mật mã cho auth — dùng các thư viện đã được kiểm chứng
- Lưu mật khẩu bằng bcrypt hoặc Argon2, KHÔNG BAO GIỜ dùng MD5/SHA1
- Áp dụng kiểm tra authorization tại ranh giới service
- Loại bỏ dữ liệu nhạy cảm khỏi log — KHÔNG BAO GIỜ log mật khẩu, token hoặc PII

## Bảo mật Dependency

- Chạy `mvn dependency:tree` hoặc `./gradlew dependencies` để kiểm toán các transitive dependency
- Dùng OWASP Dependency-Check hoặc Snyk để quét các CVE đã biết
- Luôn cập nhật dependency — thiết lập Dependabot hoặc Renovate

## Thông báo lỗi

- KHÔNG BAO GIỜ để lộ stack trace, đường dẫn nội bộ hoặc lỗi SQL trong API response
- Ánh xạ exception thành thông báo chung, an toàn cho client tại ranh giới handler
- Log lỗi chi tiết ở phía server; trả về thông báo chung cho client

```java
// Log the detail, return a generic message
try {
    return orderService.findById(id);
} catch (OrderNotFoundException ex) {
    log.warn("Order not found: id={}", id);
    return ApiResponse.error("Resource not found");  // generic, no internals
} catch (Exception ex) {
    log.error("Unexpected error processing order id={}", id, ex);
    return ApiResponse.error("Internal server error");  // never expose ex.getMessage()
}
```

## Tham chiếu

Xem skill: `springboot-security` để có các pattern authentication và authorization của Spring Security.
Xem skill: `quarkus-security` để có bảo mật Quarkus với JWT/OIDC, RBAC và CDI.
Xem skill: `security-review` để có các checklist bảo mật chung.
