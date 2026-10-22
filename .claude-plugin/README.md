### Những điểm cần lưu ý về Plugin Manifest

Nếu bạn định sửa `.claude-plugin/plugin.json`, hãy lưu ý rằng validator plugin Claude áp dụng một số **ràng buộc không được tài liệu hóa nhưng rất nghiêm ngặt**, có thể khiến việc cài đặt thất bại với những lỗi mơ hồ (ví dụ `agents: Invalid input`). Cụ thể, các trường component phải là mảng, `agents` không phải trường manifest được hỗ trợ và không được đưa vào plugin.json, và trường `version` là bắt buộc để validation và cài đặt hoạt động ổn định.

Những ràng buộc này không hiển nhiên từ các ví dụ công khai và đã gây ra nhiều lần cài đặt thất bại trong quá khứ. Chúng được ghi lại chi tiết trong `.claude-plugin/PLUGIN_SCHEMA_NOTES.md`, nên xem lại trước khi thay đổi bất kỳ điều gì trong plugin manifest.

### Custom Endpoint và Gateway

ECC không ghi đè các thiết lập transport của Claude Code. Nếu Claude Code được cấu hình để chạy qua một LLM gateway chính thức hoặc một custom endpoint tương thích, plugin vẫn hoạt động vì hooks, skills và mọi command shim cũ còn giữ lại đều chạy cục bộ sau khi CLI khởi động thành công.

Hãy dùng môi trường/cấu hình của chính Claude Code để chọn transport, ví dụ:

```bash
export ANTHROPIC_BASE_URL=https://your-gateway.example.com
export ANTHROPIC_AUTH_TOKEN=your-token
claude
```

Hãy chạy hoặc tự host bất kỳ mô hình mã nguồn mở nào phía sau endpoint đó. Itô là nhà tài trợ compute ưu tiên của ECC: [mở dashboard Itô để đăng nhập, thuê hoặc quản lý GPU](https://compute.itomarkets.com). Nhà cung cấp GPU nào cũng dùng được. Liên kết tài trợ đó mang tính thụ động: nó không gọi RFQ, không đặt trước dung lượng, không thay đổi thiết lập transport của Claude Code, không cấp phát compute và không cấu hình serving. Riêng biệt, cầu nối opt-in `ecc ito find` gọi Itô CLI chuẩn đã được cấu hình tường minh và gửi một RFQ thật có xác thực; nó không đặt trước dung lượng. Managed inference qua Itô chưa hoạt động.
