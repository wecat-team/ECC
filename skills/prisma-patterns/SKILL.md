---
name: prisma-patterns
description: Các pattern Prisma ORM cho backend TypeScript — thiết kế schema, tối ưu query, transaction, phân trang, và các cái bẫy quan trọng như updateMany trả về count thay vì records, timeout của $transaction, migrate dev reset DB, @updatedAt bị bỏ qua khi bulk write, và cạn kiệt connection trên serverless. Dùng khi viết Prisma schema hoặc query, hoặc khi debug transaction, migration hoặc giới hạn connection trên serverless.
metadata:
  origin: ECC
---

# Prisma Patterns

Các pattern cho production và những cái bẫy không hiển nhiên của Prisma ORM trong backend TypeScript.

> **Hãy kiểm tra phiên bản trước khi áp dụng các pattern.** Bề mặt API của Prisma đã thay đổi qua các bản major:
>
> ```bash
> npx prisma --version
> ```
>
> Những khác biệt API đáng chú ý giữa các phiên bản:
> - `relationJoins` có thể tải relation bằng JOIN thay vì các query riêng, nhưng có thể gây bùng nổ số dòng với relation 1:N lớn hoặc `include` lồng sâu — hãy benchmark cả hai cách
> - Đã thêm field modifier `omit` và Client Extensions API `prisma.$extends`
> - **Bản cài mới hơn**: package có thể tên là `prisma` thay vì `@prisma/client`; `PrismaClient` có thể yêu cầu driver adapter (ví dụ `@prisma/adapter-pg`); `datasource.url` có thể nằm trong `prisma.config.ts` thay vì `schema.prisma`
> - Các lệnh CLI (`migrate dev`, `migrate deploy`, `generate`) không đổi giữa các phiên bản

## Khi nào kích hoạt

- Thiết kế hoặc chỉnh sửa model và relation trong Prisma schema
- Viết query, transaction hoặc logic phân trang
- Dùng `updateMany`, `deleteMany` hoặc bất kỳ thao tác bulk nào
- Chạy hoặc lên kế hoạch database migration
- Deploy lên môi trường serverless (Vercel, Lambda, Cloudflare Workers)
- Triển khai soft delete hoặc lọc dòng theo multi-tenant

## Khái niệm cốt lõi

### Chiến lược ID

| Chiến lược | Dùng khi | Tránh khi |
|---|---|---|
| `@default(cuid())` | Lựa chọn mặc định — an toàn cho URL, sắp xếp được, không va chạm | Cần ID tuần tự cho hệ thống bên ngoài |
| `@default(uuid())` | Cần tương thích với các hệ thống không dùng Prisma | Bảng ghi nhiều (UUID ngẫu nhiên làm phân mảnh B-tree index) |
| `@default(autoincrement())` | Bảng join nội bộ, audit log | ID hiển thị công khai (lộ số lượng bản ghi) |

### Mặc định cho Schema

```prisma
model User {
  id        String    @id @default(cuid())
  email     String    @unique  // @unique already creates an index — no @@index needed
  name      String
  role      Role      @default(USER)
  posts     Post[]
  createdAt DateTime  @default(now())
  updatedAt DateTime  @updatedAt
  deletedAt DateTime?

  @@index([createdAt])
  @@index([deletedAt, createdAt]) // composite for soft-delete + sort queries
}
```

- Thêm `@@index` cho mọi foreign key và cột dùng trong `WHERE` hoặc `ORDER BY`.
- Khai báo `deletedAt DateTime?` ngay từ đầu khi có thể dự đoán cần soft delete — thêm sau này sẽ cần migration trên bảng đang chạy thật.
- `updatedAt @updatedAt` chỉ được Prisma tự đặt khi `update` và `upsert` (xem Anti-Patterns về cái bẫy khi bulk update).

### `include` vs `select`

| | `include` | `select` |
|---|---|---|
| Trả về | Tất cả scalar field + các relation chỉ định | Chỉ các field chỉ định |
| Dùng khi | Cần hầu hết các field cùng một relation | Hot path, bảng lớn, tránh over-fetch |
| Hiệu năng | Có thể over-fetch trên bảng nhiều cột | Payload tối thiểu, nhanh hơn trên dataset lớn |
| Ghi chú Prisma 5 | Mặc định dùng JOIN (`relationJoins`) | Tương tự |

