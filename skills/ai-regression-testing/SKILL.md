---
name: ai-regression-testing
description: Chiến lược kiểm thử hồi quy (regression testing) cho phát triển có AI hỗ trợ. Test API ở chế độ sandbox không phụ thuộc database, workflow bug-check tự động, và các pattern bắt điểm mù của AI khi cùng một model vừa viết vừa review code. Dùng khi thêm regression coverage cho code do AI hỗ trợ, hoặc khi cùng một model vừa viết vừa review một thay đổi.
metadata:
  origin: ECC
---

# AI Regression Testing

Các pattern kiểm thử được thiết kế riêng cho phát triển có AI hỗ trợ, nơi cùng một model vừa viết code vừa review nó — tạo ra các điểm mù có hệ thống mà chỉ test tự động mới bắt được.

## Khi nào kích hoạt

- AI agent (Claude Code, Cursor, Codex) đã sửa API route hoặc logic backend
- Một bug đã được tìm thấy và sửa — cần ngăn việc tái xuất hiện
- Dự án có chế độ sandbox/mock có thể tận dụng để test không cần DB
- Chạy `/bug-check` hoặc các lệnh review tương tự sau khi thay đổi code
- Tồn tại nhiều đường đi của code (sandbox so với production, feature flag, v.v.)

## Vấn đề cốt lõi

Khi một AI viết code rồi tự review công việc của mình, nó mang cùng một bộ giả định vào cả hai bước. Điều này tạo ra một pattern lỗi có thể dự đoán:

```
AI writes fix → AI reviews fix → AI says "looks correct" → Bug still exists
```

**Ví dụ thực tế** (quan sát được trên production):

```
Fix 1: Added notification_settings to API response
  → Forgot to add it to the SELECT query
  → AI reviewed and missed it (same blind spot)

Fix 2: Added it to SELECT query
  → TypeScript build error (column not in generated types)
  → AI reviewed Fix 1 but didn't catch the SELECT issue

Fix 3: Changed to SELECT *
  → Fixed production path, forgot sandbox path
  → AI reviewed and missed it AGAIN (4th occurrence)

Fix 4: Test caught it instantly on first run PASS:
```

Pattern: **sự không nhất quán giữa đường đi sandbox/production** là regression số 1 do AI gây ra.

## Test API ở chế độ Sandbox

Hầu hết các dự án có kiến trúc thân thiện với AI đều có chế độ sandbox/mock. Đây là chìa khóa để test API nhanh và không cần DB.

### Thiết lập (Vitest + Next.js App Router)

```typescript
// vitest.config.ts
import { defineConfig } from "vitest/config";
import path from "path";

export default defineConfig({
  test: {
    environment: "node",
    globals: true,
    include: ["__tests__/**/*.test.ts"],
    setupFiles: ["__tests__/setup.ts"],
  },
  resolve: {
    alias: {
      "@": path.resolve(__dirname, "."),
    },
  },
});
```

```typescript
// __tests__/setup.ts
// Ép bật chế độ sandbox — không cần database
process.env.SANDBOX_MODE = "true";
process.env.NEXT_PUBLIC_SUPABASE_URL = "";
process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY = "";
```

### Test Helper cho Next.js API Route

```typescript
// __tests__/helpers.ts
import { NextRequest } from "next/server";

export function createTestRequest(
  url: string,
  options?: {
    method?: string;
    body?: Record<string, unknown>;
    headers?: Record<string, string>;
    sandboxUserId?: string;
  },
): NextRequest {
  const { method = "GET", body, headers = {}, sandboxUserId } = options || {};
  const fullUrl = url.startsWith("http") ? url : `http://localhost:3000${url}`;
  const reqHeaders: Record<string, string> = { ...headers };

  if (sandboxUserId) {
    reqHeaders["x-sandbox-user-id"] = sandboxUserId;
  }

  const init: { method: string; headers: Record<string, string>; body?: string } = {
    method,
    headers: reqHeaders,
  };

  if (body) {
    init.body = JSON.stringify(body);
    reqHeaders["content-type"] = "application/json";
  }

  return new NextRequest(fullUrl, init);
}

