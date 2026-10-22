---
name: quarkus-patterns
description: Các pattern kiến trúc Quarkus 3.x LTS với Camel cho messaging, thiết kế RESTful API, CDI service, data access với Panache và xử lý bất đồng bộ (async). Dùng cho công việc backend Java Quarkus với kiến trúc event-driven. Dùng khi xây dựng hoặc review một Quarkus service, đặc biệt với Camel messaging hoặc Panache data access.
metadata:
  origin: ECC
---

# Các pattern phát triển Quarkus

Các pattern kiến trúc và API của Quarkus 3.x cho service cloud-native, event-driven với Apache Camel.

## Khi nào kích hoạt

- Xây dựng REST API với JAX-RS hoặc RESTEasy Reactive
- Cấu trúc các layer resource → service → repository
- Triển khai các pattern event-driven với Apache Camel và RabbitMQ
- Cấu hình Hibernate Panache, caching hoặc reactive stream
- Thêm validation, exception mapping hoặc phân trang
- Thiết lập profile cho môi trường dev/staging/production (cấu hình YAML)
- Logging tùy chỉnh với LogContext và Logback/Logstash encoder
- Làm việc với CompletableFuture cho các thao tác async
- Triển khai xử lý luồng có điều kiện (conditional flow)
- Làm việc với biên dịch native của GraalVM

## Service Layer với nhiều Dependency

```java
@Slf4j
@ApplicationScoped
@RequiredArgsConstructor
public class OrderProcessingService {

    private final OrderValidator orderValidator;
    private final EventService eventService;
    private final OrderRepository orderRepository;
    private final FulfillmentPublisher fulfillmentPublisher;
    private final AuditPublisher auditPublisher;

    @Transactional
    public OrderReceipt process(CreateOrderCommand command) {
        ValidationResult validation = orderValidator.validate(command);
        if (!validation.valid()) {
            eventService.createErrorEvent(command, "ORDER_REJECTED", validation.message());
            throw new WebApplicationException(validation.message(), Response.Status.BAD_REQUEST);
        }

        Order order = Order.from(command);
        orderRepository.persist(order);

        OrderReceipt receipt = OrderReceipt.from(order);
        fulfillmentPublisher.publishAsync(receipt);
        auditPublisher.publish("ORDER_ACCEPTED", receipt);
        eventService.createSuccessEvent(receipt, "ORDER_ACCEPTED");

        log.info("Processed order {}", order.id);
        return receipt;
    }
}
```

**Các pattern chính:**
- `@RequiredArgsConstructor` cho constructor injection qua Lombok
- `@Slf4j` cho logging bằng Logback
- `@Transactional` trên các method của service có ghi dữ liệu qua Panache hoặc repository
- Validate input trước khi lưu dữ liệu hoặc publish message
- Theo dõi event cho các kịch bản thành công/lỗi
- Publish message Camel bất đồng bộ

## Pattern Logging Context tùy chỉnh (Logback)

```java
@ApplicationScoped
public class ProcessingService {

    public void processDocument(Document doc) {
        LogContext logContext = CustomLog.getCurrentContext();
        try (SafeAutoCloseable ignored = CustomLog.startScope(logContext)) {
            // Add context to all log statements
            logContext.put("documentId", doc.getId().toString());
            logContext.put("documentType", doc.getType());
            logContext.put("userId", SecurityContext.getUserId());

            log.info("Starting document processing");

            // All logs within this scope inherit the context
            processInternal(doc);

            log.info("Document processing completed");
        } catch (Exception e) {
            log.error("Document processing failed", e);
            throw e;
        }
    }
}
```

**Cấu hình Logback (logback.xml):**

```xml
<configuration>
    <appender name="CONSOLE" class="ch.qos.logback.core.ConsoleAppender">
        <encoder class="net.logstash.logback.encoder.LogstashEncoder">
            <includeContext>true</includeContext>
            <includeMdc>true</includeMdc>
        </encoder>
    </appender>

    <logger name="com.example" level="INFO"/>
    <root level="WARN">
        <appender-ref ref="CONSOLE"/>
    </root>
</configuration>
```

## Pattern Event Service

