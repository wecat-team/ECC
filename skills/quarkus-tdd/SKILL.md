---
name: quarkus-tdd
description: Test-driven development (TDD) cho Quarkus 3.x LTS dùng JUnit 5, Mockito, REST Assured, Camel testing và JaCoCo. Dùng khi thêm tính năng, sửa bug hoặc refactor các service event-driven.
metadata:
  origin: ECC
---

# Quy trình TDD cho Quarkus

Hướng dẫn TDD cho các service Quarkus 3.x với coverage từ 80% trở lên (unit + integration). Được tối ưu cho kiến trúc event-driven với Apache Camel.

## Khi nào dùng

- Tính năng mới hoặc REST endpoint
- Sửa bug hoặc refactor
- Thêm logic data access, quy tắc bảo mật hoặc reactive stream
- Test các route và event handler của Apache Camel
- Test các service event-driven với RabbitMQ
- Test logic conditional flow
- Kiểm chứng các thao tác async với CompletableFuture
- Test việc truyền LogContext

## Quy trình

1. Viết test trước (test phải thất bại)
2. Triển khai code tối thiểu để test pass
3. Refactor trong khi giữ test xanh
4. Áp đặt coverage bằng JaCoCo (mục tiêu 80% trở lên)

## Unit Test tổ chức bằng @Nested

Hãy theo cách tiếp cận có cấu trúc này để viết test toàn diện và dễ đọc:

```java
@ExtendWith(MockitoExtension.class)
@DisplayName("OrderService Unit Tests")
class OrderServiceTest {

  @Mock
  private OrderRepository orderRepository;

  @Mock
  private EventService eventService;

  @Mock
  private FulfillmentPublisher fulfillmentPublisher;

  @InjectMocks
  private OrderService orderService;

  private CreateOrderCommand validCommand;

  @BeforeEach
  void setUp() {
    validCommand = new CreateOrderCommand(
        "customer-123",
        List.of(new OrderLine("sku-123", 2))
    );
  }

  @Nested
  @DisplayName("Tests for createOrder")
  class CreateOrder {

    @Test
    @DisplayName("Should persist order and publish fulfillment event")
    void givenValidCommand_whenCreateOrder_thenPersistsAndPublishes() {
      // ARRANGE
      doNothing().when(orderRepository).persist(any(Order.class));

      // ACT
      OrderReceipt receipt = orderService.createOrder(validCommand);

      // ASSERT
      assertThat(receipt).isNotNull();
      assertThat(receipt.customerId()).isEqualTo("customer-123");
      verify(orderRepository).persist(any(Order.class));
      verify(fulfillmentPublisher).publishAsync(receipt);
      verify(eventService).createSuccessEvent(receipt, "ORDER_CREATED");
    }

    @Test
    @DisplayName("Should reject missing customer id")
    void givenMissingCustomerId_whenCreateOrder_thenThrowsBadRequest() {
      // ARRANGE
      CreateOrderCommand invalid = new CreateOrderCommand("", validCommand.lines());

      // ACT & ASSERT
      WebApplicationException exception = assertThrows(
          WebApplicationException.class,
          () -> orderService.createOrder(invalid)
      );

      assertThat(exception.getResponse().getStatus()).isEqualTo(400);
      verify(orderRepository, never()).persist(any(Order.class));
      verify(fulfillmentPublisher, never()).publishAsync(any());
    }

    @Test
    @DisplayName("Should record error event when persistence fails")
    void givenPersistenceFailure_whenCreateOrder_thenRecordsErrorEvent() {
      // ARRANGE
      doThrow(new PersistenceException("database unavailable"))
          .when(orderRepository).persist(any(Order.class));

      // ACT & ASSERT
      PersistenceException exception = assertThrows(
          PersistenceException.class,
          () -> orderService.createOrder(validCommand)
      );

      assertThat(exception.getMessage()).contains("database unavailable");
      verify(eventService).createErrorEvent(
          eq(validCommand),
          eq("ORDER_CREATE_FAILED"),
          contains("database unavailable")
      );
      verify(fulfillmentPublisher, never()).publishAsync(any());
    }

    @Test
    @DisplayName("Should reject null commands")
    void givenNullCommand_whenCreateOrder_thenThrowsNullPointerException() {
      // ACT & ASSERT
      assertThrows(
          NullPointerException.class,
          () -> orderService.createOrder(null)
      );

      verify(orderRepository, never()).persist(any(Order.class));
    }
  }
}
```

