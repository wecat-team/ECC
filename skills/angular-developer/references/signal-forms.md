# Signal Form

Signal Form được khuyến nghị cho các form mới khi phiên bản Angular mục tiêu hỗ trợ chúng. Chúng cung cấp cách quản lý state của form theo hướng reactive, type-safe và model-driven bằng Angular Signal.

Khi dùng Signal Form, không dùng `null` làm giá trị hoặc type của bất kỳ field nào.

## Import

Bạn có thể import các thành phần sau từ `@angular/forms/signals`:

```ts
import {
  form,
  FormField,
  submit,
  // Rules for field state
  disabled,
  hidden,
  readonly,
  debounce,
  // Schema helpers
  applyWhen,
  applyEach,
  schema,
  // Custom validation
  validate,
  validateHttp,
  validateStandardSchema,
  // Metadata
  metadata,
} from '@angular/forms/signals';
```

## Tạo một Form

Dùng hàm `form()` với một Signal model. Cấu trúc của form được dẫn xuất trực tiếp từ model.

```ts
import {Component, signal} from '@angular/core';
import {form, FormField} from '@angular/forms/signals';

@Component({
  // ...
  imports: [FormField],
})
export class Example {
  // 1. Define your model with initial values (avoid undefined)
  userModel = signal({
    name: '', // CRITICAL: NEVER use null or undefined as initial values
    email: '',
    age: 0, // Use 0 for numbers, NOT null
    address: {
      street: '',
      city: '',
    },
    hobbies: [] as string[], // Use [] for arrays, NOT null
  });

  // WRONG - DO NOT DO THIS:
  // badModel = signal({
  //   name: null,      // ERROR: use '' instead
  //   age: null,       // ERROR: use 0 instead
  //   items: null      // ERROR: use [] instead
  // });

  // 2. Create the form
  userForm = form(this.userModel);
}
```

## Validation

Import các validator từ `@angular/forms/signals`.

```ts
import {required, email, min, max, minLength, maxLength, pattern} from '@angular/forms/signals';
```

Dùng chúng trong schema function được truyền vào `form()`:

```ts
userForm = form(this.userModel, (schemaPath) => {
  // Required
  required(schemaPath.name, {message: 'Name is required'});

  // Conditional required.
  required(schemaPath.name, {
    when({valueOf}) {
      return valueOf(schemaPath.age) > 10;
    },
  });
  // when is only available for required
  // Do NOT do this: pattern(p.name, /xxx/, {when /* ERROR */)

  // Email
  email(schemaPath.email, {message: 'Invalid email'});

  // Min/Max for numbers
  min(schemaPath.age, 18);
  max(schemaPath.age, 100);

  // MinLength/MaxLength for strings/arrays
  minLength(schemaPath.password, 8);
  maxLength(schemaPath.description, 500);

  // Pattern (Regex)
  pattern(schemaPath.zipCode, /^\d{5}$/);
});
```

## FieldState so với FormField: Yêu cầu bắt buộc phải gọi (The Parental Requirement)

Điều quan trọng là phải hiểu sự khác biệt giữa **FormField** (cấu trúc) và **FieldState** (dữ liệu/signal thực sự).

**QUY TẮC**: Bạn PHẢI **GỌI** một field như một hàm để truy cập các state signal của nó (valid, touched, dirty, hidden, v.v.).

```ts
// f is a FormField (structural)
const f = form(signal({cat: {name: 'pirojok-the-cat', age: 5}}));

f.cat.name; // FormField: You can't get flags from here!
f.cat.name.touched(); // ERROR: touched() does not exist on FormField

f.cat.name(); // FieldState: Calling it gives you access to signals
f.cat.name().touched(); // VALID: Accessing the signal
f.cat().name.touched(); // ERROR: f.cat() is state, it doesn't have children!
```

Tương tự trong template:

```html
<!-- WRONG: Property 'hidden' does not exist on type 'FormField' -->
@if (bookingForm.hotelDetails.hidden()) { ... }

<!-- RIGHT: Call it first -->
@if (bookingForm.hotelDetails().hidden()) { ... }
```

## Disabled / Readonly / Hidden

Kiểm soát trạng thái field bằng các rule trong schema.

