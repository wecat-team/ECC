---
name: angular-developer
description: Sinh code Angular và đưa ra hướng dẫn kiến trúc. Kích hoạt khi tạo project, component hoặc service, hoặc khi cần best practice về reactivity (signals, linkedSignal, resource), forms, dependency injection, routing, SSR, accessibility (ARIA), animations, styling (component styles, Tailwind CSS), testing, hoặc CLI tooling.
metadata:
  origin: ECC
---

# Hướng dẫn cho Angular Developer

## Khi nào kích hoạt

- Làm việc trong bất kỳ dự án hoặc codebase Angular nào
- Tạo hoặc dựng khung (scaffold) một project, ứng dụng hoặc thư viện Angular mới
- Sinh component, service, directive, pipe, guard hoặc resolver
- Triển khai reactivity bằng Angular Signals, `linkedSignal` hoặc `resource`
- Làm việc với Angular forms (signal forms, reactive forms hoặc template-driven)
- Thiết lập dependency injection, routing, lazy loading hoặc route guard
- Thêm accessibility (ARIA), animation hoặc styling cho component
- Viết hoặc debug test riêng cho Angular (unit, component harness, E2E)
- Cấu hình Angular CLI tooling hoặc Angular MCP server

1. LUÔN LUÔN phân tích phiên bản Angular của dự án trước khi đưa ra hướng dẫn, vì best practice và các tính năng khả dụng có thể khác biệt đáng kể giữa các phiên bản. Nếu tạo project mới bằng Angular CLI, không chỉ định phiên bản trừ khi người dùng yêu cầu.

2. Khi sinh code, hãy tuân theo style guide và best practice của Angular về khả năng bảo trì và hiệu năng. Dùng Angular CLI để scaffold component, service, directive, pipe và route nhằm đảm bảo tính nhất quán.

3. Sau khi sinh code xong, chạy `ng build` để đảm bảo không có lỗi build. Nếu có lỗi, hãy phân tích thông báo lỗi và sửa trước khi tiếp tục. KHÔNG bỏ qua bước này, vì nó rất quan trọng để đảm bảo code được sinh ra là đúng và hoạt động được.

## Tạo project mới

Nếu người dùng không đưa ra hướng dẫn nào, hãy dùng các mặc định sau khi tạo một project Angular mới:

1. Dùng phiên bản Angular ổn định mới nhất trừ khi người dùng chỉ định khác.
2. Ưu tiên Signal Forms cho project mới chỉ khi phiên bản Angular mục tiêu hỗ trợ chúng. [Tìm hiểu thêm](references/signal-forms.md).

**Quy tắc thực thi cho `ng new`:**
Khi được yêu cầu tạo một project Angular mới, bạn PHẢI xác định đúng lệnh thực thi bằng cách tuân theo các bước nghiêm ngặt sau:

**Bước 1: Kiểm tra xem người dùng có chỉ định phiên bản tường minh không.**

- **NẾU** người dùng yêu cầu một phiên bản cụ thể (ví dụ: Angular 15), bỏ qua các bản cài đặt cục bộ và dùng `npx` một cách nghiêm ngặt.
- **Lệnh:** `npx @angular/cli@<requested_version> new <project-name>`

**Bước 2: Kiểm tra xem đã có bản cài đặt Angular chưa.**

- **NẾU** không yêu cầu phiên bản cụ thể, chạy `ng version` trong terminal để kiểm tra xem Angular CLI đã được cài trên hệ thống chưa.
- **NẾU** lệnh thành công và trả về một phiên bản đã cài, dùng trực tiếp bản cài đặt cục bộ/toàn cục.
- **Lệnh:** `ng new <project-name>`

**Bước 3: Fallback về bản mới nhất.**

- **NẾU** không yêu cầu phiên bản cụ thể VÀ lệnh `ng version` thất bại (cho thấy chưa có bản cài Angular nào), bạn PHẢI dùng `npx` để lấy phiên bản mới nhất.
- **Lệnh:** `npx @angular/cli@latest new <project-name>`

## Component

Khi làm việc với Angular component, hãy tham khảo các tài liệu sau tùy theo tác vụ:

- **Nền tảng**: Cấu trúc, metadata, khái niệm cốt lõi và template control flow (@if, @for, @switch). Đọc [components.md](references/components.md)
- **Input**: Input dựa trên signal, transform và model input. Đọc [inputs.md](references/inputs.md)
- **Output**: Output dựa trên signal và best practice cho custom event. Đọc [outputs.md](references/outputs.md)
- **Host Element**: Host binding và inject attribute. Đọc [host-elements.md](references/host-elements.md)

