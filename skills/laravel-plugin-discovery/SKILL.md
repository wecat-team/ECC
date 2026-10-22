---
name: laravel-plugin-discovery
description: "Khám phá và đánh giá các package Laravel qua LaraPlugins.io MCP. Dùng khi người dùng muốn tìm plugin, kiểm tra độ 'khỏe' của package (package health), hoặc đánh giá khả năng tương thích Laravel/PHP."
metadata:
  origin: ECC
---

# Khám phá Plugin Laravel

Tìm, đánh giá và chọn các package Laravel khỏe mạnh bằng MCP server LaraPlugins.io.

## Khi nào dùng

- Người dùng muốn tìm package Laravel cho một tính năng cụ thể (ví dụ: "auth", "permissions", "admin panel")
- Người dùng hỏi "nên dùng package nào cho..." hoặc "có package Laravel nào cho..."
- Người dùng muốn kiểm tra một package có đang được bảo trì tích cực hay không
- Người dùng cần xác minh khả năng tương thích phiên bản Laravel
- Người dùng muốn đánh giá độ khỏe của package trước khi thêm vào dự án

## Yêu cầu MCP

PHẢI cấu hình LaraPlugins MCP server. Thêm vào mcpServers trong `~/.claude.json` của bạn:

```json
"laraplugins": {
  "type": "http",
  "url": "https://laraplugins.io/mcp/plugins"
}
```

Không cần API key — server miễn phí cho cộng đồng Laravel.

## MCP Tool

LaraPlugins MCP cung cấp hai tool chính:

### SearchPluginTool

Tìm package theo từ khóa, health score, vendor và khả năng tương thích phiên bản.

**Tham số:**
- `text_search` (string, tùy chọn): Từ khóa cần tìm (ví dụ: "permission", "admin", "api")
- `health_score` (string, tùy chọn): Lọc theo nhóm health — `Healthy`, `Medium`, `Unhealthy` hoặc `Unrated`
- `laravel_compatibility` (string, tùy chọn): Lọc theo phiên bản Laravel — `"5"`, `"6"`, `"7"`, `"8"`, `"9"`, `"10"`, `"11"`, `"12"`, `"13"`
- `php_compatibility` (string, tùy chọn): Lọc theo phiên bản PHP — `"7.4"`, `"8.0"`, `"8.1"`, `"8.2"`, `"8.3"`, `"8.4"`, `"8.5"`
- `vendor_filter` (string, tùy chọn): Lọc theo tên vendor (ví dụ: "spatie", "laravel")
- `page` (number, tùy chọn): Số trang cho pagination

### GetPluginDetailsTool

Lấy các số liệu chi tiết, nội dung readme và lịch sử phiên bản của một package cụ thể.

**Tham số:**
- `package` (string, bắt buộc): Tên package Composer đầy đủ (ví dụ: "spatie/laravel-permission")
- `include_versions` (boolean, tùy chọn): Bao gồm lịch sử phiên bản trong response

---

## Cách hoạt động

### Tìm Package

Khi người dùng muốn khám phá các package cho một tính năng:

1. Dùng `SearchPluginTool` với các từ khóa liên quan
2. Áp dụng bộ lọc theo health score, phiên bản Laravel hoặc phiên bản PHP
3. Xem xét kết quả gồm tên package, mô tả và chỉ báo health

### Đánh giá Package

Khi người dùng muốn đánh giá một package cụ thể:

1. Dùng `GetPluginDetailsTool` với tên package
2. Xem xét health score, ngày cập nhật gần nhất, phiên bản Laravel được hỗ trợ
3. Kiểm tra uy tín của vendor và các chỉ báo rủi ro

### Kiểm tra khả năng tương thích

Khi người dùng cần khả năng tương thích phiên bản Laravel hoặc PHP:

1. Tìm kiếm với bộ lọc `laravel_compatibility` đặt thành phiên bản của họ
2. Hoặc lấy chi tiết của một package cụ thể để xem các phiên bản được hỗ trợ

---

## Ví dụ

### Ví dụ: Tìm Package Authentication

```
SearchPluginTool({
  text_search: "authentication",
  health_score: "Healthy"
})
```

Trả về các package khớp "authentication" với trạng thái healthy:
- spatie/laravel-permission
- laravel/breeze
- laravel/passport
- v.v.

