---
paths:
  - "**/*.ts"
  - "**/*.tsx"
  - "**/*.js"
  - "**/*.jsx"
---
# Bảo mật TypeScript/JavaScript

> File này mở rộng [common/security.md](../common/security.md) với nội dung riêng cho TypeScript/JavaScript.

## Quản lý secret

```typescript
// NEVER: Hardcoded secrets
const apiKey = "sk-proj-xxxxx"

// ALWAYS: Environment variables
const apiKey = process.env.API_KEY

if (!apiKey) {
  throw new Error('API_KEY not configured')
}
```

## Hỗ trợ từ Agent

- Dùng skill **security-reviewer** cho các cuộc audit bảo mật toàn diện
