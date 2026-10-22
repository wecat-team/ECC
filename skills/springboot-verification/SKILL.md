---
name: springboot-verification
description: Chạy toàn bộ vòng xác minh (verification loop) cho Spring Boot — build bằng Maven hoặc Gradle, phân tích tĩnh SpotBugs, PMD và Checkstyle, unit test và integration test Testcontainers kèm coverage JaCoCo, quét dependency và secret theo OWASP, và review diff — để tạo báo cáo sẵn sàng (readiness) pass/fail. Dùng khi chuẩn bị pull request Spring Boot, kiểm tra ngưỡng coverage hoặc xác minh trước khi deploy.
metadata:
  origin: ECC
---

# Vòng xác minh Spring Boot

Chạy trước khi tạo PR, sau các thay đổi lớn và trước khi deploy.

## Khi nào kích hoạt

- Trước khi mở pull request cho một service Spring Boot
- Sau khi refactor lớn hoặc nâng cấp dependency
- Xác minh trước khi deploy lên staging hoặc production
- Chạy toàn bộ pipeline build → lint → test → quét bảo mật
- Kiểm tra test coverage đạt ngưỡng yêu cầu

## Giai đoạn 1: Build

```bash
mvn -T 4 clean verify -DskipTests
# or
./gradlew clean assemble -x test
```

Nếu build fail, hãy dừng lại và sửa.

## Giai đoạn 2: Phân tích tĩnh

Maven (các plugin phổ biến):
```bash
mvn -T 4 spotbugs:check pmd:check checkstyle:check
```

Gradle (nếu đã cấu hình):
```bash
./gradlew checkstyleMain pmdMain spotbugsMain
```

## Giai đoạn 3: Test + Coverage

```bash
mvn -T 4 test
mvn jacoco:report   # verify 80%+ coverage
# or
./gradlew test jacocoTestReport
```

Báo cáo:
- Tổng số test, số pass/fail
- Coverage % (line/branch)

### Unit Test

Test logic của service một cách cô lập với các dependency được mock:

```java
@ExtendWith(MockitoExtension.class)
class UserServiceTest {

  @Mock private UserRepository userRepository;
  @InjectMocks private UserService userService;

  @Test
  void createUser_validInput_returnsUser() {
    var dto = new CreateUserDto("Alice", "alice@example.com");
    var expected = new User(1L, "Alice", "alice@example.com");
    when(userRepository.save(any(User.class))).thenReturn(expected);

    var result = userService.create(dto);

    assertThat(result.name()).isEqualTo("Alice");
    verify(userRepository).save(any(User.class));
  }

  @Test
  void createUser_duplicateEmail_throwsException() {
    var dto = new CreateUserDto("Alice", "existing@example.com");
    when(userRepository.existsByEmail(dto.email())).thenReturn(true);

    assertThatThrownBy(() -> userService.create(dto))
        .isInstanceOf(DuplicateEmailException.class);
  }
}
```

### Integration Test với Testcontainers

Test trên database thật thay vì H2:

```java
@SpringBootTest
@Testcontainers
class UserRepositoryIntegrationTest {

  @Container
  static PostgreSQLContainer<?> postgres = new PostgreSQLContainer<>("postgres:16-alpine")
      .withDatabaseName("testdb");

  @DynamicPropertySource
  static void configureProperties(DynamicPropertyRegistry registry) {
    registry.add("spring.datasource.url", postgres::getJdbcUrl);
    registry.add("spring.datasource.username", postgres::getUsername);
    registry.add("spring.datasource.password", postgres::getPassword);
  }

  @Autowired private UserRepository userRepository;

  @Test
  void findByEmail_existingUser_returnsUser() {
    userRepository.save(new User("Alice", "alice@example.com"));

    var found = userRepository.findByEmail("alice@example.com");

    assertThat(found).isPresent();
    assertThat(found.get().getName()).isEqualTo("Alice");
  }
}
```

### API Test với MockMvc

Test tầng controller với Spring context đầy đủ:

```java
@WebMvcTest(UserController.class)
class UserControllerTest {

  @Autowired private MockMvc mockMvc;
  @MockBean private UserService userService;

  @Test
  void createUser_validInput_returns201() throws Exception {
    var user = new UserDto(1L, "Alice", "alice@example.com");
    when(userService.create(any())).thenReturn(user);

    mockMvc.perform(post("/api/users")
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {"name": "Alice", "email": "alice@example.com"}
                """))
        .andExpect(status().isCreated())
        .andExpect(jsonPath("$.name").value("Alice"));
  }

  @Test
  void createUser_invalidEmail_returns400() throws Exception {
    mockMvc.perform(post("/api/users")
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {"name": "Alice", "email": "not-an-email"}
                """))
        .andExpect(status().isBadRequest());
  }
}
```

## Giai đoạn 4: Quét bảo mật

```bash
# Dependency CVEs
mvn org.owasp:dependency-check-maven:check
# or
./gradlew dependencyCheckAnalyze

# Secrets in source
grep -rn "password\s*=\s*\"" src/ --include="*.java" --include="*.yml" --include="*.properties"
grep -rn "sk-\|api_key\|secret" src/ --include="*.java" --include="*.yml"

# Secrets (git history)
git secrets --scan  # if configured
```

### Các phát hiện bảo mật phổ biến

```
# Check for System.out.println (use logger instead)
grep -rn "System\.out\.print" src/main/ --include="*.java"

# Check for raw exception messages in responses
grep -rn "e\.getMessage()" src/main/ --include="*.java"

# Check for wildcard CORS
grep -rn "allowedOrigins.*\*" src/main/ --include="*.java"
```

## Giai đoạn 5: Lint/Format (gate tùy chọn)

```bash
mvn spotless:apply   # if using Spotless plugin
./gradlew spotlessApply
```

## Giai đoạn 6: Review Diff

```bash
git diff --stat
git diff
```

Checklist:
- Không còn log debug sót lại (`System.out`, `log.debug` không có guard)
- Lỗi và HTTP status có ý nghĩa
- Có transaction và validation ở những nơi cần thiết
- Các thay đổi cấu hình được ghi chép lại

## Template đầu ra

```
VERIFICATION REPORT
===================
Build:     [PASS/FAIL]
Static:    [PASS/FAIL] (spotbugs/pmd/checkstyle)
Tests:     [PASS/FAIL] (X/Y passed, Z% coverage)
Security:  [PASS/FAIL] (CVE findings: N)
Diff:      [X files changed]

Overall:   [READY / NOT READY]

Issues to Fix:
1. ...
2. ...
```

## Chế độ liên tục

- Chạy lại các giai đoạn khi có thay đổi đáng kể hoặc mỗi 30–60 phút trong các phiên làm việc dài
- Giữ một vòng lặp ngắn: `mvn -T 4 test` + spotbugs để có phản hồi nhanh

**Hãy nhớ**: Phản hồi nhanh tốt hơn những bất ngờ muộn màng. Giữ gate nghiêm ngặt — hãy coi cảnh báo (warning) là lỗi trong các hệ thống production.