```java
@Slf4j
@ApplicationScoped
@RequiredArgsConstructor
public class EventService {
    private final EventRepository eventRepository;
    private final ObjectMapper objectMapper;

    public void createSuccessEvent(Object payload, String eventType) {
        Objects.requireNonNull(payload, "Payload cannot be null");
        Event event = new Event();
        event.setType(eventType);
        event.setStatus(EventStatus.SUCCESS);
        event.setPayload(serializePayload(payload));
        event.setTimestamp(Instant.now());

        eventRepository.persist(event);
        log.info("Success event created: {}", eventType);
    }

    public void createErrorEvent(Object payload, String eventType, String errorMessage) {
        Objects.requireNonNull(payload, "Payload cannot be null");
        if (errorMessage == null || errorMessage.isBlank()) {
            throw new IllegalArgumentException("Error message cannot be blank");
        }
        Event event = new Event();
        event.setType(eventType);
        event.setStatus(EventStatus.ERROR);
        event.setErrorMessage(errorMessage);
        event.setPayload(serializePayload(payload));
        event.setTimestamp(Instant.now());

        eventRepository.persist(event);
        log.error("Error event created: {} - {}", eventType, errorMessage);
    }

    private String serializePayload(Object payload) {
        try {
            return objectMapper.writeValueAsString(payload);
        } catch (JsonProcessingException e) {
            throw new IllegalStateException("Failed to serialize event payload", e);
        }
    }
}
```

## Publish message với Camel (RabbitMQ)

```java
@Slf4j
@ApplicationScoped
@RequiredArgsConstructor
public class BusinessRulesPublisher {
    private final ProducerTemplate producerTemplate;

    public void publishSync(BusinessRulesPayload payload) {
        producerTemplate.sendBody(
            "direct:business-rules-publisher",
            payload
        );
    }
}
```

**Cấu hình Camel Route:**

```java
@ApplicationScoped
public class BusinessRulesRoute extends RouteBuilder {

    @ConfigProperty(name = "camel.rabbitmq.queue.business-rules")
    String businessRulesQueue;

    @ConfigProperty(name = "rabbitmq.host")
    String rabbitHost;

    @ConfigProperty(name = "rabbitmq.port")
    Integer rabbitPort;

    @Override
    public void configure() {
        from("direct:business-rules-publisher")
            .routeId("business-rules-publisher")
            .log("Publishing message to RabbitMQ: ${body}")
            .marshal().json(JsonLibrary.Jackson)
            .toF("spring-rabbitmq:%s?hostname=%s&portNumber=%d",
                businessRulesQueue, rabbitHost, rabbitPort);
    }
}
```

## Camel Direct Route (In-Memory)

```java
@ApplicationScoped
public class DocumentProcessingRoute extends RouteBuilder {

    @Override
    public void configure() {
        // Error handling
        onException(ValidationException.class)
            .handled(true)
            .to("direct:validation-error-handler")
            .log("Validation error: ${exception.message}");

        // Main processing route
        from("direct:process-document")
            .routeId("document-processing")
            .log("Processing document: ${header.documentId}")
            .bean(DocumentValidator.class, "validate")
            .bean(DocumentTransformer.class, "transform")
            .choice()
                .when(header("documentType").isEqualTo("INVOICE"))
                    .to("direct:process-invoice")
                .when(header("documentType").isEqualTo("CREDIT_NOTE"))
                    .to("direct:process-credit-note")
                .otherwise()
                    .to("direct:process-generic")
            .end();

        from("direct:validation-error-handler")
            .bean(EventService.class, "createErrorEvent")
            .log("Validation error handled");
    }
}
```

## Xử lý file với Camel

```java
@ApplicationScoped
public class FileMonitoringRoute extends RouteBuilder {

    @ConfigProperty(name = "file.input.directory")
    String inputDirectory;

    @ConfigProperty(name = "file.processed.directory")
    String processedDirectory;

    @ConfigProperty(name = "file.error.directory")
    String errorDirectory;

    @Override
    public void configure() {
        from("file:" + inputDirectory + "?move=" + processedDirectory +
             "&moveFailed=" + errorDirectory + "&delay=5000")
            .routeId("file-monitor")
            .log("Processing file: ${header.CamelFileName}")
            .to("direct:process-file");

        from("direct:process-file")
            .bean(OrderProcessingService.class, "processFile")
            .log("File processing completed");
    }
}
```

## Gọi Bean trong Camel

