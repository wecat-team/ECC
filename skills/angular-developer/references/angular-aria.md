# Angular Aria

Angular Aria (`@angular/aria`) là một tập hợp các directive headless, accessible, triển khai các pattern WAI-ARIA phổ biến. Các directive này xử lý tương tác bàn phím, thuộc tính ARIA, quản lý focus và hỗ trợ screen reader.

**Là một AI Agent, vai trò của bạn là cung cấp cấu trúc HTML và CSS styling**, còn các directive sẽ xử lý logic accessibility phức tạp.

## Styling Headless Component

Vì các component của Angular Aria là headless, chúng không đi kèm style mặc định. Bạn **PHẢI** dùng CSS để style các trạng thái khác nhau dựa trên các thuộc tính ARIA hoặc class cấu trúc mà directive tự động áp dụng.

Các thuộc tính ARIA thường dùng để target trong CSS:

- `[aria-expanded="true"]` / `[aria-expanded="false"]`
- `[aria-selected="true"]`
- `[aria-disabled="true"]`
- `[aria-current="page"]` (cho điều hướng)

---

**CRITICAL**: Trước khi dùng package này, nó phải được cài qua package manager. Hãy xác nhận nó đã được cài trong dự án. Dùng `npm install @angular/aria` để cài nếu cần.

## 1. Accordion

Tổ chức nội dung liên quan thành các phần có thể mở rộng/thu gọn.

**Cách dùng:** Accordion là một layout component được thiết kế để tổ chức nội dung thành các nhóm logic mà người dùng có thể mở từng nhóm một để giảm việc cuộn trên các trang nặng nội dung. Dùng nó cho FAQ, form dài, hoặc để hiển thị thông tin dần dần (progressive disclosure), nhưng tránh dùng cho điều hướng chính hoặc các tình huống người dùng phải xem nhiều phần nội dung cùng lúc.

**Imports:** `import { AccordionContent, AccordionGroup, AccordionPanel, AccordionTrigger } from '@angular/aria/accordion';`

**Directives:** `ngAccordionGroup`, `ngAccordionTrigger`, `ngAccordionPanel`, `ngAccordionContent` (cho lazy loading).

```ts
@Component({
  selector: 'app-cmp',
  imports: [AccordionContent, AccordionGroup, AccordionPanel, AccordionTrigger],
  template: `...`,
  styles: [],
})
export class App {
  protected readonly title = signal('angular-app');
}
```

```html
<div ngAccordionGroup [multiExpandable]="false">
  <div class="accordion-item">
    <button ngAccordionTrigger panelId="panel-1" class="accordion-header">
      Section 1
      <span class="icon">▼</span>
    </button>
    <div ngAccordionPanel panelId="panel-1" class="accordion-panel">
      <ng-template ngAccordionContent>
        <p>Lazy loaded content here.</p>
      </ng-template>
    </div>
  </div>
</div>
```

**Chiến lược styling:**
Target thuộc tính `[aria-expanded]` trên trigger để xoay icon, và style khả năng hiển thị của panel.

```css
.accordion-header[aria-expanded='true'] .icon {
  transform: rotate(180deg);
}

/* The panel directive handles DOM removal, but you can style the transition */
.accordion-panel {
  padding: 1rem;
  border-top: 1px solid #ccc;
}
```

---

## 2. Listbox

Một directive nền tảng để hiển thị danh sách các tùy chọn. Dùng cho danh sách chọn hiển thị sẵn (không phải dropdown).

**Cách dùng:** Danh sách chọn được hiển thị sẵn (chọn một hoặc chọn nhiều).

**Imports:** `import {Listbox, Option} from '@angular/aria/listbox';`

**Directives:** `ngListbox`, `ngOption`.

```ts
@Component({
  selector: 'app-cmp',
  imports: [Listbox, Option],
  template: `...`,
  styles: [],
})
export class App {
  protected readonly title = signal('angular-app');
}
```

