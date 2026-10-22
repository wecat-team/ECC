---
description: Sửa từng bước các lỗi build Kotlin/Gradle, warning của compiler và vấn đề dependency. Gọi agent kotlin-build-resolver để sửa tối thiểu, chính xác.
---

# Kotlin Build và Fix

Command này gọi agent **kotlin-build-resolver** để sửa từng bước các lỗi build Kotlin với thay đổi tối thiểu.

## Command này làm gì

1. **Chạy chẩn đoán**: Thực thi `./gradlew build`, `detekt`, `ktlintCheck`
2. **Phân tích lỗi**: Nhóm theo file và sắp xếp theo mức độ nghiêm trọng
3. **Sửa từng bước**: Mỗi lần một lỗi
4. **Xác minh từng bản sửa**: Chạy lại build sau mỗi thay đổi
5. **Báo cáo tóm tắt**: Hiển thị những gì đã sửa và những gì còn lại

## Khi nào dùng

Dùng `/kotlin-build` khi:
- `./gradlew build` thất bại với lỗi
- Kotlin compiler báo lỗi
- `./gradlew detekt` báo vi phạm
- Việc phân giải dependency của Gradle thất bại
- Sau khi pull các thay đổi làm hỏng build

## Các lệnh chẩn đoán được chạy

```bash
# Primary build check
./gradlew build 2>&1

# Static analysis
./gradlew detekt 2>&1 || echo "detekt not configured"
./gradlew ktlintCheck 2>&1 || echo "ktlint not configured"

# Dependency issues
./gradlew dependencies --configuration runtimeClasspath 2>&1 | head -100

# Optional deep refresh when caches or dependency metadata are suspect
./gradlew build --refresh-dependencies
```

## Phiên làm việc ví dụ

````text
User: /kotlin-build

Agent:
# Kotlin Build Resolution

## Initial Diagnostics

```bash
$ ./gradlew build
e: src/main/kotlin/com/example/service/UserService.kt:25:15 Unresolved reference: UserRepository
e: src/main/kotlin/com/example/routes/UserRoutes.kt:42:9 Type mismatch: inferred type is String but Int was expected
e: src/main/kotlin/com/example/routes/UserRoutes.kt:58:5 'when' expression must be exhaustive
```

Errors found: 3

## Fix 1: Unresolved Reference

File: src/main/kotlin/com/example/service/UserService.kt:25
Error: Unresolved reference: UserRepository
Cause: Missing import

```kotlin
// Added import
import com.example.repository.UserRepository
```

```bash
$ ./gradlew build
# 2 errors remaining
```

## Fix 2: Type Mismatch

File: src/main/kotlin/com/example/routes/UserRoutes.kt:42
Error: Type mismatch: inferred type is String but Int was expected

```kotlin
// Changed
val count = call.parameters["count"]
// To
val count = call.parameters["count"]?.toIntOrNull()
    ?: return@get call.respond(HttpStatusCode.BadRequest, "Invalid count")
```

```bash
$ ./gradlew build
# 1 error remaining
```

## Fix 3: Non-Exhaustive When

File: src/main/kotlin/com/example/routes/UserRoutes.kt:58
Error: 'when' expression must be exhaustive

```kotlin
// Added missing branch
when (user.role) {
    Role.ADMIN -> handleAdmin(user)
    Role.USER -> handleUser(user)
    Role.MODERATOR -> handleModerator(user) // Added
}
```

```bash
$ ./gradlew build
# Build successful!
```

## Final Verification

```bash
$ ./gradlew detekt
# No issues

$ ./gradlew test
# All tests passed
```

## Summary

| Metric | Count |
|--------|-------|
| Build errors fixed | 3 |
| Detekt issues fixed | 0 |
| Files modified | 2 |
| Remaining issues | 0 |

Build Status: PASS: SUCCESS
````

## Các lỗi thường gặp đã sửa

| Lỗi | Cách sửa điển hình |
|-------|-------------|
| `Unresolved reference: X` | Thêm import hoặc dependency |
| `Type mismatch` | Sửa việc chuyển đổi kiểu hoặc phép gán |
| `'when' must be exhaustive` | Thêm các nhánh sealed class còn thiếu |
| `Suspend function can only be called from coroutine` | Thêm modifier `suspend` |
| `Smart cast impossible` | Dùng `val` cục bộ hoặc `let` |
| `None of the following candidates is applicable` | Sửa kiểu của đối số |
| `Could not resolve dependency` | Sửa phiên bản hoặc thêm repository |

## Chiến lược sửa lỗi

1. **Lỗi build trước** - Code phải compile được
2. **Vi phạm Detekt thứ hai** - Sửa các vấn đề chất lượng code
3. **Warning của ktlint thứ ba** - Sửa định dạng
4. **Mỗi lần một bản sửa** - Xác minh từng thay đổi
5. **Thay đổi tối thiểu** - Không refactor, chỉ sửa

## Điều kiện dừng

Agent sẽ dừng và báo cáo nếu:
- Cùng một lỗi vẫn còn sau 3 lần thử
- Bản sửa gây thêm lỗi
- Cần thay đổi kiến trúc
- Thiếu dependency bên ngoài

## Các command liên quan

- `/kotlin-test` - Chạy test sau khi build thành công
- `/kotlin-review` - Review chất lượng code
- skill `verification-loop` - Vòng lặp xác minh đầy đủ

## Liên quan

- Agent: `agents/kotlin-build-resolver.md`
- Skill: `skills/kotlin-patterns/`
