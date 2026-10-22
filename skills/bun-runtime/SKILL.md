---
name: bun-runtime
description: Bun làm runtime, package manager, bundler và test runner. Khi nào chọn Bun thay vì Node, ghi chú migration và hỗ trợ trên Vercel.
metadata:
  origin: ECC
---

# Bun Runtime

Bun là runtime và bộ công cụ JavaScript all-in-one nhanh: runtime, package manager, bundler và test runner.

## Khi nào dùng

- **Ưu tiên Bun** cho: dự án JS/TS mới, script cần tốc độ install/run, deploy Vercel với Bun runtime, và khi muốn một toolchain duy nhất (run + install + test + build).
- **Ưu tiên Node** cho: khả năng tương thích hệ sinh thái tối đa, tooling cũ mặc định dùng Node, hoặc khi một dependency có lỗi đã biết với Bun.

Dùng khi: áp dụng Bun, migrate từ Node, viết hoặc debug script/test Bun, hoặc cấu hình Bun trên Vercel hay các nền tảng khác.

## Cách hoạt động

- **Phiên bản cơ sở**: hướng dẫn bên dưới nhắm tới Bun 1.4.x. Kiểm tra phiên bản thực tế bằng `bun --version` trước khi dựa vào tên flag, vì CLI flag có thể thay đổi giữa các bản phát hành.
- **Runtime**: Runtime tương thích Node kiểu drop-in, xây dựng trên JavaScriptCore. Từ Bun 1.4, bản thân runtime được triển khai bằng Rust (migrate từ Zig). Không tương thích Node 100% — một số native addon, các API nội bộ `node:` ít phổ biến và các package phụ thuộc vào phần nội bộ riêng của Node vẫn có thể lỗi; hãy kiểm chứng trước khi phụ thuộc vào nó trong production.
- **Package manager**: Bun có sẵn package manager; hiệu năng cài đặt phụ thuộc vào dự án, điều kiện mạng và trạng thái cache. Lockfile mặc định là `bun.lock` (text) trong Bun hiện tại; các phiên bản cũ dùng `bun.lockb` (nhị phân) — Bun vẫn đọc định dạng đó để migrate, nhưng dự án mới nên dùng `bun.lock`.
- **Bundler**: Bundler và transpiler tích hợp sẵn cho ứng dụng và thư viện.
- **Test runner**: `bun test` tích hợp sẵn với API giống Jest.

**Migration từ Node**: Thay `node script.js` bằng `bun run script.js` hoặc `bun script.js`. Chạy `bun install` thay cho `npm install`; hầu hết package đều hoạt động. Dùng `bun run` cho npm script; `bun x` cho các lần chạy một lần kiểu npx. Các built-in của Node được hỗ trợ; ưu tiên API của Bun khi có để đạt hiệu năng tốt hơn.

**Lệnh package và workspace**: `bun add <pkg>` / `bun remove <pkg>` / `bun update [pkg]` quản lý dependency; `bun outdated` liệt kê các dependency cũ. `bun pm ls` liệt kê dependency của dự án và các phiên bản đã resolve dựa trên lockfile; `--all` bao gồm cả dependency bắc cầu. Đây không phải là kiểm tra tính toàn vẹn của nội dung file đã cài. [`bun audit`](https://bun.com/docs/pm/cli/audit) truy vấn các advisory từ registry dựa trên tên package và phiên bản trong `bun.lock`; nó không sửa `package.json`, `bun.lock` hay `node_modules`. Hãy xem lại các đích đã được phê duyệt trước khi gửi metadata của package private. Các package có scoped registry không có endpoint advisory sẽ bị bỏ qua và không ảnh hưởng exit code. `bun audit fix` nâng cấp và cài đặt dependency, làm thay đổi lockfile và các package đã cài, đôi khi cả các version pin trực tiếp; hãy review nó như một thao tác cài đặt có thay đổi dữ liệu, bao gồm các lifecycle script áp dụng. `bun dedupe` gộp các bản cài trùng lặp, và `bun prune` xóa các package không còn được tham chiếu. Monorepo dùng mảng `workspaces` ở root trong `package.json` (cùng quy ước với npm/yarn); chạy script trong một workspace bằng `bun run --filter <pkg-name> <script>`.

**API tích hợp sẵn**: hãy dùng các API này trước khi thêm dependency — `Bun.file` / `Bun.write` cho file I/O, `bun:sqlite` cho cơ sở dữ liệu SQLite nhúng, `Bun.serve` cho HTTP/WebSocket server, [`Bun.sql`](https://bun.com/docs/runtime/sql) cho cơ sở dữ liệu SQL, [`Bun.redis`](https://bun.com/docs/runtime/redis) cho Redis, và [`Bun.S3Client`](https://bun.com/docs/runtime/s3) cho object storage tương thích S3. Xem [ghi chú phát hành 1.4](https://bun.com/blog/bun-v1.4) để biết phần còn lại của những điểm mới.

**Vercel**: Đặt `bunVersion: "1.4.x"` trong `vercel.json` để dùng Bun 1.4 (Rust runtime). Xem [tài liệu Bun runtime của Vercel](https://vercel.com/docs/functions/runtimes/bun). Build: `bun run build` hoặc `bun build ./src/index.ts --outdir=dist`. Install: `bun install --frozen-lockfile` để deploy có thể tái lập.

**Tham khảo**: [Ghi chú phát hành Bun 1.4](https://bun.com/blog/bun-v1.4).

## Ví dụ

### Run và install

```bash
# Install dependencies (creates/updates bun.lock)
bun install

# Run a script or file
bun run dev
bun run src/index.ts
bun src/index.ts
```

### Script và env

```bash
bun run --env-file=.env dev
FOO=bar bun run script.ts
```

### Testing

```bash
bun test
bun test --watch
```

Với CI trên Bun 1.4, các tùy chọn khả dụng gồm `bun test --changed[=<ref>]` để chạy các test bị ảnh hưởng, `bun test --isolate` để có global riêng cho từng file, `bun test --parallel[=<n>]` để chạy theo worker process, và `bun test --shard=<n>/<count>` để chia nhỏ trên CI. `--isolate` tạo một JavaScript global mới cho mỗi file trong cùng một process và dọn dẹp các tài nguyên theo từng file đã được ghi tài liệu; đây không phải là sandbox ở mức process hay bảo mật. `--parallel` bật nó theo mặc định. `--timings=<file>` đọc các thời lượng trước đó để lập lịch; `--update-timings` ghi lại thời lượng. Ví dụ: `bun test --parallel --timings=./test-timings.json --update-timings`. Hãy kiểm tra help và tài liệu của phiên bản đã cài trước khi chọn đường dẫn file timing cho workflow nhiều shard.

```typescript
// test/example.test.ts
import { expect, test } from "bun:test";

test("add", () => {
  expect(1 + 2).toBe(3);
});
```

### Runtime API

```typescript
const file = Bun.file("package.json");
const json = await file.json();

Bun.serve({
  port: 3000,
  fetch(req) {
    return new Response("Hello");
  },
});
```

## Best Practice

- Commit lockfile (`bun.lock`) để cài đặt có thể tái lập.
- Ưu tiên `bun run` cho script. Với TypeScript, Bun chạy `.ts` natively.
- Giữ dependency luôn cập nhật; Bun và hệ sinh thái phát triển rất nhanh.
