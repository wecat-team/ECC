---
paths:
  - "**/*.ets"
  - "**/*.ts"
  - "**/module.json5"
  - "**/oh-package.json5"
  - "**/build-profile.json5"
---
# Phong cách code HarmonyOS / ArkTS

> File này mở rộng [common/coding-style.md](../common/coding-style.md) với nội dung dành riêng cho HarmonyOS và ArkTS.

## Ràng buộc của ngôn ngữ ArkTS

ArkTS là một tập con nghiêm ngặt, định kiểu tĩnh của TypeScript. Vi phạm các ràng buộc này sẽ gây **lỗi biên dịch**.

### Hệ thống kiểu

- Không dùng kiểu `any` hoặc `unknown` - luôn dùng kiểu tường minh
- Không dùng index access type - dùng trực tiếp tên kiểu
- Không dùng conditional type alias hoặc từ khóa `infer`
- Không dùng intersection type - dùng kế thừa
- Không dùng mapped type - dùng class và các idiom thông thường
- Không dùng `typeof` cho type annotation - dùng khai báo kiểu tường minh
- Không dùng `as const` assertion - dùng type annotation tường minh
- Không dùng structural typing - dùng kế thừa, interface hoặc type alias
- Không dùng các utility type của TypeScript ngoại trừ `Partial`, `Required`, `Readonly`, `Record`
- Với `Record<K, V>`, kiểu của biểu thức index là `V | undefined`
- Bỏ type annotation trong mệnh đề `catch` (ArkTS không hỗ trợ `any`/`unknown`)

### Hàm & Class

- Không dùng function expression - dùng arrow function
- Không dùng hàm lồng nhau - dùng lambda
- Không dùng generator function - dùng `async`/`await` để xử lý đa tác vụ
- Không dùng `Function.apply`, `Function.call`, `Function.bind` - tuân theo OOP truyền thống đối với `this`
- Không dùng constructor type expression - dùng lambda
- Không dùng constructor signature trong interface hoặc object type - dùng method hoặc class
- Không khai báo field của class trong constructor - khai báo trong thân class
- Không dùng `this` trong hàm độc lập hoặc static method - chỉ dùng trong instance method
- Không dùng `new.target`
- Không dùng definite assignment assertion (`let v!: T`) - dùng khai báo có khởi tạo
- Không dùng class literal - hãy tạo named class type
- Không dùng class như object (gán vào biến) - khai báo class tạo ra type, không phải value
- Chỉ một static block cho mỗi class - gộp mọi câu lệnh static lại

### Object & truy cập thuộc tính

- Không khai báo field động hoặc truy cập `obj["field"]` - dùng cú pháp `obj.field`
- Không dùng toán tử `delete` - dùng nullable type với `null` để đánh dấu sự vắng mặt
- Không gán prototype - dùng class và interface
- Không dùng toán tử `in` - dùng `instanceof`
- Không gán lại method của object - dùng wrapper function hoặc kế thừa
- Không dùng API `Symbol()` (ngoại trừ `Symbol.iterator`)
- Không dùng `globalThis` hoặc phạm vi global - dùng export/import module tường minh
- Không dùng namespace như object - dùng class hoặc module
- Không đặt câu lệnh bên trong namespace - dùng hàm

### Destructuring & Spread

- Không dùng destructuring assignment hoặc khai báo biến bằng destructuring - dùng object trung gian và truy cập từng field
- Không dùng destructuring trong khai báo tham số - truyền tham số trực tiếp, tự gán tên cục bộ
- Spread operator chỉ dùng để trải mảng (hoặc class dẫn xuất từ mảng) vào rest parameter hoặc array literal

### Module & Import

- Không dùng `require()` - dùng cú pháp `import` thông thường
- Không dùng `export = ...` - dùng export/import thông thường
- Không dùng import assertion - import trong ArkTS diễn ra lúc biên dịch
- Không dùng module UMD
- Không dùng wildcard trong tên module
- Mọi câu lệnh `import` PHẢI xuất hiện trước tất cả các câu lệnh khác
- Codebase TypeScript không được phụ thuộc vào codebase ArkTS qua import (chiều ngược lại được hỗ trợ)

### Các hạn chế khác

- Không dùng `var` - dùng `let`
- Không dùng vòng lặp `for...in` - dùng vòng lặp `for` thông thường cho mảng
- Không dùng câu lệnh `with`
- Không dùng biểu thức JSX
- Không dùng định danh private `#` - dùng từ khóa `private`
- Không dùng declaration merging (class, interface, enum) - giữ định nghĩa gọn
- Không dùng index signature - dùng mảng
- Toán tử dấu phẩy chỉ dùng trong vòng lặp `for`
- Toán tử một ngôi `+`, `-`, `~` chỉ dùng cho kiểu số (không chuyển đổi chuỗi ngầm định)
- Thành viên enum: chỉ dùng biểu thức compile-time cùng kiểu cho initializer tường minh
- Suy luận kiểu trả về của hàm bị hạn chế - hãy chỉ định kiểu trả về tường minh khi gọi các hàm bị bỏ kiểu trả về

### Object Literal

- Chỉ được hỗ trợ khi compiler suy luận được class hoặc interface tương ứng
- KHÔNG được hỗ trợ cho: kiểu `any`/`Object`/`object`, class/interface có method, class có constructor tham số hóa, class có field `readonly`

## Quy ước đặt tên

- Biến / hàm: `camelCase` (ví dụ: `getUserInfo`, `goodsList`)
- Class / interface: `PascalCase` (ví dụ: `UserViewModel`, `IGoodsModel`)
- Hằng số: `UPPER_SNAKE_CASE` (ví dụ: `MAX_PAGE_SIZE`, `COLOR_PRIMARY`)
- Tên file: `PascalCase` cho component (ví dụ: `HomePage.ets`), `camelCase` cho utility

## Định dạng

- Ưu tiên dấu nháy kép cho chuỗi
- Dấu chấm phẩy ở cuối câu lệnh
- KHÔNG BAO GIỜ dùng `var` - ưu tiên `const`, sau đó đến `let`
- Mọi method, tham số, giá trị trả về PHẢI có type annotation đầy đủ

## Tổ chức file

- File component (`.ets`): mỗi file một `@ComponentV2`
- File ViewModel: mỗi file một class ViewModel
- File Model: các data model liên quan có thể dùng chung một file
- Giữ file dưới 400 dòng; tách helper ra khi file tiến gần 800 dòng

## Comment

- Header file: `@file` (mục đích file) + `@author` (lập trình viên), nếu dự án đã dùng header cho file
- Method public: JSDoc với `@param`, `@returns`; thêm `@example` cho method phức tạp
- Khớp với ngôn ngữ tài liệu sẵn có của dự án; dùng tiếng Anh trừ khi repo đã chuẩn hóa dùng comment tiếng Trung

## Xử lý lỗi

```typescript
// Use try/catch with proper error handling
try {
  const result = await riskyOperation()
  return result
} catch (error) {
  hilog.error(0x0000, 'TAG', 'Operation failed: %{public}s', error)
  throw new Error('User-friendly error message')
}
```

## Bất biến (Immutability)

Tuân theo các nguyên tắc bất biến chung - tạo object mới thay vì mutate:

```typescript
// BAD: mutation
function updateUser(user: UserModel, name: string): UserModel {
  user.name = name  // direct mutation
  return user
}

// GOOD: immutable - create new instance
function updateUser(user: UserModel, name: string): UserModel {
  const updated = new UserModel()
  updated.id = user.id
  updated.name = name
  updated.email = user.email
  return updated
}
```