```html
<!-- horizontal or vertical orientation -->
<ul ngListbox [(values)]="selectedItems" orientation="horizontal" [multi]="true">
  <li ngOption value="apple" class="option">Apple</li>
  <li ngOption value="banana" class="option">Banana</li>
</ul>
```

**Chiến lược styling:**
Target `[aria-selected="true"]` cho trạng thái được chọn và `:focus-visible` hoặc `[data-active]` cho mục đang focus (Angular Aria dùng roving tabindex hoặc activedescendant).

```css
.option {
  padding: 8px;
  cursor: pointer;
}
.option[aria-selected='true'] {
  background: #e0f7fa;
  font-weight: bold;
}
/* Focus state managed by aria */
.option:focus-visible {
  outline: 2px solid blue;
}
```

---

## 3. Combobox, Select và Multiselect

Các pattern này kết hợp `ngCombobox` với một popup chứa `ngListbox`.

- **Combobox**: Text input + popup (dùng cho Autocomplete).
- **Select**: Combobox chỉ đọc + Listbox chọn một.
- **Multiselect**: Combobox chỉ đọc + Listbox chọn nhiều.

**Cách dùng:** Combobox là một directive nguyên thủy cấp thấp, đồng bộ một text input với một popup, đóng vai trò logic nền tảng cho các pattern autocomplete, select và multiselect. Dùng nó riêng cho việc xây dựng bộ lọc tùy chỉnh, yêu cầu chọn đặc thù, hoặc phối hợp input-với-popup chuyên biệt khác với các component chuẩn đã được tài liệu hóa.

**Imports:**

```
  import {Combobox, ComboboxInput, ComboboxPopupContainer} from '@angular/aria/combobox';
  import {Listbox, Option} from '@angular/aria/listbox';
```

**Directives:** `ngCombobox`, `ngComboboxInput`, `ngComboboxPopupContainer`, `ngListbox`, `ngOption`.

```html
<!-- Example: Standard Select -->
<div ngCombobox [readonly]="true">
  <button ngComboboxInput class="select-trigger">
    {{ selectedValue() || 'Choose an option' }}
  </button>

  <ng-template ngComboboxPopupContainer>
    <ul ngListbox [(values)]="selectedValue" class="dropdown-menu">
      <li ngOption value="option1">Option 1</li>
      <li ngOption value="option2">Option 2</li>
    </ul>
  </ng-template>
</div>
```

**Chiến lược styling:**
Style popup container để trông như một dropdown nổi trên nội dung (thường kết hợp với CDK Overlay).

```css
.select-trigger {
  width: 200px;
  padding: 8px;
  text-align: left;
}
.dropdown-menu {
  list-style: none;
  padding: 0;
  margin: 0;
  border: 1px solid #ccc;
  background: white;
  box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
}
```

---

## 4. Menu và Menubar

Dùng cho action, command và context menu (không dùng để chọn trong form).

**Cách dùng:** Menubar là một pattern điều hướng cấp cao được thiết kế để xây dựng thanh lệnh kiểu ứng dụng desktop (ví dụ File, Edit, View) luôn hiện diện xuyên suốt giao diện. Nó phù hợp nhất để tổ chức các lệnh phức tạp thành các danh mục cấp cao nhất có logic với hỗ trợ bàn phím ngang đầy đủ, nhưng nên tránh dùng cho các danh sách action độc lập đơn giản hoặc layout ưu tiên mobile nơi không gian ngang bị hạn chế.

**Imports:** `import {MenuBar, Menu, MenuContent, MenuItem} from '@angular/aria/menu';`

**Directives:** `ngMenuBar`, `ngMenu`, `ngMenuItem`, `ngMenuTrigger`.

```html
<!-- Menubar Example -->
<ul ngMenuBar class="menubar">
  <li ngMenuItem value="file">
    <button ngMenuTrigger [menu]="fileMenu">File</button>
  </li>
</ul>

<ul ngMenu #fileMenu="ngMenu" class="menu">
  <li ngMenuItem value="new">New</li>
  <li ngMenuItem value="open">Open</li>
</ul>
```