```ts
import {disabled, readonly, hidden} from '@angular/forms/signals';

userForm = form(this.userModel, (schemaPath) => {
  // Conditionally disabled
  disabled(schemaPath.password, ({valueOf}) => !valueOf(schemaPath.createAccount));

  // Conditionally hidden (does NOT remove from model, just marks as hidden)
  hidden(schemaPath.shippingAddress, ({valueOf}) => valueOf(schemaPath.sameAsBilling));

  // Readonly
  readonly(schemaPath.username);
});
```

## Binding

Import `FormField` và dùng directive `[formField]`.

```ts
import {FormField} from '@angular/forms/signals';
```

Mọi property trên state, như `disabled`, `hidden`, `readonly` và `name`, đều được bind tự động.
KHÔNG bind field `name`.

**QUAN TRỌNG: CÁC ATTRIBUTE BỊ CẤM**
Khi dùng `[formField]`, bạn KHÔNG ĐƯỢC đặt các attribute sau trong template (dù là tĩnh hay bound):

- `min`, `max` (Hãy dùng validator trong schema thay thế)
- `value`, `[value]`, `[attr.value]` (Đã được `[formField]` xử lý)
- `[attr.min]`, `[attr.max]`
- `[disabled]`, `[readonly]` (Đã được `[formField]` xử lý)

KHÔNG làm thế này: `<input min="1" [formField]>` hoặc `<input [value]="val" [formField]>`.

```html
<!-- Input -->
<input [formField]="userForm.name" />

<!-- Checkbox -->
<input type="checkbox" [formField]="userForm.isAdmin" />

<!-- Select -->
<select [formField]="userForm.country">
  <option value="us">US</option>
</select>

<!-- userForm.name can NOT be nullable, because input does not accept null-->
<input [formField]="userForm.name" />
```

## Reactive Form

**KHÔNG import** `FormControl`, `FormGroup`, `FormArray` hay `FormBuilder` từ `@angular/forms`. Signal Form thay thế hoàn toàn các khái niệm này.
Signal form KHÔNG có builder.

## Truy cập State

Mỗi field trong form là một hàm trả về state của nó.

```ts
// Access the field by calling it
const emailState = this.userForm.email();

// Value (WritableSignal)
const value = this.userForm().value();

// Validation State (Signals)
const isValid = this.userForm().valid();
const isInvalid = this.userForm().invalid();
const errors = this.userForm().errors(); // Array of errors
const isPending = this.userForm().pending(); // Async validation pending

// Interaction State (Signals)
const isTouched = this.userForm().touched();
const isDirty = this.userForm().dirty();

// Availability State (Signals)
const isDisabled = this.userForm().disabled();
const isHidden = this.userForm().hidden();
const isReadonly = this.userForm().readonly();
```

QUAN TRỌNG!: Hãy chắc chắn gọi field để lấy state của nó.

```ts
form().invalid()
form.field().dirty()
form.field.subfield().touched()
form.a.b.c.d().value()
form.address.ssn().pending()
form().reset()

// The only exception is length:
form.children.length
form.length // NOTE: no parenthesis!
form.client.addresses.length  // No "()"

@for (income of form.addresses; track $index) {/**/}
```

## Submit

Dùng hàm `submit()`. Nó tự động đánh dấu mọi field là touched trước khi chạy action.

**QUAN TRỌNG**: Callback của `submit()` PHẢI là `async` và PHẢI trả về một Promise.

```ts
import { submit } from '@angular/forms/signals';

// CORRECT - async callback
onSubmit() {
  submit(this.userForm, async () => {
    // This only runs if the form is valid
    await this.apiService.save(this.userModel());
    console.log('Saved!');
  });
}

// WRONG - missing async keyword
onSubmit() {
  submit(this.userForm, () => {  // ERROR: must be async
    console.log('Saved!');
  });
}
```

## Xử lý lỗi

`field().errors()` trả về mảng lỗi kiểu ValidationError:

```ts
interface ValidationError {
  readonly kind: string;
  readonly message?: string;
}
```

KHÔNG trả về null từ validator.
Khi không có lỗi, hãy trả về undefined

### Context

Các hàm được truyền vào rule như `validate()`, `disabled()`, `applyWhen` nhận một context object. Việc hiểu cấu trúc của nó là **QUAN TRỌNG**:

