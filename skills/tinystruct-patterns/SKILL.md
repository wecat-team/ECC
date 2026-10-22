---
name: tinystruct-patterns
description: Hướng dẫn chuyên sâu để phát triển với Java framework tinystruct. Dùng khi làm việc trên codebase tinystruct hoặc bất kỳ dự án nào xây dựng trên tinystruct — bao gồm sinh các script launcher bin/dispatcher và bin/dispatcher.cmd khi dự án chưa có, tạo class Application, route ánh xạ bằng @Action, unit test, ActionRegistry, xử lý dual-mode HTTP/CLI, HTTP server tích hợp sẵn, hệ thống sự kiện (event system), JSON với Builder/Builders, lưu trữ database với AbstractData, sinh POJO, Server-Sent Events (SSE), upload file, và kết nối HTTP ra ngoài.
metadata:
  origin: ECC
  upstream: tinystruct==1.7.34
---

# Pattern phát triển với tinystruct

Các pattern kiến trúc và triển khai để xây dựng module với Java framework **tinystruct** – một framework nhẹ, hiệu năng cao, coi CLI và HTTP là hai công dân ngang hàng, không cần method `main()` và chỉ cần cấu hình tối thiểu.

## Nguyên tắc cốt lõi

**CLI và HTTP là hai công dân ngang hàng.** Mọi method được gắn `@Action` về lý tưởng đều nên chạy được từ cả terminal lẫn trình duyệt web mà không cần sửa đổi. Khả năng "dual-mode" này là triết lý thiết kế cốt lõi của tinystruct.

## Công cụ phát triển chính: `bin/dispatcher`

**`bin/dispatcher` là công cụ mặc định, có ưu tiên cao nhất để phát triển, chạy, test và debug một ứng dụng tinystruct — hãy dùng nó trước cả run configuration của IDE, `main()` tự viết, curl hay trình duyệt.** Vì mọi `@Action` đều được thiết kế dual-mode, `bin/dispatcher` cho phép bạn thử routing, binding tham số và business logic trực tiếp từ terminal, với vòng phản hồi nhanh nhất có thể và không cần server/trình duyệt.

```bash
# Run any @Action directly - the fastest way to verify a new action works
# (the class must be imported; see --import or default.import.applications in application.properties)
bin/dispatcher greet/James --import com.example.MyService
bin/dispatcher echo --words "Praise the Lord"

# Start the HTTP server when you need the web-facing counterpart
bin/dispatcher start --import org.tinystruct.system.HttpServer

# Import additional Application/MCP classes for the current run
# (one --import per class; a comma-separated list fails with ClassNotFoundException)
bin/dispatcher start --import org.tinystruct.system.HttpServer --import com.example.MyService

# Discover what's available
bin/dispatcher --help
bin/dispatcher --version
```

Hãy mặc định theo workflow này: triển khai `@Action`, chạy ngay qua `bin/dispatcher <action>` để xác nhận nó hoạt động đúng ở chế độ CLI, và chỉ khởi động HTTP server (cũng qua `bin/dispatcher start ...`) khi cần kiểm tra đường đi hướng web (ví dụ `mode = Mode.HTTP_POST`, session, upload file). KHÔNG BAO GIỜ hardcode `main(String[] args)` làm điểm vào của ứng dụng — `bin/dispatcher` (hoặc `bin/dispatcher.cmd` trên Windows) là điểm vào duy nhất cho mọi module.

### Sinh `bin/dispatcher` và `bin/dispatcher.cmd`

Mọi dự án tinystruct đều cần launcher của nó trong `bin/`. **Framework sẽ sinh ra nó — KHÔNG BAO GIỜ viết tay, không bao giờ copy từ dự án khác hay thay bằng `main()`.** `ApplicationManager.init()` ghi launcher cho hệ điều hành hiện tại vào `bin/` dưới thư mục làm việc bất cứ khi nào nó bị thiếu, từ các template nằm trong jar của tinystruct, với phiên bản của jar đó được điền sẵn. Ký tự xuống dòng và quyền executable đã đúng sẵn.