### Các pattern testing chính

1. **@Nested Classes**: Nhóm test theo method đang được test
2. **@DisplayName**: Cung cấp mô tả test dễ đọc cho báo cáo test
3. **Quy ước đặt tên**: `givenX_whenY_thenZ` để rõ ràng
4. **AAA Pattern**: Comment tường minh `// ARRANGE`, `// ACT`, `// ASSERT`
5. **@BeforeEach**: Thiết lập dữ liệu test chung để giảm trùng lặp
6. **assertDoesNotThrow**: Test kịch bản thành công mà không cần bắt exception
7. **assertThrows**: Test kịch bản exception kèm kiểm tra message bằng AssertJ
8. **Coverage toàn diện**: Test happy path, input null, edge case, exception
9. **Verify Interactions**: Dùng `verify()` của Mockito để đảm bảo các method được gọi đúng
10. **Never Verify**: Dùng `never()` để đảm bảo các method KHÔNG được gọi trong kịch bản lỗi

## Test Camel Route

```java
@QuarkusTest
@DisplayName("Business Rules Camel Route Tests")
class BusinessRulesRouteTest {

  @Inject
  CamelContext camelContext;

  @Inject
  ProducerTemplate producerTemplate;

  @InjectMock
  EventService eventService;

  @InjectMock
  DocumentValidator documentValidator;

  private BusinessRulesPayload testPayload;

  @BeforeEach
  void setUp() {
    // ARRANGE - Test data
    testPayload = new BusinessRulesPayload();
    testPayload.setDocumentId(1L);
    testPayload.setFlowProfile(FlowProfile.BASIC);
  }

  @Nested
  @DisplayName("Tests for business-rules-publisher route")
  class BusinessRulesPublisher {

    @Test
    @DisplayName("Should successfully publish message to RabbitMQ")
    void givenValidPayload_whenPublish_thenMessageSentToQueue() throws Exception {
      // ARRANGE
      MockEndpoint mockRabbitMQ = camelContext.getEndpoint("mock:rabbitmq", MockEndpoint.class);
      mockRabbitMQ.expectedMessageCount(1);

      // Replace real endpoint with mock for testing
      camelContext.getRouteController().stopRoute("business-rules-publisher");
      AdviceWith.adviceWith(camelContext, "business-rules-publisher", advice -> {
        advice.replaceFromWith("direct:business-rules-publisher");
        advice.weaveByToString(".*spring-rabbitmq.*").replace().to("mock:rabbitmq");
      });
      camelContext.getRouteController().startRoute("business-rules-publisher");

      // ACT
      producerTemplate.sendBody("direct:business-rules-publisher", testPayload);

      // ASSERT — body is a JSON String after .marshal().json(JsonLibrary.Jackson)
      mockRabbitMQ.assertIsSatisfied(5000);

      assertThat(mockRabbitMQ.getExchanges()).hasSize(1);
      String body = mockRabbitMQ.getExchanges().get(0).getIn().getBody(String.class);
      assertThat(body).contains("\"documentId\":1");
    }

    @Test
    @DisplayName("Should handle marshalling to JSON")
    void givenPayload_whenPublish_thenMarshalledToJson() throws Exception {
      // ARRANGE
      MockEndpoint mockMarshal = new MockEndpoint("mock:marshal");
      camelContext.addEndpoint("mock:marshal", mockMarshal);
      mockMarshal.expectedMessageCount(1);

      camelContext.getRouteController().stopRoute("business-rules-publisher");
      AdviceWith.adviceWith(camelContext, "business-rules-publisher", advice -> {
        advice.weaveAddLast().to("mock:marshal");
      });
      camelContext.getRouteController().startRoute("business-rules-publisher");

      // ACT
      producerTemplate.sendBody("direct:business-rules-publisher", testPayload);

      // ASSERT
      mockMarshal.assertIsSatisfied(5000);

      String body = mockMarshal.getExchanges().get(0).getIn().getBody(String.class);
      assertThat(body).contains("\"documentId\":1");
      assertThat(body).contains("\"flowProfile\":\"BASIC\"");
    }
  }

  @Nested
  @DisplayName("Tests for document-processing route")
  class DocumentProcessing {

    @Test
    @DisplayName("Should route invoice to correct processor")
    void givenInvoiceType_whenProcess_thenRoutesToInvoiceProcessor() throws Exception {
      // ARRANGE
      MockEndpoint mockInvoice = camelContext.getEndpoint("mock:invoice", MockEndpoint.class);
      mockInvoice.expectedMessageCount(1);

      camelContext.getRouteController().stopRoute("document-processing");
      AdviceWith.adviceWith(camelContext, "document-processing", advice -> {
        advice.weaveByToString(".*direct:process-invoice.*").replace().to("mock:invoice");
      });
      camelContext.getRouteController().startRoute("document-processing");

      // ACT
      producerTemplate.sendBodyAndHeader("direct:process-document",
          testPayload, "documentType", "INVOICE");

      // ASSERT
      mockInvoice.assertIsSatisfied(5000);
    }

    @Test
    @DisplayName("Should handle validation errors gracefully")
    void givenValidationError_whenProcess_thenRoutesToErrorHandler() throws Exception {
      // ARRANGE
      MockEndpoint mockError = camelContext.getEndpoint("mock:error", MockEndpoint.class);
      mockError.expectedMessageCount(1);

      camelContext.getRouteController().stopRoute("document-processing");
      AdviceWith.adviceWith(camelContext, "document-processing", advice -> {
        advice.weaveByToString(".*direct:validation-error-handler.*")
            .replace().to("mock:error");
      });
      camelContext.getRouteController().startRoute("document-processing");

      // Mock validator bean to throw exception
      when(documentValidator.validate(any())).thenThrow(new ValidationException("Invalid document"));

      // ACT
      producerTemplate.sendBody("direct:process-document", testPayload);

      // ASSERT
      mockError.assertIsSatisfied(5000);

      Exception exception = mockError.getExchanges().get(0).getException();
      assertThat(exception).isInstanceOf(ValidationException.class);
      assertThat(exception.getMessage()).contains("Invalid document");
    }
  }
}
```

