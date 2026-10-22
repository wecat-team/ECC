---
name: flutter-dart-code-review
description: Checklist code review Flutter/Dart không phụ thuộc thư viện, bao gồm best practice cho widget, pattern state management (BLoC, Riverpod, Provider, GetX, MobX, Signals), idiom Dart, hiệu năng, accessibility, bảo mật và clean architecture. Dùng khi review code Flutter hoặc Dart, bất kể project dùng thư viện state management nào.
metadata:
  origin: ECC
---

# Best Practice Code Review Flutter/Dart

Checklist toàn diện, không phụ thuộc thư viện, để review ứng dụng Flutter/Dart. Các nguyên tắc này áp dụng bất kể dùng giải pháp state management, thư viện routing hay DI framework nào.

---

## 1. Tình trạng chung của project

- [ ] Project theo cấu trúc thư mục nhất quán (feature-first hoặc layer-first)
- [ ] Tách biệt mối quan tâm (separation of concerns) đúng cách: tầng UI, business logic, data
- [ ] Không có business logic trong widget; widget thuần trình bày
- [ ] `pubspec.yaml` gọn gàng — không có dependency không dùng, version được ghim phù hợp
- [ ] `analysis_options.yaml` có bộ lint nghiêm ngặt với các thiết lập analyzer strict được bật
- [ ] Không có `print()` trong code production — dùng `log()` của `dart:developer` hoặc một package logging
- [ ] File sinh tự động (`.g.dart`, `.freezed.dart`, `.gr.dart`) được cập nhật hoặc nằm trong `.gitignore`
- [ ] Code đặc thù nền tảng được cô lập sau các abstraction

---

## 2. Cạm bẫy của ngôn ngữ Dart

- [ ] **Implicit dynamic**: Thiếu type annotation dẫn đến `dynamic` — bật `strict-casts`, `strict-inference`, `strict-raw-types`
- [ ] **Lạm dụng null safety**: Dùng `!` (bang operator) quá mức thay vì kiểm tra null đúng cách hoặc pattern matching của Dart 3 (`if (value case var v?)`)
- [ ] **Type promotion thất bại**: Dùng `this.field` ở chỗ mà promotion của biến cục bộ sẽ hoạt động
- [ ] **Catch quá rộng**: `catch (e)` không có mệnh đề `on`; luôn chỉ định kiểu exception
- [ ] **Catch `Error`**: Các subtype của `Error` chỉ ra bug và không nên bị catch
- [ ] **`async` thừa**: Hàm đánh dấu `async` nhưng không bao giờ `await` — overhead không cần thiết
- [ ] **Lạm dụng `late`**: `late` được dùng ở nơi nullable hoặc khởi tạo trong constructor sẽ an toàn hơn; đẩy lỗi sang runtime
- [ ] **Nối chuỗi trong vòng lặp**: Dùng `StringBuffer` thay vì `+` khi xây dựng chuỗi lặp
- [ ] **State có thể thay đổi trong ngữ cảnh `const`**: Các field trong class có `const` constructor không được mutable
- [ ] **Bỏ qua giá trị trả về `Future`**: Dùng `await` hoặc gọi `unawaited()` tường minh để thể hiện chủ đích
- [ ] **`var` ở nơi `final` dùng được**: Ưu tiên `final` cho biến cục bộ và `const` cho hằng số compile-time
- [ ] **Relative import**: Dùng import `package:` để nhất quán
- [ ] **Lộ collection mutable**: API public nên trả về view không thể sửa đổi, không phải `List`/`Map` thô
- [ ] **Thiếu pattern matching của Dart 3**: Ưu tiên switch expression và `if-case` hơn các kiểm tra `is` dài dòng và ép kiểu thủ công
- [ ] **Class dùng một lần để trả nhiều giá trị**: Dùng record Dart 3 `(String, int)` thay vì DTO chỉ dùng một lần
- [ ] **`print()` trong code production**: Dùng `log()` của `dart:developer` hoặc package logging của project; `print()` không có log level và không thể lọc

---

## 3. Best Practice cho Widget

