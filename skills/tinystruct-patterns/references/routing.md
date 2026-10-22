# Tham chiếu routing @Action của tinystruct

## Khi nào dùng

Dùng annotation `@Action` trong ứng dụng để định nghĩa route cho cả lệnh CLI và endpoint HTTP. Phù hợp khi cần ánh xạ logic tới một đường dẫn cụ thể, xử lý request có tham số, hoặc giới hạn việc thực thi theo từng phương thức HTTP mà vẫn giữ cấu trúc lệnh nhất quán giữa các môi trường.

## Cách hoạt động

`ActionRegistry` phân tích các annotation `@Action` để xây dựng bảng routing. Với các method có tham số, framework tự động ánh xạ kiểu tham số Java sang các đoạn regex tương ứng.

### Quy tắc sinh regex
- `getUser(int id)` → pattern: `^/?user/(-?\d+)$`
- `search(String query)` → pattern: `^/?search/([^/]+)$`

Các kiểu tham số được hỗ trợ: `String`, `int/Integer`, `long/Long`, `float/Float`, `double/Double`, `boolean/Boolean`, `char/Character`, `short/Short`, `byte/Byte`, `Date` (được parse theo định dạng `yyyy-MM-dd HH:mm:ss`).

### Các giá trị Mode

| Mode | Khi nào kích hoạt |
|---|---|
| `DEFAULT` | Cả CLI và HTTP (GET, POST, v.v.) |
| `CLI` | Chỉ CLI dispatcher |
| `HTTP_GET` | Chỉ HTTP GET |
| `HTTP_POST` | Chỉ HTTP POST |
| `HTTP_PUT` | Chỉ HTTP PUT |
| `HTTP_DELETE` | Chỉ HTTP DELETE |
| `HTTP_PATCH` | Chỉ HTTP PATCH |

> **Lưu ý:** Có thể ánh xạ tên phương thức HTTP sang `Mode` bằng `Action.Mode.fromName(String methodName)`. Giá trị không xác định hoặc null trả về `Mode.DEFAULT`.

## Ví dụ

### Khai báo Action cơ bản
```java
@Action(
    value = "path/subpath",          // required: URI segment or CLI command
    description = "What it does",    // shown in --help output
    mode = Mode.DEFAULT,             // default: Mode.DEFAULT
    example = "bin/dispatcher path/subpath/42"
)
public String myAction(int id) { ... }
```

### Đường dẫn có tham số
```java
@Action("user/{id}")
public String getUser(int id) { ... }
// → CLI: bin/dispatcher user/42
// → HTTP: /?q=user/42
```

### Dependency Injection
`ActionRegistry` tự động inject `Request` và/hoặc `Response` từ `Context` nếu chúng là tham số:

```java
@Action(value = "upload", mode = Mode.HTTP_POST)
public String upload(Request<?, ?> req, Response<?, ?> res) throws ApplicationException {
    // Access raw request/response if needed
    return "ok";
}
```

### Thứ tự ưu tiên khi khớp đường dẫn
Nếu hai method dùng chung một đường dẫn, framework dùng kết quả khớp đầu tiên trong `ActionRegistry`. Hãy dùng giá trị `Mode` tường minh để phân biệt (ví dụ: tách GET cho form và POST cho việc submit).
