# Hướng dẫn Angular CLI cho Agent

Angular CLI (`ng`) là công cụ chính để quản lý một Angular workspace. Luôn ưu tiên dùng lệnh CLI thay vì tạo file thủ công hoặc dùng các lệnh `npm` chung chung khi thay đổi cấu trúc dự án hoặc thêm dependency dành riêng cho Angular.

## 1. Quản lý dependency

**LUÔN LUÔN dùng `ng add` cho các thư viện Angular** thay vì `npm install`. `ng add` cài đặt package VÀ chạy các schematic khởi tạo (ví dụ: cấu hình `angular.json`, cập nhật root provider).

```bash
ng add @angular/material
ng add tailwindcss
ng add @angular/fire
```

Để cập nhật ứng dụng và các dependency của nó (tự động chạy các code migration):

```bash
ng update @angular/core@<latest or specific version> @angular/cli<latest or specific version>
```

## 2. Sinh code (`ng generate` hoặc `ng g`)

Luôn dùng CLI để sinh code nhằm đảm bảo tuân thủ chuẩn Angular và tự động cập nhật các file cấu hình cần thiết.

| Đối tượng    | Lệnh                  | Ghi chú                                                                                                  |
| :----------- | :-------------------- | :------------------------------------------------------------------------------------------------------- |
| Component    | `ng g c path/to/name` | Sinh một component. Dùng `--inline-style` (`-s`) hoặc `--inline-template` (`-t`) nếu được yêu cầu.       |
| Service      | `ng g s path/to/name` | Sinh một service `@Injectable({providedIn: 'root'})`.                                                    |
| Directive    | `ng g d path/to/name` | Sinh một directive.                                                                                      |
| Pipe         | `ng g p path/to/name` | Sinh một pipe.                                                                                           |
| Guard        | `ng g g path/to/name` | Sinh một functional route guard.                                                                         |
| Environments | `ng g environments`   | Dựng sẵn `src/environments/` và cập nhật `angular.json` với các file replacement.                        |

_Lưu ý: Không có lệnh nào để sinh riêng một route definition. Hãy sinh một component, sau đó thêm thủ công vào mảng `Routes` trong `app.routes.ts`._

## 3. Development Server & Proxy

Khởi động development server cục bộ với hot-module replacement (HMR):

```bash
ng serve
```

### Proxy cho Backend API

Để proxy các request API trong quá trình phát triển (ví dụ: chuyển hướng `/api` tới một Node server cục bộ):

1. Tạo `src/proxy.conf.json`:
   ```json
   {
     "/api/**": {"target": "http://localhost:3000", "secure": false}
   }
   ```
2. Cập nhật `angular.json` ở target `serve`:
   ```json
   "serve": {
     "builder": "@angular/build:dev-server",
     "options": { "proxyConfig": "src/proxy.conf.json" }
   }
   ```

## 4. Build ứng dụng

Biên dịch ứng dụng vào thư mục output (mặc định: `dist/<project-name>/browser`). Angular hiện đại dùng builder `@angular/build:application` (dựa trên esbuild).

```bash
ng build
```

- `ng build` mặc định dùng cấu hình production, bật biên dịch Ahead-of-Time (AOT), minification và tree-shaking.
- Nhắm tới các cấu hình cụ thể được định nghĩa trong `angular.json` bằng `--configuration`: `ng build --configuration=staging`.

## 5. Testing

- **Unit Test**: Chạy `ng test` để thực thi unit test thông qua test runner đã cấu hình (ví dụ: Karma hoặc Vitest).
- **End-to-End (E2E)**: Chạy `ng e2e`. Nếu chưa cấu hình framework E2E nào, CLI sẽ nhắc cài đặt một framework (Cypress, Playwright, Puppeteer, v.v.).

## 6. Deployment

Để deploy một ứng dụng, trước tiên bạn phải thêm một deployment builder, sau đó chạy lệnh deploy:

```bash
# Example for Firebase
ng add @angular/fire
ng deploy
```