### Phân rã widget:
- [ ] Không có widget nào có phương thức `build()` vượt quá ~80-100 dòng
- [ ] Widget được tách theo đóng gói (encapsulation) VÀ theo cách chúng thay đổi (ranh giới rebuild)
- [ ] Các helper method private `_build*()` trả về widget được tách thành class widget riêng (cho phép tái sử dụng element, lan truyền const và các tối ưu của framework)
- [ ] Ưu tiên Stateless widget hơn Stateful ở nơi không cần state cục bộ có thể thay đổi
- [ ] Widget được tách ra nằm trong file riêng khi có thể tái sử dụng

### Dùng const:
- [ ] `const` constructor được dùng bất cứ khi nào có thể — ngăn rebuild không cần thiết
- [ ] Literal `const` cho collection không thay đổi (`const []`, `const {}`)
- [ ] Constructor được khai báo `const` khi mọi field đều final

### Dùng key:
- [ ] `ValueKey` được dùng trong list/grid để giữ state qua các lần sắp xếp lại
- [ ] `GlobalKey` dùng tiết kiệm — chỉ khi thật sự cần truy cập state xuyên cây widget
- [ ] Tránh `UniqueKey` trong `build()` — nó ép rebuild mỗi frame
- [ ] `ObjectKey` được dùng khi định danh dựa trên một data object thay vì một giá trị đơn

### Theming & design system:
- [ ] Màu lấy từ `Theme.of(context).colorScheme` — không hardcode `Colors.red` hay giá trị hex
- [ ] Text style lấy từ `Theme.of(context).textTheme` — không dùng `TextStyle` inline với cỡ chữ thô
- [ ] Đã xác minh tương thích dark mode — không giả định nền sáng
- [ ] Khoảng cách và kích thước dùng design token hoặc hằng số nhất quán, không dùng magic number

### Độ phức tạp của phương thức build:
- [ ] Không có lời gọi mạng, file I/O hay tính toán nặng trong `build()`
- [ ] Không có `Future.then()` hay công việc `async` trong `build()`
- [ ] Không tạo subscription (`.listen()`) trong `build()`
- [ ] `setState()` được khoanh vùng vào cây con nhỏ nhất có thể

---

## 4. State Management (không phụ thuộc thư viện)

Các nguyên tắc này áp dụng cho mọi giải pháp state management của Flutter (BLoC, Riverpod, Provider, GetX, MobX, Signals, ValueNotifier, v.v.).

### Kiến trúc:
- [ ] Business logic nằm ngoài tầng widget — trong một thành phần state management (BLoC, Notifier, Controller, Store, ViewModel, v.v.)
- [ ] State manager nhận dependency qua injection, không tự khởi tạo bên trong
- [ ] Một tầng service hoặc repository trừu tượng hóa nguồn dữ liệu — widget và state manager không nên gọi trực tiếp API hay database
- [ ] State manager có một trách nhiệm duy nhất — không có manager "god" xử lý các mối quan tâm không liên quan
- [ ] Dependency giữa các thành phần tuân theo quy ước của giải pháp:
  - Trong **Riverpod**: provider phụ thuộc provider qua `ref.watch` là điều bình thường — chỉ đánh dấu các chuỗi vòng tròn hoặc rối rắm quá mức
  - Trong **BLoC**: bloc không nên phụ thuộc trực tiếp vào bloc khác — ưu tiên repository dùng chung hoặc điều phối ở tầng presentation
  - Trong các giải pháp khác: tuân theo quy ước được ghi trong tài liệu cho giao tiếp giữa các thành phần

### Bất biến & so sánh theo giá trị (cho các giải pháp state bất biến: BLoC, Riverpod, Redux):
- [ ] Đối tượng state là bất biến (immutable) — instance mới được tạo qua `copyWith()` hoặc constructor, không bao giờ mutate tại chỗ
- [ ] Class state implement `==` và `hashCode` đúng cách (mọi field đều được đưa vào so sánh)
- [ ] Cơ chế nhất quán trong toàn project — override thủ công, `Equatable`, `freezed`, record Dart hoặc cách khác
- [ ] Collection bên trong đối tượng state không bị lộ dưới dạng `List`/`Map` mutable thô

