---
paths:
  - "**/*.dart"
  - "**/pubspec.yaml"
  - "**/analysis_options.yaml"
---
# Kiểm thử Dart/Flutter

> File này mở rộng [common/testing.md](../common/testing.md) với nội dung dành riêng cho Dart và Flutter.

## Test Framework

- **flutter_test** / **dart:test** — test runner tích hợp sẵn
- **mockito** (với `@GenerateMocks`) hoặc **mocktail** (không cần codegen) để mock
- **bloc_test** cho unit test BLoC/Cubit
- **fake_async** để điều khiển thời gian trong unit test
- **integration_test** cho test end-to-end trên thiết bị

## Các loại Test

| Loại | Công cụ | Vị trí | Khi nào viết |
|------|------|----------|---------------|
| Unit | `dart:test` | `test/unit/` | Toàn bộ domain logic, state manager, repository |
| Widget | `flutter_test` | `test/widget/` | Mọi widget có hành vi đáng kể |
| Golden | `flutter_test` | `test/golden/` | Các UI component quan trọng về thiết kế |
| Integration | `integration_test` | `integration_test/` | Các luồng người dùng quan trọng trên thiết bị thật/emulator |

## Unit Test: State Manager

### BLoC với `bloc_test`

```dart
group('CartBloc', () {
  late CartBloc bloc;
  late MockCartRepository repository;

  setUp(() {
    repository = MockCartRepository();
    bloc = CartBloc(repository);
  });

  tearDown(() => bloc.close());

  blocTest<CartBloc, CartState>(
    'emits updated items when CartItemAdded',
    build: () => bloc,
    act: (b) => b.add(CartItemAdded(testItem)),
    expect: () => [CartState(items: [testItem])],
  );

  blocTest<CartBloc, CartState>(
    'emits empty cart when CartCleared',
    seed: () => CartState(items: [testItem]),
    build: () => bloc,
    act: (b) => b.add(CartCleared()),
    expect: () => [const CartState()],
  );
});
```

### Riverpod với `ProviderContainer`

```dart
test('usersProvider loads users from repository', () async {
  final container = ProviderContainer(
    overrides: [userRepositoryProvider.overrideWithValue(FakeUserRepository())],
  );
  addTearDown(container.dispose);

  final result = await container.read(usersProvider.future);
  expect(result, isNotEmpty);
});
```

## Widget Test

```dart
testWidgets('CartPage shows item count badge', (tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        cartNotifierProvider.overrideWith(() => FakeCartNotifier([testItem])),
      ],
      child: const MaterialApp(home: CartPage()),
    ),
  );

  await tester.pump();
  expect(find.text('1'), findsOneWidget);
  expect(find.byType(CartItemTile), findsOneWidget);
});

testWidgets('shows empty state when cart is empty', (tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [cartNotifierProvider.overrideWith(() => FakeCartNotifier([]))],
      child: const MaterialApp(home: CartPage()),
    ),
  );

  await tester.pump();
  expect(find.text('Your cart is empty'), findsOneWidget);
});
```

## Ưu tiên Fake hơn Mock

Ưu tiên fake viết tay cho các dependency phức tạp:

```dart
class FakeUserRepository implements UserRepository {
  final _users = <String, User>{};
  Object? fetchError;

  @override
  Future<User?> getById(String id) async {
    if (fetchError != null) throw fetchError!;
    return _users[id];
  }

  @override
  Future<List<User>> getAll() async {
    if (fetchError != null) throw fetchError!;
    return _users.values.toList();
  }

  @override
  Stream<List<User>> watchAll() => Stream.value(_users.values.toList());

  @override
  Future<void> save(User user) async {
    _users[user.id] = user;
  }

  @override
  Future<void> delete(String id) async {
    _users.remove(id);
  }

  void addUser(User user) => _users[user.id] = user;
}
```

## Kiểm thử bất đồng bộ

```dart
// Use fake_async for controlling timers and Futures
test('debounce triggers after 300ms', () {
  fakeAsync((async) {
    final debouncer = Debouncer(delay: const Duration(milliseconds: 300));
    var callCount = 0;
    debouncer.run(() => callCount++);
    expect(callCount, 0);
    async.elapse(const Duration(milliseconds: 200));
    expect(callCount, 0);
    async.elapse(const Duration(milliseconds: 200));
    expect(callCount, 1);
  });
});
```

## Golden Test

```dart
testWidgets('UserCard golden test', (tester) async {
  await tester.pumpWidget(
    MaterialApp(home: UserCard(user: testUser)),
  );

  await expectLater(
    find.byType(UserCard),
    matchesGoldenFile('goldens/user_card.png'),
  );
});
```

Chạy `flutter test --update-goldens` khi có chủ ý thay đổi giao diện.

## Đặt tên Test

Dùng tên mô tả, tập trung vào hành vi:

```dart
test('returns null when user does not exist', () { ... });
test('throws NotFoundException when id is empty string', () { ... });
testWidgets('disables submit button while form is invalid', (tester) async { ... });
```

## Tổ chức Test

```
test/
├── unit/
│   ├── domain/
│   │   └── usecases/
│   └── data/
│       └── repositories/
├── widget/
│   └── presentation/
│       └── pages/
└── golden/
    └── widgets/

integration_test/
└── flows/
    ├── login_flow_test.dart
    └── checkout_flow_test.dart
```

## Coverage

- Mục tiêu line coverage 80%+ cho business logic (domain + state manager)
- Mọi chuyển đổi state đều phải có test: loading → success, loading → error, retry
- Chạy `flutter test --coverage` và kiểm tra `lcov.info` bằng một coverage reporter
- Coverage thấp hơn ngưỡng nên chặn CI