```java
@ApplicationScoped
public class InvoiceRoute extends RouteBuilder {

    @Override
    public void configure() {
        from("direct:invoice-validation")
            .bean(InvoiceFlowValidator.class, "validateFlowWithConfig")
            .log("Validation result: ${body}");

        from("direct:persist-and-publish")
            .bean(DocumentJobService.class, "createDocumentAndJobEntities")
            .bean(BusinessRulesPublisher.class, "publishAsync")
            .bean(EventService.class, "createSuccessEvent(${body}, 'PUBLISHED')");
    }
}
```

## Cấu trúc REST API

```java
@Path("/api/documents")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
@RequiredArgsConstructor
public class DocumentResource {
  private final DocumentService documentService;

  @GET
  public Response list(
      @QueryParam("page") @DefaultValue("0") int page,
      @QueryParam("size") @DefaultValue("20") int size) {
    List<Document> documents = documentService.list(page, size);
    return Response.ok(documents).build();
  }

  @POST
  public Response create(@Valid CreateDocumentRequest request, @Context UriInfo uriInfo) {
    Document document = documentService.create(request);
    URI location = uriInfo.getAbsolutePathBuilder()
        .path(String.valueOf(document.id))
        .build();
    return Response.created(location).entity(DocumentResponse.from(document)).build();
  }

  @GET
  @Path("/{id}")
  public Response getById(@PathParam("id") Long id) {
    return documentService.findById(id)
        .map(DocumentResponse::from)
        .map(Response::ok)
        .orElse(Response.status(Response.Status.NOT_FOUND))
        .build();
  }
}
```

## Pattern Repository (Panache Repository)

```java
@ApplicationScoped
public class DocumentRepository implements PanacheRepository<Document> {

  public List<Document> findByStatus(DocumentStatus status, int page, int size) {
    return find("status = ?1 order by createdAt desc", status)
        .page(page, size)
        .list();
  }

  public Optional<Document> findByReferenceNumber(String referenceNumber) {
    return find("referenceNumber", referenceNumber).firstResultOptional();
  }

  public long countByStatusAndDate(DocumentStatus status, LocalDate date) {
    return count("status = ?1 and createdAt >= ?2", status, date.atStartOfDay());
  }
}
```

## Service Layer với Transaction

```java
@ApplicationScoped
@RequiredArgsConstructor
public class DocumentService {
  private final DocumentRepository repo;
  private final EventService eventService;

  @Transactional
  public Document create(CreateDocumentRequest request) {
    Document document = new Document();
    document.setReferenceNumber(request.referenceNumber());
    document.setDescription(request.description());
    document.setStatus(DocumentStatus.PENDING);
    document.setCreatedAt(Instant.now());

    repo.persist(document);

    eventService.createSuccessEvent(document, "DOCUMENT_CREATED");

    return document;
  }

  public Optional<Document> findById(Long id) {
    return repo.findByIdOptional(id);
  }

  public List<Document> list(int page, int size) {
    return repo.findAll()
        .page(page, size)
        .list();
  }
}
```

## DTO và Validation

```java
public record CreateDocumentRequest(
    @NotBlank @Size(max = 200) String referenceNumber,
    @NotBlank @Size(max = 2000) String description,
    @NotNull @FutureOrPresent Instant validUntil,
    @NotEmpty List<@NotBlank String> categories) {}

public record DocumentResponse(Long id, String referenceNumber, DocumentStatus status) {
  public static DocumentResponse from(Document document) {
    return new DocumentResponse(document.getId(), document.getReferenceNumber(),
        document.getStatus());
  }
}
```

## Exception Mapping

```java
@Provider
public class ValidationExceptionMapper implements ExceptionMapper<ConstraintViolationException> {
  @Override
  public Response toResponse(ConstraintViolationException exception) {
    String message = exception.getConstraintViolations().stream()
        .map(cv -> cv.getPropertyPath() + ": " + cv.getMessage())
        .collect(Collectors.joining(", "));

    return Response.status(Response.Status.BAD_REQUEST)
        .entity(Map.of("error", "validation_error", "message", message))
        .build();
  }
}

@Provider
@Slf4j
public class GenericExceptionMapper implements ExceptionMapper<Exception> {

  @Override
  public Response toResponse(Exception exception) {
    log.error("Unhandled exception", exception);
    return Response.status(Response.Status.INTERNAL_SERVER_ERROR)
        .entity(Map.of("error", "internal_error", "message", "An unexpected error occurred"))
        .build();
  }
}
```

