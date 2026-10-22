---
paths:
  - "**/*.kt"
  - "**/*.kts"
---
# Kiểm thử Kotlin

> File này mở rộng [common/testing.md](../common/testing.md) với nội dung dành riêng cho Kotlin và Android/KMP.

## Test Framework

- **kotlin.test** cho multiplatform (KMP) — `@Test`, `assertEquals`, `assertTrue`
- **JUnit 4/5** cho các test riêng của Android
- **Turbine** để test Flow và StateFlow
- **kotlinx-coroutines-test** để test coroutine (`runTest`, `TestDispatcher`)

## Kiểm thử ViewModel với Turbine

```kotlin
@Test
fun `loading state emitted then data`() = runTest {
    val repo = FakeItemRepository()
    repo.addItem(testItem)
    val viewModel = ItemListViewModel(GetItemsUseCase(repo))

    viewModel.state.test {
        assertEquals(ItemListState(), awaitItem())     // initial state
        viewModel.onEvent(ItemListEvent.Load)
        assertTrue(awaitItem().isLoading)               // loading
        assertEquals(listOf(testItem), awaitItem().items) // loaded
    }
}
```

## Ưu tiên Fake hơn Mock

Ưu tiên fake viết tay hơn các mocking framework:

```kotlin
class FakeItemRepository : ItemRepository {
    private val items = mutableListOf<Item>()
    var fetchError: Throwable? = null

    override suspend fun getAll(): Result<List<Item>> {
        fetchError?.let { return Result.failure(it) }
        return Result.success(items.toList())
    }

    override fun observeAll(): Flow<List<Item>> = flowOf(items.toList())

    fun addItem(item: Item) { items.add(item) }
}
```

## Kiểm thử Coroutine

```kotlin
@Test
fun `parallel operations complete`() = runTest {
    val repo = FakeRepository()
    val result = loadDashboard(repo)
    advanceUntilIdle()
    assertNotNull(result.items)
    assertNotNull(result.stats)
}
```

Dùng `runTest` — nó tự động tua thời gian ảo và cung cấp `TestScope`.

## Ktor MockEngine

```kotlin
val mockEngine = MockEngine { request ->
    when (request.url.encodedPath) {
        "/api/items" -> respond(
            content = Json.encodeToString(testItems),
            headers = headersOf(HttpHeaders.ContentType, ContentType.Application.Json.toString())
        )
        else -> respondError(HttpStatusCode.NotFound)
    }
}

val client = HttpClient(mockEngine) {
    install(ContentNegotiation) { json() }
}
```

## Kiểm thử Room/SQLDelight

- Room: Dùng `Room.inMemoryDatabaseBuilder()` để test in-memory
- SQLDelight: Dùng `JdbcSqliteDriver(JdbcSqliteDriver.IN_MEMORY)` cho test JVM

```kotlin
@Test
fun `insert and query items`() = runTest {
    val driver = JdbcSqliteDriver(JdbcSqliteDriver.IN_MEMORY)
    Database.Schema.create(driver)
    val db = Database(driver)

    db.itemQueries.insert("1", "Sample Item", "description")
    val items = db.itemQueries.getAll().executeAsList()
    assertEquals(1, items.size)
}
```

## Đặt tên Test

Dùng tên mô tả đặt trong dấu backtick:

```kotlin
@Test
fun `search with empty query returns all items`() = runTest { }

@Test
fun `delete item emits updated list without deleted item`() = runTest { }
```

## Tổ chức Test

```
src/
├── commonTest/kotlin/     # Shared tests (ViewModel, UseCase, Repository)
├── androidUnitTest/kotlin/ # Android unit tests (JUnit)
├── androidInstrumentedTest/kotlin/  # Instrumented tests (Room, UI)
└── iosTest/kotlin/        # iOS-specific tests
```

Coverage test tối thiểu: ViewModel + UseCase cho mọi feature.
