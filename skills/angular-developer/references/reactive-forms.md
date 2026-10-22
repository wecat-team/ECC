# Reactive Form

Reactive form cung cấp cách tiếp cận hướng model (model-driven) để xử lý input của form. Chúng được xây dựng quanh các observable stream và cho phép truy cập đồng bộ vào data model, giúp chúng dễ mở rộng và dễ kiểm thử hơn template-driven form.

## Các class cốt lõi

Reactive form được xây dựng bằng các class cơ bản sau từ `@angular/forms`:

- `FormControl`: Quản lý giá trị và tính hợp lệ của một input riêng lẻ.
- `FormGroup`: Quản lý một nhóm control (cấu trúc giống object).
- `FormArray`: Quản lý một mảng các control được đánh chỉ mục số.
- `FormBuilder`: Một service cung cấp các factory method để tạo control instance.

## Thiết lập

Import `ReactiveFormsModule` vào component của bạn.

```ts
import {Component, inject} from '@angular/core';
import {ReactiveFormsModule, FormGroup, FormControl, Validators, FormBuilder} from '@angular/forms';

@Component({
  selector: 'app-profile-editor',
  imports: [ReactiveFormsModule],
  templateUrl: './profile-editor.component.html',
})
export class ProfileEditor {
  private fb = inject(FormBuilder);

  // Using FormBuilder for concise definition
  profileForm = this.fb.group({
    firstName: ['', Validators.required],
    lastName: [''],
    address: this.fb.group({
      street: [''],
      city: [''],
    }),
    aliases: this.fb.array([this.fb.control('')]),
  });

  onSubmit() {
    console.warn(this.profileForm.value);
  }
}
```

## Template Binding

Dùng các directive để bind model vào view:

- `[formGroup]`: Bind một `FormGroup` vào `<form>` hoặc `<div>`.
- `formControlName`: Bind một control có tên trong một group vào một input.
- `formGroupName`: Bind một `FormGroup` lồng nhau.
- `formArrayName`: Bind một `FormArray` lồng nhau.
- `[formControl]`: Bind một `FormControl` độc lập.

```html
<form [formGroup]="profileForm" (ngSubmit)="onSubmit()">
  <input type="text" formControlName="firstName" />

  <div formGroupName="address">
    <input type="text" formControlName="street" />
  </div>

  <div formArrayName="aliases">
    @for (alias of aliases.controls; track $index) {
    <input type="text" [formControlName]="$index" />
    }
  </div>

  <button type="submit" [disabled]="!profileForm.valid">Submit</button>
</form>
```

## Truy cập Control

Dùng getter để truy cập control dễ dàng, đặc biệt với `FormArray`.

```ts
get aliases() {
  return this.profileForm.get('aliases') as FormArray;
}

addAlias() {
  this.aliases.push(this.fb.control(''));
}
```

## Cập nhật giá trị

- `patchValue()`: Chỉ cập nhật các property được chỉ định. Thất bại âm thầm khi cấu trúc không khớp.
- `setValue()`: Thay thế toàn bộ model. Bắt buộc nghiêm ngặt theo cấu trúc form.

```ts
updateProfile() {
  this.profileForm.patchValue({
    firstName: 'Nancy',
    address: { street: '123 Drew Street' }
  });
}
```

## Unified Change Event

Angular hiện đại (v18+) cung cấp một observable `events` duy nhất trên mọi control để theo dõi các event value, status, pristine, touched, reset và submit.

```ts
import {ValueChangeEvent, StatusChangeEvent} from '@angular/forms';

this.profileForm.events.subscribe((event) => {
  if (event instanceof ValueChangeEvent) {
    console.log('New value:', event.value);
  }
});
```

## Quản lý state thủ công

- `markAsTouched()` / `markAllAsTouched()`: Hữu ích để hiển thị lỗi validation khi submit.
- `markAsDirty()` / `markAsPristine()`: Theo dõi xem giá trị đã bị chỉnh sửa hay chưa.
- `updateValueAndValidity()`: Kích hoạt thủ công việc tính lại giá trị và trạng thái.
- Có thể truyền các tùy chọn `{ emitEvent: false }` hoặc `{ onlySelf: true }` cho hầu hết các phương thức để kiểm soát việc lan truyền.
