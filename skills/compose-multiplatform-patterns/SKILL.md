---
name: compose-multiplatform-patterns
description: Các pattern Compose Multiplatform và Jetpack Compose cho dự án KMP — quản lý state, navigation, theming, hiệu năng và UI đặc thù theo nền tảng. Dùng khi xây dựng UI, state, navigation hoặc theming với Compose hoặc Jetpack Compose trong một dự án KMP.
metadata:
  origin: ECC
---

# Các pattern Compose Multiplatform

Các pattern để xây dựng UI dùng chung trên Android, iOS, Desktop và Web bằng Compose Multiplatform và Jetpack Compose. Bao gồm quản lý state, navigation, theming và hiệu năng.

## Khi nào kích hoạt

- Xây dựng Compose UI (Jetpack Compose hoặc Compose Multiplatform)
- Quản lý UI state bằng ViewModel và Compose state
- Triển khai navigation trong dự án KMP hoặc Android
- Thiết kế composable tái sử dụng được và design system
- Tối ưu recomposition và hiệu năng rendering

## Quản lý State

### ViewModel + một State Object duy nhất

Dùng một data class duy nhất cho state của màn hình. Expose nó dưới dạng `StateFlow` và collect trong Compose:

```kotlin
data class ItemListState(
    val items: List<Item> = emptyList(),
    val isLoading: Boolean = false,
    val error: String? = null,
    val searchQuery: String = ""
)

class ItemListViewModel(
    private val getItems: GetItemsUseCase
) : ViewModel() {
    private val _state = MutableStateFlow(ItemListState())
    val state: StateFlow<ItemListState> = _state.asStateFlow()

    fun onSearch(query: String) {
        _state.update { it.copy(searchQuery = query) }
        loadItems(query)
    }

    private fun loadItems(query: String) {
        viewModelScope.launch {
            _state.update { it.copy(isLoading = true) }
            getItems(query).fold(
                onSuccess = { items -> _state.update { it.copy(items = items, isLoading = false) } },
                onFailure = { e -> _state.update { it.copy(error = e.message, isLoading = false) } }
            )
        }
    }
}
```

### Collect State trong Compose

```kotlin
@Composable
fun ItemListScreen(viewModel: ItemListViewModel = koinViewModel()) {
    val state by viewModel.state.collectAsStateWithLifecycle()

    ItemListContent(
        state = state,
        onSearch = viewModel::onSearch
    )
}

@Composable
private fun ItemListContent(
    state: ItemListState,
    onSearch: (String) -> Unit
) {
    // Stateless composable — easy to preview and test
}
```

### Pattern Event Sink

Với các màn hình phức tạp, dùng một sealed interface cho event thay vì nhiều lambda callback:

```kotlin
sealed interface ItemListEvent {
    data class Search(val query: String) : ItemListEvent
    data class Delete(val itemId: String) : ItemListEvent
    data object Refresh : ItemListEvent
}

// In ViewModel
fun onEvent(event: ItemListEvent) {
    when (event) {
        is ItemListEvent.Search -> onSearch(event.query)
        is ItemListEvent.Delete -> deleteItem(event.itemId)
        is ItemListEvent.Refresh -> loadItems(_state.value.searchQuery)
    }
}

// In Composable — single lambda instead of many
ItemListContent(
    state = state,
    onEvent = viewModel::onEvent
)
```

## Navigation

### Navigation an toàn kiểu (Compose Navigation 2.8+)

Định nghĩa route dưới dạng object `@Serializable`:

```kotlin
@Serializable data object HomeRoute
@Serializable data class DetailRoute(val id: String)
@Serializable data object SettingsRoute

@Composable
fun AppNavHost(navController: NavHostController = rememberNavController()) {
    NavHost(navController, startDestination = HomeRoute) {
        composable<HomeRoute> {
            HomeScreen(onNavigateToDetail = { id -> navController.navigate(DetailRoute(id)) })
        }
        composable<DetailRoute> { backStackEntry ->
            val route = backStackEntry.toRoute<DetailRoute>()
            DetailScreen(id = route.id)
        }
        composable<SettingsRoute> { SettingsScreen() }
    }
}
```

### Navigation cho Dialog và Bottom Sheet

Dùng `dialog()` và các pattern overlay thay vì show/hide theo kiểu imperative:

