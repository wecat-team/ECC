---
description: Xác định và xóa dead code một cách an toàn, có kiểm chứng sau mỗi thay đổi.
---

# Refactor Clean

Xác định và xóa dead code một cách an toàn, với việc kiểm chứng bằng test ở mỗi bước.

## Bước 1: Phát hiện Dead Code

Chạy các công cụ phân tích tùy theo loại project:

| Công cụ | Tìm thấy gì | Lệnh |
|------|--------------|---------|
| knip | Export, file, dependency không dùng | `npx knip` |
| depcheck | Dependency npm không dùng | `npx depcheck` |
| ts-prune | Export TypeScript không dùng | `npx ts-prune` |
| vulture | Code Python không dùng | `vulture src/` |
| deadcode | Code Go không dùng | `deadcode ./...` |
| cargo-udeps | Dependency Rust không dùng | `cargo +nightly udeps` |

Nếu không có công cụ nào, hãy dùng Grep để tìm các export không có import nào:
```
# Find exports, then check if they're imported anywhere
```

## Bước 2: Phân loại các phát hiện

Sắp xếp các phát hiện theo các tầng an toàn:

| Tầng | Ví dụ | Hành động |
|------|----------|--------|
| **SAFE** | Utility không dùng, test helper, function nội bộ | Xóa một cách tự tin |
| **CAUTION** | Component, API route, middleware | Xác minh không có dynamic import hoặc consumer bên ngoài |
| **DANGER** | File config, entry point, định nghĩa type | Điều tra trước khi đụng vào |

## Bước 3: Vòng lặp xóa an toàn

Với mỗi mục SAFE:

1. **Chạy toàn bộ test suite** — Thiết lập baseline (tất cả xanh)
2. **Xóa dead code** — Dùng tool Edit để xóa chính xác
3. **Chạy lại test suite** — Xác minh không có gì hỏng
4. **Nếu test thất bại** — Revert ngay bằng `git checkout -- <file>` và bỏ qua mục này
5. **Nếu test pass** — Chuyển sang mục tiếp theo

## Bước 4: Xử lý các mục CAUTION

Trước khi xóa các mục CAUTION:
- Tìm dynamic import: `import()`, `require()`, `__import__`
- Tìm các tham chiếu dạng chuỗi: tên route, tên component trong config
- Kiểm tra xem có được export từ API của package public không
- Xác minh không có consumer bên ngoài (kiểm tra dependents nếu đã publish)

## Bước 5: Hợp nhất phần trùng lặp

Sau khi xóa dead code, hãy tìm:
- Các function gần như trùng (>80% giống nhau) — gộp thành một
- Định nghĩa type dư thừa — hợp nhất
- Wrapper function không đem lại giá trị — inline chúng
- Re-export không có mục đích — loại bỏ lớp gián tiếp

## Bước 6: Tóm tắt

Báo cáo kết quả:

```
Dead Code Cleanup
──────────────────────────────
Deleted:   12 unused functions
           3 unused files
           5 unused dependencies
Skipped:   2 items (tests failed)
Saved:     ~450 lines removed
──────────────────────────────
All tests passing PASS:
```

## Quy tắc

- **KHÔNG BAO GIỜ xóa mà chưa chạy test trước**
- **Mỗi lần xóa một mục** — Thay đổi nguyên tử giúp rollback dễ dàng
- **Bỏ qua nếu không chắc chắn** — Giữ dead code còn hơn làm hỏng production
- **Không refactor trong khi dọn dẹp** — Tách biệt các mối quan tâm (dọn trước, refactor sau)
