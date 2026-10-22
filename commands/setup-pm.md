---
description: Cấu hình package manager ưa thích của bạn (npm/pnpm/yarn/bun)
disable-model-invocation: true
---

# Thiết lập Package Manager

Cấu hình package manager ưa thích của bạn cho project này hoặc toàn cục.

## Cách dùng

```bash
# Detect current package manager
node scripts/setup-package-manager.js --detect

# Set global preference
node scripts/setup-package-manager.js --global pnpm

# Set project preference
node scripts/setup-package-manager.js --project bun

# List available package managers
node scripts/setup-package-manager.js --list
```

## Thứ tự ưu tiên phát hiện

Khi xác định dùng package manager nào, thứ tự kiểm tra sau được áp dụng:

1. **Biến môi trường**: `CLAUDE_PACKAGE_MANAGER`
2. **Config của project**: `.claude/package-manager.json`
3. **package.json**: trường `packageManager`
4. **Lock file**: Sự hiện diện của package-lock.json, yarn.lock, pnpm-lock.yaml hoặc bun.lockb
5. **Config toàn cục**: `~/.claude/package-manager.json`
6. **Fallback**: Package manager đầu tiên có sẵn (pnpm > bun > yarn > npm)

## Các file cấu hình

### Cấu hình toàn cục
```json
// ~/.claude/package-manager.json
{
  "packageManager": "pnpm"
}
```

### Cấu hình project
```json
// .claude/package-manager.json
{
  "packageManager": "bun"
}
```

### package.json
```json
{
  "packageManager": "pnpm@8.6.0"
}
```

## Biến môi trường

Đặt `CLAUDE_PACKAGE_MANAGER` để ghi đè tất cả các phương thức phát hiện khác:

```bash
# Windows (PowerShell)
$env:CLAUDE_PACKAGE_MANAGER = "pnpm"

# macOS/Linux
export CLAUDE_PACKAGE_MANAGER=pnpm
```

## Chạy việc phát hiện

Để xem kết quả phát hiện package manager hiện tại, chạy:

```bash
node scripts/setup-package-manager.js --detect
```