```kotlin
NavHost(navController, startDestination = HomeRoute) {
    composable<HomeRoute> { /* ... */ }
    dialog<ConfirmDeleteRoute> { backStackEntry ->
        val route = backStackEntry.toRoute<ConfirmDeleteRoute>()
        ConfirmDeleteDialog(
            itemId = route.itemId,
            onConfirm = { navController.popBackStack() },
            onDismiss = { navController.popBackStack() }
        )
    }
}
```

## Thiết kế Composable

### API dựa trên Slot

Thiết kế composable với các tham số slot để linh hoạt:

```kotlin
@Composable
fun AppCard(
    modifier: Modifier = Modifier,
    header: @Composable () -> Unit = {},
    content: @Composable ColumnScope.() -> Unit,
    actions: @Composable RowScope.() -> Unit = {}
) {
    Card(modifier = modifier) {
        Column {
            header()
            Column(content = content)
            Row(horizontalArrangement = Arrangement.End, content = actions)
        }
    }
}
```

### Thứ tự Modifier

Thứ tự modifier quan trọng — áp dụng theo trình tự sau:

```kotlin
Text(
    text = "Hello",
    modifier = Modifier
        .padding(16.dp)          // 1. Layout (padding, size)
        .clip(RoundedCornerShape(8.dp))  // 2. Shape
        .background(Color.White) // 3. Drawing (background, border)
        .clickable { }           // 4. Interaction
)
```

## UI đặc thù nền tảng trong KMP

### expect/actual cho Platform Composable

```kotlin
// commonMain
@Composable
expect fun PlatformStatusBar(darkIcons: Boolean)

// androidMain
@Composable
actual fun PlatformStatusBar(darkIcons: Boolean) {
    val systemUiController = rememberSystemUiController()
    SideEffect { systemUiController.setStatusBarColor(Color.Transparent, darkIcons) }
}

// iosMain
@Composable
actual fun PlatformStatusBar(darkIcons: Boolean) {
    // iOS handles this via UIKit interop or Info.plist
}
```

## Hiệu năng

### Stable Type cho Recomposition có thể bỏ qua (Skippable)

Đánh dấu class là `@Stable` hoặc `@Immutable` khi mọi property đều stable:

```kotlin
@Immutable
data class ItemUiModel(
    val id: String,
    val title: String,
    val description: String,
    val progress: Float
)
```

### Dùng `key()` và Lazy List đúng cách

```kotlin
LazyColumn {
    items(
        items = items,
        key = { it.id }  // Stable keys enable item reuse and animations
    ) { item ->
        ItemRow(item = item)
    }
}
```

### Trì hoãn việc đọc với `derivedStateOf`

```kotlin
val listState = rememberLazyListState()
val showScrollToTop by remember {
    derivedStateOf { listState.firstVisibleItemIndex > 5 }
}
```

### Tránh cấp phát (Allocation) trong Recomposition

```kotlin
// BAD — new lambda and list every recomposition
items.filter { it.isActive }.forEach { ActiveItem(it, onClick = { handle(it) }) }

// GOOD — key each item so callbacks stay attached to the right row
val activeItems = remember(items) { items.filter { it.isActive } }
activeItems.forEach { item ->
    key(item.id) {
        ActiveItem(item, onClick = { handle(item) })
    }
}
```

## Theming

### Dynamic Theming của Material 3

```kotlin
@Composable
fun AppTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    dynamicColor: Boolean = true,
    content: @Composable () -> Unit
) {
    val colorScheme = when {
        dynamicColor && Build.VERSION.SDK_INT >= Build.VERSION_CODES.S -> {
            if (darkTheme) dynamicDarkColorScheme(LocalContext.current)
            else dynamicLightColorScheme(LocalContext.current)
        }
        darkTheme -> darkColorScheme()
        else -> lightColorScheme()
    }

    MaterialTheme(colorScheme = colorScheme, content = content)
}
```

## Anti-Pattern cần tránh

- Dùng `mutableStateOf` trong ViewModel khi `MutableStateFlow` với `collectAsStateWithLifecycle` an toàn hơn về lifecycle
- Truyền `NavController` sâu vào các composable — hãy truyền lambda callback thay thế
- Tính toán nặng bên trong hàm `@Composable` — chuyển sang ViewModel hoặc `remember {}`
- Dùng `LaunchedEffect(Unit)` thay cho init của ViewModel — nó chạy lại khi thay đổi configuration trong một số thiết lập
- Tạo instance object mới trong tham số composable — gây recomposition không cần thiết

## Tham khảo

Xem skill: `android-clean-architecture` cho cấu trúc module và phân lớp.
Xem skill: `kotlin-coroutines-flows` cho các pattern coroutine và Flow.