Nếu bạn cần tài liệu chuyên sâu hơn không có trong các tham chiếu trên, hãy đọc tài liệu tại `https://angular.dev/guide/components`.

## Reactivity và quản lý dữ liệu

Khi quản lý state và reactivity của dữ liệu, hãy dùng Angular Signals và tham khảo các tài liệu sau:

- **Tổng quan Signal**: Các khái niệm signal cốt lõi (`signal`, `computed`), reactive context và `untracked`. Đọc [signals-overview.md](references/signals-overview.md)
- **State phụ thuộc (`linkedSignal`)**: Tạo state ghi được, liên kết với các signal nguồn. Đọc [linked-signal.md](references/linked-signal.md)
- **Reactivity bất đồng bộ (`resource`)**: Lấy dữ liệu bất đồng bộ trực tiếp vào signal state. Đọc [resource.md](references/resource.md)
- **Side Effect (`effect`)**: Logging, thao tác DOM của bên thứ ba (`afterRenderEffect`), và khi nào KHÔNG nên dùng effect. Đọc [effects.md](references/effects.md)

## Form

Với hầu hết ứng dụng mới, **ưu tiên signal forms**. Khi đưa ra quyết định về forms, hãy phân tích dự án và cân nhắc các hướng dẫn sau:

- Nếu phiên bản ứng dụng hỗ trợ Signal Forms và đây là một form mới, **ưu tiên signal forms**.
- Với ứng dụng cũ hoặc form hiện có, hãy theo chiến lược form hiện tại của ứng dụng.

- **Signal Forms**: Dùng signal để quản lý state của form. Đọc [signal-forms.md](references/signal-forms.md)
- **Template-driven forms**: Dùng cho form đơn giản. Đọc [template-driven-forms.md](references/template-driven-forms.md)
- **Reactive forms**: Dùng cho form phức tạp. Đọc [reactive-forms.md](references/reactive-forms.md)

## Dependency Injection

Khi triển khai dependency injection trong Angular, hãy tuân theo các hướng dẫn sau:

- **Nền tảng**: Tổng quan về Dependency Injection, service và hàm `inject()`. Đọc [di-fundamentals.md](references/di-fundamentals.md)
- **Tạo và sử dụng Service**: Tạo service, tùy chọn `providedIn: 'root'`, và inject vào component hoặc service khác. Đọc [creating-services.md](references/creating-services.md)
- **Định nghĩa Dependency Provider**: Cung cấp tự động so với thủ công, `InjectionToken`, `useClass`, `useValue`, `useFactory` và các phạm vi (scope). Đọc [defining-providers.md](references/defining-providers.md)
- **Injection Context**: Nơi `inject()` được phép dùng, `runInInjectionContext` và `assertInInjectionContext`. Đọc [injection-context.md](references/injection-context.md)
- **Hierarchical Injector**: `EnvironmentInjector` so với `ElementInjector`, quy tắc resolve, các modifier (`optional`, `skipSelf`), và `providers` so với `viewProviders`. Đọc [hierarchical-injectors.md](references/hierarchical-injectors.md)

## Angular Aria

Khi xây dựng các component tùy chỉnh có accessibility cho bất kỳ pattern nào sau đây: Accordion, Listbox, Combobox, Menu, Tabs, Toolbar, Tree, Grid, hãy tham khảo tài liệu sau:

- **Angular Aria Components**: Xây dựng các component headless, accessible (Accordion, Listbox, Combobox, Menu, Tabs, Toolbar, Tree, Grid) và styling các thuộc tính ARIA. Đọc [angular-aria.md](references/angular-aria.md)

## Routing

Khi triển khai điều hướng trong Angular, hãy tham khảo các tài liệu sau:

- **Định nghĩa Route**: Đường dẫn URL, segment tĩnh so với động, wildcard và redirect. Đọc [define-routes.md](references/define-routes.md)
- **Chiến lược Loading Route**: Eager so với lazy loading, và loading theo ngữ cảnh. Đọc [loading-strategies.md](references/loading-strategies.md)
- **Hiển thị Route với Outlet**: Dùng `<router-outlet>`, outlet lồng nhau và named outlet. Đọc [show-routes-with-outlets.md](references/show-routes-with-outlets.md)
- **Điều hướng tới Route**: Điều hướng khai báo với `RouterLink` và điều hướng bằng lập trình với `Router`. Đọc [navigate-to-routes.md](references/navigate-to-routes.md)
- **Kiểm soát truy cập Route bằng Guard**: Triển khai `CanActivate`, `CanMatch` và các guard khác cho mục đích bảo mật. Đọc [route-guards.md](references/route-guards.md)
- **Data Resolver**: Lấy trước dữ liệu trước khi kích hoạt route bằng `ResolveFn`. Đọc [data-resolvers.md](references/data-resolvers.md)
- **Vòng đời và Event của Router**: Thứ tự thời gian của các navigation event và debug. Đọc [router-lifecycle.md](references/router-lifecycle.md)
- **Chiến lược Rendering**: CSR, SSG (Prerendering) và SSR với hydration. Đọc [rendering-strategies.md](references/rendering-strategies.md)
- **Animation chuyển Route**: Bật và tùy biến View Transitions API. Đọc [route-animations.md](references/route-animations.md)

Nếu bạn cần tài liệu chuyên sâu hơn hoặc thêm ngữ cảnh, hãy truy cập [hướng dẫn Angular Routing chính thức](https://angular.dev/guide/routing).

## Styling và Animation

Khi triển khai styling và animation trong Angular, hãy tham khảo các tài liệu sau:

- **Dùng Tailwind CSS với Angular**: Tích hợp Tailwind CSS vào các dự án Angular. Đọc [tailwind-css.md](references/tailwind-css.md)
- **Angular Animations**: Dùng CSS gốc (khuyến nghị) hoặc DSL cũ (legacy) cho các hiệu ứng động. Đọc [angular-animations.md](references/angular-animations.md)
- **Styling cho component**: Best practice cho component style và encapsulation. Đọc [component-styling.md](references/component-styling.md)

## Testing

Khi viết hoặc cập nhật test, hãy tham khảo các tài liệu sau tùy theo tác vụ:

- **Nền tảng**: Best practice cho unit testing, các pattern bất đồng bộ và `TestBed`. Đọc [testing-fundamentals.md](references/testing-fundamentals.md)
- **Component Harness**: Các pattern chuẩn để tương tác với component một cách vững chắc. Đọc [component-harnesses.md](references/component-harnesses.md)
- **Router Testing**: Dùng `RouterTestingHarness` cho các test điều hướng đáng tin cậy. Đọc [router-testing.md](references/router-testing.md)
- **End-to-End (E2E) Testing**: Best practice cho E2E test với Cypress hoặc Playwright. Đọc [e2e-testing.md](references/e2e-testing.md)

## Tooling

Khi làm việc với Angular tooling, hãy tham khảo các tài liệu sau:

- **Angular CLI**: Tạo ứng dụng, sinh code (component, route, service), serve và build. Đọc [cli.md](references/cli.md)
- **Angular MCP Server**: Các tool khả dụng, cấu hình và tính năng thử nghiệm. Đọc [mcp.md](references/mcp.md)

## Anti-Pattern

- Dùng `null` hoặc `undefined` làm giá trị khởi tạo cho field của signal form — hãy dùng `''`, `0` hoặc `[]` thay thế
- Truy cập các flag state của field trong form mà không gọi field trước: `form.field.valid()` — hãy dùng `form.field().valid()`
- Bắt đầu form mới bằng các API form cũ hơn khi phiên bản Angular mục tiêu hỗ trợ Signal Forms
- Đặt các HTML attribute `min`, `max`, `value`, `disabled` hoặc `readonly` trên input có `[formField]` — hãy định nghĩa chúng thành rule trong schema
- Gọi `inject()` bên ngoài một injection context — dùng `runInInjectionContext` khi cần
- Dùng `effect()` cho state dẫn xuất mà lẽ ra nên dùng `computed()`
- Tham chiếu `$parent.$index` trong các vòng lặp `@for` lồng nhau — Angular không hỗ trợ `$parent`; hãy dùng `let outerIdx = $index` thay thế

## Skill liên quan

- `tdd-workflow` — workflow phát triển hướng kiểm thử (test-driven development) áp dụng được cho Angular component và service
- `security-review` — checklist bảo mật cho ứng dụng web, bao gồm các vấn đề riêng của Angular
- `frontend-patterns` — các pattern frontend chung để tham khảo về cách tiếp cận React/Next.js