### Ví dụ: Tìm Package tương thích Laravel 12

```
SearchPluginTool({
  text_search: "admin panel",
  laravel_compatibility: "12"
})
```

Trả về các package tương thích với Laravel 12.

### Ví dụ: Lấy chi tiết Package

```
GetPluginDetailsTool({
  package: "spatie/laravel-permission",
  include_versions: true
})
```

Trả về:
- Health score và hoạt động gần nhất
- Phiên bản Laravel/PHP được hỗ trợ
- Uy tín vendor (risk score)
- Lịch sử phiên bản
- Mô tả ngắn

### Ví dụ: Tìm Package theo Vendor

```
SearchPluginTool({
  vendor_filter: "spatie",
  health_score: "Healthy"
})
```

Trả về tất cả package healthy của vendor "spatie".

---

## Best Practice khi lọc

### Theo Health Score

| Nhóm Health | Ý nghĩa |
|-------------|---------|
| `Healthy` | Được bảo trì tích cực, có cập nhật gần đây |
| `Medium` | Cập nhật thỉnh thoảng, có thể cần chú ý |
| `Unhealthy` | Bị bỏ rơi hoặc ít được bảo trì |
| `Unrated` | Chưa được đánh giá |

**Khuyến nghị**: Ưu tiên các package `Healthy` cho ứng dụng production.

### Theo phiên bản Laravel

| Phiên bản | Ghi chú |
|---------|-------|
| `13` | Laravel mới nhất |
| `12` | Bản ổn định hiện tại |
| `11` | Vẫn được dùng rộng rãi |
| `10` | Cũ nhưng phổ biến |
| `5`-`9` | Đã lỗi thời (deprecated) |

**Khuyến nghị**: Khớp với phiên bản Laravel của dự án mục tiêu.

### Kết hợp bộ lọc

```typescript
// Find healthy, Laravel 12 compatible packages for permissions
SearchPluginTool({
  text_search: "permission",
  health_score: "Healthy",
  laravel_compatibility: "12"
})
```

---

## Diễn giải Response

### Kết quả tìm kiếm

Mỗi kết quả bao gồm:
- Tên package (ví dụ: `spatie/laravel-permission`)
- Mô tả ngắn
- Chỉ báo trạng thái health
- Badge phiên bản Laravel được hỗ trợ

### Chi tiết Package

Response chi tiết bao gồm:
- **Health Score**: Chỉ báo dạng số hoặc theo nhóm
- **Last Activity**: Thời điểm package được cập nhật gần nhất
- **Laravel Support**: Ma trận tương thích phiên bản
- **PHP Support**: Tương thích phiên bản PHP
- **Risk Score**: Chỉ báo độ tin cậy của vendor
- **Version History**: Dòng thời gian các bản phát hành gần đây

---

## Các trường hợp sử dụng phổ biến

| Tình huống | Cách tiếp cận khuyến nghị |
|----------|---------------------|
| "Package nào cho auth?" | Tìm "auth" với bộ lọc healthy |
| "spatie/package còn được bảo trì không?" | Lấy chi tiết, kiểm tra health score |
| "Cần các package cho Laravel 12" | Tìm với laravel_compatibility: "12" |
| "Tìm package admin panel" | Tìm "admin panel", xem xét kết quả |
| "Kiểm tra uy tín vendor" | Tìm theo vendor, kiểm tra chi tiết |

---

## Best Practice

1. **Luôn lọc theo health** — Dùng `health_score: "Healthy"` cho các dự án production
2. **Khớp phiên bản Laravel** — Luôn kiểm tra `laravel_compatibility` khớp với dự án mục tiêu
3. **Kiểm tra uy tín vendor** — Ưu tiên package từ các vendor uy tín đã biết (spatie, laravel, v.v.)
4. **Xem xét trước khi đề xuất** — Dùng GetPluginDetailsTool để đánh giá toàn diện
5. **Không cần API key** — MCP miễn phí, không yêu cầu xác thực

---

## Skill liên quan

- `laravel-patterns` — Kiến trúc và các pattern Laravel
- `laravel-tdd` — Phát triển hướng kiểm thử (TDD) cho Laravel
- `laravel-security` — Best practice bảo mật Laravel
- `documentation-lookup` — Tra cứu tài liệu thư viện nói chung (Context7)
