# Template-Driven Form

Template-driven form dùng two-way data binding (`[(ngModel)]`) để cập nhật data model trong component khi có thay đổi ở template và ngược lại. Chúng lý tưởng cho các form đơn giản và dùng các directive trong HTML template để quản lý state và validation của form.

## Các Directive cốt lõi

Template-driven form dựa vào `FormsModule`, module cung cấp các directive chính sau:

- `NgModel`: Đối chiếu các thay đổi giá trị trong phần tử form với data model (`[(ngModel)]`).
- `NgForm`: Tự động tạo một `FormGroup` cấp cao nhất được bind vào thẻ `<form>`.
- `NgModelGroup`: Tạo một `FormGroup` lồng nhau được bind vào một phần tử DOM.

## Thiết lập

Trước tiên, import `FormsModule` vào component hoặc module của bạn.

```ts
import {Component} from '@angular/core';
import {FormsModule} from '@angular/forms';

@Component({
  selector: 'app-user-form',
  imports: [FormsModule],
  templateUrl: './user-form.component.html',
})
export class UserForm {
  user = {name: '', role: 'Guest'};

  onSubmit() {
    console.log('Form submitted!', this.user);
  }
}
```

## Xây dựng Form Template

### Two-Way Binding với `[(ngModel)]`

Dùng `[(ngModel)]` trên các phần tử input. **Mọi phần tử dùng `[(ngModel)]` PHẢI có thuộc tính `name`.** Angular dùng thuộc tính `name` để đăng ký control với `NgForm` cha.

```html
<form #userForm="ngForm" (ngSubmit)="onSubmit()">
  <!-- Basic Input -->
  <div>
    <label for="name">Name:</label>
    <input type="text" id="name" required [(ngModel)]="user.name" name="name" #nameCtrl="ngModel" />
  </div>

  <!-- Select Box -->
  <div>
    <label for="role">Role:</label>
    <select id="role" [(ngModel)]="user.role" name="role">
      <option value="Admin">Admin</option>
      <option value="Guest">Guest</option>
    </select>
  </div>

  <!-- Submit Button (disabled if form is invalid) -->
  <button type="submit" [disabled]="!userForm.form.valid">Submit</button>
</form>
```

## Trạng thái Form và Control

Angular tự động áp dụng các CSS class cho control và form dựa trên trạng thái của chúng:

| Trạng thái         | Class nếu đúng                      | Class nếu sai  |
| :----------------- | :---------------------------------- | :------------- |
| Đã ghé thăm        | `ng-touched`                        | `ng-untouched` |
| Giá trị đã đổi     | `ng-dirty`                          | `ng-pristine`  |
| Giá trị hợp lệ     | `ng-valid`                          | `ng-invalid`   |
| Form đã submit     | `ng-submitted` (chỉ trên `<form>`)  | -              |

Bạn có thể dùng các class này để tạo phản hồi trực quan trong CSS:

```css
.ng-valid[required],
.ng-valid.required {
  border-left: 5px solid #42a948; /* green */
}
.ng-invalid:not(form) {
  border-left: 5px solid #a94442; /* red */
}
```

## Validation và thông báo lỗi

Để hiển thị thông báo lỗi có điều kiện, export directive `ngModel` ra một template reference variable (ví dụ: `#nameCtrl="ngModel"`).

```html
<input type="text" id="name" required [(ngModel)]="user.name" name="name" #nameCtrl="ngModel" />

<!-- Show error only if the control is invalid AND (touched OR dirty) -->
@if (nameCtrl.invalid && (nameCtrl.dirty || nameCtrl.touched)) {
<div class="alert alert-danger">
  @if (nameCtrl.errors?.['required']) {
  <div>Name is required.</div>
  }
</div>
}
```

## Submit Form

1. Dùng event `(ngSubmit)` trên phần tử `<form>`.
2. Bind trạng thái disabled của nút submit với tính hợp lệ tổng thể của form bằng template reference variable của `NgForm` (ví dụ: `[disabled]="!userForm.form.valid"`).

## Reset Form

Để reset form về trạng thái pristine bằng code (xóa giá trị và các cờ validation), dùng phương thức `reset()` trên instance `NgForm`.

```html
<button type="button" (click)="userForm.reset()">Reset</button>
```