## Test Event Service

```java
@ExtendWith(MockitoExtension.class)
@DisplayName("EventService Unit Tests")
class EventServiceTest {

  @Mock
  private EventRepository eventRepository;

  @Mock
  private ObjectMapper objectMapper;

  @InjectMocks
  private EventService eventService;

  private BusinessRulesPayload testPayload;

  @BeforeEach
  void setUp() {
    // ARRANGE
    testPayload = new BusinessRulesPayload();
    testPayload.setDocumentId(1L);
  }

  @Nested
  @DisplayName("Tests for createSuccessEvent")
  class CreateSuccessEvent {

    @Test
    @DisplayName("Should create success event with correct attributes")
    void givenValidPayload_whenCreateSuccessEvent_thenEventPersisted() throws Exception {
      // ARRANGE
      when(objectMapper.writeValueAsString(testPayload)).thenReturn("{\"documentId\":1}");

      // ACT
      assertDoesNotThrow(() ->
          eventService.createSuccessEvent(testPayload, "DOCUMENT_PROCESSED"));

      // ASSERT
      verify(eventRepository).persist(argThat(event ->
          event.getType().equals("DOCUMENT_PROCESSED") &&
          event.getStatus() == EventStatus.SUCCESS &&
          event.getPayload().equals("{\"documentId\":1}") &&
          event.getTimestamp() != null
      ));
    }

    @Test
    @DisplayName("Should throw exception when payload is null")
    void givenNullPayload_whenCreateSuccessEvent_thenThrowsException() {
      // ARRANGE
      Object nullPayload = null;

      // ACT & ASSERT
      NullPointerException exception = assertThrows(
          NullPointerException.class,
          () -> eventService.createSuccessEvent(nullPayload, "EVENT_TYPE")
      );

      assertThat(exception.getMessage()).isEqualTo("Payload cannot be null");
      verify(eventRepository, never()).persist(any());
    }
  }

  @Nested
  @DisplayName("Tests for createErrorEvent")
  class CreateErrorEvent {

    @Test
    @DisplayName("Should create error event with error message")
    void givenError_whenCreateErrorEvent_thenEventPersistedWithMessage() throws Exception {
      // ARRANGE
      String errorMessage = "Processing failed";
      when(objectMapper.writeValueAsString(testPayload)).thenReturn("{\"documentId\":1}");

      // ACT
      assertDoesNotThrow(() ->
          eventService.createErrorEvent(testPayload, "PROCESSING_ERROR", errorMessage));

      // ASSERT
      verify(eventRepository).persist(argThat(event ->
          event.getType().equals("PROCESSING_ERROR") &&
          event.getStatus() == EventStatus.ERROR &&
          event.getErrorMessage().equals(errorMessage) &&
          event.getPayload().equals("{\"documentId\":1}")
      ));
    }

    @ParameterizedTest
    @DisplayName("Should reject invalid error messages")
    @ValueSource(strings = {"", " "})
    void givenBlankErrorMessage_whenCreateErrorEvent_thenThrowsException(String blankMessage) {
      // ACT & ASSERT
      IllegalArgumentException exception = assertThrows(
          IllegalArgumentException.class,
          () -> eventService.createErrorEvent(testPayload, "ERROR", blankMessage)
      );

      assertThat(exception.getMessage()).contains("Error message cannot be blank");
    }
  }
}
```

