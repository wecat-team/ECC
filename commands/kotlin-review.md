---
description: Code review toàn diện cho Kotlin về pattern idiomatic, null safety, an toàn coroutine và bảo mật. Gọi agent kotlin-reviewer.
---

# Kotlin Code Review

Command này gọi agent **kotlin-reviewer** để code review toàn diện dành riêng cho Kotlin.

## Command này làm gì

1. **Xác định thay đổi Kotlin**: Tìm các file `.kt` và `.kts` đã sửa qua `git diff`
2. **Chạy build & phân tích tĩnh**: Thực thi `./gradlew build`, `detekt`, `ktlintCheck`
3. **Quét bảo mật**: Kiểm tra SQL injection, command injection, secret bị hardcode
4. **Review null safety**: Phân tích việc dùng `!!`, xử lý platform type, unsafe cast
5. **Review coroutine**: Kiểm tra structured concurrency, cách dùng dispatcher, cancellation
6. **Tạo báo cáo**: Phân loại vấn đề theo mức độ nghiêm trọng

## Khi nào dùng

Dùng `/kotlin-review` khi:
- Sau khi viết hoặc sửa code Kotlin
- Trước khi commit các thay đổi Kotlin
- Review pull request có code Kotlin
- Làm quen với một codebase Kotlin mới
- Học các pattern Kotlin idiomatic

## Các nhóm review

### CRITICAL (PHẢI sửa)
- Lỗ hổng SQL/Command injection
- Force-unwrap `!!` không có lý do chính đáng
- Vi phạm null safety của platform type
- Dùng GlobalScope (vi phạm structured concurrency)
- Credential bị hardcode
- Deserialization không an toàn

### HIGH (Nên sửa)
- State mutable ở nơi bất biến (immutable) là đủ
- Lời gọi blocking bên trong context coroutine
- Thiếu kiểm tra cancellation trong vòng lặp dài
- `when` không exhaustive trên sealed type
- Hàm lớn (>50 dòng)
- Lồng nhau quá sâu (>4 cấp)

### MEDIUM (Cân nhắc)
- Kotlin không idiomatic (pattern kiểu Java)
- Thiếu trailing comma
- Lạm dụng hoặc lồng scope function
- Thiếu sequence cho các chuỗi xử lý collection lớn
- Khai báo kiểu tường minh thừa

## Các kiểm tra tự động được chạy

```bash
# Build check
./gradlew build

# Static analysis
./gradlew detekt

# Formatting check
./gradlew ktlintCheck

# Tests
./gradlew test
```

## Ví dụ sử dụng

````text
User: /kotlin-review

Agent:
# Kotlin Code Review Report

## Files Reviewed
- src/main/kotlin/com/example/service/UserService.kt (modified)
- src/main/kotlin/com/example/routes/UserRoutes.kt (modified)

## Static Analysis Results
✓ Build: Successful
✓ detekt: No issues
WARNING: ktlint: 2 formatting warnings

## Issues Found

[CRITICAL] Force-Unwrap Null Safety
File: src/main/kotlin/com/example/service/UserService.kt:28
Issue: Using !! on nullable repository result
```kotlin
val user = repository.findById(id)!!  // NPE risk
```
Fix: Use safe call with error handling
```kotlin
val user = repository.findById(id)
    ?: throw UserNotFoundException("User $id not found")
```

[HIGH] GlobalScope Usage
File: src/main/kotlin/com/example/routes/UserRoutes.kt:45
Issue: Using GlobalScope breaks structured concurrency
```kotlin
GlobalScope.launch {
    notificationService.sendWelcome(user)
}
```
Fix: Use the call's coroutine scope
```kotlin
launch {
    notificationService.sendWelcome(user)
}
```

## Summary
- CRITICAL: 1
- HIGH: 1
- MEDIUM: 0

Recommendation: FAIL: Block merge until CRITICAL issue is fixed
````

## Tiêu chí phê duyệt

| Trạng thái | Điều kiện |
|--------|-----------|
| PASS: Approve | Không có vấn đề CRITICAL hoặc HIGH |
| WARNING: Warning | Chỉ có vấn đề MEDIUM (merge cần thận trọng) |
| FAIL: Block | Phát hiện vấn đề CRITICAL hoặc HIGH |

## Tích hợp với các command khác

- Dùng `/kotlin-test` trước để đảm bảo test thành công
- Dùng `/kotlin-build` nếu có lỗi build
- Dùng `/kotlin-review` trước khi commit
- Dùng `/code-review` cho các mối quan tâm không đặc thù của Kotlin

## Liên quan

- Agent: `agents/kotlin-reviewer.md`
- Skills: `skills/kotlin-patterns/`, `skills/kotlin-testing/`