### Kỷ luật reactivity (cho các giải pháp reactive-mutation: MobX, GetX, Signals):
- [ ] State chỉ được thay đổi qua API reactive của giải pháp (`@action` trong MobX, `.value` trên signal, `.obs` trong GetX) — thay đổi trực tiếp field sẽ bỏ qua việc theo dõi thay đổi
- [ ] Giá trị dẫn xuất dùng cơ chế computed của giải pháp thay vì lưu trữ dư thừa
- [ ] Reaction và disposer được dọn dẹp đúng cách (`ReactionDisposer` trong MobX, effect cleanup trong Signals)

### Thiết kế hình dạng state:
- [ ] Các state loại trừ lẫn nhau dùng sealed type, union variant hoặc kiểu async state có sẵn của giải pháp (ví dụ `AsyncValue` của Riverpod) — không dùng cờ boolean (`isLoading`, `isError`, `hasData`)
- [ ] Mỗi thao tác async mô hình hóa loading, success và error thành các state riêng biệt
- [ ] Mọi biến thể state đều được xử lý đầy đủ (exhaustive) trong UI — không có trường hợp bị bỏ qua âm thầm
- [ ] State lỗi mang thông tin lỗi để hiển thị; state loading không mang dữ liệu cũ
- [ ] Không dùng dữ liệu nullable làm chỉ báo loading — state phải tường minh

```dart
// BAD — boolean flag soup allows impossible states
class UserState {
  bool isLoading = false;
  bool hasError = false; // isLoading && hasError is representable!
  User? user;
}

// GOOD (immutable approach) — sealed types make impossible states unrepresentable
sealed class UserState {}
class UserInitial extends UserState {}
class UserLoading extends UserState {}
class UserLoaded extends UserState {
  final User user;
  const UserLoaded(this.user);
}
class UserError extends UserState {
  final String message;
  const UserError(this.message);
}

// GOOD (reactive approach) — observable enum + data, mutations via reactivity API
// enum UserStatus { initial, loading, loaded, error }
// Use your solution's observable/signal to wrap status and data separately
```

### Tối ưu rebuild:
- [ ] Widget tiêu thụ state (Builder, Consumer, Observer, Obx, Watch, v.v.) có phạm vi hẹp nhất có thể
- [ ] Dùng selector để chỉ rebuild khi các field cụ thể thay đổi — không phải mỗi lần state phát ra
- [ ] Widget `const` được dùng để chặn rebuild lan truyền xuống cây
- [ ] State computed/dẫn xuất được tính theo cách reactive, không lưu trữ dư thừa

### Subscription & hủy tài nguyên:
- [ ] Mọi subscription thủ công (`.listen()`) được cancel trong `dispose()` / `close()`
- [ ] Stream controller được đóng khi không còn cần
- [ ] Timer được cancel trong vòng đời dispose
- [ ] Ưu tiên vòng đời do framework quản lý hơn subscription thủ công (declarative builder thay vì `.listen()`)
- [ ] Kiểm tra `mounted` trước `setState` trong callback async
- [ ] Không dùng `BuildContext` sau `await` mà không kiểm tra `context.mounted` (Flutter 3.7+) — context cũ gây crash
- [ ] Không điều hướng, hiển thị dialog hay scaffold message sau khoảng trống async mà không xác minh widget vẫn còn mounted
- [ ] `BuildContext` không bao giờ được lưu trong singleton, state manager hay static field

### State cục bộ vs toàn cục:
- [ ] State UI tạm thời (checkbox, slider, animation) dùng state cục bộ (`setState`, `ValueNotifier`)
- [ ] State dùng chung chỉ được nâng lên cao đến mức cần thiết — không toàn cục hóa quá mức
- [ ] State theo phạm vi feature được dispose đúng cách khi feature không còn active

---

## 5. Hiệu năng

### Rebuild không cần thiết:
- [ ] Không gọi `setState()` ở cấp root widget — khoanh vùng thay đổi state
- [ ] Widget `const` được dùng để chặn rebuild lan truyền
- [ ] `RepaintBoundary` được dùng quanh các cây con phức tạp repaint độc lập
- [ ] Tham số child của `AnimatedBuilder` được dùng cho các cây con độc lập với animation