```ts
// include — all columns + relation
const user = await prisma.user.findUnique({
  where: { id },
  include: { posts: { select: { id: true, title: true } } },
});

// select — explicit allowlist
const user = await prisma.user.findUnique({
  where: { id },
  select: { id: true, email: true, name: true },
});
```

KHÔNG BAO GIỜ trả về trực tiếp entity thô của Prisma trong API response — hãy map sang response DTO để kiểm soát các field được lộ ra:

```ts
// BAD: leaks passwordHash, deletedAt, internal fields
return await prisma.user.findUniqueOrThrow({ where: { id } });

// GOOD: explicit DTO mapping
const user = await prisma.user.findUniqueOrThrow({ where: { id } });
return { id: user.id, name: user.name, email: user.email };
```

### Chọn dạng Transaction

| Tình huống | Dùng |
|---|---|
| Các thao tác độc lập, không phụ thuộc lẫn nhau | Dạng array |
| Bước sau phụ thuộc vào kết quả bước trước | Dạng interactive |
| Có lời gọi bên ngoài (email, HTTP) | Để hoàn toàn ngoài transaction |

```ts
// Array form — batched in one round trip
const [user, post] = await prisma.$transaction([
  prisma.user.update({ where: { id }, data: { name } }),
  prisma.post.create({ data: { title, authorId: id } }),
]);

// Interactive form — use tx client only, never the outer prisma client
const post = await prisma.$transaction(async (tx) => {
  const user = await tx.user.findUniqueOrThrow({ where: { id } });
  if (user.role !== 'ADMIN') throw new Error('Forbidden');
  return tx.post.create({ data: { title, authorId: user.id } });
});
```

### PrismaClient Singleton

Mỗi instance `PrismaClient` mở một connection pool riêng. Chỉ khởi tạo một lần.

```ts
// lib/prisma.ts

// Option A — adapter-based initialization (required by newer Prisma installs)
import { PrismaClient } from '@prisma/client'; // or the generated client path for your setup
import { PrismaPg } from '@prisma/adapter-pg';

function createPrismaClient() {
  const adapter = new PrismaPg({
    connectionString: process.env.DATABASE_URL!,
  });
  return new PrismaClient({
    adapter,
    log: process.env.NODE_ENV === 'development' ? ['query', 'error'] : ['error'],
  });
}

const globalForPrisma = globalThis as unknown as { prisma?: PrismaClient };

export const prisma = globalForPrisma.prisma ?? createPrismaClient();

if (process.env.NODE_ENV !== 'production') globalForPrisma.prisma = prisma;

// Option B — direct initialization (older installs, no adapter needed)
// import { PrismaClient } from '@prisma/client';
// export const prisma = globalForPrisma.prisma ?? new PrismaClient({ ... });
```

Dùng Option A nếu bản Prisma bạn cài yêu cầu tham số `adapter` trong constructor `PrismaClient`.
Dùng Option B nếu `new PrismaClient()` chạy được không cần tham số. Hãy để compiler cho biết cách nào đúng.

Pattern `globalThis` ngăn tạo instance trùng lặp khi hot reload (Next.js, nodemon, ts-node-dev).

### Vấn đề N+1

Tải relation bên trong vòng lặp sẽ phát sinh một query cho mỗi dòng.

```ts
// BAD: N+1 — one extra query per user
const users = await prisma.user.findMany();
for (const user of users) {
  const posts = await prisma.post.findMany({ where: { authorId: user.id } });
}

// GOOD: single query
const users = await prisma.user.findMany({ include: { posts: true } });
```

Với `relationJoins` của Prisma 5+, dạng `include` dùng một JOIN duy nhất. Trên các tập 1:N lớn, điều này có thể làm tăng kích thước result set — hãy benchmark cả hai cách nếu relation có thể trả về nhiều dòng cho mỗi bản ghi cha.

## Ví dụ code

### Cursor Pagination (ưu tiên cho feed và dataset lớn)

```ts
async function getPosts(cursor?: string, limit = 20) {
  const items = await prisma.post.findMany({
    where: { published: true },
    orderBy: [
      { createdAt: 'desc' },
      { id: 'desc' }, // secondary sort prevents unstable pagination on duplicate timestamps
    ],
    take: limit + 1,
    ...(cursor && { cursor: { id: cursor }, skip: 1 }),
  });

  const hasNextPage = items.length > limit;
  if (hasNextPage) items.pop();

  return { items, nextCursor: hasNextPage ? items[items.length - 1].id : null };
}
```

