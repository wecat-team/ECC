---
name: coding-standards
description: Các convention coding nền tảng dùng chung cho nhiều dự án về đặt tên, độ dễ đọc, tính bất biến (immutable) và review chất lượng code. Dùng các skill frontend hoặc backend chi tiết cho pattern đặc thù framework. Dùng khi review chất lượng code hoặc đặt tên mà không có skill đặc thù framework nào áp dụng.
metadata:
  origin: ECC
---

# Coding Standards & Best Practice

Các convention coding nền tảng áp dụng cho nhiều dự án.

Skill này là nền chung, không phải playbook chi tiết cho từng framework.

- Dùng `frontend-patterns` cho React, state, form, rendering và kiến trúc UI.
- Dùng `backend-patterns` hoặc `api-design` cho các lớp repository/service, thiết kế endpoint, validation và các mối quan tâm đặc thù của server.
- Dùng `rules/common/coding-style.md` khi bạn cần lớp rule tái sử dụng ngắn nhất thay vì một walkthrough skill đầy đủ.

## Khi nào kích hoạt

- Bắt đầu một dự án hoặc module mới
- Review code về chất lượng và khả năng bảo trì
- Refactor code hiện có để tuân theo convention
- Thực thi sự nhất quán về đặt tên, định dạng hoặc cấu trúc
- Thiết lập các rule về linting, formatting hoặc type-checking
- Onboard contributor mới vào các coding convention

## Phạm vi

Kích hoạt skill này cho:
- đặt tên có tính mô tả
- mặc định bất biến (immutable)
- thực thi độ dễ đọc, KISS, DRY và YAGNI
- kỳ vọng về xử lý lỗi và review code smell

KHÔNG dùng skill này làm nguồn chính cho:
- composition, hook hoặc pattern rendering của React
- kiến trúc backend, thiết kế API hoặc phân lớp database
- hướng dẫn riêng theo domain của framework khi đã có một skill ECC hẹp hơn

## Nguyên tắc chất lượng code

### 1. Ưu tiên độ dễ đọc
- Code được đọc nhiều hơn được viết
- Tên biến và hàm rõ ràng
- Ưu tiên code tự giải thích hơn comment
- Định dạng nhất quán

### 2. KISS (Keep It Simple, Stupid)
- Giải pháp đơn giản nhất mà hoạt động
- Tránh over-engineering
- Không tối ưu hóa sớm
- Dễ hiểu > code thông minh

### 3. DRY (Don't Repeat Yourself)
- Tách logic chung ra thành hàm
- Tạo các component tái sử dụng được
- Chia sẻ utility giữa các module
- Tránh lập trình copy-paste

### 4. YAGNI (You Aren't Gonna Need It)
- Không xây dựng tính năng trước khi cần
- Tránh tính tổng quát mang tính suy đoán
- Chỉ thêm độ phức tạp khi cần thiết
- Bắt đầu đơn giản, refactor khi cần

## Tiêu chuẩn TypeScript/JavaScript

### Đặt tên biến

```typescript
// PASS: GOOD: Descriptive names
const marketSearchQuery = 'election'
const isUserAuthenticated = true
const totalRevenue = 1000

// FAIL: BAD: Unclear names
const q = 'election'
const flag = true
const x = 1000
```

### Đặt tên hàm

```typescript
// PASS: GOOD: Verb-noun pattern
async function fetchMarketData(marketId: string) { }
function calculateSimilarity(a: number[], b: number[]) { }
function isValidEmail(email: string): boolean { }

// FAIL: BAD: Unclear or noun-only
async function market(id: string) { }
function similarity(a, b) { }
function email(e) { }
```

### Pattern bất biến (Immutability) (CRITICAL)

```typescript
// PASS: ALWAYS use spread operator
const updatedUser = {
  ...user,
  name: 'New Name'
}

const updatedArray = [...items, newItem]

// FAIL: NEVER mutate directly
user.name = 'New Name'  // BAD
items.push(newItem)     // BAD
```

### Xử lý lỗi

```typescript
// PASS: GOOD: Comprehensive error handling
async function fetchData(url: string) {
  try {
    const response = await fetch(url)

    if (!response.ok) {
      throw new Error(`HTTP ${response.status}: ${response.statusText}`)
    }

    return await response.json()
  } catch (error) {
    console.error('Fetch failed:', error)
    throw new Error('Failed to fetch data')
  }
}

// FAIL: BAD: No error handling
async function fetchData(url) {
  const response = await fetch(url)
  return response.json()
}
```

### Best practice cho Async/Await