### Thao tác tốn kém trong build():
- [ ] Không sắp xếp, lọc hay map collection lớn trong `build()` — tính trong tầng state management
- [ ] Không compile regex trong `build()`
- [ ] Cách dùng `MediaQuery.of(context)` phải cụ thể (ví dụ `MediaQuery.sizeOf(context)`)

### Tối ưu hình ảnh:
- [ ] Ảnh từ mạng dùng caching (bất kỳ giải pháp caching nào phù hợp với project)
- [ ] Độ phân giải ảnh phù hợp với thiết bị đích (không tải ảnh 4K cho thumbnail)
- [ ] `Image.asset` với `cacheWidth`/`cacheHeight` để decode ở kích thước hiển thị
- [ ] Có placeholder và error widget cho ảnh từ mạng

### Lazy loading:
- [ ] Dùng `ListView.builder` / `GridView.builder` thay vì `ListView(children: [...])` cho list lớn hoặc động (constructor cụ thể vẫn ổn cho list nhỏ, tĩnh)
- [ ] Có phân trang (pagination) cho tập dữ liệu lớn
- [ ] Dùng deferred loading (`deferred as`) cho thư viện nặng trong bản build web

### Khác:
- [ ] Tránh widget `Opacity` trong animation — dùng `AnimatedOpacity` hoặc `FadeTransition`
- [ ] Tránh clipping trong animation — clip trước ảnh
- [ ] Không override `operator ==` trên widget — dùng `const` constructor thay thế
- [ ] Widget kích thước nội tại (`IntrinsicHeight`, `IntrinsicWidth`) dùng tiết kiệm (thêm một lượt layout)

---

## 6. Testing

### Loại test và kỳ vọng:
- [ ] **Unit test**: Bao phủ toàn bộ business logic (state manager, repository, hàm tiện ích)
- [ ] **Widget test**: Bao phủ hành vi, tương tác và đầu ra hiển thị của từng widget
- [ ] **Integration test**: Bao phủ các luồng người dùng quan trọng end-to-end
- [ ] **Golden test**: So sánh chính xác đến từng pixel cho các thành phần UI quan trọng về thiết kế

### Mục tiêu coverage:
- [ ] Hướng tới 80%+ line coverage cho business logic
- [ ] Mọi chuyển đổi state đều có test tương ứng (loading → success, loading → error, retry, v.v.)
- [ ] Đã test các edge case: state rỗng, state lỗi, state loading, giá trị biên

### Cô lập test:
- [ ] Dependency bên ngoài (API client, database, service) được mock hoặc fake
- [ ] Mỗi file test chỉ test đúng một class/đơn vị
- [ ] Test xác minh hành vi, không phải chi tiết triển khai
- [ ] Stub chỉ định nghĩa hành vi cần cho mỗi test (stub tối thiểu)
- [ ] Không có state mutable dùng chung giữa các test case

### Chất lượng widget test:
- [ ] `pumpWidget` và `pump` được dùng đúng cho thao tác async
- [ ] `find.byType`, `find.text`, `find.byKey` được dùng phù hợp
- [ ] Không có test flaky phụ thuộc thời gian — dùng `pumpAndSettle` hoặc `pump(Duration)` tường minh
- [ ] Test chạy trong CI và test lỗi chặn merge

---

## 7. Accessibility

### Semantic widget:
- [ ] Widget `Semantics` được dùng để cung cấp nhãn screen reader ở nơi nhãn tự động không đủ
- [ ] `ExcludeSemantics` được dùng cho các phần tử thuần trang trí
- [ ] `MergeSemantics` được dùng để gộp các widget liên quan thành một phần tử accessible duy nhất
- [ ] Ảnh có thuộc tính `semanticLabel` được đặt

### Hỗ trợ screen reader:
- [ ] Mọi phần tử tương tác đều focus được và có mô tả có ý nghĩa
- [ ] Thứ tự focus hợp lý (theo thứ tự đọc trực quan)

### Accessibility thị giác:
- [ ] Tỷ lệ tương phản >= 4.5:1 cho chữ so với nền
- [ ] Vùng có thể chạm tối thiểu 48x48 pixel
- [ ] Màu không phải chỉ báo duy nhất của trạng thái (dùng thêm icon/chữ)
- [ ] Chữ co giãn theo thiết lập cỡ chữ của hệ thống

