---
paths:
  - "**/*.ts"
  - "**/*.tsx"
  - "**/*.js"
  - "**/*.jsx"
---
# Coding Style TypeScript/JavaScript

> File này mở rộng [common/coding-style.md](../common/coding-style.md) với nội dung riêng cho TypeScript/JavaScript.

## Type và Interface

Dùng type để làm cho API công khai, model dùng chung và props của component tường minh, dễ đọc và tái sử dụng được.

### API công khai

- Thêm type cho tham số và giá trị trả về của các hàm được export, utility dùng chung và method công khai của class
- Để TypeScript suy luận type của các biến cục bộ hiển nhiên
- Tách các object shape inline lặp lại thành type hoặc interface có tên

```typescript
// WRONG: Exported function without explicit types
export function formatUser(user) {
  return `${user.firstName} ${user.lastName}`
}

// CORRECT: Explicit types on public APIs
interface User {
  firstName: string
  lastName: string
}

export function formatUser(user: User): string {
  return `${user.firstName} ${user.lastName}`
}
```

### Interface so với Type Alias

- Dùng `interface` cho object shape có thể được mở rộng hoặc implement
- Dùng `type` cho union, intersection, tuple, mapped type và utility type
- Ưu tiên union của string literal hơn `enum`, trừ khi cần `enum` để tương thích

```typescript
interface User {
  id: string
  email: string
}

type UserRole = 'admin' | 'member'
type UserWithRole = User & {
  role: UserRole
}
```

### Tránh `any`

- Tránh `any` trong code ứng dụng
- Dùng `unknown` cho đầu vào bên ngoài hoặc không đáng tin, rồi thu hẹp (narrow) nó một cách an toàn
- Dùng generic khi type của một giá trị phụ thuộc vào bên gọi

```typescript
// WRONG: any removes type safety
function getErrorMessage(error: any) {
  return error.message
}

// CORRECT: unknown forces safe narrowing
function getErrorMessage(error: unknown): string {
  if (error instanceof Error) {
    return error.message
  }

  return 'Unexpected error'
}
```

### React Props

- Định nghĩa props của component bằng `interface` hoặc `type` có tên
- Khai báo type tường minh cho callback props
- Không dùng `React.FC` trừ khi có lý do cụ thể

```typescript
interface User {
  id: string
  email: string
}

interface UserCardProps {
  user: User
  onSelect: (id: string) => void
}

function UserCard({ user, onSelect }: UserCardProps) {
  return <button onClick={() => onSelect(user.id)}>{user.email}</button>
}
```

### File JavaScript

- Trong file `.js` và `.jsx`, dùng JSDoc khi type giúp rõ ràng hơn và việc migrate sang TypeScript chưa khả thi
- Giữ JSDoc khớp với hành vi lúc runtime

```javascript
/**
 * @param {{ firstName: string, lastName: string }} user
 * @returns {string}
 */
export function formatUser(user) {
  return `${user.firstName} ${user.lastName}`
}
```

## Bất biến (Immutability)

Dùng spread operator để cập nhật bất biến:

```typescript
interface User {
  id: string
  name: string
}

// WRONG: Mutation
function updateUser(user: User, name: string): User {
  user.name = name // MUTATION!
  return user
}

// CORRECT: Immutability
function updateUser(user: Readonly<User>, name: string): User {
  return {
    ...user,
    name
  }
}
```

## Xử lý lỗi

Dùng async/await với try-catch và thu hẹp lỗi unknown một cách an toàn:

```typescript
interface User {
  id: string
  email: string
}

declare function riskyOperation(userId: string): Promise<User>

function getErrorMessage(error: unknown): string {
  if (error instanceof Error) {
    return error.message
  }

  return 'Unexpected error'
}

const logger = {
  error: (message: string, error: unknown) => {
    // Replace with your production logger (for example, pino or winston).
  }
}

async function loadUser(userId: string): Promise<User> {
  try {
    const result = await riskyOperation(userId)
    return result
  } catch (error: unknown) {
    logger.error('Operation failed', error)
    throw new Error(getErrorMessage(error))
  }
}
```

## Kiểm tra đầu vào (Input Validation)

Dùng Zod để validate dựa trên schema và suy ra type từ schema:

```typescript
import { z } from 'zod'

const userSchema = z.object({
  email: z.string().email(),
  age: z.number().int().min(0).max(150)
})

type UserInput = z.infer<typeof userSchema>

const validated: UserInput = userSchema.parse(input)
```

## Console.log

- Không có câu lệnh `console.log` trong code production
- Hãy dùng thư viện logging phù hợp thay thế
- Xem hook để phát hiện tự động
