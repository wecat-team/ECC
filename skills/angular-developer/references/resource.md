# Reactivity bất đồng bộ với `resource`

> [!IMPORTANT]
> API `resource` hiện đang ở mức thử nghiệm (experimental) trong Angular.

`Resource` đưa việc lấy dữ liệu bất đồng bộ vào hệ thống reactivity dựa trên signal của Angular. Nó thực thi một hàm loader bất đồng bộ mỗi khi các dependency của nó thay đổi, và cung cấp trạng thái cùng kết quả dưới dạng các signal đồng bộ.

## Cách dùng cơ bản

Hàm `resource` nhận một object tùy chọn với hai property chính:

1. `params`: Một phép tính reactive (như `computed`). Khi các signal được đọc ở đây thay đổi, resource sẽ fetch lại.
2. `loader`: Một hàm bất đồng bộ lấy dữ liệu dựa trên các tham số.

```ts
import { Component, resource, signal, computed } from '@angular/core';

@Component({...})
export class UserProfile {
  userId = signal('123');

  userResource = resource({
    // Reactively tracking userId
    params: () => ({ id: this.userId() }),

    // Executes whenever params change
    loader: async ({ params, abortSignal }) => {
      const response = await fetch(`/api/users/${params.id}`, { signal: abortSignal });
      if (!response.ok) throw new Error('Network error');
      return response.json();
    }
  });

  // Use the resource value in computed signals
  userName = computed(() => {
    if (this.userResource.hasValue()) {
      return this.userResource.value()?.name;
    } else {
      return 'Loading...';
    }
  });
}
```

## Hủy Request

Nếu signal `params` thay đổi trong khi một loader trước đó vẫn đang chạy, `Resource` sẽ cố gắng hủy request đang chờ bằng `abortSignal` được cung cấp. **LUÔN LUÔN truyền `abortSignal` vào các lệnh `fetch` của bạn.**

## Tải lại dữ liệu

Bạn có thể ép resource chạy lại loader theo cách mệnh lệnh mà không cần params thay đổi bằng cách gọi `.reload()`.

```ts
this.userResource.reload();
```

## Các Signal trạng thái của Resource

Đối tượng `Resource` cung cấp nhiều signal để đọc trạng thái hiện tại của nó:

- `value()`: Dữ liệu đã resolve, hoặc `undefined`.
- `hasValue()`: Boolean dạng type-guard. `true` nếu có giá trị.
- `isLoading()`: Boolean cho biết loader có đang chạy hay không.
- `error()`: Lỗi do loader ném ra, hoặc `undefined`.
- `status()`: Một hằng chuỗi biểu thị trạng thái chính xác (`'idle'`, `'loading'`, `'resolved'`, `'error'`, `'reloading'`, `'local'`).

## Thay đổi cục bộ (Local Mutation)

Bạn có thể cập nhật giá trị của resource một cách lạc quan (optimistic) trực tiếp. Việc này đổi trạng thái thành `'local'`.

```ts
this.userResource.value.set({name: 'Optimistic Update'});
```

## Lấy dữ liệu reactive với `httpResource`

Nếu bạn đang dùng `HttpClient` của Angular, hãy ưu tiên dùng `httpResource`. Đây là một wrapper chuyên dụng tận dụng HTTP stack của Angular (bao gồm cả interceptor) trong khi vẫn cung cấp cùng API resource dựa trên signal.
