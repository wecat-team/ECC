---
description: Review code Flutter/Dart về pattern idiomatic, best practice cho widget, quản lý state, hiệu năng, accessibility và bảo mật. Gọi agent flutter-reviewer.
---

# Flutter Code Review

Command này gọi agent **flutter-reviewer** để review các thay đổi code Flutter/Dart.

## Command này làm gì

1. **Thu thập context**: Xem `git diff --staged` và `git diff`
2. **Kiểm tra dự án**: Xem `pubspec.yaml`, `analysis_options.yaml`, giải pháp quản lý state
3. **Quét bảo mật sơ bộ**: Kiểm tra secret bị hardcode và các vấn đề bảo mật nghiêm trọng
4. **Review đầy đủ**: Áp dụng toàn bộ checklist review
5. **Báo cáo phát hiện**: Xuất các vấn đề được nhóm theo mức độ nghiêm trọng kèm hướng dẫn sửa

## Điều kiện tiên quyết

Trước khi chạy `/flutter-review`, hãy đảm bảo:
1. **Build thành công** — chạy `/flutter-build` trước; review trên code bị hỏng sẽ không đầy đủ
2. **Test thành công** — chạy `/flutter-test` để xác nhận không có regression
3. **Không có merge conflict** — giải quyết mọi conflict để diff chỉ phản ánh các thay đổi có chủ đích
4. **`flutter analyze` sạch** — sửa các warning của analyzer trước khi review

## Khi nào dùng

Dùng `/flutter-review` khi:
- Trước khi gửi PR có thay đổi Flutter/Dart (sau khi build và test thành công)
- Sau khi triển khai một tính năng mới để phát hiện vấn đề sớm
- Khi review code Flutter của người khác
- Để audit một widget, thành phần quản lý state hoặc service class
- Trước khi release lên production

## Các hạng mục review

| Hạng mục | Mức độ nghiêm trọng |
|------|----------|
| Secret bị hardcode, HTTP không mã hóa | CRITICAL |
| Vi phạm kiến trúc, anti-pattern quản lý state | CRITICAL |
| Vấn đề rebuild widget, rò rỉ tài nguyên | HIGH |
| Thiếu `dispose()`, `BuildContext` sau await | HIGH |
| Dart null safety, thiếu trạng thái error/loading | HIGH |
| Const propagation, composition của widget | HIGH |
| Hiệu năng: công việc tốn kém trong `build()` | HIGH |
| Accessibility, semantic label | MEDIUM |
| Thiếu test cho các chuyển đổi state | HIGH |
| String bị hardcode (l10n) | MEDIUM |
| Sự gọn gàng của pub dependency | LOW |

## Phiên làm việc ví dụ

````text
User: /flutter-review

Agent:
# Flutter Code Review

## Context

Changed files:
- lib/features/auth/presentation/login_page.dart
- lib/features/auth/data/auth_repository_impl.dart

State management: Riverpod (detected from pubspec.yaml)
Architecture: feature-first

## Security Pre-scan

✓ No hardcoded secrets detected
✓ No cleartext HTTP calls

## Review Findings

[HIGH] BuildContext used after async gap without mounted check
File: lib/features/auth/presentation/login_page.dart:67
Issue: `context.go('/home')` called after `await auth.login(...)` with no `mounted` check.
Fix: Add `if (!context.mounted) return;` before any navigation after awaits (Flutter 3.7+).

[HIGH] AsyncValue error state not handled
File: lib/features/auth/presentation/login_page.dart:42
Issue: `ref.watch(authProvider)` switches on loading/data but has no `error` branch.
Fix: Add error case to the switch expression or `when()` call to show a user-facing error message.

[MEDIUM] Hardcoded string not localized
File: lib/features/auth/presentation/login_page.dart:89
Issue: `Text('Login')` — user-visible string not using localization system.
Fix: Use the project's l10n accessor: `Text(context.l10n.loginButton)`.

## Review Summary

| Severity | Count | Status |
|----------|-------|--------|
| CRITICAL | 0     | pass   |
| HIGH     | 2     | block  |
| MEDIUM   | 1     | info   |
| LOW      | 0     | note   |

Verdict: BLOCK — HIGH issues must be fixed before merge.
````

## Tiêu chí phê duyệt

- **Approve**: Không có vấn đề CRITICAL hoặc HIGH
- **Block**: Mọi vấn đề CRITICAL hoặc HIGH phải được sửa trước khi merge

## Các command liên quan

- `/flutter-build` — Sửa lỗi build trước
- `/flutter-test` — Chạy test trước khi review
- `/code-review` — Code review tổng quát (không phụ thuộc ngôn ngữ)

## Liên quan

- Agent: `agents/flutter-reviewer.md`
- Skill: `skills/flutter-dart-code-review/`
- Rules: `rules/dart/`
