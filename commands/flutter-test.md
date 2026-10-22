---
description: Chạy test Flutter/Dart, báo cáo lỗi và sửa dần các vấn đề của test. Bao gồm unit, widget, golden và integration test.
---

# Flutter Test

Command này chạy bộ test Flutter và báo cáo kết quả. Khi có lỗi, nó chẩn đoán và sửa dần từng vấn đề.

## Command này làm gì

1. **Chạy test**: Thực thi `flutter test` (hoặc giới hạn trong các file đã thay đổi)
2. **Phân tích lỗi**: Xác định các test thất bại theo loại và nguyên nhân
3. **Sửa từng bước**: Mỗi lần một lỗi nếu có thể
4. **Xác minh**: Chạy lại sau mỗi bản sửa
5. **Báo cáo**: Hiển thị tóm tắt coverage và các lỗi còn lại

## Khi nào dùng

Dùng `/flutter-test` khi:
- Sau khi triển khai một tính năng để xác minh không có gì bị hỏng
- Sau khi chạy `/flutter-build` để đảm bảo test thành công
- Để kiểm tra test coverage trên code mới
- Khi một file test cụ thể đang thất bại
- Trước khi gửi PR

## Các lệnh được chạy

```bash
# Run all tests
flutter test 2>&1

# Run with coverage
flutter test --coverage 2>&1

# Run specific test file
flutter test test/unit/domain/usecases/get_user_test.dart 2>&1

# Run tests matching a name pattern
flutter test --name "CartBloc" 2>&1

# Run integration tests (requires device/emulator)
flutter test integration_test/ 2>&1

# Update golden files when intentional visual changes are made
flutter test --update-goldens 2>&1
```

## Phiên làm việc ví dụ

````text
User: /flutter-test

Agent:
# Flutter Test Run

## Test Execution

```
$ flutter test
00:05 +42 -2: Some tests failed.

FAILED: test/unit/data/user_repository_test.dart
  UserRepository getById
    returns null when user not found
    Expected: null
    Actual: User(id: 'test-id', name: 'Test User')

FAILED: test/widget/cart_page_test.dart
  CartPage
    shows empty state when cart is empty
    Expected: exactly one widget with text 'Your cart is empty'
    Found: no widget with text 'Your cart is empty'
```

## Fix 1: Repository Test

File: test/unit/data/user_repository_test.dart
Failure: `getById` returns a user when it should return null for missing ID

Root cause: Test setup adds a user with ID 'test-id' but queries with 'missing-id'.
Fix: Updated test to query with 'missing-id' — setup was correct, query was wrong.

```
$ flutter test test/unit/data/user_repository_test.dart
1 test passed.
```

## Fix 2: Widget Test

File: test/widget/cart_page_test.dart
Failure: Empty state text widget not found

Root cause: Empty state message was renamed from 'Your cart is empty' to 'Cart is empty' in the widget.
Fix: Updated test string to match current widget copy.

```
$ flutter test test/widget/cart_page_test.dart
1 test passed.
```

## Final Run

```
$ flutter test --coverage
All 44 tests passed.
Coverage: 84.2% (target: 80%)
```

## Summary

| Metric | Value |
|--------|-------|
| Total tests | 44 |
| Passed | 44 |
| Failed | 0 |
| Coverage | 84.2% |

Test Status: PASS ✓
````

## Các lỗi test thường gặp

| Lỗi | Cách sửa điển hình |
|---------|-------------|
| `Expected: <X> Actual: <Y>` | Cập nhật assertion hoặc sửa phần triển khai |
| `Widget not found` | Sửa selector của finder hoặc cập nhật test sau khi đổi tên widget |
| `Golden file not found` | Chạy `flutter test --update-goldens` để tạo |
| `Golden mismatch` | Xem diff; chạy `--update-goldens` nếu thay đổi là có chủ đích |
| `MissingPluginException` | Mock platform channel trong phần setup của test |
| `LateInitializationError` | Khởi tạo các field `late` trong `setUp()` |
| `pumpAndSettle timed out` | Thay bằng các lời gọi `pump(Duration)` tường minh |

## Các command liên quan

- `/flutter-build` — Sửa lỗi build trước khi chạy test
- `/flutter-review` — Review code sau khi test thành công
- skill `tdd-workflow` — Workflow phát triển hướng kiểm thử (TDD)

## Liên quan

- Agent: `agents/flutter-reviewer.md`
- Agent: `agents/dart-build-resolver.md`
- Skill: `skills/flutter-dart-code-review/`
- Rules: `rules/dart/testing.md`
