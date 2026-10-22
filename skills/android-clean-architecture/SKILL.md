---
name: android-clean-architecture
description: Các pattern Clean Architecture cho dự án Android và Kotlin Multiplatform — cấu trúc module, quy tắc dependency, UseCase, Repository và pattern cho data layer. Dùng khi tổ chức module, layer hoặc luồng dữ liệu trong một dự án Android hoặc KMP.
metadata:
  origin: ECC
---

# Android Clean Architecture

Các pattern Clean Architecture cho dự án Android và KMP. Bao gồm ranh giới module, dependency inversion, pattern UseCase/Repository và thiết kế data layer với Room, SQLDelight và Ktor.

## Khi nào kích hoạt

- Tổ chức các module của dự án Android hoặc KMP
- Triển khai UseCase, Repository hoặc DataSource
- Thiết kế luồng dữ liệu giữa các layer (domain, data, presentation)
- Thiết lập dependency injection với Koin hoặc Hilt
- Làm việc với Room, SQLDelight hoặc Ktor trong kiến trúc phân tầng

## Cấu trúc Module

### Bố cục khuyến nghị

```
project/
├── app/                  # Android entry point, DI wiring, Application class
├── core/                 # Shared utilities, base classes, error types
├── domain/               # UseCases, domain models, repository interfaces (pure Kotlin)
├── data/                 # Repository implementations, DataSources, DB, network
├── presentation/         # Screens, ViewModels, UI models, navigation
├── design-system/        # Reusable Compose components, theme, typography
└── feature/              # Feature modules (optional, for larger projects)
    ├── auth/
    ├── settings/
    └── profile/
```

### Quy tắc Dependency

```
app → presentation, domain, data, core
presentation → domain, design-system, core
data → domain, core
domain → core (or no dependencies)
core → (nothing)
```

**Quan trọng**: `domain` KHÔNG BAO GIỜ được phụ thuộc vào `data`, `presentation` hay bất kỳ framework nào. Nó chỉ chứa Kotlin thuần.

## Domain Layer

### Pattern UseCase

Mỗi UseCase đại diện cho một thao tác nghiệp vụ. Dùng `operator fun invoke` để nơi gọi gọn gàng:

```kotlin
class GetItemsByCategoryUseCase(
    private val repository: ItemRepository
) {
    suspend operator fun invoke(category: String): Result<List<Item>> {
        return repository.getItemsByCategory(category)
    }
}

// UseCase dựa trên Flow cho các luồng reactive
class ObserveUserProgressUseCase(
    private val repository: UserRepository
) {
    operator fun invoke(userId: String): Flow<UserProgress> {
        return repository.observeProgress(userId)
    }
}
```

### Domain Model

Domain model là các data class Kotlin thuần — không có annotation của framework:

```kotlin
data class Item(
    val id: String,
    val title: String,
    val description: String,
    val tags: List<String>,
    val status: Status,
    val category: String
)

enum class Status { DRAFT, ACTIVE, ARCHIVED }
```

### Repository Interface

Định nghĩa trong domain, triển khai trong data:

```kotlin
interface ItemRepository {
    suspend fun getItemsByCategory(category: String): Result<List<Item>>
    suspend fun saveItem(item: Item): Result<Unit>
    fun observeItems(): Flow<List<Item>>
}
```

## Data Layer

### Triển khai Repository

Điều phối giữa data source cục bộ và từ xa:

```kotlin
class ItemRepositoryImpl(
    private val localDataSource: ItemLocalDataSource,
    private val remoteDataSource: ItemRemoteDataSource
) : ItemRepository {

    override suspend fun getItemsByCategory(category: String): Result<List<Item>> {
        return runCatching {
            val remote = remoteDataSource.fetchItems(category)
            localDataSource.insertItems(remote.map { it.toEntity() })
            localDataSource.getItemsByCategory(category).map { it.toDomain() }
        }
    }

    override suspend fun saveItem(item: Item): Result<Unit> {
        return runCatching {
            localDataSource.insertItems(listOf(item.toEntity()))
        }
    }

    override fun observeItems(): Flow<List<Item>> {
        return localDataSource.observeAll().map { entities ->
            entities.map { it.toDomain() }
        }
    }
}
```

### Pattern Mapper

Giữ mapper dưới dạng extension function đặt gần các data model:

```kotlin
// Trong data layer
fun ItemEntity.toDomain() = Item(
    id = id,
    title = title,
    description = description,
    tags = tags.split("|"),
    status = Status.valueOf(status),
    category = category
)

fun ItemDto.toEntity() = ItemEntity(
    id = id,
    title = title,
    description = description,
    tags = tags.joinToString("|"),
    status = status,
    category = category
)
```

### Room Database (Android)

