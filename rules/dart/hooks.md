---
paths:
  - "**/*.dart"
  - "**/pubspec.yaml"
  - "**/analysis_options.yaml"
---
# Hook cho Dart/Flutter

> File này mở rộng [common/hooks.md](../common/hooks.md) với nội dung dành riêng cho Dart và Flutter.

## Hook PostToolUse

Cấu hình trong `~/.claude/settings.json`:

- **dart format**: Tự động format các file `.dart` sau khi sửa
- **dart analyze**: Chạy phân tích tĩnh sau khi sửa file Dart và hiển thị cảnh báo
- **flutter test**: Tùy chọn chạy các test bị ảnh hưởng sau các thay đổi đáng kể

## Cấu hình Hook được khuyến nghị

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": { "tool_name": "Edit", "file_paths": ["**/*.dart"] },
        "hooks": [
          { "type": "command", "command": "dart format $CLAUDE_FILE_PATHS" }
        ]
      }
    ]
  }
}
```

## Kiểm tra Pre-commit

Chạy trước khi commit thay đổi Dart/Flutter:

```bash
dart format --set-exit-if-changed .
dart analyze --fatal-infos
flutter test
```

## Các lệnh một dòng hữu ích

```bash
# Format all Dart files
dart format .

# Analyze and report issues
dart analyze

# Run all tests with coverage
flutter test --coverage

# Regenerate code-gen files
dart run build_runner build --delete-conflicting-outputs

# Check for outdated packages
flutter pub outdated

# Upgrade packages within constraints
flutter pub upgrade
```