### Accessibility tương tác:
- [ ] Không có callback `onPressed` rỗng — mỗi nút đều làm gì đó hoặc bị disable
- [ ] Trường lỗi gợi ý cách sửa
- [ ] Context không thay đổi bất ngờ khi người dùng đang nhập dữ liệu

---

## 8. Vấn đề đặc thù nền tảng

### Khác biệt iOS/Android:
- [ ] Widget thích ứng nền tảng được dùng khi phù hợp
- [ ] Điều hướng quay lại được xử lý đúng (nút back Android, vuốt để quay lại trên iOS)
- [ ] Status bar và safe area được xử lý qua widget `SafeArea`
- [ ] Quyền đặc thù nền tảng được khai báo trong `AndroidManifest.xml` và `Info.plist`

### Thiết kế responsive:
- [ ] `LayoutBuilder` hoặc `MediaQuery` được dùng cho layout responsive
- [ ] Breakpoint được định nghĩa nhất quán (phone, tablet, desktop)
- [ ] Chữ không tràn trên màn hình nhỏ — dùng `Flexible`, `Expanded`, `FittedBox`
- [ ] Hướng ngang (landscape) đã được test hoặc khóa tường minh
- [ ] Riêng web: hỗ trợ tương tác chuột/bàn phím, có hover state

---

## 9. Bảo mật

### Lưu trữ an toàn:
- [ ] Dữ liệu nhạy cảm (token, credential) được lưu bằng secure storage của nền tảng (Keychain trên iOS, EncryptedSharedPreferences trên Android)
- [ ] KHÔNG BAO GIỜ lưu secret trong storage dạng plaintext
- [ ] Cân nhắc yêu cầu xác thực sinh trắc học (biometric) cho các thao tác nhạy cảm

### Xử lý API key:
- [ ] API key KHÔNG được hardcode trong source Dart — dùng `--dart-define`, file `.env` loại khỏi VCS, hoặc cấu hình compile-time
- [ ] Secret không được commit vào git — kiểm tra `.gitignore`
- [ ] Dùng backend proxy cho các key thật sự bí mật (client không bao giờ nên giữ secret của server)

### Kiểm tra đầu vào (input validation):
- [ ] Mọi input của người dùng được validate trước khi gửi tới API
- [ ] Form validation dùng pattern validation phù hợp
- [ ] Không có SQL thô hay nội suy chuỗi từ input của người dùng
- [ ] URL deep link được validate và sanitize trước khi điều hướng

### Bảo mật mạng:
- [ ] Bắt buộc HTTPS cho mọi lời gọi API
- [ ] Cân nhắc certificate pinning cho ứng dụng yêu cầu bảo mật cao
- [ ] Token xác thực được refresh và hết hạn đúng cách
- [ ] Không log hay print dữ liệu nhạy cảm

---

## 10. Review Package/Dependency

### Đánh giá package pub.dev:
- [ ] Kiểm tra **pub points score** (hướng tới 130+/160)
- [ ] Kiểm tra **likes** và **popularity** như tín hiệu cộng đồng
- [ ] Xác minh publisher đã được **verified** trên pub.dev
- [ ] Kiểm tra ngày publish gần nhất — package cũ (>1 năm) là rủi ro
- [ ] Xem các issue đang mở và thời gian phản hồi của maintainer
- [ ] Kiểm tra tính tương thích license với project của bạn
- [ ] Xác minh hỗ trợ nền tảng bao phủ các target của bạn

### Ràng buộc version:
- [ ] Dùng cú pháp caret (`^1.2.3`) cho dependency — cho phép cập nhật tương thích
- [ ] Chỉ ghim version chính xác khi thật sự cần thiết
- [ ] Chạy `flutter pub outdated` thường xuyên để theo dõi dependency cũ
- [ ] Không có dependency override trong `pubspec.yaml` production — chỉ cho bản sửa tạm thời kèm comment/link issue
- [ ] Giảm thiểu số lượng transitive dependency — mỗi dependency là một bề mặt tấn công

### Riêng cho monorepo (melos/workspace):
- [ ] Package nội bộ chỉ import từ public API — không dùng `package:other/src/internal.dart` (phá vỡ đóng gói của package Dart)
- [ ] Dependency của package nội bộ dùng workspace resolution, không dùng chuỗi tương đối `path: ../../` hardcode
- [ ] Mọi sub-package dùng chung hoặc kế thừa `analysis_options.yaml` ở root