## Thao tác Async với CompletableFuture

```java
@Slf4j
@ApplicationScoped
@RequiredArgsConstructor
public class FileStorageService {
    private final S3Client s3Client;
    private final ExecutorService executorService;

    @ConfigProperty(name = "storage.bucket-name")
    String bucketName;

    public CompletableFuture<StoredDocumentInfo> uploadOriginalFile(
            InputStream inputStream,
            long size,
            LogContext logContext,
            InvoiceFormat format) {

        return CompletableFuture.supplyAsync(() -> {
            try (SafeAutoCloseable ignored = CustomLog.startScope(logContext)) {
                String path = generateStoragePath(format);

                PutObjectRequest request = PutObjectRequest.builder()
                    .bucket(bucketName)
                    .key(path)
                    .contentLength(size)
                    .build();

                s3Client.putObject(request, RequestBody.fromInputStream(inputStream, size));

                log.info("File uploaded to S3: {}", path);

                return new StoredDocumentInfo(path, size, Instant.now());
            } catch (Exception e) {
                log.error("Failed to upload file to S3", e);
                throw new StorageException("Upload failed", e);
            }
        }, executorService);
    }
}
```

## Caching

```java
@ApplicationScoped
@RequiredArgsConstructor
public class DocumentCacheService {
  private final DocumentRepository repo;

  @CacheResult(cacheName = "document-cache")
  public Optional<Document> getById(@CacheKey Long id) {
    return repo.findByIdOptional(id);
  }

  @CacheInvalidate(cacheName = "document-cache")
  public void evict(@CacheKey Long id) {}

  @CacheInvalidateAll(cacheName = "document-cache")
  public void evictAll() {}
}
```

## Cấu hình bằng YAML

```yaml
# application.yml
"%dev":
  quarkus:
    datasource:
      jdbc:
        url: jdbc:postgresql://localhost:5432/dev_db
      username: dev_user
      password: ${DB_PASSWORD}
    hibernate-orm:
      database:
        generation: drop-and-create

  rabbitmq:
    host: localhost
    port: 5672
    username: ${RABBITMQ_USER}
    password: ${RABBITMQ_PASSWORD}

"%test":
  quarkus:
    datasource:
      jdbc:
        url: jdbc:h2:mem:test
    hibernate-orm:
      database:
        generation: drop-and-create

"%prod":
  quarkus:
    datasource:
      jdbc:
        url: ${DATABASE_URL}
      username: ${DB_USER}
      password: ${DB_PASSWORD}
    hibernate-orm:
      database:
        generation: validate

  rabbitmq:
    host: ${RABBITMQ_HOST}
    port: ${RABBITMQ_PORT}
    username: ${RABBITMQ_USER}
    password: ${RABBITMQ_PASSWORD}

# Camel configuration
camel:
  rabbitmq:
    queue:
      business-rules: business-rules-queue
      invoice-processing: invoice-processing-queue
```

## Health Check

```java
@Readiness
@ApplicationScoped
@RequiredArgsConstructor
public class DatabaseHealthCheck implements HealthCheck {
  private final AgroalDataSource dataSource;

  @Override
  public HealthCheckResponse call() {
    try (Connection conn = dataSource.getConnection()) {
      boolean valid = conn.isValid(2);
      return HealthCheckResponse.named("Database connection")
          .status(valid)
          .build();
    } catch (SQLException e) {
      return HealthCheckResponse.down("Database connection");
    }
  }
}

@Liveness
@ApplicationScoped
public class CamelHealthCheck implements HealthCheck {
  @Inject
  CamelContext camelContext;

  @Override
  public HealthCheckResponse call() {
    boolean isStarted = camelContext.getStatus().isStarted();
    return HealthCheckResponse.named("Camel Context")
        .status(isStarted)
        .build();
  }
}
```

## Dependency (Maven)

