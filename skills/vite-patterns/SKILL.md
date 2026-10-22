---
name: vite-patterns
description: Các pattern cho build tool Vite gồm config, plugin, HMR, biến môi trường (env variables), thiết lập proxy, SSR, library mode, dependency pre-bundling và tối ưu build. Kích hoạt khi làm việc với vite.config.ts, plugin Vite hoặc các dự án dùng Vite.
metadata:
  origin: ECC
---

# Pattern Vite

Các pattern cho build tool và dev server trong dự án Vite 8+. Bao gồm cấu hình, biến môi trường, thiết lập proxy, library mode, dependency pre-bundling và các cạm bẫy thường gặp khi lên production.

## Khi nào dùng

- Cấu hình `vite.config.ts` hoặc `vite.config.js`
- Thiết lập biến môi trường hoặc file `.env`
- Cấu hình proxy của dev server cho backend API
- Tối ưu đầu ra build (chunk, minification, asset)
- Publish thư viện với `build.lib`
- Xử lý sự cố dependency pre-bundling hoặc tương tác CJS/ESM
- Debug lỗi HMR, dev server hoặc build
- Chọn hoặc sắp xếp thứ tự các plugin Vite

## Cách hoạt động

- **Dev mode** phục vụ source file dưới dạng ESM native — không bundle. Việc transform diễn ra theo yêu cầu cho từng request module, đó là lý do khởi động nguội (cold start) nhanh và HMR chính xác.
- **Build mode** dùng Rolldown (v7+) hoặc Rollup (v5–v6) để bundle ứng dụng cho production với tree-shaking, code-splitting và minification dựa trên Oxc.
- **Dependency pre-bundling** chuyển các dependency CJS/UMD sang ESM một lần qua esbuild và cache kết quả dưới `node_modules/.vite`, nên các lần khởi động sau bỏ qua công việc này.
- **Plugin** dùng chung một interface thống nhất giữa dev và build — cùng một object plugin hoạt động cho cả các transform theo yêu cầu của dev server lẫn pipeline production.
- **Biến môi trường** được inline tĩnh tại thời điểm build. Các biến có tiền tố `VITE_` trở thành hằng số công khai trong bundle; mọi biến không có tiền tố đều vô hình với code phía client.

## Ví dụ

### Cấu trúc config

#### Config cơ bản

```typescript
// vite.config.ts
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
  resolve: {
    alias: { '@': new URL('./src', import.meta.url).pathname },
  },
})
```

#### Config có điều kiện

```typescript
// vite.config.ts
import { defineConfig, loadEnv } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig(({ command, mode }) => {
  const env = loadEnv(mode, process.cwd())   // VITE_ prefixed only (safe)

  return {
    plugins: [react()],
    server: command === 'serve' ? { port: 3000 } : undefined,
    define: {
      __API_URL__: JSON.stringify(env.VITE_API_URL),
    },
  }
})
```

#### Các tùy chọn config chính

| Key | Mặc định | Mô tả |
|-----|---------|-------------|
| `root` | `'.'` | Thư mục gốc dự án (nơi chứa `index.html`) |
| `base` | `'/'` | Public base path cho các asset đã deploy |
| `envPrefix` | `'VITE_'` | Tiền tố cho các biến env được expose ra client |
| `build.outDir` | `'dist'` | Thư mục đầu ra |
| `build.minify` | `'oxc'` | Minifier (`'oxc'`, `'terser'` hoặc `false`) |
| `build.sourcemap` | `false` | `true`, `'inline'` hoặc `'hidden'` |

### Plugin

#### Các plugin thiết yếu

Hầu hết nhu cầu về plugin đã được một số ít package được bảo trì tốt đáp ứng. Hãy dùng chúng trước khi tự viết.

