---
name: quarkus-verification
description: "Vòng lặp kiểm chứng (verification loop) cho dự án Quarkus: build, phân tích tĩnh (Checkstyle, PMD, SpotBugs), test với coverage JaCoCo, quét bảo mật dependency và container bằng OWASP, biên dịch native GraalVM, health check và kiểm tra config. Dùng khi kiểm chứng một Quarkus service trước PR, sau refactor lớn hoặc nâng cấp dependency, hoặc trước khi deploy."
metadata:
  origin: ECC
---

# Vòng lặp kiểm chứng cho Quarkus

Chạy trước khi tạo PR, sau các thay đổi lớn và trước khi deploy.

## Khi nào kích hoạt

- Trước khi mở pull request cho một Quarkus service
- Sau khi refactor lớn hoặc nâng cấp dependency
- Kiểm chứng trước khi deploy lên staging hoặc production
- Chạy toàn bộ pipeline build → lint → test → quét bảo mật → biên dịch native
- Xác nhận coverage của test đạt ngưỡng (80% trở lên)
- Test khả năng tương thích của native image

## Giai đoạn 1: Build

```bash
# Maven
mvn clean verify -DskipTests

# Gradle
./gradlew clean assemble -x test
```

Nếu build thất bại, hãy dừng lại và sửa các lỗi biên dịch.

## Giai đoạn 2: Phân tích tĩnh

### Checkstyle, PMD, SpotBugs (Maven)

```bash
mvn checkstyle:check pmd:check spotbugs:check
```

### SonarQube (nếu đã cấu hình)

```bash
mvn sonar:sonar \
  -Dsonar.projectKey=my-quarkus-project \
  -Dsonar.host.url=http://localhost:9000 \
  -Dsonar.login=${SONAR_TOKEN}
```

### Các vấn đề thường gặp cần xử lý

- Import hoặc biến không dùng đến
- Method phức tạp (cyclomatic complexity cao)
- Khả năng dereference null pointer
- Vấn đề bảo mật do SpotBugs cảnh báo

## Giai đoạn 3: Test + Coverage

```bash
# Run all tests
mvn clean test

# Generate coverage report
mvn jacoco:report

# Enforce coverage threshold (80%)
mvn jacoco:check

# Or with Gradle
./gradlew test jacocoTestReport jacocoTestCoverageVerification
```

### Các loại test

#### Unit Test
Test logic của service với dependency đã mock:

```java
@ExtendWith(MockitoExtension.class)
class UserServiceTest {
  @Mock UserRepository userRepository;
  @InjectMocks UserService userService;

  @Test
  void createUser_validInput_returnsUser() {
    var dto = new CreateUserDto("Alice", "alice@example.com");

    // Panache persist() is void — use doNothing + verify
    doNothing().when(userRepository).persist(any(User.class));

    User result = userService.create(dto);

    assertThat(result.name).isEqualTo("Alice");
    verify(userRepository).persist(any(User.class));
  }
}
```

#### Integration Test
Test với database thật (Testcontainers):

```java
@QuarkusTest
@QuarkusTestResource(PostgresTestResource.class)
class UserRepositoryIntegrationTest {

  @Inject
  UserRepository userRepository;

  @Test
  @Transactional
  void findByEmail_existingUser_returnsUser() {
    User user = new User();
    user.name = "Alice";
    user.email = "alice@example.com";
    userRepository.persist(user);

    Optional<User> found = userRepository.findByEmail("alice@example.com");

    assertThat(found).isPresent();
    assertThat(found.get().name).isEqualTo("Alice");
  }
}
```

#### API Test
Test REST endpoint bằng REST Assured:

```java
@QuarkusTest
class UserResourceTest {

  @Test
  void createUser_validInput_returns201() {
    given()
        .contentType(ContentType.JSON)
        .body("""
            {"name": "Alice", "email": "alice@example.com"}
            """)
        .when().post("/api/users")
        .then()
        .statusCode(201)
        .body("name", equalTo("Alice"));
  }

  @Test
  void createUser_invalidEmail_returns400() {
    given()
        .contentType(ContentType.JSON)
        .body("""
            {"name": "Alice", "email": "invalid"}
            """)
        .when().post("/api/users")
        .then()
        .statusCode(400);
  }
}
```

