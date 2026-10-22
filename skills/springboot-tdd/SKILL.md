---
name: springboot-tdd
description: Phát triển hướng kiểm thử (TDD) cho Spring Boot với JUnit 5, Mockito, MockMvc, Testcontainers và JaCoCo. Dùng khi thêm tính năng, sửa bug hoặc refactor.
metadata:
  origin: ECC
---

# Workflow TDD cho Spring Boot

Hướng dẫn TDD cho service Spring Boot với coverage 80%+ (unit + integration).

## Khi nào dùng

- Tính năng hoặc endpoint mới
- Sửa bug hoặc refactor
- Thêm logic data access hoặc quy tắc bảo mật

## Workflow

1) Viết test trước (chúng phải fail)
2) Triển khai code tối thiểu để pass
3) Refactor khi test vẫn xanh
4) Thực thi coverage (JaCoCo)

## Unit Test (JUnit 5 + Mockito)

```java
@ExtendWith(MockitoExtension.class)
class MarketServiceTest {
  @Mock MarketRepository repo;
  @InjectMocks MarketService service;

  @Test
  void createsMarket() {
    CreateMarketRequest req = new CreateMarketRequest("name", "desc", Instant.now(), List.of("cat"));
    when(repo.save(any())).thenAnswer(inv -> inv.getArgument(0));

    Market result = service.create(req);

    assertThat(result.name()).isEqualTo("name");
    verify(repo).save(any());
  }
}
```

Pattern:
- Arrange-Act-Assert
- Tránh partial mock; ưu tiên stubbing tường minh
- Dùng `@ParameterizedTest` cho các biến thể

## Test tầng Web (MockMvc)

```java
@WebMvcTest(MarketController.class)
class MarketControllerTest {
  @Autowired MockMvc mockMvc;
  @MockBean MarketService marketService;

  @Test
  void returnsMarkets() throws Exception {
    when(marketService.list(any())).thenReturn(Page.empty());

    mockMvc.perform(get("/api/markets"))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.content").isArray());
  }
}
```

## Integration Test (SpringBootTest)

```java
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class MarketIntegrationTest {
  @Autowired MockMvc mockMvc;

  @Test
  void createsMarket() throws Exception {
    mockMvc.perform(post("/api/markets")
        .contentType(MediaType.APPLICATION_JSON)
        .content("""
          {"name":"Test","description":"Desc","endDate":"2030-01-01T00:00:00Z","categories":["general"]}
        """))
      .andExpect(status().isCreated());
  }
}
```

## Test tầng Persistence (DataJpaTest)

```java
@DataJpaTest
@AutoConfigureTestDatabase(replace = AutoConfigureTestDatabase.Replace.NONE)
@Import(TestContainersConfig.class)
class MarketRepositoryTest {
  @Autowired MarketRepository repo;

  @Test
  void savesAndFinds() {
    MarketEntity entity = new MarketEntity();
    entity.setName("Test");
    repo.save(entity);

    Optional<MarketEntity> found = repo.findByName("Test");
    assertThat(found).isPresent();
  }
}
```

## Testcontainers

- Dùng container có thể tái sử dụng cho Postgres/Redis để phản chiếu production
- Kết nối qua `@DynamicPropertySource` để inject JDBC URL vào Spring context

## Coverage (JaCoCo)

Đoạn cấu hình Maven:
```xml
<plugin>
  <groupId>org.jacoco</groupId>
  <artifactId>jacoco-maven-plugin</artifactId>
  <version>0.8.14</version>
  <executions>
    <execution>
      <goals><goal>prepare-agent</goal></goals>
    </execution>
    <execution>
      <id>report</id>
      <phase>verify</phase>
      <goals><goal>report</goal></goals>
    </execution>
  </executions>
</plugin>
```

## Assertion

- Ưu tiên AssertJ (`assertThat`) để dễ đọc
- Với response JSON, dùng `jsonPath`
- Với exception: `assertThatThrownBy(...)`

## Test Data Builder

```java
class MarketBuilder {
  private String name = "Test";
  MarketBuilder withName(String name) { this.name = name; return this; }
  Market build() { return new Market(null, name, MarketStatus.ACTIVE); }
}
```

## Lệnh CI

- Maven: `mvn -T 4 test` or `mvn verify`
- Gradle: `./gradlew test jacocoTestReport`

**Hãy nhớ**: Giữ test nhanh, cô lập và xác định (deterministic). Test hành vi, không test chi tiết triển khai.
