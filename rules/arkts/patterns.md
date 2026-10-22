---
paths:
  - "**/*.ets"
  - "**/*.ts"
---
# Pattern HarmonyOS / ArkTS

> File này mở rộng [common/patterns.md](../common/patterns.md) với các pattern riêng cho HarmonyOS và ArkTS.

## Quản lý State: Chỉ dùng V2

**PHẢI dùng** ArkUI State Management V2. Các decorator V1 đã bị deprecated và không được dùng.

### Decorator V2

| Decorator | Mục đích |
|-----------|---------|
| `@ComponentV2` | Đánh dấu một struct là component V2 |
| `@Local` | State cục bộ bên trong component |
| `@Param` | Props nhận từ component cha (chỉ đọc) |
| `@Event` | Callback event từ con lên cha |
| `@Provider` | Cung cấp state cho các component hậu duệ |
| `@Consumer` | Tiêu thụ state từ `@Provider` của tổ tiên |
| `@Monitor` | Theo dõi thay đổi state (thay thế `@Watch` của V1) |
| `@Computed` | Giá trị dẫn xuất/tính toán |
| `@ObservedV2` | Biến một class thành observable cho V2 state management |
| `@Trace` | Đánh dấu các thuộc tính observable trong class `@ObservedV2` |

### Các decorator V1 bị cấm

KHÔNG BAO GIỜ dùng: `@State`, `@Prop`, `@Link`, `@ObjectLink`, `@Observed`, `@Provide`, `@Consume`, `@Watch`, `@Component` (dùng `@ComponentV2` thay thế).

### Ví dụ component V2

```typescript
@ObservedV2
class UserModel {
  @Trace name: string = ''
  @Trace age: number = 0
}

@ComponentV2
struct UserCard {
  @Param user: UserModel = new UserModel()
  @Event onDelete: () => void = () => {}

  build() {
    Column() {
      Text(this.user.name)
        .fontSize($r('app.float.font_size_title'))
      Text(`${this.user.age}`)
        .fontSize($r('app.float.font_size_body'))
      Button($r('app.string.delete'))
        .onClick(() => this.onDelete())
    }
  }
}
```

### Đồng bộ State

```typescript
@ComponentV2
struct ParentPage {
  @Provider('userState') userModel: UserModel = new UserModel()

  build() {
    Column() {
      ChildComponent()  // automatically receives @Consumer('userState')
    }
  }
}

@ComponentV2
struct ChildComponent {
  @Consumer('userState') userModel: UserModel = new UserModel()

  build() {
    Text(this.userModel.name)
  }
}
```

## Routing: Chỉ dùng Navigation

**PHẢI dùng** component `Navigation` với `NavPathStack`. KHÔNG BAO GIỜ dùng `@ohos.router`.

### Thiết lập Navigation

```typescript
@ComponentV2
struct MainPage {
  @Local navPathStack: NavPathStack = new NavPathStack()

  build() {
    Navigation(this.navPathStack) {
      // Home content
    }
    .navDestination(this.routerMap)
  }

  @Builder
  routerMap(name: string, param: ESObject) {
    if (name === 'detail') {
      DetailPage()
    } else if (name === 'settings') {
      SettingsPage()
    }
  }
}
```

### Điều hướng trang

```typescript
// Push a new page
this.navPathStack.pushPath({ name: 'detail', param: { id: '123' } })

// Replace current page
this.navPathStack.replacePath({ name: 'settings' })

// Pop back
this.navPathStack.pop()

// Pop to root
this.navPathStack.clear()
```

### Trang con NavDestination

```typescript
@ComponentV2
struct DetailPage {
  build() {
    NavDestination() {
      Column() {
        Text($r('app.string.detail_title'))
      }
    }
    .title($r('app.string.detail_nav_title'))
  }
}
```

## Pattern kiến trúc: MVVM

Kiến trúc được khuyến nghị cho ứng dụng HarmonyOS:

```
feature/
  |-- model/           # Data models (@ObservedV2 classes)
  |-- viewmodel/       # Business logic (ViewModel classes)
  |-- view/            # UI components (@ComponentV2 structs)
  |-- service/         # API calls, data access
```

- **View**: Chỉ chứa logic render, không có business logic trong `build()`
- **ViewModel**: Toàn bộ business logic được đóng gói tại đây
- **Model**: Các data class thuần với `@ObservedV2` và `@Trace`
- **Service**: Request mạng, thao tác database, file I/O

## Pattern animation của ArkUI

### Animation điều khiển bởi State

```typescript
@ComponentV2
struct AnimatedCard {
  @Local isExpanded: boolean = false
  @Local cardScale: number = 0.8

  build() {
    Column() {
      // Content
    }
    .scale({ x: this.cardScale, y: this.cardScale })
    .animation({ duration: 300, curve: Curve.EaseInOut })
    .onClick(() => {
      this.isExpanded = !this.isExpanded
      this.cardScale = this.isExpanded ? 1.0 : 0.8
    })
  }
}
```

### Quy tắc animation

- Ưu tiên các API animation native của HarmonyOS và các advanced template
- Dùng declarative UI với animation điều khiển bởi state (đổi biến state để kích hoạt animation)
- Đặt `renderGroup(true)` cho animation của sub-component phức tạp để giảm số batch render
- **KHÔNG BAO GIỜ** thay đổi thường xuyên `width`, `height`, `padding`, `margin` trong lúc animation - ảnh hưởng hiệu năng nghiêm trọng
- Dùng `animateTo` để điều khiển animation tường minh
- Ưu tiên `transform` (translate, scale, rotate) và `opacity` để animation có hiệu năng tốt

## Pattern hiệu năng

### LazyForEach cho danh sách lớn

```typescript
@ComponentV2
struct LargeList {
  @Local dataSource: MyDataSource = new MyDataSource()

  build() {
    List() {
      LazyForEach(this.dataSource, (item: ItemModel) => {
        ListItem() {
          ItemComponent({ item: item })
        }
      }, (item: ItemModel) => item.id)
    }
  }
}
```

### Tái sử dụng component

- Tách các component tái sử dụng được ra file riêng
- Dùng `@Builder` cho các đoạn UI nhẹ bên trong một component
- Dùng `@Param` cho component có thể cấu hình

## Tham chiếu Resource

Luôn định nghĩa hằng số UI dưới dạng resource và tham chiếu qua `$r()`:

```typescript
// BAD: hardcoded values
Text('Hello')
  .fontSize(16)
  .fontColor('#333333')

// GOOD: resource references
Text($r('app.string.greeting'))
  .fontSize($r('app.float.font_size_body'))
  .fontColor($r('app.color.text_primary'))
```
