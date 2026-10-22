---
name: jpa-patterns
description: "Các pattern JPA/Hibernate cho thiết kế entity, quan hệ, tối ưu query, transaction, auditing, indexing, pagination và pooling trong Spring Boot. Dùng khi thiết kế JPA entity hoặc quan hệ, hoặc khi cần sửa một query Hibernate, transaction hay vấn đề N+1."
metadata:
  origin: ECC
---

# Các pattern JPA/Hibernate

Dùng cho data modeling, repository và tinh chỉnh hiệu năng trong Spring Boot.

## Khi nào kích hoạt

- Thiết kế JPA entity và ánh xạ bảng
- Định nghĩa các quan hệ (@OneToMany, @ManyToOne, @ManyToMany)
- Tối ưu query (phòng tránh N+1, chiến lược fetch, projection)
- Cấu hình transaction, auditing hoặc soft delete
- Thiết lập pagination, sorting hoặc các method repository tùy chỉnh
- Tinh chỉnh connection pooling (HikariCP) hoặc second-level caching

## Thiết kế Entity

```java
@Entity
@Table(name = "markets", indexes = {
  @Index(name = "idx_markets_slug", columnList = "slug", unique = true)
})
@EntityListeners(AuditingEntityListener.class)
public class MarketEntity {
  @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
  private Long id;

  @Column(nullable = false, length = 200)
  private String name;

  @Column(nullable = false, unique = true, length = 120)
  private String slug;

  @Enumerated(EnumType.STRING)
  private MarketStatus status = MarketStatus.ACTIVE;

  @CreatedDate private Instant createdAt;
  @LastModifiedDate private Instant updatedAt;
}
```

Bật auditing:
```java
@Configuration
@EnableJpaAuditing
class JpaConfig {}
```

## Quan hệ và phòng tránh N+1

```java
@OneToMany(mappedBy = "market", cascade = CascadeType.ALL, orphanRemoval = true)
private List<PositionEntity> positions = new ArrayList<>();
```

- Mặc định dùng lazy loading; dùng `JOIN FETCH` trong query khi cần
- Tránh `EAGER` trên collection; dùng DTO projection cho các đường đọc

```java
@Query("select m from MarketEntity m left join fetch m.positions where m.id = :id")
Optional<MarketEntity> findWithPositions(@Param("id") Long id);
```

## Pattern Repository

```java
public interface MarketRepository extends JpaRepository<MarketEntity, Long> {
  Optional<MarketEntity> findBySlug(String slug);

  @Query("select m from MarketEntity m where m.status = :status")
  Page<MarketEntity> findByStatus(@Param("status") MarketStatus status, Pageable pageable);
}
```

- Dùng projection cho các query nhẹ:
```java
public interface MarketSummary {
  Long getId();
  String getName();
  MarketStatus getStatus();
}
Page<MarketSummary> findAllBy(Pageable pageable);
```

## Transaction

- Đánh dấu các method của service bằng `@Transactional`
- Dùng `@Transactional(readOnly = true)` cho các đường đọc để tối ưu
- Chọn propagation cẩn thận; tránh transaction chạy lâu

```java
@Transactional
public Market updateStatus(Long id, MarketStatus status) {
  MarketEntity entity = repo.findById(id)
      .orElseThrow(() -> new EntityNotFoundException("Market"));
  entity.setStatus(status);
  return Market.from(entity);
}
```

## Pagination

```java
PageRequest page = PageRequest.of(pageNumber, pageSize, Sort.by("createdAt").descending());
Page<MarketEntity> markets = repo.findByStatus(MarketStatus.ACTIVE, page);
```

Với pagination kiểu cursor, thêm `id > :lastId` vào JPQL kèm ordering.

## Indexing và hiệu năng

- Thêm index cho các bộ lọc phổ biến (`status`, `slug`, foreign key)
- Dùng composite index khớp với pattern của query (`status, created_at`)
- Tránh `select *`; chỉ project các cột cần thiết
- Ghi theo batch với `saveAll` và `hibernate.jdbc.batch_size`

## Connection Pooling (HikariCP)

Các property khuyến nghị:
```
spring.datasource.hikari.maximum-pool-size=20
spring.datasource.hikari.minimum-idle=5
spring.datasource.hikari.connection-timeout=30000
spring.datasource.hikari.validation-timeout=5000
```

Để xử lý LOB trên PostgreSQL, thêm:
```
spring.jpa.properties.hibernate.jdbc.lob.non_contextual_creation=true
```

## Caching

- Cache cấp 1 (1st-level) gắn với từng EntityManager; tránh giữ entity qua nhiều transaction
- Với entity đọc nhiều, cân nhắc second-level cache một cách thận trọng; xác thực chiến lược eviction

## Migration

- Dùng Flyway hoặc Liquibase; KHÔNG BAO GIỜ dựa vào Hibernate auto DDL trong production
- Giữ migration idempotent và mang tính bổ sung (additive); tránh xóa cột khi không có kế hoạch

## Kiểm thử truy cập dữ liệu

- Ưu tiên `@DataJpaTest` với Testcontainers để phản ánh production
- Đánh giá hiệu quả SQL qua log: đặt `logging.level.org.hibernate.SQL=DEBUG` và `logging.level.org.hibernate.orm.jdbc.bind=TRACE` để xem giá trị tham số

**Hãy nhớ**: Giữ entity gọn nhẹ, query có chủ đích và transaction ngắn. Phòng tránh N+1 bằng chiến lược fetch và projection, và đánh index cho các đường đọc/ghi của bạn.