## Test CompletableFuture

```java
@ExtendWith(MockitoExtension.class)
@DisplayName("FileStorageService Unit Tests")
class FileStorageServiceTest {

  @Mock
  private S3Client s3Client;

  @Mock
  private ExecutorService executorService;

  @InjectMocks
  private FileStorageService fileStorageService;

  private InputStream testInputStream;
  private LogContext testLogContext;

  @BeforeEach
  void setUp() {
    // ARRANGE
    testInputStream = new ByteArrayInputStream("test content".getBytes());
    testLogContext = new LogContext();
    testLogContext.put("traceId", "trace-123");
  }

  @Nested
  @DisplayName("Tests for uploadOriginalFile")
  class UploadOriginalFile {

    @Test
    @DisplayName("Should successfully upload file and return document info")
    void givenValidFile_whenUpload_thenReturnsDocumentInfo() throws Exception {
      // ARRANGE
      doAnswer(invocation -> {
        ((Runnable) invocation.getArgument(0)).run();
        return null;
      }).when(executorService).execute(any(Runnable.class));

      when(s3Client.putObject(any(PutObjectRequest.class), any(RequestBody.class)))
          .thenReturn(PutObjectResponse.builder().build());

      // ACT
      CompletableFuture<StoredDocumentInfo> future =
          fileStorageService.uploadOriginalFile(testInputStream, 1024L,
              testLogContext, InvoiceFormat.UBL);

      StoredDocumentInfo result = future.join();

      // ASSERT
      assertThat(result).isNotNull();
      assertThat(result.getPath()).isNotBlank();
      assertThat(result.getSize()).isEqualTo(1024L);
      assertThat(result.getUploadedAt()).isNotNull();

      verify(s3Client).putObject(any(PutObjectRequest.class), any(RequestBody.class));
    }

    @Test
    @DisplayName("Should handle S3 upload failure")
    void givenS3Failure_whenUpload_thenCompletableFutureFails() {
      // ARRANGE — run synchronously so exception propagates through the future
      doAnswer(invocation -> {
        ((Runnable) invocation.getArgument(0)).run();
        return null;
      }).when(executorService).execute(any(Runnable.class));

      when(s3Client.putObject(any(PutObjectRequest.class), any(RequestBody.class)))
          .thenThrow(new StorageException("S3 unavailable"));

      // ACT
      CompletableFuture<StoredDocumentInfo> future =
          fileStorageService.uploadOriginalFile(testInputStream, 1024L,
              testLogContext, InvoiceFormat.UBL);

      // ASSERT
      assertThatThrownBy(() -> future.join())
          .isInstanceOf(CompletionException.class)
          .hasCauseInstanceOf(StorageException.class)
          .hasMessageContaining("S3 unavailable");
    }

    @Test
    @DisplayName("Should propagate LogContext to async operation")
    void givenLogContext_whenUpload_thenContextPropagated() throws Exception {
      // ARRANGE
      AtomicReference<LogContext> capturedContext = new AtomicReference<>();

      doAnswer(invocation -> {
        capturedContext.set(CustomLog.getCurrentContext());
        ((Runnable) invocation.getArgument(0)).run();
        return null;
      }).when(executorService).execute(any(Runnable.class));

      // ACT
      fileStorageService.uploadOriginalFile(testInputStream, 1024L,
          testLogContext, InvoiceFormat.UBL).join();

      // ASSERT
      assertThat(capturedContext.get()).isNotNull();
      assertThat(capturedContext.get().get("traceId")).isEqualTo("trace-123");
    }
  }
}
```

