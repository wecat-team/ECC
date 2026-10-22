---
description: Sửa từng bước các lỗi Dart analyzer và lỗi build Flutter. Gọi agent dart-build-resolver để sửa tối thiểu, chính xác.
---

# Flutter Build và Fix

Command này gọi agent **dart-build-resolver** để sửa từng bước các lỗi build Dart/Flutter với thay đổi tối thiểu.

## Command này làm gì

1. **Chạy chẩn đoán**: Thực thi `flutter analyze`, `flutter pub get`
2. **Phân tích lỗi**: Nhóm theo file và sắp xếp theo mức độ nghiêm trọng
3. **Sửa từng bước**: Mỗi lần một lỗi
4. **Xác minh từng bản sửa**: Chạy lại analysis sau mỗi thay đổi
5. **Báo cáo tóm tắt**: Hiển thị những gì đã sửa và những gì còn lại

## Khi nào dùng

Dùng `/flutter-build` khi:
- `flutter analyze` báo lỗi
- `flutter build` thất bại trên bất kỳ nền tảng nào
- `dart pub get` / `flutter pub get` thất bại do xung đột phiên bản
- `build_runner` không sinh được code
- Sau khi pull các thay đổi làm hỏng build

## Các lệnh chẩn đoán được chạy

```bash
# Analysis
flutter analyze 2>&1

# Dependencies
flutter pub get 2>&1

# Code generation (if project uses build_runner)
dart run build_runner build --delete-conflicting-outputs 2>&1

# Platform builds
flutter build apk 2>&1
flutter build web 2>&1
```

## Phiên làm việc ví dụ

````text
User: /flutter-build

Agent:
# Flutter Build Resolution

## Initial Diagnostics

```
$ flutter analyze
Analyzing project...

  error • lib/features/user/data/user_repository_impl.dart:34:16 •
    A value of type 'String?' can't be assigned to a variable of type 'String'. •
    invalid_assignment

  error • lib/features/cart/presentation/cart_page.dart:58:5 •
    The method 'add' isn't defined for the type 'List<Item>'.
    Try correcting the name to the name of an existing method, or defining a method named 'add'. •
    undefined_method

2 errors found.
```

## Fix 1: Null Safety

File: lib/features/user/data/user_repository_impl.dart:34
Error: A value of type 'String?' can't be assigned to type 'String'

Changed:
```dart
final id = response.id;
```
To:
```dart
final id = response.id ?? '';
```

```
$ flutter analyze
1 error found.
```

## Fix 2: Immutable List

File: lib/features/cart/presentation/cart_page.dart:58
Error: The method 'add' isn't defined for the type 'List<Item>'
Cause: State holds an unmodifiable list; mutation goes through Cubit

Changed:
```dart
state.items.add(item);
```
To:
```dart
context.read<CartCubit>().addItem(item);
// Note: Cubit exposes named methods (addItem, removeItem);
// .add(event) is the BLoC event API — don't mix them.
```

```
$ flutter analyze
No issues found!
```

## Final Verification

```
$ flutter test
All tests passed.
```

## Summary

| Metric | Count |
|--------|-------|
| Analysis errors fixed | 2 |
| Files modified | 2 |
| Remaining issues | 0 |

Build Status: PASS ✓
````

## Các lỗi thường gặp đã sửa

| Lỗi | Cách sửa điển hình |
|-------|-------------|
| `A value of type 'X?' can't be assigned to 'X'` | Thêm `?? default` hoặc null guard |
| `The name 'X' isn't defined` | Thêm import hoặc sửa lỗi gõ |
| `Non-nullable instance field must be initialized` | Thêm initializer hoặc `late` |
| `Version solving failed` | Điều chỉnh ràng buộc phiên bản trong pubspec.yaml |
| `Missing concrete implementation of 'X'` | Triển khai method interface còn thiếu |
| `build_runner: Part of X expected` | Xóa `.g.dart` cũ và build lại |

## Chiến lược sửa lỗi

1. **Lỗi analysis trước** — code phải không còn lỗi
2. **Phân loại warning thứ hai** — sửa các warning có thể gây bug lúc runtime
3. **Xung đột pub thứ ba** — sửa việc phân giải dependency
4. **Mỗi lần một bản sửa** — xác minh từng thay đổi
5. **Thay đổi tối thiểu** — không refactor, chỉ sửa

## Điều kiện dừng

Agent sẽ dừng và báo cáo nếu:
- Cùng một lỗi vẫn còn sau 3 lần thử
- Bản sửa gây thêm lỗi
- Cần thay đổi kiến trúc
- Xung đột khi nâng cấp package cần người dùng quyết định

## Các command liên quan

- `/flutter-test` — Chạy test sau khi build thành công
- `/flutter-review` — Review chất lượng code
- skill `verification-loop` — Vòng lặp xác minh đầy đủ

## Liên quan

- Agent: `agents/dart-build-resolver.md`
- Skill: `skills/flutter-dart-code-review/`