```ts
validate(
  schemaPath.username,
  ({
    value, // Signal<T>: Writable current value of the field
    fieldTree, // FieldTree<T>: Sub-fields (if it's a group/array)
    state, // FieldState<T>: Access flags like state.valid(), state.dirty()
    valueOf, // (path) => T: Read values of OTHER fields (tracking dependencies), e.g. valueOf(schemaPath.password)
    stateOf, // (path) => FieldState: Access state (valid/dirty) of OTHER fields, e.g. stateOf(schemaPath.password).valid()
    pathKeys, // Signal<string[]>: Path from root to this field
  }) => {
    // WRONG: if (touched()) ... (touched is not in context)
    // RIGHT: if (state.touched()) ...

    if (value() === 'admin') {
      return {kind: 'reserved', message: 'Username admin is reserved'};
    }
  },
);
```

### QUAN TRỌNG: Path KHÔNG phải là Signal

Bên trong callback của `form()`, `schemaPath` và các phần tử con của nó (ví dụ: `schemaPath.user.name`) **KHÔNG** phải là signal và **KHÔNG** thể gọi như hàm.

```ts
// WRONG - This will throw an error:
applyWhen(p.ssn, () => p.ssn().touched(), (ssnField) => { ... });

// RIGHT - Use stateOf() to get the state of a path:
applyWhen(p.ssn, ({ stateOf }) => stateOf(p.ssn).touched(), (ssnField) => { ... });

// RIGHT - Use valueOf() to get the value of a path:
applyWhen(p.ssn, ({ valueOf }) => valueOf(p.ssn) !== '', (ssnField) => { ... });
```

### Nhiều phần tử (Multiple Items)

- Dùng `applyEach` để áp dụng rule cho từng phần tử.
- **QUAN TRỌNG**: Callback của `applyEach` chỉ nhận MỘT tham số (path của phần tử), KHÔNG phải hai:

```ts
// CORRECT - single argument
applyEach(s.items, (item) => {
  required(item.name);
});

// WRONG - do NOT pass index
applyEach(s.items, (item, index) => {
  // ERROR: callback takes 1 argument
  required(item.name);
});
```

- Trong template dùng `@for` để lặp qua các phần tử.
- Để xóa một phần tử khỏi mảng, chỉ cần xóa phần tử tương ứng khỏi mảng trong dữ liệu.
- **Binding `select`**: Bạn CÓ THỂ bind vào `<select [formField]="form.country">`. Đảm bảo các option có thuộc tính `value`.

### @for lồng nhau

**QUAN TRỌNG**: Angular KHÔNG có `$parent`. Trong các vòng lặp lồng nhau, hãy lưu index bên ngoài vào một biến:

```html
<!-- WRONG - $parent does not exist -->
@for (item of form.items; track $index) { @for (option of item.options; track $index) {
<button (click)="removeOption($parent.$index, $index)">Remove</button>
<!-- ERROR -->
} }

<!-- CORRECT - use let to store outer index -->
@for (item of form.items; track $index; let outerIndex = $index) { @for (option of item.options;
track $index) {
<button (click)="removeOption(outerIndex, $index)">Remove</button>
} }
```

### Vô hiệu hóa nút của Form

```html
<button [disabled]="form().invalid() || form().pending()" />
<!-- Or -->
<button [disabled]="taxForm.invalid()" />
```

KHÔNG dùng `[disabled]` trên một input. `[formField]` sẽ làm việc này.
KHÔNG dùng `[readonly]` trên một input. `[formField]` sẽ làm việc này.
Nếu cần disable hoặc readonly một field, hãy dùng các rule `disabled()` hoặc `readonly()` trong schema.

### Async Validation

Không dùng `validate()` cho async, thay vào đó dùng `validateAsync()`:

**QUAN TRỌNG**:

1. Tùy chọn `params` PHẢI là một hàm trả về giá trị cần validate.
2. Handler `onError` là **BẮT BUỘC** - nó KHÔNG phải tùy chọn!

