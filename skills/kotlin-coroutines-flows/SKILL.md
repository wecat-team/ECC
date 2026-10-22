---
name: kotlin-coroutines-flows
description: "Các pattern Kotlin Coroutines và Flow cho Android và KMP — structured concurrency, toán tử Flow, StateFlow, xử lý lỗi và testing. Dùng khi viết code coroutine hoặc Flow trên Android hoặc KMP, hoặc khi debug cancellation và concurrency."
metadata:
  origin: ECC
---

# Kotlin Coroutines & Flows

Các pattern cho structured concurrency, reactive stream dựa trên Flow và testing coroutine trong các dự án Android và Kotlin Multiplatform.

## Khi nào kích hoạt

- Viết code bất đồng bộ với Kotlin coroutines
- Dùng Flow, StateFlow hoặc SharedFlow cho dữ liệu reactive
- Xử lý các thao tác đồng thời (tải song song, debounce, retry)
- Testing coroutine và Flow
- Quản lý coroutine scope và cancellation

## Structured Concurrency

### Phân cấp Scope

```
Application
  └── viewModelScope (ViewModel)
        └── coroutineScope { } (structured child)
              ├── async { } (concurrent task)
              └── async { } (concurrent task)
```

Luôn dùng structured concurrency — KHÔNG BAO GIỜ dùng `GlobalScope`:

```kotlin
// BAD
GlobalScope.launch { fetchData() }

// GOOD — scoped to ViewModel lifecycle
viewModelScope.launch { fetchData() }

// GOOD — scoped to composable lifecycle
LaunchedEffect(key) { fetchData() }
```

### Phân rã song song (Parallel Decomposition)

Dùng `coroutineScope` + `async` cho công việc song song:

```kotlin
suspend fun loadDashboard(): Dashboard = coroutineScope {
    val items = async { itemRepository.getRecent() }
    val stats = async { statsRepository.getToday() }
    val profile = async { userRepository.getCurrent() }
    Dashboard(
        items = items.await(),
        stats = stats.await(),
        profile = profile.await()
    )
}
```

### SupervisorScope

Dùng `supervisorScope` khi lỗi của một child không được hủy các sibling:

```kotlin
suspend fun syncAll() = supervisorScope {
    launch { syncItems() }       // failure here won't cancel syncStats
    launch { syncStats() }
    launch { syncSettings() }
}
```

## Pattern Flow

### Cold Flow — Chuyển từ One-Shot sang Stream

```kotlin
fun observeItems(): Flow<List<Item>> = flow {
    // Re-emits whenever the database changes
    itemDao.observeAll()
        .map { entities -> entities.map { it.toDomain() } }
        .collect { emit(it) }
}
```

### StateFlow cho UI State

```kotlin
class DashboardViewModel(
    observeProgress: ObserveUserProgressUseCase
) : ViewModel() {
    val progress: StateFlow<UserProgress> = observeProgress()
        .stateIn(
            scope = viewModelScope,
            started = SharingStarted.WhileSubscribed(5_000),
            initialValue = UserProgress.EMPTY
        )
}
```

`WhileSubscribed(5_000)` giữ upstream hoạt động thêm 5 giây sau khi subscriber cuối cùng rời đi — sống sót qua các thay đổi cấu hình (configuration change) mà không phải khởi động lại.

### Kết hợp nhiều Flow

```kotlin
val uiState: StateFlow<HomeState> = combine(
    itemRepository.observeItems(),
    settingsRepository.observeTheme(),
    userRepository.observeProfile()
) { items, theme, profile ->
    HomeState(items = items, theme = theme, profile = profile)
}.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), HomeState())
```

### Toán tử Flow

```kotlin
// Debounce search input
searchQuery
    .debounce(300)
    .distinctUntilChanged()
    .flatMapLatest { query -> repository.search(query) }
    .catch { emit(emptyList()) }
    .collect { results -> _state.update { it.copy(results = results) } }

// Retry with exponential backoff
fun fetchWithRetry(): Flow<Data> = flow { emit(api.fetch()) }
    .retryWhen { cause, attempt ->
        if (cause is IOException && attempt < 3) {
            delay(1000L * (1 shl attempt.toInt()))
            true
        } else {
            false
        }
    }
```

### SharedFlow cho sự kiện một lần (One-Time Events)