## Test Resource Layer (REST Assured)

```java
@QuarkusTest
@DisplayName("DocumentResource API Tests")
class DocumentResourceTest {

  @InjectMock
  DocumentService documentService;

  @Nested
  @DisplayName("Tests for GET /api/documents")
  class ListDocuments {

    @Test
    @DisplayName("Should return list of documents")
    void givenDocumentsExist_whenList_thenReturnsOk() {
      // ARRANGE
      List<Document> documents = List.of(createDocument(1L, "DOC-001"));
      when(documentService.list(0, 20)).thenReturn(documents);

      // ACT & ASSERT
      given()
          .when().get("/api/documents")
          .then()
          .statusCode(200)
          .body("$.size()", is(1))
          .body("[0].referenceNumber", equalTo("DOC-001"));
    }
  }

  @Nested
  @DisplayName("Tests for POST /api/documents")
  class CreateDocument {

    @Test
    @DisplayName("Should create document and return 201")
    void givenValidRequest_whenCreate_thenReturns201() {
      // ARRANGE
      Document document = createDocument(1L, "DOC-001");
      when(documentService.create(any())).thenReturn(document);

      // ACT & ASSERT
      given()
          .contentType(ContentType.JSON)
          .body("""
              {
                "referenceNumber": "DOC-001",
                "description": "Test document",
                "validUntil": "2030-01-01T00:00:00Z",
                "categories": ["test"]
              }
              """)
          .when().post("/api/documents")
          .then()
          .statusCode(201)
          .header("Location", containsString("/api/documents/1"))
          .body("referenceNumber", equalTo("DOC-001"));
    }

    @Test
    @DisplayName("Should return 400 for invalid input")
    void givenInvalidRequest_whenCreate_thenReturns400() {
      // ACT & ASSERT
      given()
          .contentType(ContentType.JSON)
          .body("""
              {
                "referenceNumber": "",
                "description": "Test"
              }
              """)
          .when().post("/api/documents")
          .then()
          .statusCode(400);
    }
  }

  private Document createDocument(Long id, String referenceNumber) {
    Document document = new Document();
    document.setId(id);
    document.setReferenceNumber(referenceNumber);
    document.setStatus(DocumentStatus.PENDING);
    return document;
  }
}
```