**1. Tìm phiên bản tinystruct** mà dự án build với: thuộc tính `<tinystruct.version>` hoặc dependency `org.tinystruct:tinystruct` trong `pom.xml`. Jar phải truy cập được, trong `~/.m2/repository/org/tinystruct/tinystruct/<version>/` (chạy `mvn dependency:resolve` nếu chưa có) hoặc trong `lib/` của dự án.

**2. Từ thư mục gốc của dự án, chạy framework một lần:**

```bash
java -cp ~/.m2/repository/org/tinystruct/tinystruct/<version>/tinystruct-<version>.jar \
     org.tinystruct.system.Dispatcher --version
```

Thay `<version>` bằng phiên bản tìm được ở bước 1. Trên Windows dùng `%USERPROFILE%\.m2\repository\org\tinystruct\tinystruct\<version>\tinystruct-<version>.jar` và cùng class đó. Lệnh này tạo **chỉ script cho hệ điều hành bạn đã chạy**, và chỉ khi nó chưa tồn tại:

| Chạy trên | Tạo ra |
|---|---|
| Linux, macOS | `bin/dispatcher` (executable, LF) |
| Windows | `bin\dispatcher.cmd` (CRLF) |

**3. Xác minh.** Từ thư mục gốc dự án chạy `bin/dispatcher --version` (Windows: `bin\dispatcher.cmd --version`). Nó in ra `Dispatcher (cli) (built on tinystruct-<version>)`, và `VERSION` bên trong script bằng phiên bản của jar. Sau đó `bin/dispatcher --help` liệt kê các lệnh và mọi action đã import. Hãy cho người dùng xem file bạn đã tạo.

**4. Lấy cả hai script bằng cách chạy bước 2 trên từng hệ điều hành**, hoặc nhờ đồng đội hay CI trên hệ điều hành còn lại chạy rồi commit kết quả. Commit cả hai, để checkout trên hệ điều hành nào cũng chạy được. Đừng cố giả lập hệ điều hành kia bằng `-Dos.name=…`: trên Windows nó thất bại (`UnsupportedOperationException` từ `setPosixFilePermissions`) và để lại một `bin/dispatcher` rỗng. `.gitattributes` khuyến nghị, để checkout không làm hỏng ký tự xuống dòng:

```
bin/dispatcher     text eol=lf
bin/dispatcher.cmd text eol=crlf
```

**Nâng cấp tinystruct:** đổi phiên bản trong `pom.xml`, xóa script cũ, và lặp lại bước 2 với jar mới. Hoặc `bin/dispatcher update` kiểm tra Maven Central để tìm bản phát hành mới nhất, nâng cấp dependency của dự án và sinh lại script với force; nó cần mạng, sửa `pom.xml`, và nâng lên phiên bản *mới nhất*, không phải phiên bản tự chọn.

**Nó cũng xảy ra ngầm.** Bất kỳ đoạn code nào chạm tới `ApplicationManager.init()` (chính dispatcher, hoặc `ApplicationManager.install(app, config)` trong unit test) đều tạo script trong *thư mục hiện tại* nếu nó thiếu. Nếu unit test làm vương vãi `bin/dispatcher.cmd` vào các thư mục module, hãy chạy chúng từ thư mục build: trong cấu hình surefire đặt `<workingDirectory>${project.build.directory}</workingDirectory>`.

**Các script làm gì**, điều này giải thích phần lớn các vấn đề:

