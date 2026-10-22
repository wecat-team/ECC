---
description: Phát hiện hệ thống build của dự án và sửa dần dần các lỗi build/type bằng những thay đổi tối thiểu, an toàn.
---

# Build và Fix

Sửa dần dần các lỗi build và type bằng những thay đổi tối thiểu, an toàn.

## Bước 1: Phát hiện hệ thống build

Xác định công cụ build của dự án và chạy build:

| Dấu hiệu | Lệnh build |
|-----------|---------------|
| `package.json` có script `build` | `npm run build` hoặc `pnpm build` |
| `tsconfig.json` (chỉ TypeScript) | `npx tsc --noEmit` |
| `Cargo.toml` | `cargo build 2>&1` |
| `pom.xml` | `mvn compile` |
| `build.gradle` | `./gradlew compileJava` |
| `go.mod` | `go build ./...` |
| `pyproject.toml` | `python -m compileall -q .` hoặc `mypy .` |

## Bước 2: Phân tích và nhóm lỗi

1. Chạy lệnh build và bắt stderr
2. Nhóm lỗi theo đường dẫn file
3. Sắp xếp theo thứ tự dependency (sửa import/type trước lỗi logic)
4. Đếm tổng số lỗi để theo dõi tiến độ

## Bước 3: Vòng lặp sửa (mỗi lần một lỗi)

Với mỗi lỗi:

1. **Đọc file** — Dùng tool Read để xem context của lỗi (10 dòng xung quanh lỗi)
2. **Chẩn đoán** — Xác định nguyên nhân gốc (thiếu import, sai type, lỗi cú pháp)
3. **Sửa tối thiểu** — Dùng tool Edit cho thay đổi nhỏ nhất giải quyết được lỗi
4. **Chạy lại build** — Xác minh lỗi đã hết và không phát sinh lỗi mới
5. **Chuyển sang lỗi tiếp theo** — Tiếp tục với các lỗi còn lại

## Bước 4: Rào chắn (Guardrails)

Dừng lại và hỏi người dùng nếu:
- Một cách sửa gây ra **nhiều lỗi hơn số lỗi giải quyết được**
- **Cùng một lỗi vẫn còn sau 3 lần thử** (có thể là vấn đề sâu hơn)
- Cách sửa đòi hỏi **thay đổi kiến trúc** (không chỉ là sửa build)
- Lỗi build xuất phát từ **thiếu dependency** (cần `npm install`, `cargo add`, v.v.)

## Bước 5: Tóm tắt

Hiển thị kết quả:
- Các lỗi đã sửa (kèm đường dẫn file)
- Các lỗi còn lại (nếu có)
- Các lỗi mới phát sinh (phải bằng không)
- Đề xuất các bước tiếp theo cho những vấn đề chưa giải quyết

## Chiến lược khôi phục

| Tình huống | Hành động |
|-----------|--------|
| Thiếu module/import | Kiểm tra package đã được cài chưa; gợi ý lệnh cài đặt |
| Type không khớp | Đọc cả hai định nghĩa type; sửa type hẹp hơn |
| Circular dependency | Xác định vòng bằng import graph; gợi ý tách ra |
| Xung đột phiên bản | Kiểm tra `package.json` / `Cargo.toml` để xem ràng buộc phiên bản |
| Cấu hình sai công cụ build | Đọc file config; so sánh với mặc định đang hoạt động |

Sửa từng lỗi một để đảm bảo an toàn. Ưu tiên diff tối thiểu hơn là refactor.