## Integration Test với Database thật

```java
@QuarkusTest
@TestProfile(IntegrationTestProfile.class)
@DisplayName("Document Integration Tests")
class DocumentIntegrationTest {

  @Test
  @Transactional
  @DisplayName("Should create and retrieve document via API")
  void givenNewDocument_whenCreateAndRetrieve_thenSuccessful() {
    // ACT - Create via API
    Long id = given()
        .contentType(ContentType.JSON)
        .body("""
            {
              "referenceNumber": "INT-001",
              "description": "Integration test",
              "validUntil": "2030-01-01T00:00:00Z",
              "categories": ["test"]
            }
            """)
        .when().post("/api/documents")
        .then()
        .statusCode(201)
        .extract().path("id");

    // ASSERT - Retrieve via API
    given()
        .when().get("/api/documents/" + id)
        .then()
        .statusCode(200)
        .body("referenceNumber", equalTo("INT-001"));
  }
}
```

## Coverage với JaCoCo

### Cấu hình Maven (đầy đủ)

```xml
<plugin>
  <groupId>org.jacoco</groupId>
  <artifactId>jacoco-maven-plugin</artifactId>
  <version>0.8.13</version>
  <executions>
    <!-- Prepare agent for test execution -->
    <execution>
      <id>prepare-agent</id>
      <goals>
        <goal>prepare-agent</goal>
      </goals>
    </execution>

    <!-- Generate coverage report -->
    <execution>
      <id>report</id>
      <phase>verify</phase>
      <goals>
        <goal>report</goal>
      </goals>
    </execution>

    <!-- Enforce coverage thresholds -->
    <execution>
      <id>check</id>
      <goals>
        <goal>check</goal>
      </goals>
      <configuration>
        <rules>
          <rule>
            <element>BUNDLE</element>
            <limits>
              <limit>
                <counter>LINE</counter>
                <value>COVEREDRATIO</value>
                <minimum>0.80</minimum>
              </limit>
              <limit>
                <counter>BRANCH</counter>
                <value>COVEREDRATIO</value>
                <minimum>0.70</minimum>
              </limit>
            </limits>
          </rule>
        </rules>
      </configuration>
    </execution>
  </executions>
</plugin>
```

Chạy test kèm coverage:
```bash
mvn clean test
mvn jacoco:report
mvn jacoco:check

# Report at: target/site/jacoco/index.html
```

## Dependency cho Test

```xml
<dependencies>
    <!-- Quarkus Testing -->
    <dependency>
        <groupId>io.quarkus</groupId>
        <artifactId>quarkus-junit5</artifactId>
        <scope>test</scope>
    </dependency>
    <dependency>
        <groupId>io.quarkus</groupId>
        <artifactId>quarkus-junit5-mockito</artifactId>
        <scope>test</scope>
    </dependency>

    <!-- Mockito -->
    <dependency>
        <groupId>org.mockito</groupId>
        <artifactId>mockito-core</artifactId>
        <scope>test</scope>
    </dependency>

    <!-- AssertJ (preferred over JUnit assertions) -->
    <dependency>
        <groupId>org.assertj</groupId>
        <artifactId>assertj-core</artifactId>
        <version>3.24.2</version>
        <scope>test</scope>
    </dependency>

    <!-- REST Assured -->
    <dependency>
        <groupId>io.rest-assured</groupId>
        <artifactId>rest-assured</artifactId>
        <scope>test</scope>
    </dependency>

    <!-- Camel Testing -->
    <dependency>
        <groupId>org.apache.camel.quarkus</groupId>
        <artifactId>camel-quarkus-junit5</artifactId>
        <scope>test</scope>
    </dependency>
</dependencies>
```

## Best Practices