```ts
import {resource} from '@angular/core';
import {validateAsync} from '@angular/forms/signals';

userForm = form(this.userModel, (s) => {
  validateAsync(s.username, {
    // 1. MUST be a function - params takes context and returns the value
    params: ({value}) => value(),

    // 2. Create the resource - factory receives a Signal
    factory: (username) =>
      resource({
        params: username, // Use 'params' in resource()
        loader: async ({params: value}) => {
          await new Promise((resolve) => setTimeout(resolve, 1000));
          return value === 'taken';
        },
      }),

    // 3. Map success to errors
    onSuccess: (isTaken) =>
      isTaken ? {kind: 'taken', message: 'Username is already taken'} : undefined,

    // 4. Handle errors - THIS IS REQUIRED!
    onError: () => ({kind: 'error', message: 'Validation failed'}),
  });
});
```

**Ví dụ SAI:**

```ts
// WRONG - params must be a function
validateAsync(s.username, {
  params: s.username, // ERROR: must be ({ value }) => value()
  // ...
});

// WRONG - missing onError (it's required!)
validateAsync(s.username, {
  params: ({value}) => value(),
  factory: (username) =>
    resource({
      /* ... */
    }),
  onSuccess: (result) => (result ? {kind: 'error'} : undefined),
  // ERROR: 'onError' is missing but required!
});
```

### Dùng Resource

**QUAN TRỌNG**: Trong `resource()` của Angular, dùng `params` cho input signal.

```ts
// CORRECT
resource({
  params: mySignal,
  loader: async ({params: value}) => {
    /* ... */
  },
});

// WRONG
resource({
  request: mySignal, // ERROR: should be 'params'
  loader: async ({request}) => {
    /* ... */
  },
});
```

Dùng `debounce()` để trì hoãn việc đồng bộ giữa UI và model.

```ts
import {debounce} from '@angular/forms/signals';

userForm = form(this.userModel, (s) => {
  // Delay model updates by 300ms
  debounce(s.username, 300);
});
```

### Validation có điều kiện

```ts
form(
  data,
  (path) => {
    applyWhen(
      name,
      ({value}) => value() !== 'admin',
      (namePath) => {
        validate(namePath.last /* ... */);
        disable(namePath.last /* ... */);
      },
    );
  },
  {injector: TestBed.inject(Injector)},
);
```

`applyWhen` truyền path đã được ánh xạ vào tham số đầu tiên.
Nếu cần field cha, chỉ cần truyền nó vào `applyWhen`:

```ts
form(
  data,
  (path) => {
    applyWhen(
      cat,
      ({value}) => value().name !== 'admin',
      (catPath) => {
        require(cat.catPath /* ... */);
      },
    );
  },
  {injector: TestBed.inject(Injector)},
);
```

## Các lỗi thường gặp (KHÔNG LÀM NHỮNG ĐIỀU NÀY)

| Tình huống lỗi         | SAI (Lỗi thường gặp)                          | ĐÚNG (Cách làm đúng)                                        |
| :--------------------- | :-------------------------------------------- | :---------------------------------------------------------- |
| **Truy cập flag**      | `form.field.valid()`                          | `form.field().valid()`                                      |
| **Truy cập value**     | `form.field.value()`                          | `form.field().value()`                                      |
| **Đặt value**          | `form.field.set(x)`                           | Cập nhật model signal: `this.model.update(...)`             |
| **Flag của form root** | `form.invalid()`                              | `form().invalid()`                                          |
| **Gọi hai lần**        | `form.field()()`                              | `form.field().value()`                                      |
| **Rules Context**      | `({ touched }) => touched()`                  | `({ state }) => state.touched()`                            |
| **Gọi Path**           | `applyWhen(p.foo, () => p.foo() === 'x')`     | `applyWhen(p.foo, ({ valueOf }) => valueOf(p.foo) === 'x')` |
| **Tham số applyWhen**  | `applyWhen(condition, () => {...})`           | `applyWhen(path, condition, schemaFn)` - cần 3 tham số      |
| **Độ dài mảng**        | `form.items().length`                         | `form.items.length` (structural)                            |
| **Multi-select array** | `<select [formField]="form.tags">` (string[]) | Dùng checkbox cho các field kiểu mảng                       |
| **Attribute readonly** | `<input readonly [formField]>`                | Dùng rule `readonly()` trong schema                         |
| **Attribute min/max**  | `<input min="1" max="10">`                    | Dùng các rule `min()` và `max()` trong schema               |
| **Binding value**      | `<input [value]="val">`                       | KHÔNG dùng `[value]` với `[formField]`                      |
| **Tùy chọn when**      | `pattern(p.x, /.../, {when: ...})`            | `when` chỉ hoạt động với `required()`                       |
| **Submit callback**    | `submit(form, () => { ... })`                 | `submit(form, async () => { ... })`                         |
| **Async params**       | `params: s.field`                             | `params: ({ value }) => value()`                            |
| **Async onError**      | Bỏ qua `onError`                              | `onError` là BẮT BUỘC trong `validateAsync`                 |
| **API resource()**     | `request: signal`                             | `params: signal`                                            |
| **Tham số applyEach**  | `applyEach(s.items, (item, index) => ...)`    | `applyEach(s.items, (item) => ...)`                         |
| **@for lồng nhau**     | `$parent.$index`                              | Dùng `let outerIndex = $index`                              |
| **Import FormState**   | `import { FormState }`                        | `FormState` không tồn tại, hãy dùng `FieldState`            |
| **Null trong model**   | `signal({ name: null })`                      | `signal({ name: '' })` hoặc `signal({ age: 0 })`            |
| **Cú pháp validate**   | `validate(s.field, { value } => ...)`         | `validate(s.field, ({ value }) => ...)`                     |
| **Checkbox Array**     | `[formField]="form.tags"` (string[])          | Checkbox CHỈ bind với `boolean`                             |