---

## 11. Điều hướng và Routing

### Nguyên tắc chung (áp dụng cho mọi giải pháp routing):
- [ ] Dùng một cách tiếp cận routing nhất quán — không trộn `Navigator.push` imperative với router declarative
- [ ] Tham số route có kiểu — không ép kiểu `Map<String, dynamic>` hay `Object?`
- [ ] Đường dẫn route được định nghĩa dưới dạng hằng số, enum hoặc sinh tự động — không có magic string rải rác trong code
- [ ] Auth guard/redirect tập trung — không lặp lại ở từng màn hình
- [ ] Deep link được cấu hình cho cả Android và iOS
- [ ] URL deep link được validate và sanitize trước khi điều hướng
- [ ] State điều hướng test được — thay đổi route có thể được xác minh trong test
- [ ] Hành vi quay lại đúng trên mọi nền tảng

---

## 12. Xử lý lỗi

### Xử lý lỗi của framework:
- [ ] Override `FlutterError.onError` để bắt lỗi framework (build, layout, paint)
- [ ] Đặt `PlatformDispatcher.instance.onError` cho lỗi async mà Flutter không bắt
- [ ] Tùy biến `ErrorWidget.builder` cho chế độ release (thân thiện với người dùng thay vì màn hình đỏ)
- [ ] Wrapper bắt lỗi toàn cục quanh `runApp` (ví dụ `runZonedGuarded`, wrapper Sentry/Crashlytics)

### Báo cáo lỗi:
- [ ] Đã tích hợp dịch vụ báo cáo lỗi (Firebase Crashlytics, Sentry hoặc tương đương)
- [ ] Lỗi non-fatal được báo cáo kèm stack trace
- [ ] Error observer của state management được nối với báo cáo lỗi (ví dụ BlocObserver, ProviderObserver hoặc tương đương cho giải pháp của bạn)
- [ ] Thông tin định danh người dùng (user ID) được đính kèm báo cáo lỗi để debug

### Suy giảm êm dịu (graceful degradation):
- [ ] Lỗi API dẫn đến UI lỗi thân thiện với người dùng, không crash
- [ ] Có cơ chế retry cho lỗi mạng tạm thời
- [ ] Trạng thái offline được xử lý êm dịu
- [ ] State lỗi trong state management mang thông tin lỗi để hiển thị
- [ ] Exception thô (mạng, parsing) được ánh xạ thành thông báo thân thiện, đã bản địa hóa trước khi tới UI — KHÔNG BAO GIỜ hiển thị chuỗi exception thô cho người dùng

---

## 13. Quốc tế hóa (l10n)

### Thiết lập:
- [ ] Đã cấu hình giải pháp localization (ARB/l10n tích hợp của Flutter, easy_localization hoặc tương đương)
- [ ] Các locale được hỗ trợ được khai báo trong cấu hình app

### Nội dung:
- [ ] Mọi chuỗi hiển thị cho người dùng dùng hệ thống localization — không hardcode chuỗi trong widget
- [ ] File template có mô tả/ngữ cảnh cho người dịch
- [ ] Cú pháp message ICU được dùng cho số nhiều, giới tính, select
- [ ] Placeholder được định nghĩa kèm kiểu
- [ ] Không thiếu key giữa các locale

### Code review:
- [ ] Accessor localization được dùng nhất quán trong toàn project
- [ ] Định dạng ngày, giờ, số và tiền tệ nhận biết locale
- [ ] Hỗ trợ hướng văn bản (RTL) nếu nhắm tới tiếng Ả Rập, Do Thái, v.v.
- [ ] Không nối chuỗi cho văn bản đã bản địa hóa — dùng message có tham số

---

## 14. Dependency Injection