| Plugin | Mục đích | Khi nào dùng |
|--------|---------|-------------|
| `@vitejs/plugin-react-swc` | React HMR + Fast Refresh qua SWC | Mặc định cho ứng dụng React (nhanh hơn bản Babel) |
| `@vitejs/plugin-react` | React HMR + Fast Refresh qua Babel | Chỉ khi cần plugin Babel (emotion, decorator của MobX) |
| `@vitejs/plugin-vue` | Hỗ trợ Vue 3 SFC | Ứng dụng Vue |
| `vite-plugin-checker` | Chạy `tsc` + ESLint trong worker thread với HMR overlay | **Mọi ứng dụng TypeScript** — Vite KHÔNG type-check trong `vite build` |
| `vite-tsconfig-paths` | Tôn trọng các alias `paths` của `tsconfig.json` | Bất cứ khi nào bạn đã có alias trong `tsconfig.json` |
| `vite-plugin-dts` | Sinh file `.d.ts` trong library mode | Publish thư viện TypeScript |
| `vite-plugin-svgr` | Import SVG dưới dạng React component | Ứng dụng React dùng SVG như component |
| `rollup-plugin-visualizer` | Báo cáo treemap/sunburst của bundle | Kiểm tra kích thước bundle định kỳ (dùng `enforce: 'post'`) |
| `vite-plugin-pwa` | PWA không cần cấu hình + Workbox | Ứng dụng hỗ trợ offline |

**Lưu ý QUAN TRỌNG:** `vite build` chỉ transpile chứ KHÔNG type-check. Lỗi type sẽ âm thầm lên production trừ khi bạn thêm `vite-plugin-checker` hoặc chạy `tsc --noEmit` trong CI.

#### Tự viết plugin tùy chỉnh

Việc tự viết plugin hiếm khi cần — hầu hết nhu cầu đã được các plugin có sẵn đáp ứng. Khi thực sự cần, hãy bắt đầu inline trong `vite.config.ts` và chỉ tách ra khi được tái sử dụng.

```typescript
// vite.config.ts — minimal inline plugin
function myPlugin(): Plugin {
  return {
    name: 'my-plugin',                       // required, must be unique
    enforce: 'pre',                           // 'pre' | 'post' (optional)
    apply: 'build',                           // 'build' | 'serve' (optional)
    transform(code, id) {
      if (!id.endsWith('.custom')) return
      return { code: transformCustom(code), map: null }
    },
  }
}
```

**Các hook chính:** `transform` (sửa source), `resolveId` + `load` (virtual module), `transformIndexHtml` (chèn vào HTML), `configureServer` (thêm middleware cho dev), `hotUpdate` (HMR tùy chỉnh — thay thế `handleHotUpdate` đã deprecated từ v7+).

**Virtual module** dùng quy ước tiền tố `\0` — `resolveId` trả về `'\0virtual:my-id'` để các plugin khác bỏ qua nó. Code của người dùng import `'virtual:my-id'`.