export async function parseResponse(response: Response) {
  const json = await response.json();
  return { status: response.status, json };
}
```

### Viết Regression Test

Nguyên tắc then chốt: **viết test cho các bug đã được tìm thấy, không phải cho code đang chạy tốt**.

```typescript
// __tests__/api/user/profile.test.ts
import { describe, it, expect } from "vitest";
import { createTestRequest, parseResponse } from "../../helpers";
import { GET, PATCH } from "@/app/api/user/profile/route";

// Định nghĩa hợp đồng (contract) — những field PHẢI có trong response
const REQUIRED_FIELDS = [
  "id",
  "email",
  "full_name",
  "phone",
  "role",
  "created_at",
  "avatar_url",
  "notification_settings",  // ← Added after bug found it missing
];

describe("GET /api/user/profile", () => {
  it("returns all required fields", async () => {
    const req = createTestRequest("/api/user/profile");
    const res = await GET(req);
    const { status, json } = await parseResponse(res);

    expect(status).toBe(200);
    for (const field of REQUIRED_FIELDS) {
      expect(json.data).toHaveProperty(field);
    }
  });

  // Regression test — đúng bug này đã bị AI gây ra 4 lần
  it("notification_settings is not undefined (BUG-R1 regression)", async () => {
    const req = createTestRequest("/api/user/profile");
    const res = await GET(req);
    const { json } = await parseResponse(res);

    expect("notification_settings" in json.data).toBe(true);
    const ns = json.data.notification_settings;
    expect(ns === null || typeof ns === "object").toBe(true);
  });
});
```

### Test sự tương đương Sandbox/Production

Regression phổ biến nhất của AI: sửa đường đi production nhưng quên đường đi sandbox (hoặc ngược lại).

```typescript
// Test rằng response của sandbox khớp với contract kỳ vọng
describe("GET /api/user/messages (conversation list)", () => {
  it("includes partner_name in sandbox mode", async () => {
    const req = createTestRequest("/api/user/messages", {
      sandboxUserId: "user-001",
    });
    const res = await GET(req);
    const { json } = await parseResponse(res);

    // This caught a bug where partner_name was added
    // to production path but not sandbox path
    if (json.data.length > 0) {
      for (const conv of json.data) {
        expect("partner_name" in conv).toBe(true);
      }
    }
  });
});
```

## Tích hợp Test vào workflow Bug-Check

### Định nghĩa Custom Command

```markdown
<!-- .claude/commands/bug-check.md -->
# Bug Check

## Step 1: Automated Tests (mandatory, cannot skip)

Run these commands FIRST before any code review:

    npm run test       # Vitest test suite
    npm run build      # TypeScript type check + build

- If tests fail → report as highest priority bug
- If build fails → report type errors as highest priority
- Only proceed to Step 2 if both pass

## Step 2: Code Review (AI review)

1. Sandbox / production path consistency
2. API response shape matches frontend expectations
3. SELECT clause completeness
4. Error handling with rollback
5. Optimistic update race conditions

## Step 3: For each bug fixed, propose a regression test
```

### Workflow

```
User: "バグチェックして" (or "/bug-check")
  │
  ├─ Step 1: npm run test
  │   ├─ FAIL → Bug found mechanically (no AI judgment needed)
  │   └─ PASS → Continue
  │
  ├─ Step 2: npm run build
  │   ├─ FAIL → Type error found mechanically
  │   └─ PASS → Continue
  │
  ├─ Step 3: AI code review (with known blind spots in mind)
  │   └─ Findings reported
  │
  └─ Step 4: For each fix, write a regression test
      └─ Next bug-check catches if fix breaks
```

## Các pattern Regression thường gặp của AI

### Pattern 1: Lệch đường đi Sandbox/Production

**Tần suất**: Phổ biến nhất (quan sát thấy ở 3 trong 4 regression)

```typescript
// FAIL: AI chỉ thêm field vào đường đi production
if (isSandboxMode()) {
  return { data: { id, email, name } };  // Missing new field
}
// Production path
return { data: { id, email, name, notification_settings } };