### Tổ chức test
- Dùng class `@Nested` để nhóm test theo method đang được test
- Dùng `@DisplayName` để có mô tả test dễ đọc hiển thị trong báo cáo
- Theo quy ước đặt tên `givenX_whenY_thenZ` cho các method test
- Dùng `@BeforeEach` để thiết lập dữ liệu test chung nhằm giảm trùng lặp

### Cấu trúc test
- Theo AAA pattern với comment tường minh (`// ARRANGE`, `// ACT`, `// ASSERT`)
- Dùng `assertDoesNotThrow` cho kịch bản thành công
- Dùng `assertThrows` cho kịch bản exception kèm kiểm tra message
- Xác minh message của exception khớp với giá trị kỳ vọng bằng `contains()` hoặc `isEqualTo()` của AssertJ

### Test Coverage
- Test happy path cho mọi method public
- Test việc xử lý input null
- Test các edge case (collection rỗng, giá trị biên, ID âm, chuỗi trống)
- Test kịch bản exception một cách toàn diện
- Mock mọi dependency bên ngoài (repository, service, Camel endpoint)
- Hướng tới line coverage từ 80% và branch coverage từ 70% trở lên

### Assertion
- **Ưu tiên AssertJ** (`assertThat`) hơn assertion của JUnit khi kiểm tra giá trị
- Dùng fluent API của AssertJ cho dễ đọc: `assertThat(list).hasSize(3).contains(item)`
- Với exception: dùng `assertThrows` của JUnit để bắt, sau đó dùng AssertJ để kiểm tra message
- Với đường thành công không ném exception: dùng `assertDoesNotThrow` của JUnit
- Với collection: `extracting()`, `filteredOn()`, `containsExactly()`

### Integration Testing
- Dùng `@QuarkusTest` cho integration test
- Dùng `@InjectMock` để mock dependency trong test Quarkus
- Ưu tiên REST Assured để test API
- Dùng `@TestProfile` cho cấu hình riêng của test

### Test Event-Driven
- Test Camel route bằng `AdviceWith` và `MockEndpoint`
- Dùng annotation `@CamelQuarkusTest` (nếu dùng test Camel độc lập)
- Xác minh nội dung message, header và logic routing
- Test các route xử lý lỗi một cách riêng biệt
- Mock các hệ thống bên ngoài (RabbitMQ, S3, database) trong unit test

### Test Camel Route
- Dùng `MockEndpoint` để assert luồng message
- Dùng `AdviceWith` để sửa route phục vụ test (thay endpoint bằng mock)
- Test việc biến đổi message và marshalling
- Test xử lý exception và dead letter queue

### Test thao tác Async
- Test kịch bản thành công và thất bại của CompletableFuture
- Dùng `.join()` trong test để chờ hoàn tất async
- Test việc lan truyền exception từ CompletableFuture
- Xác minh LogContext được truyền vào các thao tác async

### Hiệu năng
- Giữ test nhanh và cô lập
- Chạy test ở chế độ liên tục: `mvn quarkus:test`
- Dùng parameterized test (`@ParameterizedTest`) cho các biến thể input
- Xây dựng test data builder hoặc factory method dùng lại được

### Đặc thù Quarkus
- Luôn dùng phiên bản LTS mới nhất (Quarkus 3.x)
- Định kỳ test khả năng tương thích với native compilation
- Dùng Quarkus test profile cho các kịch bản khác nhau
- Tận dụng Quarkus dev services cho test cục bộ
- Dùng `@InjectMock` thay cho `@MockBean` (đặc thù của Quarkus)

### Best Practice khi Verify
- LUÔN LUÔN verify các tương tác trên dependency đã mock
- Dùng `verify(mock, never())` để đảm bảo các method KHÔNG được gọi trong kịch bản lỗi
- Dùng `argThat()` để so khớp tham số phức tạp
- Verify thứ tự các lời gọi khi thứ tự quan trọng: `InOrder` của Mockito