## Ví dụ Form lớn

### `src/app/app.ts`

```ts
import {Component, signal, ChangeDetectionStrategy} from '@angular/core';
import {
  form,
  FormField,
  submit,
  required,
  email,
  min,
  hidden,
  applyEach,
  validate,
} from '@angular/forms/signals';

@Component({
  selector: 'app-root',
  standalone: true,
  imports: [FormField],
  templateUrl: './app.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class App {
  model = signal({
    personalInfo: {
      firstName: '',
      lastName: '',
      email: '',
      age: 0,
    },
    tripDetails: {
      destination: 'Mars',
      launchDate: '',
    },
    package: {
      tier: 'economy',
      extras: [] as string[],
    },
    companions: [] as Array<{name: string; relation: string}>,
  });

  bookingForm = form(this.model, (s) => {
    required(s.personalInfo.firstName, {message: 'First name is required'});
    required(s.personalInfo.lastName, {message: 'Last name is required'});
    required(s.personalInfo.email, {message: 'Email is required'});
    email(s.personalInfo.email, {message: 'Invalid email address'});
    required(s.personalInfo.age, {message: 'Age is required'});
    min(s.personalInfo.age, 18, {message: 'Must be at least 18'});

    required(s.tripDetails.destination);
    required(s.tripDetails.launchDate);
    validate(s.tripDetails.launchDate, ({value}) => {
      const date = new Date(value());
      if (isNaN(date.getTime())) return undefined;
      const today = new Date();
      if (date < today) {
        return {kind: 'pastData', message: 'Launch date must be in the future'};
      }
      return undefined;
    });

    // valueOf is used to access values of other fields in rules
    hidden(s.package.extras, ({valueOf}) => valueOf(s.package.tier) === 'economy');

    applyEach(s.companions, (companion) => {
      required(companion.name, {message: 'Companion name required'});
      required(companion.relation, {message: 'Relation required'});
    });
  });

  addCompanion() {
    this.model.update((m) => ({
      ...m,
      companions: [...m.companions, {name: '', relation: ''}],
    }));
  }

  removeCompanion(index: number) {
    this.model.update((m) => ({
      ...m,
      companions: m.companions.filter((_, i) => i !== index),
    }));
  }

  onSubmit() {
    // CRITICAL: submit callback MUST be async
    submit(this.bookingForm, async () => {
      console.log('Booking Confirmed:', this.model());
      // If you need to do async work:
      // await this.apiService.save(this.model());
    });
  }
}
```

### `src/app/app.html`