```kotlin
class ItemListViewModel : ViewModel() {
    private val _effects = MutableSharedFlow<Effect>()
    val effects: SharedFlow<Effect> = _effects.asSharedFlow()

    sealed interface Effect {
        data class ShowSnackbar(val message: String) : Effect
        data class NavigateTo(val route: String) : Effect
    }

    private fun deleteItem(id: String) {
        viewModelScope.launch {
            repository.delete(id)
            _effects.emit(Effect.ShowSnackbar("Item deleted"))
        }
    }
}

// Collect in Composable
LaunchedEffect(Unit) {
    viewModel.effects.collect { effect ->
        when (effect) {
            is Effect.ShowSnackbar -> snackbarHostState.showSnackbar(effect.message)
            is Effect.NavigateTo -> navController.navigate(effect.route)
        }
    }
}
```

## Dispatcher

```kotlin
// CPU-intensive work
withContext(Dispatchers.Default) { parseJson(largePayload) }

// IO-bound work
withContext(Dispatchers.IO) { database.query() }

// Main thread (UI) — default in viewModelScope
withContext(Dispatchers.Main) { updateUi() }
```

Trong KMP, dùng `Dispatchers.Default` và `Dispatchers.Main` (có sẵn trên mọi nền tảng). `Dispatchers.IO` chỉ có trên JVM/Android — dùng `Dispatchers.Default` trên các nền tảng khác hoặc cung cấp qua DI.

## Cancellation

### Cooperative Cancellation

Các vòng lặp chạy lâu phải kiểm tra cancellation:

```kotlin
suspend fun processItems(items: List<Item>) = coroutineScope {
    for (item in items) {
        ensureActive()  // throws CancellationException if cancelled
        process(item)
    }
}
```

### Dọn dẹp với try/finally

```kotlin
viewModelScope.launch {
    try {
        _state.update { it.copy(isLoading = true) }
        val data = repository.fetch()
        _state.update { it.copy(data = data) }
    } finally {
        _state.update { it.copy(isLoading = false) }  // always runs, even on cancellation
    }
}
```

## Testing

### Test StateFlow với Turbine

```kotlin
@Test
fun `search updates item list`() = runTest {
    val fakeRepository = FakeItemRepository().apply { emit(testItems) }
    val viewModel = ItemListViewModel(GetItemsUseCase(fakeRepository))

    viewModel.state.test {
        assertEquals(ItemListState(), awaitItem())  // initial

        viewModel.onSearch("query")
        val loading = awaitItem()
        assertTrue(loading.isLoading)

        val loaded = awaitItem()
        assertFalse(loaded.isLoading)
        assertEquals(1, loaded.items.size)
    }
}
```

### Test với TestDispatcher

```kotlin
@Test
fun `parallel load completes correctly`() = runTest {
    val viewModel = DashboardViewModel(
        itemRepo = FakeItemRepo(),
        statsRepo = FakeStatsRepo()
    )

    viewModel.load()
    advanceUntilIdle()

    val state = viewModel.state.value
    assertNotNull(state.items)
    assertNotNull(state.stats)
}
```

### Giả lập Flow (Faking Flows)

```kotlin
class FakeItemRepository : ItemRepository {
    private val _items = MutableStateFlow<List<Item>>(emptyList())

    override fun observeItems(): Flow<List<Item>> = _items

    fun emit(items: List<Item>) { _items.value = items }

    override suspend fun getItemsByCategory(category: String): Result<List<Item>> {
        return Result.success(_items.value.filter { it.category == category })
    }
}
```

## Anti-Pattern cần tránh

- Dùng `GlobalScope` — rò rỉ coroutine, không có structured cancellation
- Collect Flow trong `init {}` mà không có scope — hãy dùng `viewModelScope.launch`
- Dùng `MutableStateFlow` với collection có thể thay đổi (mutable) — luôn dùng bản sao bất biến (immutable): `_state.update { it.copy(list = it.list + newItem) }`
- Bắt `CancellationException` — hãy để nó lan truyền để cancellation hoạt động đúng
- Dùng `flowOn(Dispatchers.Main)` để collect — dispatcher của việc collect là dispatcher của bên gọi
- Tạo `Flow` trong `@Composable` mà không có `remember` — tạo lại flow ở mỗi lần recomposition

## Tham khảo

Xem skill: `compose-multiplatform-patterns` để biết cách UI tiêu thụ Flow.
Xem skill: `android-clean-architecture` để biết coroutine nằm ở đâu trong các tầng.