### Báo cáo Coverage

Xem `target/site/jacoco/index.html` để biết coverage chi tiết:
- Line coverage tổng thể (mục tiêu: 80% trở lên)
- Branch coverage (mục tiêu: 70% trở lên)
- Xác định các critical path chưa được cover

## Giai đoạn 4: Quét bảo mật

### Lỗ hổng trong Dependency (Maven)

```bash
mvn org.owasp:dependency-check-maven:check
```

Xem `target/dependency-check-report.html` để kiểm tra các CVE.

### Audit bảo mật Quarkus

```bash
# Check vulnerable extensions
mvn quarkus:audit

# List all extensions
mvn quarkus:list-extensions
```

### OWASP ZAP (Test bảo mật API)

```bash
docker run -t ghcr.io/zaproxy/zaproxy:stable zap-api-scan.py \
  -t http://localhost:8080/q/openapi \
  -f openapi
```

### Các kiểm tra bảo mật thường gặp

- [ ] Mọi secret nằm trong biến môi trường (không nằm trong code)
- [ ] Input validation trên mọi endpoint
- [ ] Đã cấu hình authentication/authorization
- [ ] CORS được cấu hình đúng
- [ ] Đã đặt security header
- [ ] Mật khẩu được hash bằng BCrypt
- [ ] Chống SQL injection (parameterized query)
- [ ] Rate limiting trên các endpoint công khai

## Giai đoạn 5: Biên dịch Native

Test khả năng tương thích với GraalVM native image:

```bash
# Build native executable
mvn package -Dnative

# Or with container
mvn package -Dnative -Dquarkus.native.container-build=true

# Test native executable
./target/*-runner

# Run basic smoke tests
curl http://localhost:8080/q/health/live
curl http://localhost:8080/q/health/ready
```

### Xử lý sự cố Native Image

Các vấn đề thường gặp:
- **Reflection**: Thêm reflection config cho các class động
- **Resources**: Đưa resource vào bằng `quarkus.native.resources.includes`
- **JNI**: Đăng ký các class JNI nếu dùng thư viện native

Ví dụ reflection config:
```java
@RegisterForReflection(targets = {MyDynamicClass.class})
public class ReflectionConfiguration {}
```

## Giai đoạn 6: Performance Testing

### Load Testing với K6

```javascript
// load-test.js
import http from 'k6/http';
import { check } from 'k6';

export const options = {
  stages: [
    { duration: '30s', target: 50 },
    { duration: '1m', target: 100 },
    { duration: '30s', target: 0 },
  ],
};

export default function () {
  const res = http.get('http://localhost:8080/api/markets');
  check(res, {
    'status is 200': (r) => r.status === 200,
    'response time < 200ms': (r) => r.timings.duration < 200,
  });
}
```

Chạy:
```bash
k6 run load-test.js
```

### Các metric cần theo dõi

- Response time (p50, p95, p99)
- Throughput (request/giây)
- Tỷ lệ lỗi
- Mức dùng bộ nhớ
- Mức dùng CPU

## Giai đoạn 7: Health Check

```bash
# Liveness
curl http://localhost:8080/q/health/live

# Readiness
curl http://localhost:8080/q/health/ready

# All health checks
curl http://localhost:8080/q/health

# Metrics (if enabled)
curl http://localhost:8080/q/metrics
```

Phản hồi kỳ vọng:
```json
{
  "status": "UP",
  "checks": [
    {
      "name": "Database connection",
      "status": "UP"
    }
  ]
}
```

## Giai đoạn 8: Build Container Image

```bash
# Build container image
mvn package -Dquarkus.container-image.build=true

# Or with specific registry
mvn package \
  -Dquarkus.container-image.build=true \
  -Dquarkus.container-image.registry=docker.io \
  -Dquarkus.container-image.group=myorg \
  -Dquarkus.container-image.tag=1.0.0

# Test container
docker run -p 8080:8080 myorg/my-quarkus-app:1.0.0
```

### Quét bảo mật Container

```bash
# Trivy
trivy image myorg/my-quarkus-app:1.0.0

# Grype
grype myorg/my-quarkus-app:1.0.0
```

## Giai đoạn 9: Kiểm tra Cấu hình

```bash
# Check all configuration properties
mvn quarkus:info

# List all config sources
curl http://localhost:8080/q/dev/io.quarkus.quarkus-vertx-http/config
```

