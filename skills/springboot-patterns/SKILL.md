---
name: springboot-patterns
description: "Các pattern kiến trúc Spring Boot, thiết kế REST API, service phân tầng, data access, caching, xử lý bất đồng bộ và logging. Dùng cho công việc backend Java Spring Boot. Dùng khi xây dựng hoặc review backend Spring Boot — tầng REST, service, data access, caching hoặc xử lý async."
metadata:
  origin: ECC
---

# Pattern phát triển Spring Boot

Các pattern kiến trúc và API của Spring Boot cho service có khả năng mở rộng, đạt chuẩn production.

## Khi nào kích hoạt

- Xây dựng REST API với Spring MVC hoặc WebFlux
- Tổ chức các tầng controller → service → repository
- Cấu hình Spring Data JPA, caching hoặc xử lý async
- Thêm validation, xử lý exception hoặc phân trang
- Thiết lập profile cho các môi trường dev/staging/production
- Triển khai các pattern hướng sự kiện (event-driven) với Spring Events hoặc Kafka

## Cấu trúc REST API

```java
@RestController
@RequestMapping("/api/markets")
@Validated
class MarketController {
  private final MarketService marketService;

  MarketController(MarketService marketService) {
    this.marketService = marketService;
  }

  @GetMapping
  ResponseEntity<Page<MarketResponse>> list(
      @RequestParam(defaultValue = "0") int page,
      @RequestParam(defaultValue = "20") int size) {
    Page<Market> markets = marketService.list(PageRequest.of(page, size));
    return ResponseEntity.ok(markets.map(MarketResponse::from));
  }

  @PostMapping
  ResponseEntity<MarketResponse> create(@Valid @RequestBody CreateMarketRequest request) {
    Market market = marketService.create(request);
    return ResponseEntity.status(HttpStatus.CREATED).body(MarketResponse.from(market));
  }
}
```

## Repository Pattern (Spring Data JPA)

```java
public interface MarketRepository extends JpaRepository<MarketEntity, Long> {
  @Query("select m from MarketEntity m where m.status = :status order by m.volume desc")
  List<MarketEntity> findActive(@Param("status") MarketStatus status, Pageable pageable);
}
```

## Tầng Service với Transaction

```java
@Service
public class MarketService {
  private final MarketRepository repo;

  public MarketService(MarketRepository repo) {
    this.repo = repo;
  }

  @Transactional
  public Market create(CreateMarketRequest request) {
    MarketEntity entity = MarketEntity.from(request);
    MarketEntity saved = repo.save(entity);
    return Market.from(saved);
  }
}
```

## DTO và Validation

```java
public record CreateMarketRequest(
    @NotBlank @Size(max = 200) String name,
    @NotBlank @Size(max = 2000) String description,
    @NotNull @FutureOrPresent Instant endDate,
    @NotEmpty List<@NotBlank String> categories) {}

public record MarketResponse(Long id, String name, MarketStatus status) {
  static MarketResponse from(Market market) {
    return new MarketResponse(market.id(), market.name(), market.status());
  }
}
```

## Xử lý Exception

```java
@ControllerAdvice
class GlobalExceptionHandler {
  @ExceptionHandler(MethodArgumentNotValidException.class)
  ResponseEntity<ApiError> handleValidation(MethodArgumentNotValidException ex) {
    String message = ex.getBindingResult().getFieldErrors().stream()
        .map(e -> e.getField() + ": " + e.getDefaultMessage())
        .collect(Collectors.joining(", "));
    return ResponseEntity.badRequest().body(ApiError.validation(message));
  }

  @ExceptionHandler(AccessDeniedException.class)
  ResponseEntity<ApiError> handleAccessDenied() {
    return ResponseEntity.status(HttpStatus.FORBIDDEN).body(ApiError.of("Forbidden"));
  }

  @ExceptionHandler(Exception.class)
  ResponseEntity<ApiError> handleGeneric(Exception ex) {
    // Log unexpected errors with stack traces
    return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
        .body(ApiError.of("Internal server error"));
  }
}
```

## Caching

Yêu cầu `@EnableCaching` trên một class cấu hình.

```java
@Service
public class MarketCacheService {
  private final MarketRepository repo;

  public MarketCacheService(MarketRepository repo) {
    this.repo = repo;
  }

  @Cacheable(value = "market", key = "#id")
  public Market getById(Long id) {
    return repo.findById(id)
        .map(Market::from)
        .orElseThrow(() -> new EntityNotFoundException("Market not found"));
  }

  @CacheEvict(value = "market", key = "#id")
  public void evict(Long id) {}
}
```

## Xử lý bất đồng bộ (Async)

Yêu cầu `@EnableAsync` trên một class cấu hình.

```java
@Service
public class NotificationService {
  @Async
  public CompletableFuture<Void> sendAsync(Notification notification) {
    // send email/SMS
    return CompletableFuture.completedFuture(null);
  }
}
```

## Logging (SLF4J)

```java
@Service
public class ReportService {
  private static final Logger log = LoggerFactory.getLogger(ReportService.class);

  public Report generate(Long marketId) {
    log.info("generate_report marketId={}", marketId);
    try {
      // logic
    } catch (Exception ex) {
      log.error("generate_report_failed marketId={}", marketId, ex);
      throw ex;
    }
    return new Report();
  }
}
```

## Middleware / Filter