Để xem API plugin đầy đủ, xem [vite.dev/guide/api-plugin](https://vite.dev/guide/api-plugin). Dùng `vite-plugin-inspect` trong quá trình phát triển để debug pipeline transform.

### HMR API

Các plugin framework (`@vitejs/plugin-react`, `@vitejs/plugin-vue`, v.v.) xử lý HMR tự động. Chỉ dùng trực tiếp `import.meta.hot` khi xây dựng state store tùy chỉnh, dev tool, hoặc tiện ích không phụ thuộc framework cần giữ state qua các lần cập nhật.

```typescript
// src/store.ts — manual HMR for a vanilla module
if (import.meta.hot) {
  // Persist state across updates (must MUTATE, never reassign .data)
  import.meta.hot.data.count = import.meta.hot.data.count ?? 0

  // Cleanup side effects before module is replaced
  import.meta.hot.dispose((data) => clearInterval(data.intervalId))

  // Accept this module's own updates
  import.meta.hot.accept()
}
```

Toàn bộ code `import.meta.hot` được tree-shake khỏi build production — không cần gỡ guard.

### Biến môi trường

Vite nạp `.env`, `.env.local`, `.env.[mode]` và `.env.[mode].local` theo thứ tự đó (file sau ghi đè file trước); các file `*.local` bị gitignore và dành cho secret cục bộ.

#### Truy cập phía client

Chỉ các biến có tiền tố `VITE_` được expose cho code client:

```typescript
import.meta.env.VITE_API_URL   // string
import.meta.env.MODE            // 'development' | 'production' | custom
import.meta.env.BASE_URL        // base config value
import.meta.env.DEV             // boolean
import.meta.env.PROD            // boolean
import.meta.env.SSR             // boolean
```

#### Dùng env trong config

```typescript
// vite.config.ts
import { defineConfig, loadEnv } from 'vite'

export default defineConfig(({ mode }) => {
  const env = loadEnv(mode, process.cwd())          // VITE_ prefixed only (safe)
  return {
    define: {
      __API_URL__: JSON.stringify(env.VITE_API_URL),
    },
  }
})
```

### Bảo mật

#### Tiền tố `VITE_` KHÔNG phải ranh giới bảo mật

Mọi biến có tiền tố `VITE_` đều **được inline tĩnh vào client bundle tại thời điểm build**. Minification, mã hóa base64 và tắt source map KHÔNG che giấu được nó. Kẻ tấn công quyết tâm có thể trích xuất bất kỳ biến `VITE_` nào từ JavaScript đã phát hành.

**Quy tắc:** Chỉ các giá trị công khai (URL API, feature flag, public key) mới được đặt trong biến `VITE_`. Secret (API token, URL database, private key) PHẢI nằm phía server sau một API hoặc serverless function.

#### Cái bẫy `loadEnv('')`

```typescript
// BAD: passing '' as the third arg loads ALL env vars — including server secrets —
// and makes them available to inline into client code via `define`.
const env = loadEnv(mode, process.cwd(), '')

// GOOD: explicit prefix list
const env = loadEnv(mode, process.cwd(), ['VITE_', 'APP_'])
```

#### Source map trên production

Source map production làm lộ mã nguồn gốc của bạn. Hãy tắt chúng trừ khi bạn upload lên error tracker (Sentry, Bugsnag) và xóa cục bộ sau đó:

```typescript
build: {
  sourcemap: false,                                  // default — keep it this way
}
```

#### Checklist `.gitignore`

- `.env.local`, `.env.*.local` — ghi đè secret cục bộ
- `dist/` — đầu ra build
- `node_modules/.vite` — cache pre-bundle (entry cũ gây ra lỗi ma)

### Server Proxy

```typescript
// vite.config.ts — server.proxy
server: {
  proxy: {
    '/foo': 'http://localhost:4567',                    // string shorthand

    '/api': {
      target: 'http://localhost:8080',
      changeOrigin: true,                               // needed for virtual-hosted backends
      rewrite: (path) => path.replace(/^\/api/, ''),
    },
  },
}
```

Để proxy WebSocket, thêm `ws: true` vào cấu hình route.

### Tối ưu build

#### Manual Chunks

```typescript
// vite.config.ts — build.rolldownOptions
build: {
  rolldownOptions: {
    output: {
      // Object form: group specific packages
      manualChunks: {
        'react-vendor': ['react', 'react-dom'],
        'ui-vendor': ['@radix-ui/react-dialog', '@radix-ui/react-popover'],
      },
    },
  },
}
```

```typescript
// Function form: split by heuristic
manualChunks(id) {
  if (id.includes('node_modules/react')) return 'react-vendor'
  if (id.includes('node_modules')) return 'vendor'
}
```

### Hiệu năng

#### Tránh Barrel File

Barrel file (`index.ts` re-export mọi thứ từ một thư mục) buộc Vite phải nạp mọi file được re-export ngay cả khi bạn chỉ import một symbol. Đây là nguyên nhân số 1 làm chậm dev server mà tài liệu chính thức nêu ra.

```typescript
// BAD — importing one util forces Vite to load the whole barrel
import { slash } from '@/utils'

// GOOD — direct import, only the one file is loaded
import { slash } from '@/utils/slash'
```

#### Ghi rõ phần mở rộng khi import

Mỗi phần mở rộng ngầm định buộc tối đa 6 lần kiểm tra filesystem qua `resolve.extensions`. Trong codebase lớn, chi phí này cộng dồn đáng kể.

```typescript
// BAD
import Component from './Component'

// GOOD
import Component from './Component.tsx'
```

Thu hẹp `allowImportingTsExtensions` của `tsconfig.json` + `resolve.extensions` chỉ còn các phần mở rộng bạn thực sự dùng.

#### Warm-up các route đường nóng (hot-path)

`server.warmup.clientFiles` transform trước các entry nóng đã biết trước khi trình duyệt yêu cầu chúng — loại bỏ thác request (request waterfall) khi tải nguội trên ứng dụng lớn.

```typescript
// vite.config.ts
server: {
  warmup: {
    clientFiles: ['./src/main.tsx', './src/routes/**/*.tsx'],
  },
}
```

#### Profiling dev server chậm

Khi `vite dev` chậm, hãy bắt đầu với `vite --profile`, tương tác với ứng dụng, rồi nhấn `p+enter` để lưu file `.cpuprofile`. Nạp nó vào [Speedscope](https://www.speedscope.app) để tìm plugin nào đang ngốn thời gian — thường là các hook `buildStart`, `config` hoặc `configResolved` trong plugin cộng đồng.

### Library Mode

Khi publish một npm package, dùng `build.lib`. Hai cái bẫy quan trọng hơn chi tiết cấu hình:

1. **Type không được sinh ra** — thêm `vite-plugin-dts` hoặc chạy `tsc --emitDeclarationOnly` riêng.
2. **Peer dependency PHẢI được externalize** — các peer không được liệt kê sẽ bị bundle vào thư viện của bạn, gây lỗi duplicate-runtime ở phía người dùng.

```typescript
// vite.config.ts
build: {
  lib: {
    entry: 'src/index.ts',
    formats: ['es', 'cjs'],
    fileName: (format) => `my-lib.${format}.js`,
  },
  rolldownOptions: {
    external: ['react', 'react-dom', 'react/jsx-runtime'],  // every peer dep
  },
}
```

### SSR Externals

Các thiết lập `createServer({ middlewareMode: true })` trần là lãnh địa của tác giả framework. Hầu hết ứng dụng nên dùng Nuxt, Remix, SvelteKit, Astro hoặc TanStack Start. Thứ bạn *sẽ* tinh chỉnh khi là người dùng framework là cấu hình externals khi dependency bị lỗi trong SSR:

```typescript
// vite.config.ts — ssr options
ssr: {
  external: ['node-native-package'],           // keep as require() in SSR bundle
  noExternal: ['esm-only-package'],            // force-bundle into SSR output (fixes most SSR errors)
  target: 'node',                              // 'node' or 'webworker'
}
```

### Dependency Pre-Bundling

Vite pre-bundle dependency để chuyển CJS/UMD sang ESM và giảm số lượng request.

```typescript
// vite.config.ts — optimizeDeps
optimizeDeps: {
  include: [
    'lodash-es',                              // force pre-bundle known heavy deps
    'cjs-package',                            // CJS deps that cause interop issues
    'deep-lib/components/**',                 // glob for deep imports
  ],
  exclude: ['local-esm-package'],             // must be valid ESM if excluded
  force: true,                                // ignore cache, re-optimize (temporary debugging)
}
```

### Các cạm bẫy thường gặp

#### Dev không khớp với Build

Dev dùng esbuild/Rolldown để transform; build dùng Rolldown để bundle. Thư viện CJS có thể hoạt động khác nhau giữa hai chế độ. Luôn xác minh bằng `vite build && vite preview` trước khi deploy.

#### Chunk cũ sau khi deploy

Build mới tạo hash chunk mới. Người dùng có phiên đang hoạt động sẽ yêu cầu các tên file cũ không còn tồn tại. Vite không có giải pháp tích hợp. Cách giảm thiểu:

- Giữ các file `dist/assets/` cũ trong một khoảng thời gian deploy
- Bắt lỗi dynamic import trong router và buộc tải lại trang

#### Docker và Container

Vite mặc định bind vào `localhost`, không thể truy cập từ bên ngoài container:

```typescript
// vite.config.ts — Docker/container setup
server: {
  host: true,                                  // bind 0.0.0.0
  hmr: { clientPort: 3000 },                   // if behind a reverse proxy
}
```

#### Truy cập file trong Monorepo

Vite giới hạn việc phục vụ file trong thư mục gốc dự án. Các package nằm ngoài root bị chặn:

```typescript
// vite.config.ts — monorepo file access
server: {
  fs: {
    allow: ['..'],                             // allow parent directory (workspace root)
  },
}
```

### Anti-Pattern

```typescript
// BAD: Setting envPrefix to '' exposes ALL env vars (including secrets) to the client
envPrefix: ''

// BAD: Assuming require() works in application source code — Vite is ESM-first
const lib = require('some-lib')                // use import instead

// BAD: Splitting every node_module into its own chunk — creates hundreds of tiny files
manualChunks(id) {
  if (id.includes('node_modules')) {
    return id.split('node_modules/')[1].split('/')[0]   // one chunk per package
  }
}

// BAD: Not externalizing peer deps in library mode — causes duplicate runtime errors
// build.lib without rolldownOptions.external

// BAD: Using deprecated esbuild minifier
build: { minify: 'esbuild' }                  // use 'oxc' (default) or 'terser'

// BAD: Mutating import.meta.hot.data by reassignment
import.meta.hot.data = { count: 0 }           // WRONG: must mutate properties, not reassign
import.meta.hot.data.count = 0                 // CORRECT
```

**Anti-pattern về quy trình:**

- **`vite preview` KHÔNG phải server production** — nó là smoke test cho bundle đã build. Deploy `dist/` lên một static host thực thụ (NGINX, Cloudflare Pages, Vercel static) hoặc dùng Dockerfile multi-stage.
- **Kỳ vọng `vite build` sẽ type-check** — nó chỉ transpile. Lỗi type âm thầm lên production. Thêm `vite-plugin-checker` hoặc chạy `tsc --noEmit` trong CI.
- **Mặc định phát hành `@vitejs/plugin-legacy`** — nó làm bundle phình ~40%, phá vỡ các công cụ phân tích bundle dựa trên source-map, và không cần thiết cho hơn 95% người dùng trên trình duyệt hiện đại. Hãy quyết định dựa trên analytics thực tế, không phải giả định.
- **Viết tay 30+ entry `resolve.alias` trùng với `paths` trong `tsconfig.json`** — hãy dùng `vite-tsconfig-paths` thay thế. Gặp ở Excalidraw và PostHog; tránh trong dự án mới.
- **Để lại `node_modules/.vite` cũ sau khi dependency thay đổi** — cache pre-bundle gây ra lỗi ma. Hãy xóa nó khi chuyển branch hoặc sau khi patch dependency.

## Tham khảo nhanh

| Pattern | Khi nào dùng |
|---------|-------------|
| `defineConfig` | Luôn luôn — cung cấp type inference |
| `loadEnv(mode, root, ['VITE_'])` | Truy cập biến env trong config (tiền tố tường minh) |
| `vite-plugin-checker` | Mọi ứng dụng TypeScript (lấp khoảng trống type-check) |
| `vite-tsconfig-paths` | Thay cho `resolve.alias` viết tay |
| `optimizeDeps.include` | Dependency CJS gây vấn đề interop |
| `server.proxy` | Chuyển request API tới backend khi dev |
| `server.host: true` | Docker, container, truy cập từ xa |
| `server.warmup.clientFiles` | Transform trước các route đường nóng |
| `build.lib` + `external` | Publish npm package |
| `manualChunks` (object) | Tách vendor bundle |
| `vite --profile` | Debug dev server chậm |
| `vite build && vite preview` | Smoke test bundle prod cục bộ (KHÔNG phải server prod) |

## Skill liên quan

- `frontend-patterns` — Pattern cho React component
- `docker-patterns` — dev trong container với Vite
- `nextjs-turbopack` — bundler thay thế cho Next.js