- Chạy chúng **từ thư mục gốc dự án**: shell script lấy thư mục hiện tại làm root, còn `.cmd` lấy thư mục cha của `bin/`.
- Classpath gồm `target/classes`, `lib/*.jar`, `WEB-INF/lib/*`, `WEB-INF/classes` và jar tinystruct (từ `lib/`, nếu không thì `~/.m2`), sau đó chạy `org.tinystruct.system.Dispatcher` với các tham số của bạn.
- Ở lần chạy đầu, nếu thiếu `mvnw` / `mvnw.cmd`, chúng giải nén Maven Wrapper vào thư mục gốc dự án (`unzip` trên Unix, PowerShell trên Windows). Hãy báo cho người dùng biết điều này xảy ra; các file có thể commit hoặc ignore.
- Chỉ shell script coi các tham số `-D…` và `-X…` là JVM option.

**Những điểm dễ vấp:**

- **Trên Windows dùng `bin\dispatcher.cmd`.** Shell script nối classpath bằng `:`, nên dưới Git Bash/MSYS nó lỗi với `ClassNotFoundException: org.tinystruct.system.Dispatcher`. Hãy dùng WSL, hoặc `.cmd`.
- **Chỉ có jar tinystruct nằm trên classpath.** Framework không còn đóng gói fat jar theo mặc định, nên các module khác, JDBC driver và thư viện (jjwt, lettuce, …) của bạn phải nằm trong `lib/`: `mvn dependency:copy-dependencies -DoutputDirectory=lib` (và git-ignore `lib/`). Trong build multi-module, hãy để launcher ở thư mục chứa `target/classes` và `lib/`, và copy jar của các module anh em vào `lib/` đó; chạy nó từ một module mà các module anh em không nằm trên classpath sẽ lỗi `NoClassDefFoundError`.
- **Nạp application bằng `--import` hoặc cấu hình.** Mỗi class một `--import` (`--import a.A,b.B` lỗi; hãy viết `--import a.A --import b.B`), hoặc liệt kê một lần trong `application.properties`: `default.import.applications=a.A;b.B` (phân cách bằng `;`).
- **PHẢI đặt `JAVA_HOME`** cho `.cmd`; nếu không nó dừng với lỗi.
- **`bin/` nằm trực tiếp dưới thư mục chứa `target/classes` và `lib/`.** `.cmd` coi thư mục cha của `bin/` là root, nên một `bin/` lồng sai thư mục sẽ đặt sai classpath trước `Dispatcher`.

## Khi nào kích hoạt

### Khi nào dùng

- Chạy, test hoặc debug bất kỳ `@Action` nào qua `bin/dispatcher` — đây là cách làm việc mặc định với ứng dụng tinystruct, trước khi dùng đến HTTP hay run configuration của IDE.
- Thiết lập dự án chưa có `bin/dispatcher` / `bin/dispatcher.cmd` — hãy để framework sinh ra (xem "Sinh `bin/dispatcher` và `bin/dispatcher.cmd`").
- Tạo module `Application` mới bằng cách kế thừa `AbstractApplication`.
- Định nghĩa route và action dòng lệnh bằng `@Action`.
- Xử lý trạng thái theo từng request qua `Context`.
- Thực hiện serialize JSON bằng các thành phần native `Builder` và `Builders`.
- Làm việc với lưu trữ database qua các POJO `AbstractData`.
- Sinh POJO từ bảng database bằng lệnh `generate`, với file XML mapping hoặc annotation (`--mapping annotation`).
- Triển khai Server-Sent Events (SSE) cho push thời gian thực.
- Xử lý upload file qua dữ liệu multipart.
- Gửi HTTP request ra ngoài bằng `URLRequest` và `HTTPHandler`.
- Cấu hình kết nối database hoặc cài đặt hệ thống trong `application.properties`.
- Debug xung đột routing (Action) hoặc việc parse tham số CLI.

## Cách hoạt động

Framework tinystruct coi bất kỳ method nào được gắn `@Action` là một endpoint có thể route được cho cả môi trường terminal lẫn web. Ứng dụng được tạo bằng cách kế thừa `AbstractApplication`, class này cung cấp các lifecycle hook cốt lõi như `init()` và quyền truy cập `Context` của request.