### Nguyên tắc (áp dụng cho mọi cách tiếp cận DI):
- [ ] Class phụ thuộc vào abstraction (interface), không phải implementation cụ thể ở ranh giới giữa các tầng
- [ ] Dependency được cung cấp từ bên ngoài qua constructor, DI framework hoặc provider graph — không tạo bên trong
- [ ] Việc đăng ký phân biệt vòng đời: singleton vs factory vs lazy singleton
- [ ] Binding theo môi trường (dev/staging/prod) dùng cấu hình, không dùng kiểm tra `if` lúc runtime
- [ ] Không có dependency vòng tròn trong DI graph
- [ ] Lời gọi service locator (nếu dùng) không rải rác khắp business logic

---

## 15. Phân tích tĩnh (Static Analysis)

### Cấu hình:
- [ ] Có `analysis_options.yaml` với các thiết lập strict được bật
- [ ] Thiết lập analyzer strict: `strict-casts: true`, `strict-inference: true`, `strict-raw-types: true`
- [ ] Có bao gồm bộ rule lint toàn diện (very_good_analysis, flutter_lints hoặc rule strict tùy chỉnh)
- [ ] Mọi sub-package trong monorepo kế thừa hoặc dùng chung analysis option ở root

### Thực thi:
- [ ] Không còn analyzer warning chưa giải quyết trong code đã commit
- [ ] Các lint suppression (`// ignore:`) được biện minh bằng comment giải thích lý do
- [ ] `flutter analyze` chạy trong CI và lỗi chặn merge

### Các rule chính cần xác minh bất kể package lint:
- [ ] `prefer_const_constructors` — hiệu năng trong cây widget
- [ ] `avoid_print` — dùng logging đúng cách
- [ ] `unawaited_futures` — ngăn bug async fire-and-forget
- [ ] `prefer_final_locals` — tính bất biến ở cấp biến
- [ ] `always_declare_return_types` — hợp đồng tường minh
- [ ] `avoid_catches_without_on_clauses` — xử lý lỗi cụ thể
- [ ] `always_use_package_imports` — phong cách import nhất quán

---

## Tham chiếu nhanh State Management

Bảng dưới đây ánh xạ các nguyên tắc chung sang cách triển khai trong các giải pháp phổ biến. Dùng nó để điều chỉnh các rule review cho phù hợp với giải pháp mà project đang dùng.

| Nguyên tắc | BLoC/Cubit | Riverpod | Provider | GetX | MobX | Signals | Tích hợp sẵn |
|-----------|-----------|----------|----------|------|------|---------|----------|
| State container | `Bloc`/`Cubit` | `Notifier`/`AsyncNotifier` | `ChangeNotifier` | `GetxController` | `Store` | `signal()` | `StatefulWidget` |
| UI consumer | `BlocBuilder` | `ConsumerWidget` | `Consumer` | `Obx`/`GetBuilder` | `Observer` | `Watch` | `setState` |
| Selector | `BlocSelector`/`buildWhen` | `ref.watch(p.select(...))` | `Selector` | N/A | computed | `computed()` | N/A |
| Side effect | `BlocListener` | `ref.listen` | callback của `Consumer` | `ever()`/`once()` | `reaction` | `effect()` | callback |
| Hủy (disposal) | tự động qua `BlocProvider` | `.autoDispose` | tự động qua `Provider` | `onClose()` | `ReactionDisposer` | thủ công | `dispose()` |
| Testing | `blocTest()` | `ProviderContainer` | `ChangeNotifier` trực tiếp | `Get.put` trong test | store trực tiếp | signal trực tiếp | widget test |

---

## Nguồn tham khảo

- [Effective Dart: Style](https://dart.dev/effective-dart/style)
- [Effective Dart: Usage](https://dart.dev/effective-dart/usage)
- [Effective Dart: Design](https://dart.dev/effective-dart/design)
- [Flutter Performance Best Practices](https://docs.flutter.dev/perf/best-practices)
- [Flutter Testing Overview](https://docs.flutter.dev/testing/overview)
- [Flutter Accessibility](https://docs.flutter.dev/ui/accessibility-and-internationalization/accessibility)
- [Flutter Internationalization](https://docs.flutter.dev/ui/accessibility-and-internationalization/internationalization)
- [Flutter Navigation and Routing](https://docs.flutter.dev/ui/navigation)
- [Flutter Error Handling](https://docs.flutter.dev/testing/errors)
- [Flutter State Management Options](https://docs.flutter.dev/data-and-backend/state-mgmt/options)