Lấy `limit + 1` rồi pop — cách chuẩn để phát hiện `hasNextPage` mà không cần thêm query count. LUÔN LUÔN thêm một field duy nhất (ví dụ `id`) làm `orderBy` phụ để tránh phân trang không ổn định khi nhiều dòng có cùng timestamp. Chỉ dùng offset pagination khi người dùng cần nhảy tới trang bất kỳ (bảng admin).

### Soft Delete

```ts
// Always filter explicitly — do not rely on middleware (hides behavior, hard to debug)
const activeUsers = await prisma.user.findMany({ where: { deletedAt: null } });

await prisma.user.update({ where: { id }, data: { deletedAt: new Date() } });
await prisma.user.update({ where: { id }, data: { deletedAt: null } }); // restore
```

### Xử lý lỗi

```ts
import { Prisma } from '@prisma/client'; // or the generated client path for your setup

try {
  await prisma.user.create({ data: { email } });
} catch (e) {
  if (e instanceof Prisma.PrismaClientKnownRequestError) {
    if (e.code === 'P2002') throw new ConflictError('Email already exists');
    if (e.code === 'P2025') throw new NotFoundError('Record not found');
    if (e.code === 'P2003') throw new BadRequestError('Referenced record does not exist');
  }
  throw e;
}
```

Các mã thường gặp: `P2002` vi phạm unique · `P2025` không tìm thấy · `P2003` vi phạm foreign key.

Bắt lỗi ở ranh giới service và chuyển thành domain error. KHÔNG BAO GIỜ để lộ message thô của Prisma cho phía dùng API.

### Connection Pool — Serverless

Nhúng các tham số connection trực tiếp vào `DATABASE_URL` — nối chuỗi sẽ lỗi nếu URL đã có query parameter (ví dụ `?schema=public`):

```bash
# .env — preferred: embed params in the URL
DATABASE_URL="postgresql://user:pass@host/db?connection_limit=1&pool_timeout=20"

# With an external pooler (PgBouncer, Supabase pooler)
DATABASE_URL="postgresql://user:pass@host/db?pgbouncer=true&connection_limit=1"
```

```ts
// Vercel, AWS Lambda, and similar serverless runtimes:
// cap pool to 1 per instance; connection_limit and pool_timeout controlled via DATABASE_URL

// Adapter-based setup (if your Prisma install requires an adapter):
import { PrismaClient } from '@prisma/client';
import { PrismaPg } from '@prisma/adapter-pg';

const prisma = new PrismaClient({
  adapter: new PrismaPg({ connectionString: process.env.DATABASE_URL }),
});

// Direct setup (if your Prisma install does not require an adapter):
// const prisma = new PrismaClient();
```

## Anti-Patterns

### `updateMany` trả về count, không phải records

```ts
// BAD: result is { count: 2 } — users[0] is undefined
const users = await prisma.user.updateMany({ where: { role: 'GUEST' }, data: { role: 'USER' } });

// GOOD: capture IDs first, then update, then fetch only the affected rows
const targets = await prisma.user.findMany({
  where: { role: 'GUEST' },
  select: { id: true },
});
const ids = targets.map((u) => u.id);
await prisma.user.updateMany({ where: { id: { in: ids } }, data: { role: 'USER' } });
const updated = await prisma.user.findMany({ where: { id: { in: ids } } });
```

Tương tự với `deleteMany` — trả về `{ count: n }`, không bao giờ trả về các dòng đã xóa.

### Dạng interactive của `$transaction` bị timeout sau 5 giây

```ts
// BAD: external call inside transaction exceeds 5s default → "Transaction already closed"
await prisma.$transaction(async (tx) => {
  const user = await tx.user.findUniqueOrThrow({ where: { id } });
  await sendWelcomeEmail(user.email); // external call
  await tx.user.update({ where: { id }, data: { emailSent: true } });
});

// GOOD: external calls outside the transaction
const user = await prisma.user.findUniqueOrThrow({ where: { id } });
await sendWelcomeEmail(user.email);
await prisma.user.update({ where: { id }, data: { emailSent: true } });

// Only raise timeout when bulk processing genuinely needs it
await prisma.$transaction(async (tx) => { ... }, { timeout: 30_000 });
```

### `migrate dev` có thể reset database

`migrate dev` phát hiện schema drift và có thể yêu cầu reset DB, xóa toàn bộ dữ liệu.