### Kiểm tra theo từng môi trường

- [ ] URL database được cấu hình theo từng môi trường
- [ ] Secret được tách ra ngoài (Vault, biến môi trường)
- [ ] Mức logging phù hợp
- [ ] CORS origin được đặt đúng
- [ ] Đã cấu hình rate limiting
- [ ] Đã bật monitoring/tracing

## Giai đoạn 10: Review Tài liệu

- [ ] Tài liệu OpenAPI/Swagger được cập nhật (`/q/swagger-ui`)
- [ ] README có hướng dẫn cài đặt
- [ ] Thay đổi API đã được ghi lại
- [ ] Có migration guide cho các breaking change
- [ ] Các configuration property đã được ghi lại

Tạo OpenAPI spec:
```bash
curl http://localhost:8080/q/openapi -o openapi.json
```

## Checklist kiểm chứng

### Chất lượng code
- [ ] Build pass không có warning
- [ ] Phân tích tĩnh sạch (không có vấn đề mức high/medium)
- [ ] Code tuân theo quy ước của team
- [ ] Không có code bị comment-out hoặc TODO trong PR

### Testing
- [ ] Mọi test đều pass
- [ ] Code coverage ≥ 80%
- [ ] Integration test với database thật
- [ ] Security test pass
- [ ] Hiệu năng nằm trong giới hạn chấp nhận được

### Bảo mật
- [ ] Không có lỗ hổng trong dependency
- [ ] Đã test authentication/authorization
- [ ] Input validation đầy đủ
- [ ] Secret không nằm trong source code
- [ ] Đã cấu hình security header

### Deployment
- [ ] Biên dịch native thành công
- [ ] Container image build được
- [ ] Health check phản hồi đúng
- [ ] Cấu hình hợp lệ cho môi trường đích

### Native Image
- [ ] Native executable build được
- [ ] Native test pass
- [ ] Thời gian khởi động < 100ms
- [ ] Dung lượng bộ nhớ chấp nhận được

## Script kiểm chứng tự động

```bash
#!/bin/bash
set -e

echo "=== Phase 1: Build ==="
mvn clean verify -DskipTests

echo "=== Phase 2: Static Analysis ==="
mvn checkstyle:check pmd:check spotbugs:check

echo "=== Phase 3: Tests + Coverage ==="
mvn test jacoco:report jacoco:check

echo "=== Phase 4: Security Scan ==="
mvn org.owasp:dependency-check-maven:check

echo "=== Phase 5: Native Compilation ==="
mvn package -Dnative -Dquarkus.native.container-build=true

echo "=== All Phases Complete ==="
echo "Review reports:"
echo "  - Coverage: target/site/jacoco/index.html"
echo "  - Security: target/dependency-check-report.html"
echo "  - Native: target/*-runner"
```

## Tích hợp CI/CD

### Ví dụ GitHub Actions

```yaml
name: Verification

on: [push, pull_request]

jobs:
  verify:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v7

      - name: Set up JDK 21
        uses: actions/setup-java@v5
        with:
          java-version: '21'
          distribution: 'temurin'

      - name: Cache Maven packages
        uses: actions/cache@v6
        with:
          path: ~/.m2
          key: ${{ runner.os }}-m2-${{ hashFiles('**/pom.xml') }}

      - name: Build
        run: mvn clean verify -DskipTests

      - name: Test with Coverage
        run: mvn test jacoco:report jacoco:check

      - name: Security Scan
        run: mvn org.owasp:dependency-check-maven:check

      - name: Upload Coverage
        uses: codecov/codecov-action@v7
        with:
          token: ${{ secrets.CODECOV_TOKEN }}
          files: target/site/jacoco/jacoco.xml
```

## Best Practices

- Chạy verification loop trước mỗi PR
- Tự động hóa trong CI/CD pipeline
- Sửa vấn đề ngay lập tức; đừng để tích tụ nợ kỹ thuật
- Giữ coverage trên 80%
- Cập nhật dependency thường xuyên
- Định kỳ test biên dịch native
- Theo dõi xu hướng hiệu năng
- Ghi lại các breaking change
- Review kết quả quét bảo mật
- Kiểm tra cấu hình cho từng môi trường