Routing do `ActionRegistry` đảm nhiệm, nó tự động ánh xạ các đoạn đường dẫn sang tham số method và inject dependency. Với các dịch vụ chỉ phục vụ dữ liệu, nên dùng các thành phần native `Builder` và `Builders` để serialize JSON nhằm giữ footprint không có dependency ngoài. Lớp database dùng các POJO `AbstractData` được ánh xạ tới bảng bằng annotation `@Table`/`@Column` hoặc file XML mapping để thực hiện CRUD mà không cần thư viện ORM ngoài. Các bảng còn thiếu có thể được tạo tự động với `database.autocreate=true`.

## Ví dụ

### Application cơ bản (MyService)
```java
public class MyService extends AbstractApplication {
    @Override
    public void init() {
        this.setTemplateRequired(false); // Disable .view lookup for data/API apps
    }

    @Override public String version() { return "1.0.0"; }

    @Action("greet")
    public String greet() {
        return "Hello from tinystruct!";
    }

    // Path parameter: GET /?q=greet/James  OR  bin/dispatcher greet/James
    @Action("greet")
    public String greet(String name) {
        return "Hello, " + name + "!";
    }
}
```

### Phân biệt HTTP Mode (login)
```java
@Action(value = "login", mode = Mode.HTTP_POST)
public String doLogin(Request<?, ?> request) throws ApplicationException {
    request.getSession().setAttribute("userId", "42");
    return "Logged in";
}
```

### Xử lý dữ liệu JSON native (Builder + Builders)
```java
import org.tinystruct.data.component.Builder;
import org.tinystruct.data.component.Builders;

@Action("api/data")
public String getData() throws ApplicationException {
    Builders dataList = new Builders();
    Builder item = new Builder();
    item.put("id", 1);
    item.put("name", "James");
    dataList.add(item);

    Builder response = new Builder();
    response.put("status", "success");
    response.put("data", dataList);
    return response.toString(); // {"status":"success","data":[{"id":1,"name":"James"}]}
}
```

### SSE (Server-Sent Events)
```java
import org.tinystruct.http.SSEPushManager;

@Action("sse/connect")
public String connect() {
    return "{\"type\":\"connect\",\"message\":\"Connected to SSE\"}";
}

// Push to a specific client
String sessionId = getContext().getId();
Builder msg = new Builder();
msg.put("text", "Hello, user!");
SSEPushManager.getInstance().push(sessionId, msg);

// Broadcast to all
// Broadcast to all
SSEPushManager.getInstance().broadcast(msg);
```

### Upload file
```java
import org.tinystruct.data.FileEntity;

@Action(value = "upload", mode = Mode.HTTP_POST)
public String upload(Request<?, ?> request) throws ApplicationException {
    List<FileEntity> files = request.getAttachments();
    if (files != null) {
        for (FileEntity file : files) {
            System.out.println("Uploaded: " + file.getFilename());
        }
    }
    return "Upload OK";
}
```

### Thao tác metadata của database
`DatabaseOperator` cung cấp truy cập trực tiếp tới catalog, schema và metadata ở mức connection:
```java
import org.tinystruct.data.DatabaseOperator;

DatabaseOperator operator = new DatabaseOperator();
try {
    String catalog = operator.getCatalog();
    String schema = operator.getSchema();
    java.sql.DatabaseMetaData metaData = operator.getMetaData();
    System.out.println("Using catalog: " + catalog + ", schema: " + schema);
} finally {
    operator.close();
}
```

## Tích hợp MCP Server và Tools

tinystruct hỗ trợ native cho Model Context Protocol (MCP) kể từ phiên bản SDK **`1.7.0`**.
Các API MCP (ví dụ `org.tinystruct.mcp.MCPTool`, `org.tinystruct.mcp.MCPServer`, `org.tinystruct.mcp.MCPException`) nằm sẵn trong dependency lõi:
```xml
<dependency>
    <groupId>org.tinystruct</groupId>
    <artifactId>tinystruct</artifactId>
    <version>1.7.34</version>
</dependency>
```

