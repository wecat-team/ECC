# Tạo và sử dụng Service

Service trong Angular là các đoạn code tái sử dụng, xử lý việc lấy dữ liệu, business logic hoặc quản lý state mà nhiều component hoặc service khác cần truy cập.

## Tạo một Service

Bạn có thể sinh một service bằng Angular CLI:

```bash
ng generate service my-data
```

Hoặc bạn có thể tạo thủ công một class TypeScript và gắn decorator `@Injectable()`.

```ts
import {Injectable} from '@angular/core';

@Injectable({
  providedIn: 'root',
})
export class BasicDataStore {
  private data: string[] = [];

  addData(item: string): void {
    this.data.push(item);
  }

  getData(): string[] {
    return [...this.data];
  }
}
```

### Tùy chọn `providedIn: 'root'`

Dùng `providedIn: 'root'` là cách được khuyến nghị cho hầu hết service. Nó yêu cầu Angular:

- **Tạo một instance duy nhất (singleton)** cho toàn bộ ứng dụng.
- **Cho phép dùng ở mọi nơi** một cách tự động, không cần liệt kê trong bất kỳ mảng `providers` nào.
- **Bật tree-shaking**, nghĩa là service chỉ được đưa vào JavaScript bundle cuối cùng nếu nó thực sự được inject ở đâu đó.

## Inject một Service

Khi service đã được tạo, bạn có thể inject nó vào component, directive hoặc service khác bằng hàm `inject()`.

### Inject vào Component

```ts
import {Component, inject} from '@angular/core';
import {BasicDataStore} from './basic-data-store.service';

@Component({
  selector: 'app-example',
  template: `
    <div>
      <p>Data items: {{ dataStore.getData().length }}</p>
      <button (click)="dataStore.addData('New Item')">Add Item</button>
    </div>
  `,
})
export class Example {
  // Inject the service as a class field
  dataStore = inject(BasicDataStore);
}
```

### Inject vào Service khác

Service có thể inject các service khác theo đúng cách tương tự.

```ts
import {Injectable, inject} from '@angular/core';
import {AdvancedDataStore} from './advanced-data-store.service';

@Injectable({
  providedIn: 'root',
})
export class BasicDataStore {
  // Injecting another service
  private advancedDataStore = inject(AdvancedDataStore);

  private data: string[] = [];

  getData(): string[] {
    // Combine data from this service and the injected service
    return [...this.data, ...this.advancedDataStore.getData()];
  }
}
```

## Các pattern Service nâng cao

Dù `providedIn: 'root'` bao phủ hầu hết các tình huống, đôi khi bạn có thể cần:

- **Instance riêng cho component**: Nếu một component cần instance cô lập của một service, hãy cung cấp nó trực tiếp trong mảng `@Component({ providers: [MyService] })` của component.
- **Factory provider**: Dùng để tạo động.
- **Value provider**: Dùng để inject các object cấu hình.
