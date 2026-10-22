---
paths:
  - "**/*.java"
---
# Kiểm thử Java

> File này mở rộng [common/testing.md](../common/testing.md) với nội dung dành riêng cho Java.

## Test Framework

- **JUnit 5** (`@Test`, `@ParameterizedTest`, `@Nested`, `@DisplayName`)
- **AssertJ** cho fluent assertion (`assertThat(result).isEqualTo(expected)`)
- **Mockito** để mock dependency
- **Testcontainers** cho integration test cần database hoặc service

## Tổ chức Test

```
src/test/java/com/example/app/
  service/           # Unit tests for service layer
  controller/        # Web layer / API tests
  repository/        # Data access tests
  integration/       # Cross-layer integration tests
```

Phản chiếu cấu trúc package `src/main/java` trong `src/test/java`.

## Pattern Unit Test

```java
@ExtendWith(MockitoExtension.class)
class OrderServiceTest {

    @Mock
    private OrderRepository orderRepository;

    private OrderService orderService;

    @BeforeEach
    void setUp() {
        orderService = new OrderService(orderRepository);
    }

    @Test
    @DisplayName("findById returns order when exists")
    void findById_existingOrder_returnsOrder() {
        var order = new Order(1L, "Alice", BigDecimal.TEN);
        when(orderRepository.findById(1L)).thenReturn(Optional.of(order));

        var result = orderService.findById(1L);

        assertThat(result.customerName()).isEqualTo("Alice");
        verify(orderRepository).findById(1L);
    }

    @Test
    @DisplayName("findById throws when order not found")
    void findById_missingOrder_throws() {
        when(orderRepository.findById(99L)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> orderService.findById(99L))
            .isInstanceOf(OrderNotFoundException.class)
            .hasMessageContaining("99");
    }
}
```

## Parameterized Test

```java
@ParameterizedTest
@CsvSource({
    "100.00, 10, 90.00",
    "50.00, 0, 50.00",
    "200.00, 25, 150.00"
})
@DisplayName("discount applied correctly")
void applyDiscount(BigDecimal price, int pct, BigDecimal expected) {
    assertThat(PricingUtils.discount(price, pct)).isEqualByComparingTo(expected);
}
```

## Integration Test

Dùng Testcontainers để tích hợp với database thật:

```java
@Testcontainers
class OrderRepositoryIT {

    @Container
    static PostgreSQLContainer<?> postgres = new PostgreSQLContainer<>("postgres:16");

    private OrderRepository repository;

    @BeforeEach
    void setUp() {
        var dataSource = new PGSimpleDataSource();
        dataSource.setUrl(postgres.getJdbcUrl());
        dataSource.setUser(postgres.getUsername());
        dataSource.setPassword(postgres.getPassword());
        repository = new JdbcOrderRepository(dataSource);
    }

    @Test
    void save_and_findById() {
        var saved = repository.save(new Order(null, "Bob", BigDecimal.ONE));
        var found = repository.findById(saved.getId());
        assertThat(found).isPresent();
    }
}
```

Với integration test Spring Boot, xem skill: `springboot-tdd`.
Với integration test Quarkus, xem skill: `quarkus-tdd`.

## Đặt tên Test

Dùng tên mô tả với `@DisplayName`:
- `methodName_scenario_expectedBehavior()` cho tên method
- `@DisplayName("human-readable description")` cho báo cáo

## Coverage

- Mục tiêu line coverage 80%+
- Dùng JaCoCo để báo cáo coverage
- Tập trung vào service và domain logic — bỏ qua getter đơn giản/class cấu hình

## Tham chiếu

Xem skill: `springboot-tdd` để có các pattern TDD Spring Boot với MockMvc và Testcontainers.
Xem skill: `quarkus-tdd` để có các pattern TDD Quarkus với REST Assured và Dev Services.
Xem skill: `java-coding-standards` để biết các kỳ vọng về kiểm thử.