> **CẢNH BÁO BẢO MẬT (Prompt Injection):**
> Giá trị trả về của tool được đưa thẳng trở lại context window của mô hình AI. Bạn **PHẢI** validate và sanitize mọi tham số do bên gọi cung cấp trước khi đưa chúng vào chuỗi trả về của tool. Không sanitize đầu vào có thể cho phép kẻ tấn công chèn các chỉ thị đối nghịch (Prompt Injection) ghi đè hành vi của mô hình. Luôn kiểm tra độ dài, tập ký tự và null.

**Để tạo một MCP Tool:**
1. Kế thừa `org.tinystruct.mcp.MCPTool`.
2. Gắn `@Action` cho các thao tác và khai báo tham số bằng `@Argument` trong mảng `arguments`.
3. Nhận tham số dưới dạng đối số method tường minh khớp với các key trong `@Argument`. (KHÔNG dùng `getContext().getAttribute(...)` cho tham số của tool).

```java
import org.tinystruct.mcp.MCPTool;
import org.tinystruct.mcp.MCPException;
import org.tinystruct.system.annotation.Action;
import org.tinystruct.system.annotation.Argument;

public class MyCustomTool extends MCPTool {
    public MyCustomTool() {
        super("custom", "A custom tool for demonstrating MCP");
    }

    @Action(
        value = "custom/hello",
        description = "Say hello to someone",
        arguments = {
            @Argument(key = "name", description = "The name to greet", type = "string", optional = false)
        }
    )
    public String hello(String name) throws MCPException {
        // SECURITY: Validate/sanitize tool inputs before returning to the model
        // to prevent prompt injection vulnerabilities.
        if (name == null || name.length() > 50 || !name.matches("^[a-zA-Z0-9 ]+$")) {
            throw new MCPException("Invalid name provided");
        }
        return "Hello, " + name + "!";
    }
}
```

**Để triển khai một MCP Server:**
1. Kế thừa `org.tinystruct.mcp.MCPServer`.
2. Override `init()` và đăng ký các tool bằng `this.registerTool()`. Framework tự động quét và ánh xạ các method `@Action`.

```java
import org.tinystruct.mcp.MCPServer;

public class MyMCPServer extends MCPServer {
    @Override
    public void init() {
        super.init();
        this.registerTool(new MyCustomTool());
    }

    @Override
    public String version() {
        return "1.0.0";
    }
}
```

Chạy server qua dispatcher:
```bash
bin/dispatcher start --import org.tinystruct.system.HttpServer --import com.example.MyMCPServer
```

### Method của Tool được overload
tinystruct hỗ trợ các method overload cho cùng một tên tool trong `MCPTool` (dùng chung tên tool nhưng nhận các chữ ký tham số khác nhau).
- **Gộp schema (Schema Merging)**: Input schema của mọi overload cùng tên được gộp động thành một JSON schema thống nhất. Các property được lấy hợp, còn các property bắt buộc được lấy giao (chỉ các field bắt buộc trong *tất cả* overload mới vẫn được đánh dấu bắt buộc).
- **Định tuyến thực thi (Execution Routing)**: Khi thực thi một tool, server duyệt tuần tự qua các method overload hiện có và thử thực thi. Việc validate schema của từng method được thực hiện trước, và overload đầu tiên validate thành công với các tham số được cung cấp sẽ được thực thi. Nếu không chữ ký nào khớp hoặc thành công, framework ném exception phù hợp.

## Cấu hình

Các cài đặt được quản lý trong `src/main/resources/application.properties`.

