---
name: java-coding-standards
description: "Chuẩn coding Java cho các service Spring Boot và Quarkus: đặt tên, immutability, dùng Optional, stream, exception, generics, CDI, reactive pattern và bố cục dự án. Tự động áp dụng các convention riêng của framework. Dùng khi viết hoặc review Java trong một service Spring Boot hoặc Quarkus."
metadata:
  origin: ECC
---

# Chuẩn coding Java

Các chuẩn cho code Java (17+) dễ đọc, dễ bảo trì trong các service Spring Boot và Quarkus.

## Khi nào dùng

- Viết hoặc review code Java trong các dự án Spring Boot hoặc Quarkus
- Thực thi các convention về đặt tên, bất biến (immutable) hoặc xử lý exception
- Làm việc với record, sealed class hoặc pattern matching (Java 17+)
- Review việc dùng Optional, stream hoặc generics
- Cấu trúc package và bố cục dự án
- **[QUARKUS]**: Làm việc với CDI scope, Panache entity hoặc reactive pipeline

## Cách hoạt động

### Phát hiện framework

Trước khi áp dụng các chuẩn, xác định framework từ file build:

- File build chứa `quarkus` → áp dụng convention **[QUARKUS]**
- File build chứa `spring-boot` → áp dụng convention **[SPRING]**
- Không phát hiện được cái nào → chỉ áp dụng các convention dùng chung

## Nguyên tắc cốt lõi

- Ưu tiên sự rõ ràng hơn sự khôn khéo
- Bất biến (immutable) theo mặc định; giảm thiểu shared mutable state
- Fail fast với các exception có ý nghĩa
- Đặt tên và cấu trúc package nhất quán
- **[QUARKUS]**: Ưu tiên xử lý lúc build hơn lúc runtime; tránh runtime reflection khi có thể

## Ví dụ

Các phần bên dưới trình bày các ví dụ cụ thể cho Spring Boot, Quarkus và Java dùng chung
về đặt tên, immutability, dependency injection, code reactive, exception,
bố cục dự án, logging, cấu hình (configuration) và test.

## Đặt tên

```java
// PASS: Classes/Records: PascalCase
public class MarketService {}
public record Money(BigDecimal amount, Currency currency) {}

// PASS: Methods/fields: camelCase
private final MarketRepository marketRepository;
public Market findBySlug(String slug) {}

// PASS: Constants: UPPER_SNAKE_CASE
private static final int MAX_PAGE_SIZE = 100;

// PASS: [QUARKUS] JAX-RS resources named as *Resource, not *Controller
public class MarketResource {}

// PASS: [SPRING] REST controllers named as *Controller
public class MarketController {}
```

## Immutability

```java
// PASS: Favor records and final fields
public record MarketDto(Long id, String name, MarketStatus status) {}

public class Market {
  private final Long id;
  private final String name;
  // getters only, no setters
}

// PASS: [QUARKUS] Panache active-record entities use public fields (Quarkus convention)
@Entity
public class Market extends PanacheEntity {
  public String name;
  public MarketStatus status;
  // Panache generates accessors at build time; public fields are idiomatic here
}

// PASS: [QUARKUS] Panache MongoDB entities
@MongoEntity(collection = "markets")
public class Market extends PanacheMongoEntity {
  public String name;
  public MarketStatus status;
}
```

## Dùng Optional

```java
// PASS: Return Optional from find* methods
// [SPRING]
Optional<Market> market = marketRepository.findBySlug(slug);

// [QUARKUS] Panache
Optional<Market> market = Market.find("slug", slug).firstResultOptional();

// PASS: Map/flatMap instead of get()
return market
    .map(MarketResponse::from)
    .orElseThrow(() -> new EntityNotFoundException("Market not found"));
```

## Best Practice cho Stream

```java
// PASS: Use streams for transformations, keep pipelines short
List<String> names = markets.stream()
    .map(Market::name)
    .filter(Objects::nonNull)
    .toList();

// FAIL: Avoid complex nested streams; prefer loops for clarity
```

## Dependency Injection