```typescript
// PASS: GOOD: Parallel execution when possible
const [users, markets, stats] = await Promise.all([
  fetchUsers(),
  fetchMarkets(),
  fetchStats()
])

// FAIL: BAD: Sequential when unnecessary
const users = await fetchUsers()
const markets = await fetchMarkets()
const stats = await fetchStats()
```

### An toàn kiểu (Type Safety)

```typescript
// PASS: GOOD: Proper types
interface Market {
  id: string
  name: string
  status: 'active' | 'resolved' | 'closed'
  created_at: Date
}

function getMarket(id: string): Promise<Market> {
  // Implementation
}

// FAIL: BAD: Using 'any'
function getMarket(id: any): Promise<any> {
  // Implementation
}
```

## Best practice cho React

### Cấu trúc component

```typescript
// PASS: GOOD: Functional component with types
interface ButtonProps {
  children: React.ReactNode
  onClick: () => void
  disabled?: boolean
  variant?: 'primary' | 'secondary'
}

export function Button({
  children,
  onClick,
  disabled = false,
  variant = 'primary'
}: ButtonProps) {
  return (
    <button
      onClick={onClick}
      disabled={disabled}
      className={`btn btn-${variant}`}
    >
      {children}
    </button>
  )
}

// FAIL: BAD: No types, unclear structure
export function Button(props) {
  return <button onClick={props.onClick}>{props.children}</button>
}
```

### Custom Hook

```typescript
// PASS: GOOD: Reusable custom hook
export function useDebounce<T>(value: T, delay: number): T {
  const [debouncedValue, setDebouncedValue] = useState<T>(value)

  useEffect(() => {
    const handler = setTimeout(() => {
      setDebouncedValue(value)
    }, delay)

    return () => clearTimeout(handler)
  }, [value, delay])

  return debouncedValue
}

// Usage
const debouncedQuery = useDebounce(searchQuery, 500)
```

### Quản lý state

```typescript
// PASS: GOOD: Proper state updates
const [count, setCount] = useState(0)

// Functional update for state based on previous state
setCount(prev => prev + 1)

// FAIL: BAD: Direct state reference
setCount(count + 1)  // Can be stale in async scenarios
```

### Conditional Rendering

```typescript
// PASS: GOOD: Clear conditional rendering
{isLoading && <Spinner />}
{error && <ErrorMessage error={error} />}
{data && <DataDisplay data={data} />}

// FAIL: BAD: Ternary hell
{isLoading ? <Spinner /> : error ? <ErrorMessage error={error} /> : data ? <DataDisplay data={data} /> : null}
```

## Tiêu chuẩn thiết kế API

### Convention REST API

```
GET    /api/markets              # List all markets
GET    /api/markets/:id          # Get specific market
POST   /api/markets              # Create new market
PUT    /api/markets/:id          # Update market (full)
PATCH  /api/markets/:id          # Update market (partial)
DELETE /api/markets/:id          # Delete market

# Query parameters for filtering
GET /api/markets?status=active&limit=10&offset=0
```

### Định dạng response

```typescript
// PASS: GOOD: Consistent response structure
interface ApiResponse<T> {
  success: boolean
  data?: T
  error?: string
  meta?: {
    total: number
    page: number
    limit: number
  }
}

// Success response
return NextResponse.json({
  success: true,
  data: markets,
  meta: { total: 100, page: 1, limit: 10 }
})

// Error response
return NextResponse.json({
  success: false,
  error: 'Invalid request'
}, { status: 400 })
```

### Kiểm tra đầu vào (Input Validation)

```typescript
import { z } from 'zod'

// PASS: GOOD: Schema validation
const CreateMarketSchema = z.object({
  name: z.string().min(1).max(200),
  description: z.string().min(1).max(2000),
  endDate: z.string().datetime(),
  categories: z.array(z.string()).min(1)
})

export async function POST(request: Request) {
  const body = await request.json()

  try {
    const validated = CreateMarketSchema.parse(body)
    // Proceed with validated data
  } catch (error) {
    if (error instanceof z.ZodError) {
      return NextResponse.json({
        success: false,
        error: 'Validation failed',
        details: error.issues
      }, { status: 400 })
    }
  }
}
```

## Tổ chức file

### Cấu trúc dự án

```
src/
├── app/                    # Next.js App Router
│   ├── api/               # API routes
│   ├── markets/           # Market pages
│   └── (auth)/           # Auth pages (route groups)
├── components/            # React components
│   ├── ui/               # Generic UI components
│   ├── forms/            # Form components
│   └── layouts/          # Layout components
├── hooks/                # Custom React hooks
├── lib/                  # Utilities and configs
│   ├── api/             # API clients
│   ├── utils/           # Helper functions
│   └── constants/       # Constants
├── types/                # TypeScript types
└── styles/              # Global styles
```