```properties
# Database
driver=org.h2.Driver
database.url=jdbc:h2:~/mydb
database.user=sa
database.password=
# Optional: create missing tables from the class mapping on first use (off by default)
# database.autocreate=true

# Server
default.home.page=hello
server.port=8080
default.server.open_browser=true

# Locale
default.language=en_US

# Session (Redis for clustered environments)
# default.session.repository=org.tinystruct.http.RedisSessionRepository
# redis.host=127.0.0.1
# redis.port=6379

# Programmatic Logging Configuration
logging.enabled=true
logging.level=INFO
org.tinystruct.level=FINE
```

Truy cập giá trị cấu hình trong ứng dụng:
```java
String port = this.getConfiguration("server.port");
```

## Logging và chẩn đoán

Framework có một lớp bao (wrapper) lập trình được quanh `java.util.logging` (JUL), cung cấp output console đẹp mắt và truy vết caller nâng cao ngay từ đầu.

- **Màu ANSI trên console**: Output console được tô màu theo mức log (đỏ cho SEVERE, vàng cho WARNING, xanh lá cho INFO, cyan cho CONFIG, và xám cho log FINE/debug).
- **Truy vết caller chính xác**: Dùng API `StackWalker` của Java để truy vết call stack lúc runtime. Nó xác định và ghi log chính xác class, method, tên file và số dòng của caller đã khởi tạo log (bỏ qua các lớp tiện ích và logging nội bộ).
- **Ghi đè mức theo package/logger**: Đặt các ghi đè riêng cho package trực tiếp trong `application.properties` (ví dụ `org.tinystruct.level=FINE`).

## Dấu hiệu cảnh báo & Anti-pattern

| Triệu chứng | Pattern đúng |
|---|---|
| Import `com.google.gson` hoặc `com.fasterxml.jackson` | Dùng `org.tinystruct.data.component.Builder` / `Builders`. |
| Dùng `List<Builder>` cho JSON array | Dùng `Builders` để tránh các vấn đề type erasure của generic. |
| `ApplicationRuntimeException: template not found` | Gọi `setTemplateRequired(false)` trong `init()` với ứng dụng chỉ làm API. |
| Gắn `@Action` cho method `private` | Action phải là `public` thì framework mới đăng ký. |
| Hardcode `main(String[] args)` trong ứng dụng, hoặc chỉ test qua curl/trình duyệt/run config của IDE | Dùng `bin/dispatcher` làm điểm vào và công cụ dev/test mặc định cho mọi module. |
| Thiếu `bin/dispatcher`, hoặc là script launcher viết tay hay copy | Để framework sinh ra: chạy `org.tinystruct.system.Dispatcher --version` một lần từ thư mục gốc dự án (tạo script cho hệ điều hành hiện tại). |
| `bin/dispatcher` lỗi `ClassNotFoundException: org.tinystruct.system.Dispatcher` trên Windows | Shell script không chạy được dưới Git Bash/MSYS; dùng `bin\dispatcher.cmd` hoặc WSL. |
| `ClassNotFoundException` với `--import a.A,b.B` | Mỗi class một `--import`: `--import a.A --import b.B`. |
| Script launcher shell lỗi `\r: command not found` | File có ký tự xuống dòng CRLF; chuyển `bin/dispatcher` sang LF. |
| Đăng ký `ActionRegistry` thủ công | Ưu tiên annotation `@Action` để được phát hiện tự động. |
| Không tìm thấy action lúc runtime | Đảm bảo class được import qua `--import` hoặc được liệt kê trong `application.properties`. |
| Không thấy tham số CLI | Truyền bằng `--key value`; truy cập qua `getContext().getAttribute("--key")`. |
| Hai method cùng đường dẫn, method chạy sai | Đặt `mode` tường minh (ví dụ `HTTP_GET` so với `HTTP_POST`) để phân biệt. |

## Best practice