// PASS: Cả hai đường đi phải trả về cùng một shape
if (isSandboxMode()) {
  return { data: { id, email, name, notification_settings: null } };
}
return { data: { id, email, name, notification_settings } };
```

**Test để bắt nó**:

```typescript
it("sandbox and production return same fields", async () => {
  // In test env, sandbox mode is forced ON
  const res = await GET(createTestRequest("/api/user/profile"));
  const { json } = await parseResponse(res);

  for (const field of REQUIRED_FIELDS) {
    expect(json.data).toHaveProperty(field);
  }
});
```

### Pattern 2: Bỏ sót trong mệnh đề SELECT

**Tần suất**: Thường gặp với Supabase/Prisma khi thêm cột mới

```typescript
// FAIL: Cột mới được thêm vào response nhưng không có trong SELECT
const { data } = await supabase
  .from("users")
  .select("id, email, name")  // notification_settings not here
  .single();

return { data: { ...data, notification_settings: data.notification_settings } };
// → notification_settings is always undefined

// PASS: Dùng SELECT * hoặc đưa cột mới vào tường minh
const { data } = await supabase
  .from("users")
  .select("*")
  .single();
```

### Pattern 3: Rò rỉ Error State

**Tần suất**: Trung bình — khi thêm xử lý lỗi vào các component hiện có

```typescript
// FAIL: Đã đặt error state nhưng dữ liệu cũ chưa bị xóa
catch (err) {
  setError("Failed to load");
  // reservations still shows data from previous tab!
}

// PASS: Xóa state liên quan khi có lỗi
catch (err) {
  setReservations([]);  // Clear stale data
  setError("Failed to load");
}
```

### Pattern 4: Optimistic Update không có Rollback đúng cách

```typescript
// FAIL: Không rollback khi thất bại
const handleRemove = async (id: string) => {
  setItems(prev => prev.filter(i => i.id !== id));
  await fetch(`/api/items/${id}`, { method: "DELETE" });
  // If API fails, item is gone from UI but still in DB
};

// PASS: Lưu state trước đó và rollback khi thất bại
const handleRemove = async (id: string) => {
  const prevItems = [...items];
  setItems(prev => prev.filter(i => i.id !== id));
  try {
    const res = await fetch(`/api/items/${id}`, { method: "DELETE" });
    if (!res.ok) throw new Error("API error");
  } catch {
    setItems(prevItems);  // Rollback
    alert("削除に失敗しました");
  }
};
```

## Chiến lược: Test ở nơi bug đã xuất hiện

Đừng nhắm tới coverage 100%. Thay vào đó:

```
Bug found in /api/user/profile     → Write test for profile API
Bug found in /api/user/messages    → Write test for messages API
Bug found in /api/user/favorites   → Write test for favorites API
No bug in /api/user/notifications  → Don't write test (yet)
```

**Vì sao cách này hiệu quả với phát triển có AI:**

1. AI có xu hướng mắc **cùng một loại lỗi** lặp đi lặp lại
2. Bug tập trung ở các vùng phức tạp (auth, logic nhiều đường đi, quản lý state)
3. Một khi đã được test, đúng regression đó **không thể xảy ra lại**
4. Số lượng test tăng tự nhiên theo các bản sửa bug — không lãng phí công sức

## Tham khảo nhanh

| Pattern Regression của AI | Chiến lược test | Ưu tiên |
|---|---|---|
| Lệch sandbox/production | Assert response shape giống nhau ở chế độ sandbox |  High |
| Bỏ sót trong mệnh đề SELECT | Assert mọi field bắt buộc có trong response |  High |
| Rò rỉ error state | Assert state được dọn dẹp khi lỗi |  Medium |
| Thiếu rollback | Assert state được khôi phục khi API lỗi |  Medium |
| Ép kiểu che giấu null | Assert field không phải undefined |  Medium |

## DO / DON'T

**NÊN:**
- Viết test ngay sau khi tìm thấy bug (trước khi sửa nếu có thể)
- Test response shape của API, không test phần triển khai
- Chạy test như bước đầu tiên của mọi bug-check
- Giữ test nhanh (< 1 giây tổng cộng với chế độ sandbox)
- Đặt tên test theo bug mà nó ngăn chặn (ví dụ "BUG-R1 regression")

**KHÔNG NÊN:**
- Viết test cho code chưa từng có bug
- Tin vào việc AI tự review thay cho test tự động
- Bỏ qua test đường đi sandbox vì "chỉ là mock data"
- Viết integration test khi unit test là đủ
- Nhắm tới tỷ lệ coverage — hãy nhắm tới việc ngăn regression
