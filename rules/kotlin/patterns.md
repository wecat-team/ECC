---
paths:
  - "**/*.kt"
  - "**/*.kts"
---
# Pattern Kotlin

> File này mở rộng [common/patterns.md](../common/patterns.md) với nội dung dành riêng cho Kotlin và Android/KMP.

## Dependency Injection

Ưu tiên constructor injection. Dùng Koin (KMP) hoặc Hilt (chỉ Android):

```kotlin
// Koin — declare modules
val dataModule = module {
    single<ItemRepository> { ItemRepositoryImpl(get(), get()) }
    factory { GetItemsUseCase(get()) }
    viewModelOf(::ItemListViewModel)
}

// Hilt — annotations
@HiltViewModel
class ItemListViewModel @Inject constructor(
    private val getItems: GetItemsUseCase
) : ViewModel()
```

## ViewModel Pattern

Một state object duy nhất, event sink, luồng dữ liệu một chiều:

```kotlin
data class ScreenState(
    val items: List<Item> = emptyList(),
    val isLoading: Boolean = false
)

class ScreenViewModel(private val useCase: GetItemsUseCase) : ViewModel() {
    private val _state = MutableStateFlow(ScreenState())
    val state = _state.asStateFlow()

    fun onEvent(event: ScreenEvent) {
        when (event) {
            is ScreenEvent.Load -> load()
            is ScreenEvent.Delete -> delete(event.id)
        }
    }
}
```

## Repository Pattern

- Hàm `suspend` trả về `Result<T>` hoặc kiểu lỗi tùy chỉnh
- `Flow` cho các reactive stream
- Phối hợp nguồn dữ liệu local + remote

```kotlin
interface ItemRepository {
    suspend fun getById(id: String): Result<Item>
    suspend fun getAll(): Result<List<Item>>
    fun observeAll(): Flow<List<Item>>
}
```

## UseCase Pattern

Một trách nhiệm duy nhất, `operator fun invoke`:

```kotlin
class GetItemUseCase(private val repository: ItemRepository) {
    suspend operator fun invoke(id: String): Result<Item> {
        return repository.getById(id)
    }
}

class GetItemsUseCase(private val repository: ItemRepository) {
    suspend operator fun invoke(): Result<List<Item>> {
        return repository.getAll()
    }
}
```

## expect/actual (KMP)

Dùng cho các triển khai riêng theo nền tảng:

```kotlin
// commonMain
expect fun platformName(): String
expect class SecureStorage {
    fun save(key: String, value: String)
    fun get(key: String): String?
}

// androidMain
actual fun platformName(): String = "Android"
actual class SecureStorage {
    actual fun save(key: String, value: String) { /* EncryptedSharedPreferences */ }
    actual fun get(key: String): String? = null /* ... */
}

// iosMain
actual fun platformName(): String = "iOS"
actual class SecureStorage {
    actual fun save(key: String, value: String) { /* Keychain */ }
    actual fun get(key: String): String? = null /* ... */
}
```

## Pattern Coroutine

- Dùng `viewModelScope` trong ViewModel, `coroutineScope` cho công việc con có cấu trúc
- Dùng `stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), initialValue)` để tạo StateFlow từ các Flow lạnh (cold Flow)
- Dùng `supervisorScope` khi lỗi của các tác vụ con cần độc lập với nhau

## Builder Pattern với DSL

```kotlin
class HttpClientConfig {
    var baseUrl: String = ""
    var timeout: Long = 30_000
    private val interceptors = mutableListOf<Interceptor>()

    fun interceptor(block: () -> Interceptor) {
        interceptors.add(block())
    }
}

fun httpClient(block: HttpClientConfig.() -> Unit): HttpClient {
    val config = HttpClientConfig().apply(block)
    return HttpClient(config)
}

// Usage
val client = httpClient {
    baseUrl = "https://api.example.com"
    timeout = 15_000
    interceptor { AuthInterceptor(tokenProvider) }
}
```

## Tham chiếu

Xem skill: `kotlin-coroutines-flows` để có các pattern coroutine chi tiết.
Xem skill: `android-clean-architecture` để có các pattern module và layer.
