---
description: Phân tích coverage, xác định khoảng trống và tạo các test còn thiếu để đạt ngưỡng mục tiêu.
---

# Test Coverage

Phân tích test coverage, xác định khoảng trống và tạo các test còn thiếu để đạt coverage 80%+.

## Bước 1: Phát hiện Test Framework

| Dấu hiệu | Lệnh coverage |
|-----------|-----------------|
| `jest.config.*` hoặc jest trong `package.json` | `npx jest --coverage --coverageReporters=json-summary` |
| `vitest.config.*` | `npx vitest run --coverage` |
| `pytest.ini` / pytest trong `pyproject.toml` | `pytest --cov=src --cov-report=json` |
| `Cargo.toml` | `cargo llvm-cov --json` |
| `pom.xml` với JaCoCo | `mvn test jacoco:report` |
| `go.mod` | `go test -coverprofile=coverage.out ./...` |

## Bước 2: Phân tích báo cáo coverage

1. Chạy lệnh coverage
2. Parse đầu ra (JSON summary hoặc đầu ra terminal)
3. Liệt kê các file **dưới 80% coverage**, sắp xếp từ tệ nhất
4. Với mỗi file chưa đủ coverage, xác định:
   - Function hoặc method chưa được test
   - Thiếu branch coverage (if/else, switch, đường lỗi)
   - Dead code làm phình mẫu số

## Bước 3: Tạo các test còn thiếu

Với mỗi file chưa đủ coverage, tạo test theo thứ tự ưu tiên sau:

1. **Happy path** — Chức năng cốt lõi với đầu vào hợp lệ
2. **Xử lý lỗi** — Đầu vào không hợp lệ, thiếu dữ liệu, lỗi mạng
3. **Edge case** — Mảng rỗng, null/undefined, giá trị biên (0, -1, MAX_INT)
4. **Branch coverage** — Mỗi if/else, case của switch, ternary

### Quy tắc tạo test

- Đặt test cạnh source: `foo.ts` → `foo.test.ts` (hoặc theo quy ước của project)
- Dùng các pattern test hiện có của project (kiểu import, thư viện assertion, cách mock)
- Mock các dependency bên ngoài (database, API, file system)
- Mỗi test phải độc lập — không có mutable state dùng chung giữa các test
- Đặt tên test mô tả rõ: `test_create_user_with_duplicate_email_returns_409`

## Bước 4: Xác minh

1. Chạy toàn bộ test suite — tất cả test phải pass
2. Chạy lại coverage — xác minh có cải thiện
3. Nếu vẫn dưới 80%, lặp lại Bước 3 cho các khoảng trống còn lại

## Bước 5: Báo cáo

Hiển thị so sánh trước/sau:

```
Coverage Report
──────────────────────────────
File                   Before  After
src/services/auth.ts   45%     88%
src/utils/validation.ts 32%    82%
──────────────────────────────
Overall:               67%     84%  PASS:
```

## Các vùng cần tập trung

- Function có phân nhánh phức tạp (cyclomatic complexity cao)
- Error handler và khối catch
- Utility function được dùng xuyên suốt codebase
- Handler của API endpoint (luồng request → response)
- Edge case: null, undefined, chuỗi rỗng, mảng rỗng, số không, số âm