```kotlin
@Entity(tableName = "items")
data class ItemEntity(
    @PrimaryKey val id: String,
    val title: String,
    val description: String,
    val tags: String,
    val status: String,
    val category: String
)

@Dao
interface ItemDao {
    @Query("SELECT * FROM items WHERE category = :category")
    suspend fun getByCategory(category: String): List<ItemEntity>

    @Upsert
    suspend fun upsert(items: List<ItemEntity>)

    @Query("SELECT * FROM items")
    fun observeAll(): Flow<List<ItemEntity>>
}
```

### SQLDelight (KMP)

```sql
-- Item.sq
CREATE TABLE ItemEntity (
    id TEXT NOT NULL PRIMARY KEY,
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    tags TEXT NOT NULL,
    status TEXT NOT NULL,
    category TEXT NOT NULL
);

getByCategory:
SELECT * FROM ItemEntity WHERE category = ?;

upsert:
INSERT OR REPLACE INTO ItemEntity (id, title, description, tags, status, category)
VALUES (?, ?, ?, ?, ?, ?);

observeAll:
SELECT * FROM ItemEntity;
```

### Ktor Network Client (KMP)

```kotlin
class ItemRemoteDataSource(private val client: HttpClient) {

    suspend fun fetchItems(category: String): List<ItemDto> {
        return client.get("api/items") {
            parameter("category", category)
        }.body()
    }
}

// Thiết lập HttpClient với content negotiation
val httpClient = HttpClient {
    install(ContentNegotiation) { json(Json { ignoreUnknownKeys = true }) }
    install(Logging) { level = LogLevel.HEADERS }
    defaultRequest { url("https://api.example.com/") }
}
```

## Dependency Injection

### Koin (thân thiện với KMP)

```kotlin
// Domain module
val domainModule = module {
    factory { GetItemsByCategoryUseCase(get()) }
    factory { ObserveUserProgressUseCase(get()) }
}

// Data module
val dataModule = module {
    single<ItemRepository> { ItemRepositoryImpl(get(), get()) }
    single { ItemLocalDataSource(get()) }
    single { ItemRemoteDataSource(get()) }
}

// Presentation module
val presentationModule = module {
    viewModelOf(::ItemListViewModel)
    viewModelOf(::DashboardViewModel)
}
```

### Hilt (chỉ Android)

```kotlin
@Module
@InstallIn(SingletonComponent::class)
abstract class RepositoryModule {
    @Binds
    abstract fun bindItemRepository(impl: ItemRepositoryImpl): ItemRepository
}

@HiltViewModel
class ItemListViewModel @Inject constructor(
    private val getItems: GetItemsByCategoryUseCase
) : ViewModel()
```

## Xử lý lỗi

### Pattern Result/Try

Dùng `Result<T>` hoặc một sealed type tùy chỉnh để lan truyền lỗi:

```kotlin
sealed interface Try<out T> {
    data class Success<T>(val value: T) : Try<T>
    data class Failure(val error: AppError) : Try<Nothing>
}

sealed interface AppError {
    data class Network(val message: String) : AppError
    data class Database(val message: String) : AppError
    data object Unauthorized : AppError
}

// Trong ViewModel — ánh xạ sang UI state
viewModelScope.launch {
    when (val result = getItems(category)) {
        is Try.Success -> _state.update { it.copy(items = result.value, isLoading = false) }
        is Try.Failure -> _state.update { it.copy(error = result.error.toMessage(), isLoading = false) }
    }
}
```

## Convention Plugin (Gradle)

Với dự án KMP, dùng convention plugin để giảm trùng lặp trong file build:

```kotlin
// build-logic/src/main/kotlin/kmp-library.gradle.kts
plugins {
    id("org.jetbrains.kotlin.multiplatform")
}

kotlin {
    androidTarget()
    iosX64(); iosArm64(); iosSimulatorArm64()
    sourceSets {
        commonMain.dependencies { /* shared deps */ }
        commonTest.dependencies { implementation(kotlin("test")) }
    }
}
```

Áp dụng trong các module:

```kotlin
// domain/build.gradle.kts
plugins { id("kmp-library") }
```

## Anti-Pattern cần tránh

- Import class của Android framework trong `domain` — giữ nó là Kotlin thuần
- Để lộ database entity hoặc DTO ra UI layer — luôn ánh xạ sang domain model
- Đặt business logic trong ViewModel — hãy tách ra UseCase
- Dùng `GlobalScope` hoặc coroutine không có cấu trúc — dùng `viewModelScope` hoặc structured concurrency
- Triển khai repository quá béo — tách thành các DataSource tập trung
- Dependency vòng giữa các module — nếu A phụ thuộc B thì B không được phụ thuộc A

## Tham chiếu

Xem skill: `compose-multiplatform-patterns` cho các pattern UI.
Xem skill: `kotlin-coroutines-flows` cho các pattern async.