```bash
# NEVER on shared dev, staging, or production
npx prisma migrate dev --name add_column

# Safe everywhere except local solo dev
npx prisma migrate deploy

# Check drift without applying
npx prisma migrate diff \
  --from-migrations ./prisma/migrations \
  --to-schema-datamodel ./prisma/schema.prisma \
  --shadow-database-url "$SHADOW_DATABASE_URL"
```

### Sửa tay file migration sẽ làm hỏng các lần deploy sau

Prisma tính checksum cho mọi file migration. Sửa file sau khi đã apply sẽ gây lỗi `P3006 checksum mismatch` trên mọi môi trường đã chạy bản gốc. Hãy tạo migration mới thay vì sửa.

### Thay đổi schema gây breaking cần migration nhiều bước

Thêm `NOT NULL` vào cột hiện có hoặc đổi tên cột trong một migration duy nhất sẽ khóa bảng hoặc mất dữ liệu. Hãy dùng expand-and-contract:

```bash
# Step 1: create migration locally, then deploy
npx prisma migrate dev --name add_new_column   # local only
npx prisma migrate deploy                       # staging / production
```

```ts
// Step 2: backfill data (run in a script or migration job, not in the shell)
await prisma.user.updateMany({ data: { newColumn: derivedValue } });
```

```bash
# Step 3: create the NOT NULL constraint migration locally, then deploy
npx prisma migrate dev --name make_new_column_required  # local only
npx prisma migrate deploy                               # staging / production
```

### `@updatedAt` không được kích hoạt khi `updateMany`

`@updatedAt` chỉ được đặt tự động khi `update` và `upsert`. Bulk write sẽ để nó giữ giá trị cũ.

```ts
// BAD: updatedAt stays at its old value
await prisma.post.updateMany({ where: { authorId }, data: { published: true } });

// GOOD
await prisma.post.updateMany({
  where: { authorId },
  data: { published: true, updatedAt: new Date() },
});
```

### Soft delete + `findUniqueOrThrow` làm lộ bản ghi đã xóa

`findUniqueOrThrow` chỉ ném `P2025` khi dòng không tồn tại trong DB. Các dòng đã soft delete vẫn tồn tại và được trả về mà không có lỗi.

`findUniqueOrThrow` yêu cầu field có unique constraint trong `where` — thêm `deletedAt: null` cạnh `id` sẽ gây lỗi type vì `{ id, deletedAt }` không phải compound unique constraint. Hãy dùng `findFirstOrThrow`.

```ts
// BAD: returns soft-deleted user
const user = await prisma.user.findUniqueOrThrow({ where: { id } });

// BAD: Prisma type error — { id, deletedAt } is not a unique constraint
const user = await prisma.user.findUniqueOrThrow({ where: { id, deletedAt: null } });

// GOOD: findFirstOrThrow supports arbitrary where conditions
const user = await prisma.user.findFirstOrThrow({ where: { id, deletedAt: null } });
```

### `deleteMany` không có `where` sẽ xóa mọi dòng

```ts
// BAD: silently wipes the table
await prisma.post.deleteMany();

// GOOD
await prisma.post.deleteMany({ where: { authorId: userId } });
```

## Best Practices

| Quy tắc | Lý do |
|---|---|
| `migrate deploy` trong CI/CD, `migrate dev` chỉ dùng ở local | `migrate dev` có thể reset DB khi có drift |
| Map entity sang response DTO | Tránh lộ các field nội bộ |
| Bắt `PrismaClientKnownRequestError` ở ranh giới service | Chuyển thành domain error |
| Ưu tiên các method `*OrThrow` thay vì kiểm tra null thủ công | Tự động ném P2025; dùng `findFirstOrThrow` khi lọc theo field không unique |
| `connection_limit=1` + pooler bên ngoài trên serverless | Tránh cạn kiệt connection |
| LUÔN LUÔN cung cấp `where` cho `deleteMany` | Tránh vô tình xóa sạch bảng |
| Đặt `updatedAt: new Date()` thủ công trong `updateMany` | `@updatedAt` bỏ qua bulk write |

## Skill liên quan

- `nestjs-patterns` — service layer NestJS tích hợp Prisma
- `postgres-patterns` — indexing và tinh chỉnh connection ở cấp PostgreSQL
- `database-migrations` — lập kế hoạch migration nhiều bước cho production
- `backend-patterns` — thiết kế API và service layer nói chung