```xml
<properties>
    <quarkus.platform.version>3.27.0</quarkus.platform.version>
    <lombok.version>1.18.42</lombok.version>
    <assertj-core.version>3.24.2</assertj-core.version>
    <jacoco-maven-plugin.version>0.8.13</jacoco-maven-plugin.version>
    <maven.compiler.release>17</maven.compiler.release>
</properties>

<dependencyManagement>
    <dependencies>
        <dependency>
            <groupId>io.quarkus.platform</groupId>
            <artifactId>quarkus-bom</artifactId>
            <version>${quarkus.platform.version}</version>
            <type>pom</type>
            <scope>import</scope>
        </dependency>
        <dependency>
            <groupId>io.quarkus.platform</groupId>
            <artifactId>quarkus-camel-bom</artifactId>
            <version>${quarkus.platform.version}</version>
            <type>pom</type>
            <scope>import</scope>
        </dependency>
    </dependencies>
</dependencyManagement>

<dependencies>
    <!-- Quarkus Core -->
    <dependency>
        <groupId>io.quarkus</groupId>
        <artifactId>quarkus-arc</artifactId>
    </dependency>
    <dependency>
        <groupId>io.quarkus</groupId>
        <artifactId>quarkus-config-yaml</artifactId>
    </dependency>

    <!-- Camel Extensions -->
    <dependency>
        <groupId>org.apache.camel.quarkus</groupId>
        <artifactId>camel-quarkus-spring-rabbitmq</artifactId>
    </dependency>
    <dependency>
        <groupId>org.apache.camel.quarkus</groupId>
        <artifactId>camel-quarkus-direct</artifactId>
    </dependency>
    <dependency>
        <groupId>org.apache.camel.quarkus</groupId>
        <artifactId>camel-quarkus-bean</artifactId>
    </dependency>

    <!-- Lombok -->
    <dependency>
        <groupId>org.projectlombok</groupId>
        <artifactId>lombok</artifactId>
        <version>${lombok.version}</version>
        <scope>provided</scope>
    </dependency>

    <!-- Logging -->
    <dependency>
        <groupId>io.quarkiverse.logging.logback</groupId>
        <artifactId>quarkus-logging-logback</artifactId>
    </dependency>
    <dependency>
        <groupId>net.logstash.logback</groupId>
        <artifactId>logstash-logback-encoder</artifactId>
    </dependency>
</dependencies>
```

## Best Practices

### Kiến trúc
- Dùng `@RequiredArgsConstructor` của Lombok cho constructor injection
- Giữ service layer mỏng; ủy thác logic phức tạp cho các class chuyên biệt
- Dùng Camel route cho message routing và các pattern tích hợp
- Ưu tiên pattern Panache Repository cho data access

### Event-Driven
- LUÔN LUÔN theo dõi các thao tác bằng EventService (event thành công/lỗi)
- Dùng endpoint `direct:` của Camel cho routing trong bộ nhớ
- Dùng component `spring-rabbitmq` để tích hợp RabbitMQ
- Triển khai publish bất đồng bộ bằng `ProducerTemplate.asyncSendBody()`

### Logging
- Dùng Logback với Logstash encoder cho structured logging
- Truyền LogContext qua các lời gọi service bằng `SafeAutoCloseable`
- Thêm thông tin ngữ cảnh vào LogContext để truy vết request
- Dùng `@Slf4j` thay vì tự khởi tạo logger thủ công

### Thao tác Async
- Dùng CompletableFuture cho các thao tác I/O không chặn (non-blocking)
- Gọi `.join()` khi cần chờ hoàn tất
- Xử lý đúng exception từ CompletableFuture
- Truyền LogContext vào các thao tác async để truy vết

### Cấu hình
- Dùng cấu hình YAML (`quarkus-config-yaml`)
- Cấu hình theo profile cho môi trường dev/test/prod
- Tách cấu hình nhạy cảm ra biến môi trường
- Dùng `@ConfigProperty` để inject config an toàn về type

### Validation
- Validate ở resource layer bằng `@Valid`
- Dùng annotation Bean Validation trên DTO
- Map exception sang HTTP response phù hợp bằng `@Provider`

### Transaction
- Dùng `@Transactional` trên các method của service có thay đổi dữ liệu
- Giữ transaction ngắn và tập trung
- Tránh gọi các thao tác async bên trong transaction

### Testing
- Dùng `camel-quarkus-junit5` để test route
- Dùng AssertJ cho assertion
- Mock mọi dependency bên ngoài
- Test kỹ logic của conditional flow

### Đặc thù Quarkus
- Luôn dùng phiên bản LTS mới nhất (3.x)
- Dùng Quarkus dev mode để hot reload
- Thêm health check để sẵn sàng cho production
- Định kỳ test khả năng tương thích với native compilation
