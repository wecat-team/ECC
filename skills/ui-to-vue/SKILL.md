---
name: ui-to-vue
description: Dùng khi người dùng có ảnh chụp màn hình UI hoặc file design export cần chuyển đổi hàng loạt (batch) thành các component Vue 3, đặc biệt với Vant, Element Plus hoặc Ant Design Vue.
metadata:
  origin: community
---

# UI To Vue

Chuyển đổi hàng loạt ảnh chụp màn hình thiết kế UI thành code component Vue 3 Composition API.

## Khi nào dùng

- Người dùng cung cấp một thư mục chứa ảnh chụp màn hình thiết kế hoặc ảnh design export.
- Ứng dụng đích dùng Vue 3.
- Người dùng muốn có bản đầu tiên của các page component, shared component và phần nối router.
- Người dùng chỉ định Vant, Element Plus hoặc Ant Design Vue làm thư viện component.

## Khi nào KHÔNG dùng

- Người dùng chỉ có một ảnh chụp màn hình và muốn một component được làm riêng.
- Dự án đích không phải Vue.
- Thiết kế đòi hỏi logic tương tác chi tiết, data flow hoặc review accessibility.
- Ảnh chụp màn hình chứa dữ liệu khách hàng riêng tư không được phép gửi tới API của mô hình bên ngoài.

## Đầu vào

Dùng một thư mục đầu vào nhóm ảnh chụp màn hình theo module và trạng thái trang:

```text
screenshots/
|-- HomePage/
|   |-- List/
|   |   |-- HomePage-List-Default@3x.png
|   |   `-- cut-images/
|   |-- cut-images/
|   `-- HomePage-Default@3x.png
`-- cut-images/
```

Các tên thư mục cut-image được hỗ trợ gồm `assets`, `icons`, `sprites`, `cut`, `images` và `cut-images`.

## Mô hình chuyển đổi

- Gom nhóm trang: gộp các ảnh chụp màn hình liên quan thành một page component khi chúng biểu diễn các trạng thái danh sách, chi tiết, form, loading hoặc rỗng.
- Ánh xạ thư viện UI: ánh xạ các phần tử trực quan native sang component Vant, Element Plus hoặc Ant Design Vue khi khả thi.
- Ưu tiên cut-image: ưu tiên asset cấp trang, sau đó asset cấp module, rồi asset dùng chung toàn cục.
- Tách component: tách các vùng UI lặp lại thành shared component khi chúng xuất hiện nhiều hơn một lần.

## Sử dụng CLI

Chạy converter bằng `npx` để lệnh được tài liệu hóa hoạt động mà không phụ thuộc vào binary cài global:

```bash
export DASHSCOPE_API_KEY=your_key
npx ui-to-vue-converter@1.0.2 --input ./screenshots --ui vant --output ./src
```

Với các thư viện UI desktop:

```bash
npx ui-to-vue-converter@1.0.2 --input ./designs --ui element-plus --output ./src
npx ui-to-vue-converter@1.0.2 --input ./designs --ui antd-vue --output ./src
```

Nếu package được cài global, có thể dùng trực tiếp binary `ui-to-vue`:

```bash
npm install -g ui-to-vue-converter@1.0.2
ui-to-vue --input ./screenshots --ui vant --output ./src
```

## Tùy chọn

| Tùy chọn | Mô tả | Mặc định |
| --- | --- | --- |
| `--input` | Thư mục chứa ảnh thiết kế | `./screenshots` |
| `--ui` | Thư viện UI: `vant`, `element-plus` hoặc `antd-vue` | `vant` |
| `--output` | Thư mục đầu ra | `./src` |
| `--config` | Đường dẫn file cấu hình | `./.ui-to-vue.config.json` |

## Xử lý API Key

Converter có thể đọc thông tin xác thực DashScope từ file cấu hình hoặc từ biến môi trường. Trong repo, ưu tiên dùng biến môi trường:

```bash
export DASHSCOPE_API_KEY=your_key
```

Nếu bắt buộc phải có file cấu hình cục bộ, hãy giữ nó ngoài version control:

```json
{
  "apiKey": "your_dashscope_key",
  "input": "./designs",
  "ui": "vant",
  "output": "./src"
}
```

```gitignore
.ui-to-vue.config.json
```

## Bảo mật và quyền riêng tư

- Coi ảnh chụp màn hình thiết kế là tư liệu nguồn có thể bị gửi tới API của mô hình bên ngoài.
- Không chạy quy trình này trên các thiết kế riêng tư của khách hàng khi chưa được cho phép.
- Ghim (pin) phiên bản converter trong các workflow cần lặp lại được thay vì dùng `@latest`.
- Review code Vue được sinh ra trước khi commit.
- Không commit `.ui-to-vue.config.json`, API key, secret được sinh ra hoặc ảnh chụp màn hình của khách hàng.

## Checklist review đầu ra

- [ ] Các page component được sinh ra dưới `views/` hoặc thư mục đầu ra đã chọn.
- [ ] Các vùng UI lặp lại chỉ được tách vào `components/` khi việc tái sử dụng là rõ ràng.
- [ ] Đầu ra router tương thích với phong cách router của dự án đích.
- [ ] Các component được sinh ra dùng thư viện UI được yêu cầu một cách nhất quán.
- [ ] Đơn vị CSS được sinh ra khớp với baseline của thiết kế.
- [ ] Code qua được formatter, linter, type checker và build của dự án.
- [ ] Nội dung placeholder, mock data và asset được sinh ra đã được review trước khi commit.

## Xử lý sự cố

| Vấn đề | Kiểm tra |
| --- | --- |
| Lỗi `401` hoặc lỗi xác thực | Xác nhận `DASHSCOPE_API_KEY` đã được đặt trong shell chạy lệnh. |
| `command not found: ui-to-vue` | Dùng dạng `npx ui-to-vue-converter@1.0.2` hoặc cài package global. |
| Cut image bị bỏ qua | Xác nhận tên thư mục asset được hỗ trợ và nằm lồng dưới đúng trang hoặc module tương ứng. |
| Component bỏ qua thư viện UI được yêu cầu | Chạy lại với giá trị `--ui` tường minh và kiểm tra các import được sinh ra. |
| Kích thước layout được sinh ra trông sai | Xác nhận chiều rộng ảnh export khớp với baseline của thư viện đích. |

## Tham khảo

- npm package: `ui-to-vue-converter`
