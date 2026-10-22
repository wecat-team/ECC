---
paths:
  - "**/*.dart"
  - "**/pubspec.yaml"
  - "**/analysis_options.yaml"
---
# Phong cách code Dart/Flutter

> File này mở rộng [common/coding-style.md](../common/coding-style.md) với nội dung dành riêng cho Dart và Flutter.

## Định dạng

- **dart format** cho mọi file `.dart` — được ép buộc trong CI (`dart format --set-exit-if-changed .`)
- Độ dài dòng: 80 ký tự (mặc định của dart format)
- Dùng trailing comma ở các danh sách đối số/tham số nhiều dòng để cải thiện diff và định dạng

## Bất biến (Immutability)

- Ưu tiên `final` cho biến cục bộ và `const` cho hằng số compile-time
- Dùng constructor `const` ở mọi nơi mà tất cả field đều là `final`
- Trả về các collection không thể sửa đổi từ API public (`List.unmodifiable`, `Map.unmodifiable`)
- Dùng `copyWith()` cho các thay đổi state trong các class state bất biến

```dart
// BAD
var count = 0;
List<String> items = ['a', 'b'];

// GOOD
final count = 0;
const items = ['a', 'b'];
```

## Đặt tên

Tuân theo quy ước của Dart:
- `camelCase` cho biến, tham số và named constructor
- `PascalCase` cho class, enum, typedef và extension
- `snake_case` cho tên file và tên library
- `SCREAMING_SNAKE_CASE` cho hằng số khai báo bằng `const` ở cấp cao nhất
- Thêm tiền tố `_` cho thành viên private
- Tên extension mô tả type mà nó mở rộng: `StringExtensions`, không phải `MyHelpers`

## Null Safety

- Tránh `!` (bang operator) — ưu tiên `?.`, `??`, `if (x != null)` hoặc pattern matching của Dart 3; chỉ dùng `!` khi giá trị null là lỗi lập trình và việc crash là hành vi đúng
- Tránh `late` trừ khi đảm bảo khởi tạo trước lần dùng đầu tiên (ưu tiên nullable hoặc khởi tạo trong constructor)
- Dùng `required` cho các tham số constructor luôn phải được cung cấp

```dart
// BAD — crashes at runtime if user is null
final name = user!.name;

// GOOD — null-aware operators
final name = user?.name ?? 'Unknown';

// GOOD — Dart 3 pattern matching (exhaustive, compiler-checked)
final name = switch (user) {
  User(:final name) => name,
  null => 'Unknown',
};

// GOOD — early-return null guard
String getUserName(User? user) {
  if (user == null) return 'Unknown';
  return user.name; // promoted to non-null after the guard
}
```

## Sealed Type và Pattern Matching (Dart 3+)

Dùng sealed class để mô hình hóa các hệ phân cấp state đóng:

```dart
sealed class AsyncState<T> {
  const AsyncState();
}

final class Loading<T> extends AsyncState<T> {
  const Loading();
}

final class Success<T> extends AsyncState<T> {
  const Success(this.data);
  final T data;
}

final class Failure<T> extends AsyncState<T> {
  const Failure(this.error);
  final Object error;
}
```

Luôn dùng `switch` đầy đủ (exhaustive) với sealed type — không dùng default/wildcard:

```dart
// BAD
if (state is Loading) { ... }

// GOOD
return switch (state) {
  Loading() => const CircularProgressIndicator(),
  Success(:final data) => DataWidget(data),
  Failure(:final error) => ErrorWidget(error.toString()),
};
```

## Xử lý lỗi

- Chỉ định kiểu exception trong mệnh đề `on` — KHÔNG BAO GIỜ dùng `catch (e)` trần
- KHÔNG BAO GIỜ catch các subtype của `Error` — chúng cho thấy bug lập trình
- Dùng các type kiểu `Result` hoặc sealed class cho các lỗi có thể phục hồi
- Tránh dùng exception để điều khiển luồng

```dart
// BAD
try {
  await fetchUser();
} catch (e) {
  log(e.toString());
}

// GOOD
try {
  await fetchUser();
} on NetworkException catch (e) {
  log('Network error: ${e.message}');
} on NotFoundException {
  handleNotFound();
}
```

## Async / Future

- Luôn `await` Future hoặc gọi `unawaited()` tường minh để báo hiệu việc cố ý fire-and-forget
- Không đánh dấu hàm là `async` nếu nó không bao giờ `await` thứ gì
- Dùng `Future.wait` / `Future.any` cho các thao tác đồng thời
- Kiểm tra `context.mounted` trước khi dùng `BuildContext` sau bất kỳ `await` nào (Flutter 3.7+)

```dart
// BAD — ignoring Future
fetchData(); // fire-and-forget without marking intent

// GOOD
unawaited(fetchData()); // explicit fire-and-forget
await fetchData();      // or properly awaited
```

## Import

- Dùng import `package:` xuyên suốt — KHÔNG BAO GIỜ dùng import tương đối (`../`) cho code xuyên feature hoặc xuyên layer
- Thứ tự: `dart:` → `package:` bên ngoài → `package:` nội bộ (cùng package)
- Không có import thừa — `dart analyze` ép buộc điều này bằng `unused_import`

## Code Generation

- File được sinh (`.g.dart`, `.freezed.dart`, `.gr.dart`) phải được commit hoặc gitignore một cách nhất quán — chọn một chiến lược cho mỗi dự án
- KHÔNG BAO GIỜ sửa thủ công file được sinh
- Chỉ đặt annotation của generator (`@JsonSerializable`, `@freezed`, `@riverpod`, v.v.) trên file nguồn chính thức (canonical)
