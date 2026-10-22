# Pattern kiểm thử trong tinystruct

## Khi nào dùng

Dùng các pattern này khi viết unit test cho ứng dụng bằng **JUnit 5**. Rất cần thiết để xác minh logic của action, việc đăng ký routing và hành vi của các HTTP mode.

## Cách hoạt động

### Unit test cho ứng dụng
ActionRegistry là singleton. Để test một ứng dụng:
1. Khởi tạo ứng dụng.
2. Cung cấp một object `Settings` (kích hoạt `init()` và xử lý annotation).
3. Dùng `app.invoke(path, args)` để test logic trực tiếp.

### Integration test qua HTTP
Với các test dùng HTTP server tích hợp sẵn:
1. Khởi động `HttpServer` trong một background thread.
2. Dùng `ApplicationManager.call("start", context, Action.Mode.CLI)` để boot.
3. Chờ cổng mở bằng một `Socket`.
4. Dùng `URLRequest` và `HTTPHandler` để thực hiện request thật.

## Ví dụ

### Unit test
```java
import org.junit.jupiter.api.*;
import org.tinystruct.system.Settings;

class MyAppTest {
    private MyApp app;

    @BeforeEach
    void setUp() {
        app = new MyApp();
        app.setConfiguration(new Settings());
        app.init(); // triggers @Action annotation processing and registers all actions
    }

    @Test
    void testHello() throws Exception {
        Object result = app.invoke("hello");
        Assertions.assertEquals("Hello!", result);
    }

    @Test
    void testGreet() throws Exception {
        Object result = app.invoke("greet", new Object[]{"James"});
        Assertions.assertEquals("Hello, James!", result);
    }
}
```

### Test việc khớp ActionRegistry
```java
@Test
void testRouting() {
    ActionRegistry registry = ActionRegistry.getInstance();
    Action action = registry.getAction("greet/James");
    Assertions.assertNotNull(action);
}
```

### Pattern integration test qua HTTP
Tham khảo: `src/test/java/org/tinystruct/system/HttpServerHttpModeTest.java`

```java
// Pattern:
// 1. Start server in thread
// 2. Poll for port availability
// 3. Send HTTP request via HTTPHandler
// 4. Assert response body/status
```
