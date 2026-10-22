# Kiến trúc và cấu hình của tinystruct

## Khi nào dùng

Chọn **tinystruct** khi bạn cần một framework Java nhẹ, hiệu năng cao, coi CLI và HTTP là hai thành phần ngang hàng. Lý tưởng cho microservice, tiện ích CLI và các ứng dụng hướng dữ liệu với dung lượng nhỏ và xử lý JSON không cần dependency.

## Cách hoạt động

### Kiến trúc cốt lõi

Framework vận hành dựa trên một `ActionRegistry` singleton ánh xạ các URL pattern (hoặc chuỗi lệnh) tới các đối tượng `Action`. Khi có request đến, hệ thống resolve đường dẫn và gọi method handle tương ứng.

#### Các abstraction chính

| Class/Interface | Vai trò |
|---|---|
| `AbstractApplication` | Base class cho mọi ứng dụng tinystruct. Hãy extend class này. |
| Annotation `@Action` | Ánh xạ một method tới một đường dẫn URI (web) hoặc tên lệnh (CLI). Là primitive định tuyến duy nhất. |
| `ActionRegistry` | Singleton ánh xạ URL pattern tới các đối tượng `Action` qua regex. KHÔNG BAO GIỜ khởi tạo trực tiếp. |
| `Action` | Bao bọc một `MethodHandle` + regex pattern + priority + `Mode` để điều phối (dispatch). |
| `Context` | Kho lưu state theo từng request. Truy cập qua `getContext()`. Chứa các tham số CLI và HTTP request/response. |
| `Dispatcher` | Điểm vào của CLI (`bin/dispatcher`). Đọc `--import` để nạp các ứng dụng. |
| `HttpServer` | HTTP server tích hợp sẵn. Khởi động bằng `bin/dispatcher start --import org.tinystruct.system.HttpServer`. |

### Sơ đồ package

```
org.tinystruct/
├── AbstractApplication.java      ← extend this
├── Application.java              ← interface
├── ApplicationException.java     ← checked exception
├── ApplicationRuntimeException.java ← unchecked exception
├── application/
│   ├── Action.java               ← runtime action wrapper
│   ├── ActionRegistry.java       ← singleton route registry
│   └── Context.java              ← request context
├── system/
│   ├── annotation/Action.java    ← @Action annotation + Mode enum
│   ├── Dispatcher.java           ← CLI dispatcher
│   ├── HttpServer.java           ← built-in HTTP server
│   ├── EventDispatcher.java      ← event bus
│   └── Settings.java             ← reads application.properties
├── data/
│   ├── component/Builder.java    ← JSON object (use instead of Gson/Jackson)
│   ├── component/Builders.java   ← JSON array
│   ├── component/AbstractData.java ← base POJO for DB persistence
│   ├── component/Condition.java  ← fluent SQL query builder
│   ├── component/FieldType.java  ← SQL-to-Java type mappings
│   ├── annotation/               ← @Table, @Id, @Column mapping annotations
│   ├── Mapping.java              ← reads @Table/@Column annotations or .map.xml metadata, cached per class
│   ├── tools/TableCreator.java   ← creates missing tables (database.autocreate)
│   ├── DatabaseOperator.java     ← low-level JDBC wrapper
│   └── FileEntity.java           ← file upload representation
├── http/                         ← Request, Response, Constants
│   └── SSEPushManager.java       ← Server-Sent Events management
└── net/                          ← URLRequest, HTTPHandler (outbound HTTP)
```

### Hành vi của Template và luồng Dispatch

Theo mặc định, framework giả định rằng cần có một view template. Nếu `templateRequired` là `true`, `toString()` sẽ tìm file `.view` trong `src/main/resources/themes/<ClassName>.view`. Dùng `setVariable("name", value)` để truyền dữ liệu cho template, template dùng `{%name%}` để nội suy.

## Ví dụ

### Khởi tạo ứng dụng tối thiểu
```java
@Override
public void init() {
    this.setTemplateRequired(false); // Skip .view template lookup for data-only apps
    // Do NOT call setAction() here — use @Action annotation instead
}
```

### Định nghĩa Action và gọi từ CLI
```java
@Action("hello")
public String hello() {
    return "Hello, tinystruct!";
}
```
**Thực thi qua Dispatcher:**
```bash
bin/dispatcher hello
bin/dispatcher greet/James
bin/dispatcher echo --words "Hello" --import com.example.HelloApp
```

### Truy cập cấu hình
Nằm tại `src/main/resources/application.properties`:
```java
String port = this.getConfiguration("server.port");
```