**Chiến lược styling:**
Dùng flexbox cho menubar. Ẩn/hiện submenu dựa trên trạng thái của trigger.

```css
.menubar {
  display: flex;
  gap: 10px;
  list-style: none;
  padding: 0;
}
.menu {
  background: white;
  border: 1px solid #ccc;
  padding: 5px 0;
}
.menu li {
  padding: 5px 15px;
  cursor: pointer;
}
```

---

## 5. Tabs

Các phần nội dung xếp lớp, trong đó chỉ một panel hiển thị.

**Cách dùng:** Component Tabs dùng để tổ chức nội dung liên quan thành các phần riêng biệt, có thể điều hướng, cho phép người dùng chuyển giữa các danh mục hoặc view mà không rời khỏi trang. Nó lý tưởng cho panel cài đặt, tài liệu nhiều chủ đề, hoặc dashboard, nhưng nên tránh dùng cho workflow tuần tự (stepper) hoặc khi điều hướng có hơn 7–8 phần.

**Imports:** `import {Tab, Tabs, TabList, TabPanel, TabContent} from '@angular/aria/tabs';`

**Directives:** `ngTabs`, `ngTabList`, `ngTab`, `ngTabPanel`, `ngTabContent`.

```html
<div ngTabs>
  <ul ngTabList class="tab-list">
    <li ngTab value="profile" class="tab-btn">Profile</li>
    <li ngTab value="security" class="tab-btn">Security</li>
  </ul>

  <div ngTabPanel value="profile" class="tab-panel">
    <ng-template ngTabContent>Profile Settings</ng-template>
  </div>
  <div ngTabPanel value="security" class="tab-panel">
    <ng-template ngTabContent>Security Settings</ng-template>
  </div>
</div>
```

**Chiến lược styling:**
Target `[aria-selected="true"]` trên các nút tab.

```css
.tab-list {
  display: flex;
  border-bottom: 2px solid #ccc;
  list-style: none;
  padding: 0;
}
.tab-btn {
  padding: 10px 20px;
  cursor: pointer;
  border-bottom: 2px solid transparent;
}
.tab-btn[aria-selected='true'] {
  border-bottom-color: blue;
  font-weight: bold;
}
.tab-panel {
  padding: 20px;
}
```

---

## 6. Toolbar

Nhóm các điều khiển liên quan (như định dạng văn bản).

**Cách dùng:** Toolbar là một component tổ chức được thiết kế để nhóm các điều khiển liên quan, được truy cập thường xuyên vào một container logic duy nhất. Nó được dùng tốt nhất để tăng hiệu quả bàn phím (qua điều hướng phím mũi tên) và cấu trúc thị giác cho các workflow cần thao tác lặp lại, như định dạng văn bản hoặc điều khiển media.

**Imports:** `import {Toolbar, ToolbarWidget, ToolbarWidgetGroup} from '@angular/aria/toolbar';`

**Directives:** `ngToolbar`, `ngToolbarWidget`, `ngToolbarWidgetGroup`.

```html
<div ngToolbar class="toolbar">
  <div ngToolbarWidgetGroup [multi]="true" role="group" aria-label="Formatting">
    <button ngToolbarWidget value="bold" class="tool-btn">B</button>
    <button ngToolbarWidget value="italic" class="tool-btn">I</button>
  </div>
</div>
```

**Chiến lược styling:**
Target `[aria-pressed="true"]` (cho nút toggle) hoặc `[aria-checked="true"]` (cho nhóm radio) bên trong toolbar.

```css
.toolbar {
  display: flex;
  gap: 5px;
  padding: 8px;
  background: #f5f5f5;
}
.tool-btn {
  padding: 5px 10px;
  border: 1px solid #ccc;
}
.tool-btn[aria-pressed='true'],
.tool-btn[aria-checked='true'] {
  background: #ddd;
}
```