```html
<form (submit)="onSubmit(); $event.preventDefault()">
  <h1>Interstellar Booking</h1>

  <section>
    <h2>Personal Info</h2>

    <label>
      First Name
      <input [formField]="bookingForm.personalInfo.firstName" />
      @if (bookingForm.personalInfo.firstName().touched() &&
      bookingForm.personalInfo.firstName().errors().length) {
      <span>{{ bookingForm.personalInfo.firstName().errors()[0].message }}</span>
      }
    </label>

    <label>
      Last Name
      <input [formField]="bookingForm.personalInfo.lastName" />
      @if (bookingForm.personalInfo.lastName().touched() &&
      bookingForm.personalInfo.lastName().errors().length) {
      <span>{{ bookingForm.personalInfo.lastName().errors()[0].message }}</span>
      }
    </label>

    <label>
      Email
      <input type="email" [formField]="bookingForm.personalInfo.email" />
      @if (bookingForm.personalInfo.email().touched() &&
      bookingForm.personalInfo.email().errors().length) {
      <span>{{ bookingForm.personalInfo.email().errors()[0].message }}</span>
      }
    </label>

    <label>
      Age
      <input type="number" [formField]="bookingForm.personalInfo.age" />
      @if (bookingForm.personalInfo.age().touched() &&
      bookingForm.personalInfo.age().errors().length) {
      <span>{{ bookingForm.personalInfo.age().errors()[0].message }}</span>
      }
    </label>
  </section>

  <section>
    <h2>Trip Details</h2>

    <label>
      Destination
      <select [formField]="bookingForm.tripDetails.destination">
        <option value="Mars">Mars</option>
        <option value="Moon">Moon</option>
        <option value="Titan">Titan</option>
      </select>
    </label>

    <label>
      Launch Date
      <input type="date" [formField]="bookingForm.tripDetails.launchDate" />
      @if (bookingForm.tripDetails.launchDate().touched() &&
      bookingForm.tripDetails.launchDate().errors().length) {
      <span>{{ bookingForm.tripDetails.launchDate().errors()[0].message }}</span>
      }
    </label>
  </section>

  <section>
    <h2>Package</h2>

    <label>
      <input type="radio" value="economy" [formField]="bookingForm.package.tier" />
      Economy
    </label>
    <label>
      <input type="radio" value="business" [formField]="bookingForm.package.tier" />
      Business
    </label>
    <label>
      <input type="radio" value="first" [formField]="bookingForm.package.tier" />
      First Class
    </label>

    @if (!bookingForm.package.extras().hidden()) {
    <div>
      <h3>Extras</h3>
      <!-- Multi-select for arrays must use select multiple -->
      <select multiple [formField]="bookingForm.package.extras">
        <option value="wifi">WiFi</option>
        <option value="gym">Gym</option>
      </select>
    </div>
    }
  </section>

  <section>
    <h2>Companions</h2>
    <button type="button" (click)="addCompanion()">Add Companion</button>

    @for (companion of bookingForm.companions; track $index) {
    <div>
      <input [formField]="companion.name" placeholder="Name" />
      @if (companion.name().touched() && companion.name().errors().length) {
      <span>{{ companion.name().errors()[0].message }}</span>
      }

      <input [formField]="companion.relation" placeholder="Relation" />
      @if (companion.relation().touched() && companion.relation().errors().length) {
      <span>{{ companion.relation().errors()[0].message }}</span>
      }

      <button type="button" (click)="removeCompanion($index)">Remove</button>
    </div>
    }
  </section>

  <button [disabled]="bookingForm().invalid()">Submit</button>
</form>
```

## Khắc phục lỗi Build

Nếu gặp lỗi build, đây là các cách khắc phục phổ biến nhất:

### `Property 'value' does not exist on type 'FieldTree'`

**Vấn đề**: Truy cập `.value()` trực tiếp trên một field mà không gọi nó trước.

```ts
// WRONG
const val = this.form.field.value();
// RIGHT
const val = this.form.field().value();
```

### `Property 'set' does not exist on type 'FieldTree'`

**Vấn đề**: Cố gắng đặt giá trị trên form tree. Signal Form là model-driven.

```ts
// WRONG
this.form.address.street.set('Main St');
// RIGHT - update the model signal instead
this.model.update((m) => ({...m, address: {...m.address, street: 'Main St'}}));
```

### `Type 'string[]' is not assignable to type 'string'`

**Vấn đề**: Bind `[formField]` vào một field kiểu mảng với `<select>` đơn giá trị.

```html
<!-- WRONG - assignees is string[], select expects string -->
<select [formField]="form.assignees">
  ...
</select>

<!-- RIGHT - Use select multiple for array fields -->
<select multiple [formField]="form.assignees">
  <option value="us">US</option>
</select>
```
