---
description: Sửa lỗi build Gradle cho các dự án Android và KMP
---

# Gradle Build Fix

Sửa dần các lỗi build và biên dịch Gradle cho dự án Android và Kotlin Multiplatform.

## Bước 1: Phát hiện cấu hình build

Xác định loại dự án và chạy lệnh build phù hợp:

| Dấu hiệu | Lệnh build |
|-----------|---------------|
| `build.gradle.kts` + `composeApp/` (KMP) | `./gradlew composeApp:compileKotlinMetadata 2>&1` |
| `build.gradle.kts` + `app/` (Android) | `./gradlew app:compileDebugKotlin 2>&1` |
| `settings.gradle.kts` có các module | `./gradlew assemble 2>&1` |
| Đã cấu hình Detekt | `./gradlew detekt 2>&1` |

Đồng thời kiểm tra `gradle.properties` và `local.properties` để xem cấu hình.

## Bước 2: Phân tích và nhóm lỗi

1. Chạy lệnh build và thu thập output
2. Tách lỗi biên dịch Kotlin khỏi lỗi cấu hình Gradle
3. Nhóm theo module và đường dẫn file
4. Sắp xếp: lỗi cấu hình trước, sau đó là lỗi biên dịch theo thứ tự dependency

## Bước 3: Vòng lặp sửa lỗi

Với mỗi lỗi:

1. **Đọc file** — Toàn bộ context xung quanh dòng lỗi
2. **Chẩn đoán** — Các nhóm thường gặp:
   - Thiếu import hoặc unresolved reference
   - Type mismatch hoặc kiểu không tương thích
   - Thiếu dependency trong `build.gradle.kts`
   - Expect/actual mismatch (KMP)
   - Lỗi Compose compiler
3. **Sửa tối thiểu** — Thay đổi nhỏ nhất giải quyết được lỗi
4. **Chạy lại build** — Xác minh bản sửa và kiểm tra lỗi mới
5. **Tiếp tục** — Chuyển sang lỗi tiếp theo

## Bước 4: Rào chắn an toàn (Guardrails)

Dừng lại và hỏi người dùng nếu:
- Bản sửa gây ra nhiều lỗi hơn số lỗi nó giải quyết
- Cùng một lỗi vẫn còn sau 3 lần thử
- Lỗi đòi hỏi thêm dependency mới hoặc thay đổi cấu trúc module
- Bản thân Gradle sync thất bại (lỗi ở pha cấu hình)
- Lỗi nằm trong code được sinh tự động (Room, SQLDelight, KSP)

## Bước 5: Tóm tắt

Báo cáo:
- Các lỗi đã sửa (module, file, mô tả)
- Các lỗi còn lại
- Các lỗi mới phát sinh (phải bằng không)
- Các bước tiếp theo được đề xuất

## Các bản sửa Gradle/KMP thường gặp

| Lỗi | Cách sửa |
|-------|-----|
| Unresolved reference trong `commonMain` | Kiểm tra dependency có nằm trong `commonMain.dependencies {}` không |
| Expect declaration không có actual | Thêm phần triển khai `actual` trong từng source set của nền tảng |
| Phiên bản Compose compiler không khớp | Đồng bộ phiên bản Kotlin và Compose compiler trong `libs.versions.toml` |
| Duplicate class | Kiểm tra các dependency xung đột bằng `./gradlew dependencies` |
| Lỗi KSP | Chạy `./gradlew kspCommonMainKotlinMetadata` để sinh lại |
| Vấn đề configuration cache | Kiểm tra các input của task không thể serialize |