---

## 7. Tree

Hiển thị dữ liệu phân cấp (hệ thống file, điều hướng lồng nhau).

**Cách dùng:** Component Tree được thiết kế để điều hướng và hiển thị các cấu trúc dữ liệu phân cấp lồng sâu như hệ thống file, sơ đồ tổ chức, hoặc kiến trúc site phức tạp. Nên dùng riêng cho các quan hệ nhiều cấp nơi người dùng cần mở rộng hoặc thu gọn các nhánh, nhưng nên tránh dùng cho danh sách phẳng, bảng dữ liệu hoặc menu chọn đơn giản.

**Imports:** `import {Tree, TreeItem, TreeItemGroup} from '@angular/aria/tree';`

**Directives:** `ngTree`, `ngTreeItem`, `ngTreeGroup`.

```html
<ul ngTree class="tree">
  <li ngTreeItem value="documents">
    <span class="tree-label">Documents</span>
    <ul ngTreeGroup class="tree-group">
      <li ngTreeItem value="resume">Resume.pdf</li>
    </ul>
  </li>
</ul>
```

**Chiến lược styling:**
Target `[aria-expanded]` để ẩn/hiện phần tử con hoặc xoay icon chevron. Dùng `padding-left` trên các nhóm lồng nhau để thể hiện phân cấp.

```css
.tree,
.tree-group {
  list-style: none;
  padding-left: 20px;
}
.tree-label::before {
  content: '> ';
  display: inline-block;
  transition: transform 0.2s;
}
li[aria-expanded='true'] > .tree-label::before {
  transform: rotate(90deg);
}
```

## 8. Grid

Một tập hợp ô tương tác hai chiều cho phép điều hướng bằng phím mũi tên.

**Cách dùng:** Bảng dữ liệu, lịch, spreadsheet và các pattern layout cho phần tử tương tác.
**Directives:** `ngGrid`, `ngGridRow`, `ngGridCell`, `ngGridCellWidget`.

```html
<table ngGrid [multi]="true" [enableSelection]="true" class="grid-table">
  <tr ngGridRow>
    <th ngGridCell role="columnheader">Name</th>
    <th ngGridCell role="columnheader">Status</th>
  </tr>
  <tr ngGridRow>
    <td ngGridCell>Project A</td>
    <td ngGridCell [(selected)]="isSelected">
      <button ngGridCellWidget (activated)="onActivate()">Active</button>
    </td>
  </tr>
</table>
```

**Chiến lược styling:**
Target `[aria-selected="true"]` cho các ô được chọn và `:focus-visible` cho ô đang active (roving tabindex) hoặc `[aria-activedescendant]` trên container.

```css
.grid-table {
  border-collapse: collapse;
}
[ngGridCell] {
  padding: 8px;
  border: 1px solid #ddd;
}
[ngGridCell][aria-selected='true'] {
  background: #e3f2fd;
}
/* Focus state managed by roving tabindex */
[ngGridCell]:focus-visible {
  outline: 2px solid #2196f3;
  outline-offset: -2px;
}
```

## Quy tắc chung cho Agent

1. **KHÔNG BAO GIỜ dùng các phần tử HTML native như `<select>`** khi được yêu cầu triển khai các pattern Aria cụ thể này. Hãy dùng các directive `ng*`.
2. **Tự xử lý CSS**: Hãy nhớ rằng `Angular Aria` KHÔNG cung cấp style. Bạn phải viết CSS, target các thuộc tính ARIA native (`aria-expanded`, `aria-selected`, v.v.) mà directive tự động bật/tắt.
3. **Lazy Loading**: Luôn dùng các structural directive được cung cấp (`ngAccordionContent`, `ngTabContent`) bên trong `ng-template` cho các panel nội dung nặng để đảm bảo chúng được render lazy.
