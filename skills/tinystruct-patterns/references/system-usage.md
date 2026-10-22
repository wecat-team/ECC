# Tham chiếu hệ thống và cách sử dụng của tinystruct

## Khi nào dùng

Dùng các pattern này để xử lý trạng thái request, quản lý web session, triển khai Server-Sent Events (SSE), xử lý upload file, hoặc thực hiện kết nối HTTP ra bên ngoài.

## Cách hoạt động

### Context và tham số CLI
`Context` là nơi lưu trữ dữ liệu chính cho trạng thái riêng của từng request. Các flag CLI truyền dạng `--key value` được lưu trong `Context` với khóa `"--key"`.

### Quản lý session
Kiến trúc cắm rút (pluggable). Mặc định là `MemorySessionRepository`. Cấu hình Redis trong `application.properties`:
```properties
default.session.repository=org.tinystruct.http.RedisSessionRepository
redis.host=127.0.0.1
redis.port=6379
```

### Server-Sent Events (SSE)
Hỗ trợ sẵn cho push thời gian thực. `HttpServer` tự động xử lý vòng đời SSE khi phát hiện header `Accept: text/event-stream`. Các kết nối được theo dõi theo session ID trong `SSEPushManager`.

### Kết nối mạng ra ngoài
Dùng `URLRequest` và `HTTPHandler` để gửi HTTP request tới các dịch vụ bên ngoài.

## Ví dụ

### Context và tham số CLI
```java
@Action("echo")
public String echo() {
    // CLI: bin/dispatcher echo --words "Hello World"
    Object words = getContext().getAttribute("--words");
    if (words != null) return words.toString();
    return "No words provided";
}
```

### Quản lý session
```java
@Action(value = "login", mode = Mode.HTTP_POST)
public String login(Request<?, ?> request) {
    request.getSession().setAttribute("userId", "42");
    return "Logged in";
}
```

### Server-Sent Events (SSE)
```java
@Action("sse/connect")
public String connect() {
    return "{\"type\":\"connect\",\"message\":\"Connected\"}";
}

// In another method or event handler:
String sessionId = getContext().getId();
SSEPushManager.getInstance().push(sessionId, new Builder().put("msg", "hello"));
```

### Upload file
```java
import org.tinystruct.data.FileEntity;

@Action(value = "upload", mode = Mode.HTTP_POST)
public String upload(Request<?, ?> request) throws ApplicationException {
    List<FileEntity> files = request.getAttachments();
    if (files != null) {
        for (FileEntity file : files) {
            // file.getFilename(), file.getContent()
        }
    }
    return "Uploaded";
}
```

### HTTP ra ngoài
```java
import org.tinystruct.net.URLRequest;
import org.tinystruct.net.handlers.HTTPHandler;

URLRequest request = new URLRequest(new URL("https://api.example.com"));
request.setMethod("POST").setBody("{\"data\":\"val\"}");

HTTPHandler handler = new HTTPHandler();
var response = handler.handleRequest(request);
if (response.getStatusCode() == 200) {
    String body = response.getBody();
}
```

### Hệ thống sự kiện (Event System)
Đăng ký handler trong `init()` để thực thi tác vụ bất đồng bộ.
```java
EventDispatcher.getInstance().registerHandler(MyEvent.class, event -> {
    CompletableFuture.runAsync(() -> doHeavyWork(event.getPayload()));
});
```