```java
// PASS: [SPRING] Constructor injection (preferred over @Autowired on fields)
@Service
public class MarketService {
  private final MarketRepository marketRepository;

  public MarketService(MarketRepository marketRepository) {
    this.marketRepository = marketRepository;
  }
}

// PASS: [QUARKUS] Constructor injection
@ApplicationScoped
public class MarketService {
  private final MarketRepository marketRepository;

  @Inject
  public MarketService(MarketRepository marketRepository) {
    this.marketRepository = marketRepository;
  }
}

// PASS: [QUARKUS] Package-private field injection (acceptable in Quarkus — avoids proxy issues)
@ApplicationScoped
public class MarketService {
  @Inject
  MarketRepository marketRepository;
}

// FAIL: [SPRING] Field injection with @Autowired
@Autowired
private MarketRepository marketRepository; // use constructor injection

// FAIL: [QUARKUS] @Singleton when interception or lazy init is needed
@Singleton // non-proxyable — use @ApplicationScoped instead
public class MarketService {}
```

## Reactive Pattern [QUARKUS]

```java
// PASS: Return Uni/Multi from reactive endpoints
@GET
@Path("/{slug}")
public Uni<Market> findBySlug(@PathParam("slug") String slug) {
  return Market.find("slug", slug)
      .<Market>firstResult()
      .onItem().ifNull().failWith(() -> new MarketNotFoundException(slug));
}

// PASS: Non-blocking pipeline composition
public Uni<OrderConfirmation> placeOrder(OrderRequest req) {
  return validateOrder(req)
      .chain(valid -> persistOrder(valid))
      .chain(order -> notifyFulfillment(order));
}

// FAIL: Blocking call inside a Uni/Multi pipeline
public Uni<Market> find(String slug) {
  Market m = Market.find("slug", slug).firstResult(); // BLOCKING — breaks event loop
  return Uni.createFrom().item(m);
}

// FAIL: Subscribing more than once to a shared Uni
Uni<Market> shared = fetchMarket(slug);
shared.subscribe().with(m -> log(m));
shared.subscribe().with(m -> cache(m)); // double subscribe — use Uni.memoize()
```

## Exception

- Dùng unchecked exception cho lỗi domain; bọc các exception kỹ thuật kèm context
- Tạo các exception riêng cho domain (ví dụ: `MarketNotFoundException`)
- Tránh `catch (Exception ex)` quá rộng trừ khi rethrow/log tập trung

```java
throw new MarketNotFoundException(slug);
```

### Xử lý exception tập trung

```java
// [SPRING]
@RestControllerAdvice
public class GlobalExceptionHandler {
  @ExceptionHandler(MarketNotFoundException.class)
  public ResponseEntity<ErrorResponse> handle(MarketNotFoundException ex) {
    return ResponseEntity.status(404).body(ErrorResponse.from(ex));
  }
}

// [QUARKUS] Option A: ExceptionMapper
@Provider
public class MarketNotFoundMapper implements ExceptionMapper<MarketNotFoundException> {
  @Override
  public Response toResponse(MarketNotFoundException ex) {
    return Response.status(404).entity(ErrorResponse.from(ex)).build();
  }
}

// [QUARKUS] Option B: @ServerExceptionMapper (RESTEasy Reactive)
@ServerExceptionMapper
public RestResponse<ErrorResponse> handle(MarketNotFoundException ex) {
  return RestResponse.status(Status.NOT_FOUND, ErrorResponse.from(ex));
}
```

## Generics và an toàn kiểu (Type Safety)

- Tránh raw type; khai báo tham số generic
- Ưu tiên bounded generics cho các utility tái sử dụng

```java
public <T extends Identifiable> Map<Long, T> indexById(Collection<T> items) { ... }
```

## Cấu trúc dự án

### [SPRING] Maven/Gradle

```
src/main/java/com/example/app/
  config/
  controller/
  service/
  repository/
  domain/
  dto/
  util/
src/main/resources/
  application.yml
src/test/java/... (mirrors main)
```

### [QUARKUS] Maven/Gradle

```
src/main/java/com/example/app/
  config/              # @ConfigMapping, @ConfigProperty beans, Producers
  resource/            # JAX-RS resources (not "controller")
  service/
  repository/          # PanacheRepository implementations (if not using active record)
  domain/              # JPA/Panache entities, MongoDB entities
  dto/
  util/
  mapper/              # MapStruct mappers (if used)
src/main/resources/
  application.properties   # Quarkus convention (YAML supported with quarkus-config-yaml)
  import.sql               # Hibernate auto-import for dev/test
src/test/java/... (mirrors main)
```

## Định dạng và style