```java
@Component
public class RequestLoggingFilter extends OncePerRequestFilter {
  private static final Logger log = LoggerFactory.getLogger(RequestLoggingFilter.class);

  @Override
  protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response,
      FilterChain filterChain) throws ServletException, IOException {
    long start = System.currentTimeMillis();
    try {
      filterChain.doFilter(request, response);
    } finally {
      long duration = System.currentTimeMillis() - start;
      log.info("req method={} uri={} status={} durationMs={}",
          request.getMethod(), request.getRequestURI(), response.getStatus(), duration);
    }
  }
}
```

## Phân trang và sắp xếp

```java
PageRequest page = PageRequest.of(pageNumber, pageSize, Sort.by("createdAt").descending());
Page<Market> results = marketService.list(page);
```

## Gọi dịch vụ bên ngoài có khả năng chịu lỗi

```java
public <T> T withRetry(Supplier<T> supplier, int maxRetries) {
  int attempts = 0;
  while (true) {
    try {
      return supplier.get();
    } catch (Exception ex) {
      attempts++;
      if (attempts >= maxRetries) {
        throw ex;
      }
      try {
        Thread.sleep((long) Math.pow(2, attempts) * 100L);
      } catch (InterruptedException ie) {
        Thread.currentThread().interrupt();
        throw ex;
      }
    }
  }
}
```

## Rate Limiting (Filter + Bucket4j)

**Lưu ý bảo mật**: Header `X-Forwarded-For` mặc định không đáng tin cậy vì client có thể giả mạo nó.
Chỉ dùng các forwarded header khi:
1. Ứng dụng của bạn nằm sau một reverse proxy đáng tin cậy (nginx, AWS ALB, v.v.)
2. Bạn đã đăng ký `ForwardedHeaderFilter` như một bean
3. Bạn đã cấu hình `server.forward-headers-strategy=NATIVE` hoặc `FRAMEWORK` trong application properties
4. Proxy của bạn được cấu hình để ghi đè (không phải nối thêm vào) header `X-Forwarded-For`

Khi `ForwardedHeaderFilter` được cấu hình đúng, `request.getRemoteAddr()` sẽ tự động
trả về đúng IP của client từ các forwarded header. Nếu không có cấu hình này, hãy dùng
trực tiếp `request.getRemoteAddr()` — nó trả về IP của kết nối trực tiếp, đây là giá trị duy nhất
đáng tin cậy.

```java
@Component
public class RateLimitFilter extends OncePerRequestFilter {
  private final Map<String, Bucket> buckets = new ConcurrentHashMap<>();

  /*
   * SECURITY: This filter uses request.getRemoteAddr() to identify clients for rate limiting.
   *
   * If your application is behind a reverse proxy (nginx, AWS ALB, etc.), you MUST configure
   * Spring to handle forwarded headers properly for accurate client IP detection:
   *
   * 1. Set server.forward-headers-strategy=NATIVE (for cloud platforms) or FRAMEWORK in
   *    application.properties/yaml
   * 2. If using FRAMEWORK strategy, register ForwardedHeaderFilter:
   *
   *    @Bean
   *    ForwardedHeaderFilter forwardedHeaderFilter() {
   *        return new ForwardedHeaderFilter();
   *    }
   *
   * 3. Ensure your proxy overwrites (not appends) the X-Forwarded-For header to prevent spoofing
   * 4. Configure server.tomcat.remoteip.trusted-proxies or equivalent for your container
   *
   * Without this configuration, request.getRemoteAddr() returns the proxy IP, not the client IP.
   * Do NOT read X-Forwarded-For directly—it is trivially spoofable without trusted proxy handling.
   */
  @Override
  protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response,
      FilterChain filterChain) throws ServletException, IOException {
    // Use getRemoteAddr() which returns the correct client IP when ForwardedHeaderFilter
    // is configured, or the direct connection IP otherwise. Never trust X-Forwarded-For
    // headers directly without proper proxy configuration.
    String clientIp = request.getRemoteAddr();

    Bucket bucket = buckets.computeIfAbsent(clientIp,
        k -> Bucket.builder()
            .addLimit(Bandwidth.classic(100, Refill.greedy(100, Duration.ofMinutes(1))))
            .build());

    if (bucket.tryConsume(1)) {
      filterChain.doFilter(request, response);
    } else {
      response.setStatus(HttpStatus.TOO_MANY_REQUESTS.value());
    }
  }
}
```

## Background Job

Dùng `@Scheduled` của Spring hoặc tích hợp với queue (ví dụ Kafka, SQS, RabbitMQ). Giữ các handler idempotent và có thể quan sát (observable).

## Observability

- Structured logging (JSON) qua Logback encoder
- Metrics: Micrometer + Prometheus/OTel
- Tracing: Micrometer Tracing với backend OpenTelemetry hoặc Brave

## Mặc định cho Production

- Ưu tiên constructor injection, tránh field injection
- Bật `spring.mvc.problemdetails.enabled=true` cho lỗi theo RFC 7807 (Spring Boot 3+)
- Cấu hình kích thước pool HikariCP theo workload, đặt timeout
- Dùng `@Transactional(readOnly = true)` cho các truy vấn
- Đảm bảo null-safety qua `@NonNull` và `Optional` khi phù hợp

**Hãy nhớ**: Giữ controller mỏng, service tập trung, repository đơn giản và xử lý lỗi tập trung. Tối ưu cho khả năng bảo trì và khả năng test.
