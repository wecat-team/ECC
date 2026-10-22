---
paths:
  - "**/*.ets"
  - "**/*.ts"
  - "**/module.json5"
  - "**/oh-package.json5"
---
# Hook cho HarmonyOS / ArkTS

> File này mở rộng [common/hooks.md](../common/hooks.md) với các hook build và kiểm tra riêng cho HarmonyOS.

## Lệnh build

### Build gói HAP

```bash
# Build HAP package (global hvigor environment)
hvigorw assembleHap -p product=default

# Build with specific module
hvigorw assembleHap -p module=entry -p product=default

# Clean build
hvigorw clean
```

### DevEco Studio CLI

```bash
# Check project structure
hvigorw --version

# Install dependencies
ohpm install

# Update dependencies
ohpm update
```

## Hook PostToolUse được khuyến nghị

### Sau khi sửa file .ets/.ts

Chạy hvigor build để kiểm tra lỗi biên dịch ArkTS:

```json
{
  "type": "PostToolUse",
  "matcher": {
    "tool": ["Edit", "Write"],
    "filePath": ["**/*.ets", "**/*.ts"]
  },
  "hooks": [
    {
      "command": "hvigorw assembleHap -p product=default 2>&1 | tail -20",
      "async": true,
      "timeout": 60000
    }
  ]
}
```

### Sau khi sửa module.json5

Kiểm tra các khai báo permission và ability:

```json
{
  "type": "PostToolUse",
  "matcher": {
    "tool": "Edit",
    "filePath": "**/module.json5"
  },
  "hooks": [
    {
      "command": "echo '[HarmonyOS] module.json5 modified - verify permissions and abilities'",
      "async": false
    }
  ]
}
```

### Sau khi sửa oh-package.json5

Cài đặt lại dependency:

```json
{
  "type": "PostToolUse",
  "matcher": {
    "tool": "Edit",
    "filePath": "**/oh-package.json5"
  },
  "hooks": [
    {
      "command": "ohpm install 2>&1 | tail -10",
      "async": true,
      "timeout": 30000
    }
  ]
}
```

## Hook PreToolUse

### Chốt chặn decorator V1

Cảnh báo khi code chứa các decorator quản lý state V1:

```json
{
  "type": "PreToolUse",
  "matcher": {
    "tool": ["Write", "Edit"],
    "filePath": "**/*.ets"
  },
  "hooks": [
    {
      "command": "echo '[HarmonyOS] Reminder: Use @ComponentV2 / @Local / @Param - V1 decorators (@State, @Prop, @Link) are prohibited'"
    }
  ]
}
```

## Checklist kiểm tra

Sau mỗi chu kỳ triển khai, hãy xác minh:

- [ ] `hvigorw assembleHap` hoàn tất không có lỗi
- [ ] Không có decorator V1 trong các file `.ets` mới hoặc đã sửa
- [ ] Không có import `@ohos.router` trong các file mới hoặc đã sửa
- [ ] Mọi permission của API đều được khai báo trong `module.json5`
- [ ] Mọi dependency đều được liệt kê trong `oh-package.json5`
- [ ] Chuỗi resource đã được thêm vào tất cả thư mục i18n
- [ ] Đã cung cấp màu cho dark theme với các color resource mới