- Dùng 2 hoặc 4 dấu cách nhất quán (theo chuẩn của dự án)
- Mỗi file một top-level type public
- Giữ method ngắn và tập trung; tách các helper
- Thứ tự thành viên: hằng số, field, constructor, method public, protected, private

## Code Smell cần tránh

- Danh sách tham số dài → dùng DTO/builder
- Lồng sâu → dùng early return
- Magic number → hằng số có tên
- Static mutable state → ưu tiên dependency injection
- Khối catch im lặng → log và xử lý hoặc rethrow
- **[QUARKUS]**: `@Singleton` ở chỗ định dùng `@ApplicationScoped` — làm hỏng proxy và interception
- **[QUARKUS]**: Trộn lẫn `quarkus-resteasy-reactive` và `quarkus-resteasy` (classic) — chọn một stack
- **[QUARKUS]**: Panache active-record + repository pattern trong cùng một bounded context — chọn một

## Logging

```java
// [SPRING] SLF4J
private static final Logger log = LoggerFactory.getLogger(MarketService.class);
log.info("fetch_market slug={}", slug);
log.error("failed_fetch_market slug={}", slug, ex);

// [QUARKUS] JBoss Logging (default, zero-cost at build time)
private static final Logger log = Logger.getLogger(MarketService.class);
log.infof("fetch_market slug=%s", slug);
log.errorf(ex, "failed_fetch_market slug=%s", slug);

// [QUARKUS] Alternative: simplified logging with @Inject
@Inject
Logger log; // CDI-injected, scoped to declaring class
```

## Xử lý Null

- Chỉ chấp nhận `@Nullable` khi không thể tránh; còn lại dùng `@NonNull`
- Dùng Bean Validation (`@NotNull`, `@NotBlank`) trên đầu vào
- **[QUARKUS]**: Áp dụng `@Valid` trên `@BeanParam`, `@RestForm` và các tham số request body

## Cấu hình (Configuration)

```java
// [SPRING] @ConfigurationProperties
@ConfigurationProperties(prefix = "market")
public record MarketProperties(int maxPageSize, Duration cacheTtl) {}

// [QUARKUS] @ConfigMapping (type-safe, build-time validated)
@ConfigMapping(prefix = "market")
public interface MarketConfig {
  int maxPageSize();
  Duration cacheTtl();
}

// [QUARKUS] Simple values with @ConfigProperty
@ConfigProperty(name = "market.max-page-size", defaultValue = "100")
int maxPageSize;
```

## Kỳ vọng về Testing

### Dùng chung
- JUnit 5 + AssertJ cho fluent assertion
- Mockito để mock; tránh partial mock khi có thể
- Ưu tiên test có tính xác định (deterministic); không sleep ẩn

### [SPRING]
- `@WebMvcTest` cho controller slice, `@DataJpaTest` cho repository slice
- `@SpringBootTest` dành riêng cho integration test đầy đủ
- `@MockBean` để thay thế bean trong Spring context

### [QUARKUS]
- JUnit 5 + Mockito thuần cho unit test (không dùng `@QuarkusTest`)
- `@QuarkusTest` dành riêng cho CDI integration test
- `@InjectMock` để thay thế CDI bean trong integration test
- Dev Services cho database/Kafka/Redis — tránh thiết lập Testcontainers thủ công khi Dev Services đã đủ
- `@QuarkusTestResource` cho vòng đời dịch vụ bên ngoài tùy chỉnh

```java
// [SPRING] Controller test
@WebMvcTest(MarketController.class)
class MarketControllerTest {
  @Autowired MockMvc mockMvc;
  @MockBean MarketService marketService;
}

// [QUARKUS] Integration test
@QuarkusTest
class MarketResourceTest {
  @InjectMock
  MarketService marketService;

  @Test
  void should_return_404_when_market_not_found() {
    given().when().get("/markets/unknown").then().statusCode(404);
  }
}

// [QUARKUS] Unit test (no CDI, no @QuarkusTest)
@ExtendWith(MockitoExtension.class)
class MarketServiceTest {
  @Mock MarketRepository marketRepository;
  @InjectMocks MarketService marketService;
}
```

**Hãy nhớ**: Giữ code có chủ đích, có kiểu rõ ràng và quan sát được (observable). Tối ưu cho khả năng bảo trì hơn là micro-optimization trừ khi được chứng minh là cần thiết.
