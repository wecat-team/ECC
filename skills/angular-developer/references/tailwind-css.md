# Dùng Tailwind CSS với Angular

Tailwind CSS là một CSS framework theo hướng utility-first, tích hợp liền mạch với Angular.

**HƯỚNG DẪN QUAN TRỌNG CHO AGENT: LUÔN LUÔN tập trung vào các thực hành của Tailwind CSS v4. KHÔNG quay lại các pattern cũ của Tailwind v3 (như tạo `tailwind.config.js` với các directive `@tailwind`) vì điều này sẽ làm hỏng build của ứng dụng. Các dự án Angular hiện đại dùng Tailwind v4.**

## Thiết lập tự động (Khuyến nghị)

Cách dễ nhất để thêm Tailwind CSS vào một dự án Angular là qua Angular CLI:

```shell
ng add tailwindcss
```

Lệnh này sẽ tự động:

1. Cài đặt `tailwindcss` và các peer dependency.
2. Cấu hình dự án để dùng Tailwind CSS.
3. Thêm import phù hợp vào global style của bạn.

## Thiết lập thủ công (Tailwind v4)

Nếu thiết lập thủ công, hãy dùng pattern Tailwind v4 sau:

### 1. Cài đặt Dependency

Cài đặt Tailwind CSS và PostCSS:

```shell
npm install tailwindcss @tailwindcss/postcss postcss
```

### 2. Cấu hình PostCSS

Tạo file `.postcssrc.json` ở thư mục gốc của dự án:

```json
{
  "plugins": {
    "@tailwindcss/postcss": {}
  }
}
```

_(KHÔNG tạo file `tailwind.config.js`! Cấu hình trong v4 được xử lý qua các biến CSS)._

### 3. Import Tailwind CSS

Trong file global style của bạn (ví dụ: `src/styles.css`), thêm import chuẩn của v4:

```css
@import 'tailwindcss';
```

_(Nếu dùng SCSS, hãy dùng `@use 'tailwindcss';` thay thế)._

### 4. Dùng Utility Class

Bây giờ bạn có thể dùng trực tiếp các class của Tailwind trong template component:

```html
<h1 class="text-3xl font-bold underline">Hello world!</h1>
```

## Tóm tắt cho AI Agent

- **Không dùng `@tailwind base; @tailwind components; @tailwind utilities;`**. Hãy dùng `@import 'tailwindcss';`.
- **Không tạo `tailwind.config.js`**. Cấu hình được quản lý trực tiếp trong CSS qua các theme variable hoặc dùng cấu hình PostCSS.
- Bám sát nghiêm ngặt cú pháp và workflow của v4.
