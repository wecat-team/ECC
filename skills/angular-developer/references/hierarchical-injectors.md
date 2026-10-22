# Hierarchical Injector

Hệ thống dependency injection của Angular có tính phân cấp, nghĩa là service có thể được giới hạn phạm vi ở các cấp khác nhau của ứng dụng.

## Các loại phân cấp Injector

1. **Phân cấp `EnvironmentInjector`**: Được cấu hình qua `@Injectable({ providedIn: 'root' })` hoặc `ApplicationConfig.providers` khi bootstrap. Đây là các singleton toàn cục.
2. **Phân cấp `ElementInjector`**: Được tạo ngầm định tại mỗi phần tử DOM. Được cấu hình qua mảng `providers` hoặc `viewProviders` trong `@Component()` hoặc `@Directive()`.

## Quy tắc resolve

Khi một dependency được yêu cầu, Angular resolve nó qua hai pha:

1. Tìm ngược lên cây **`ElementInjector`**, bắt đầu từ component/directive yêu cầu lên đến root element.
2. Nếu không tìm thấy, tìm trong cây **`EnvironmentInjector`**, bắt đầu từ environment injector gần nhất lên đến root.
3. Nếu vẫn không tìm thấy, ném lỗi (trừ khi được đánh dấu optional).

## Resolution Modifier

Bạn có thể thay đổi cách Angular tìm một dependency bằng object tùy chọn trong `inject()`:

- **`optional`**: Nếu không tìm thấy dependency, trả về `null` thay vì ném lỗi.
- **`self`**: Chỉ kiểm tra `ElementInjector` hiện tại. Không tìm lên cây cha.
- **`skipSelf`**: Bắt đầu tìm từ `ElementInjector` cha, bỏ qua phần tử hiện tại.
- **`host`**: Dừng tìm kiếm khi chạm tới ranh giới view của host component.

```ts
@Component({...})
export class Example {
  // Returns null if not found instead of crashing
  optionalService = inject(MyService, { optional: true });

  // Skips this component's providers, looks at parent
  parentService = inject(ParentService, { skipSelf: true });
}
```

## `providers` so với `viewProviders`

Khi cung cấp một service ở cấp component:

- **`providers`**: Service khả dụng cho component, view (template) của nó và mọi **nội dung được project** (`<ng-content>`).
- **`viewProviders`**: Service khả dụng cho component và view của nó, nhưng **KHÔNG** khả dụng cho nội dung được project. Dùng cách này để cô lập service khỏi nội dung do bên sử dụng truyền vào.