### Đặt tên file

```
components/Button.tsx          # PascalCase for components
hooks/useAuth.ts              # camelCase with 'use' prefix
lib/formatDate.ts             # camelCase for utilities
types/market.types.ts         # camelCase with .types suffix
```

## Comment & Tài liệu

### Khi nào nên comment

```typescript
// PASS: GOOD: Explain WHY, not WHAT
// Use exponential backoff to avoid overwhelming the API during outages
const delay = Math.min(1000 * Math.pow(2, retryCount), 30000)

// Deliberately using mutation here for performance with large arrays
items.push(newItem)

// FAIL: BAD: Stating the obvious
// Increment counter by 1
count++

// Set name to user's name
name = user.name
```

### JSDoc cho Public API

```typescript
/**
 * Searches markets using semantic similarity.
 *
 * @param query - Natural language search query
 * @param limit - Maximum number of results (default: 10)
 * @returns Array of markets sorted by similarity score
 * @throws {Error} If OpenAI API fails or Redis unavailable
 *
 * @example
 * ```typescript
 * const results = await searchMarkets('election', 5)
 * console.log(results[0].name) // "Trump vs Biden"
 * ```
 */
export async function searchMarkets(
  query: string,
  limit: number = 10
): Promise<Market[]> {
  // Implementation
}
```

## Best practice về hiệu năng

### Memoization

```typescript
import { useMemo, useCallback } from 'react'

// PASS: GOOD: Memoize expensive computations
// Copy before sorting - Array.prototype.sort mutates in place
const sortedMarkets = useMemo(() => {
  return [...markets].sort((a, b) => b.volume - a.volume)
}, [markets])

// PASS: GOOD: Memoize callbacks
const handleSearch = useCallback((query: string) => {
  setSearchQuery(query)
}, [])
```

### Lazy Loading

```typescript
import { lazy, Suspense } from 'react'

// PASS: GOOD: Lazy load heavy components
const HeavyChart = lazy(() => import('./HeavyChart'))

export function Dashboard() {
  return (
    <Suspense fallback={<Spinner />}>
      <HeavyChart />
    </Suspense>
  )
}
```

### Database Query

```typescript
// PASS: GOOD: Select only needed columns
const { data } = await supabase
  .from('markets')
  .select('id, name, status')
  .limit(10)

// FAIL: BAD: Select everything
const { data } = await supabase
  .from('markets')
  .select('*')
```

## Tiêu chuẩn Testing

### Cấu trúc test (Pattern AAA)

```typescript
test('calculates similarity correctly', () => {
  // Arrange
  const vector1 = [1, 0, 0]
  const vector2 = [0, 1, 0]

  // Act
  const similarity = calculateCosineSimilarity(vector1, vector2)

  // Assert
  expect(similarity).toBe(0)
})
```

### Đặt tên test

```typescript
// PASS: GOOD: Descriptive test names
test('returns empty array when no markets match query', () => { })
test('throws error when OpenAI API key is missing', () => { })
test('falls back to substring search when Redis unavailable', () => { })

// FAIL: BAD: Vague test names
test('works', () => { })
test('test search', () => { })
```

## Phát hiện Code Smell

Hãy chú ý các anti-pattern sau:

### 1. Hàm quá dài
```typescript
// FAIL: BAD: Function > 50 lines
function processMarketData() {
  // 100 lines of code
}

// PASS: GOOD: Split into smaller functions
function processMarketData() {
  const validated = validateData()
  const transformed = transformData(validated)
  return saveData(transformed)
}
```

### 2. Lồng nhau quá sâu
```typescript
// FAIL: BAD: 5+ levels of nesting
if (user) {
  if (user.isAdmin) {
    if (market) {
      if (market.isActive) {
        if (hasPermission) {
          // Do something
        }
      }
    }
  }
}

// PASS: GOOD: Early returns
if (!user) return
if (!user.isAdmin) return
if (!market) return
if (!market.isActive) return
if (!hasPermission) return

// Do something
```

### 3. Magic Number
```typescript
// FAIL: BAD: Unexplained numbers
if (retryCount > 3) { }
setTimeout(callback, 500)

// PASS: GOOD: Named constants
const MAX_RETRIES = 3
const DEBOUNCE_DELAY_MS = 500

if (retryCount > MAX_RETRIES) { }
setTimeout(callback, DEBOUNCE_DELAY_MS)
```

**Hãy nhớ**: Chất lượng code là không thể thương lượng. Code rõ ràng, dễ bảo trì giúp phát triển nhanh và refactor tự tin.