1. **`bin/dispatcher` trước tiên**: Phát triển và xác minh với `bin/dispatcher` trước mọi thứ khác — chạy action từ CLI, xác nhận hành vi, rồi mới thêm các vấn đề HTTP/mode. Đó là vòng lặp nội bộ nhanh nhất và là công cụ duy nhất đảm bảo khớp với cách framework thực sự route và bind tham số.
2. **Application chi tiết nhỏ**: Chia logic thành các application nhỏ, tập trung thay vì một class nguyên khối.
3. **Thiết lập trong `init()`**: Dùng `init()` để thiết lập (config, DB) thay vì constructor. KHÔNG gọi `setAction()` — hãy dùng annotation `@Action`.
4. **Nhận thức về Mode**: Dùng tham số `Mode` trong `@Action` để giới hạn các thao tác nhạy cảm chỉ ở `CLI` hoặc các phương thức HTTP cụ thể.
5. **Context thay vì tham số**: Với các flag CLI tùy chọn, dùng `getContext().getAttribute("--flag")` thay vì thêm tham số vào chữ ký method.
6. **Sự kiện bất đồng bộ**: Với tác vụ nặng được kích hoạt bởi sự kiện, dùng `CompletableFuture.runAsync()` bên trong event handler.

## Tài liệu tham chiếu kỹ thuật

Các hướng dẫn chi tiết có trong thư mục `references/`:

- [Architecture & Config](references/architecture.md) — Abstraction, Package Map, Properties
- [Routing & @Action](references/routing.md) — Chi tiết annotation, Mode, tham số
- [Data Handling](references/data-handling.md) — Builder, Builders, serialize & parse JSON
- [Database Persistence](references/database.md) — POJO AbstractData, CRUD, annotation và XML mapping, sinh POJO, tự động tạo bảng
- [System & Usage](references/system-usage.md) — Context, Session, SSE, Upload file, Event, Networking
- [Testing Patterns](references/testing.md) — Unit test JUnit 5 và integration test qua HTTP

## File mã nguồn tham chiếu (nội bộ)

- `src/main/java/org/tinystruct/AbstractApplication.java` — Base class cốt lõi với các lifecycle hook
- `src/main/java/org/tinystruct/system/annotation/Action.java` — Annotation & Mode
- `src/main/java/org/tinystruct/application/ActionRegistry.java` — Engine routing
- `src/main/java/org/tinystruct/data/component/Builder.java` — Bộ serialize JSON object
- `src/main/java/org/tinystruct/data/component/Builders.java` — Bộ serialize JSON array
- `src/main/java/org/tinystruct/data/component/AbstractData.java` — Base class POJO với CRUD
- `src/main/java/org/tinystruct/data/Mapping.java` — Metadata mapping (annotation hoặc XML), được cache theo class
- `src/main/java/org/tinystruct/data/annotation/Table.java` — `@Table`, cùng với `@Id` và `@Column` bên cạnh
- `src/main/java/org/tinystruct/data/tools/TableCreator.java` — Tạo các bảng còn thiếu (`database.autocreate`)
- `src/main/java/org/tinystruct/data/tools/MySQLGenerator.java` — Tham chiếu bộ sinh POJO (`MappingMode` chọn XML hoặc annotation)
- `src/main/java/org/tinystruct/data/component/FieldType.java` — Ánh xạ kiểu SQL sang Java
- `src/main/java/org/tinystruct/data/component/Condition.java` — Bộ dựng truy vấn SQL fluent
- `src/main/java/org/tinystruct/http/SSEPushManager.java` — Quản lý kết nối SSE
- `src/main/java/org/tinystruct/system/logging/LogFormatter.java` — Log formatter tùy chỉnh với màu ANSI console và truy vết caller dựa trên StackWalker
- `src/main/java/org/tinystruct/system/logging/LoggerConfigurer.java` — Bộ cấu hình logging lập trình được từ application properties
- `src/test/java/org/tinystruct/application/ActionRegistryTest.java` — Ví dụ test registry
- `src/test/java/org/tinystruct/system/HttpServerHttpModeTest.java` — Pattern integration test qua HTTP
