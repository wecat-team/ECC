---
name: frontend-a11y
description: Pattern accessibility (a11y) cho React và Next.js — HTML ngữ nghĩa (semantic HTML), thuộc tính ARIA, gắn nhãn form, điều hướng bằng bàn phím, quản lý focus và hỗ trợ screen reader. Dùng khi xây dựng hoặc review form, modal, dropdown, tooltip hoặc tab, sửa phát hiện từ a11y lint hoặc code review, hoặc triển khai điều hướng bàn phím và quản lý focus.
metadata:
  origin: community
---

# Pattern Accessibility cho Frontend

Các pattern accessibility thực dụng cho React và Next.js. Bao gồm những vấn đề thường bị đánh dấu nhất trong code review: thiếu nhãn form, dùng ARIA sai, phần tử tương tác không ngữ nghĩa và điều hướng bàn phím bị hỏng.

## Khi nào kích hoạt

- Xây dựng hoặc review các component form (`<input>`, `<select>`, `<textarea>`)
- Tạo các phần tử tương tác (modal, dropdown, tooltip, tab)
- Dùng `<div>` hoặc `<span>` với `onClick`
- Thêm thuộc tính `aria-*` vào bất kỳ phần tử nào
- Triển khai điều hướng bàn phím hoặc quản lý focus
- Nhận phản hồi accessibility từ công cụ code review (CodeRabbit, ESLint a11y)
- Xây dựng component phải hỗ trợ screen reader

## Accessibility cho Form

Thiếu cặp `htmlFor` / `id` và thông báo lỗi không được liên kết là những vấn đề phổ biến nhất bị đánh dấu trong code review.

### Kết nối Label

```tsx
// BAD: label không có kết nối với input — screen reader không thể liên kết chúng
<label>Email</label>
<input type="email" />

// GOOD: htmlFor khớp với id của input
<label htmlFor="email">Email</label>
<input id="email" type="email" />
```

### Trường bắt buộc

```tsx
// BAD: dấu sao chỉ có tác dụng thị giác, không truyền đạt gì cho screen reader
<label htmlFor="email">Email *</label>
<input id="email" type="email" />

// GOOD: required bật validation gốc của trình duyệt; aria-required báo hiệu cho screen reader
<label htmlFor="email">
  Email <span aria-hidden="true">*</span>
</label>
<input id="email" type="email" required aria-required="true" />
```

### Thông báo lỗi

```tsx
// BAD: văn bản lỗi hiển thị trực quan nhưng không được liên kết với input
<input id="email" type="email" />
<span className="error">Invalid email address</span>

// GOOD: aria-describedby kết nối input với thông báo lỗi của nó
// aria-invalid báo trạng thái không hợp lệ cho screen reader
<input
  id="email"
  type="email"
  aria-describedby="email-error"
  aria-invalid={!!error}
/>
{error && (
  <span id="email-error" role="alert">
    {error}
  </span>
)}
```

### Form Accessible hoàn chỉnh

```tsx
interface LoginFormProps {
  onSubmit: (email: string, password: string) => void;
}

export function LoginForm({ onSubmit }: LoginFormProps) {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [errors, setErrors] = useState<{ email?: string; password?: string }>({});

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    const newErrors: typeof errors = {};
    if (!email) newErrors.email = 'Email is required';
    if (!password) newErrors.password = 'Password is required';
    if (Object.keys(newErrors).length) {
      setErrors(newErrors);
      return;
    }
    onSubmit(email, password);
  };

  return (
    <form onSubmit={handleSubmit} noValidate>
      <div>
        <label htmlFor="email">
          Email <span aria-hidden="true">*</span>
        </label>
        <input
          id="email"
          type="email"
          value={email}
          onChange={e => setEmail(e.target.value)}
          aria-required="true"
          aria-describedby={errors.email ? 'email-error' : undefined}
          aria-invalid={!!errors.email}
          autoComplete="email"
        />
        {errors.email && (
          <span id="email-error" role="alert">
            {errors.email}
          </span>
        )}
      </div>

      <div>
        <label htmlFor="password">
          Password <span aria-hidden="true">*</span>
        </label>
        <input
          id="password"
          type="password"
          value={password}
          onChange={e => setPassword(e.target.value)}
          aria-required="true"
          aria-describedby={errors.password ? 'password-error' : undefined}
          aria-invalid={!!errors.password}
          autoComplete="current-password"
        />
        {errors.password && (
          <span id="password-error" role="alert">
            {errors.password}
          </span>
        )}
      </div>

      <button type="submit">Log in</button>
    </form>
  );
}
```

## HTML ngữ nghĩa (Semantic HTML)

Hãy dùng phần tử khớp với ý định. Screen reader và người dùng bàn phím phụ thuộc vào ngữ nghĩa gốc.

```tsx
// BAD: div không có role, không hỗ trợ bàn phím, không có tên accessible
<div onClick={handleClick}>Submit</div>

// GOOD: button focus được, kích hoạt bằng Enter/Space, được đọc là "button"
<button type="button" onClick={handleClick}>Submit</button>
```

```tsx
// BAD: điều hướng không ngữ nghĩa
<div onClick={() => navigate('/home')}>Home</div>

// GOOD: anchor hỗ trợ chuột phải, chuột giữa và điều hướng bàn phím
<a href="/home">Home</a>
```

```tsx
// BAD: bỏ qua cấp heading (h1 sang h4)
<h1>Dashboard</h1>
<h4>Recent Activity</h4>

// GOOD: các cấp heading liên tiếp
<h1>Dashboard</h1>
<h2>Recent Activity</h2>
```

## Thuộc tính ARIA

Chỉ dùng ARIA khi ngữ nghĩa HTML gốc không đủ. ARIA sai còn tệ hơn không có ARIA.

### aria-label so với aria-labelledby

```tsx
// aria-label: nhãn chuỗi inline — dùng khi không có văn bản nhãn hiển thị
<button aria-label="Close modal">
  <XIcon />
</button>

// aria-labelledby: tham chiếu văn bản của phần tử khác — dùng khi có nhãn hiển thị
<section aria-labelledby="section-title">
  <h2 id="section-title">Recent Orders</h2>
  {/* content */}
</section>
```

### aria-describedby

```tsx
// Cung cấp mô tả bổ sung ngoài nhãn
<button
  aria-describedby="delete-warning"
  onClick={handleDelete}
> Delete account
</button>
<p id="delete-warning">This action cannot be undone.</p>
```

### aria-live cho nội dung động

```tsx
// Dùng aria-live để thông báo nội dung cập nhật mà không tải lại trang
// polite: chờ người dùng hoàn tất thao tác hiện tại rồi mới thông báo
// assertive: ngắt ngay lập tức — chỉ dùng cho lỗi khẩn cấp

export function StatusMessage({ message, isError }: { message: string; isError?: boolean }) {
  return (
    <div role="status" aria-live={isError ? 'assertive' : 'polite'} aria-atomic="true">
      {message}
    </div>
  );
}
```

### aria-expanded và aria-controls

```tsx
export function Accordion({ title, children }: { title: string; children: React.ReactNode }) {
  const [isOpen, setIsOpen] = useState(false);
  const contentId = useId();

  return (
    <div>
      <button aria-expanded={isOpen} aria-controls={contentId} onClick={() => setIsOpen(prev => !prev)}>
        {title}
      </button>
      <div id={contentId} hidden={!isOpen}>
        {children}
      </div>
    </div>
  );
}
```

## Điều hướng bằng bàn phím

Mọi phần tử tương tác phải truy cập và thao tác được chỉ bằng bàn phím.

### Dropdown tùy chỉnh

```tsx
export function Dropdown({ options, onSelect }: { options: string[]; onSelect: (value: string) => void }) {
  const [isOpen, setIsOpen] = useState(false);
  const [activeIndex, setActiveIndex] = useState(0);
  const listId = useId();

  if (!options.length) return null;

  const handleKeyDown = (e: React.KeyboardEvent) => {
    switch (e.key) {
      case 'ArrowDown':
        e.preventDefault();
        setActiveIndex(i => Math.min(i + 1, options.length - 1));
        break;
      case 'ArrowUp':
        e.preventDefault();
        setActiveIndex(i => Math.max(i - 1, 0));
        break;
      case 'Enter':
      case ' ':
        e.preventDefault();
        if (isOpen) onSelect(options[activeIndex]);
        setIsOpen(prev => !prev);
        break;
      case 'Escape':
        setIsOpen(false);
        break;
    }
  };

  return (
    <div
      role="combobox"
      aria-expanded={isOpen}
      aria-haspopup="listbox"
      aria-controls={listId}
      tabIndex={0}
      onKeyDown={handleKeyDown}
      onClick={() => setIsOpen(prev => !prev)}
    >
      <span>{options[activeIndex]}</span>
      {isOpen && (
        <ul id={listId} role="listbox">
          {options.map((option, index) => (
            <li
              key={option}
              role="option"
              aria-selected={index === activeIndex}
              onClick={() => {
                onSelect(option);
                setIsOpen(false);
              }}
            >
              {option}
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}
```

## Quản lý Focus

Focus phải di chuyển hợp lý khi trạng thái UI thay đổi — đặc biệt với modal và chuyển route.

### Khôi phục Focus của Modal

> Ví dụ này bao gồm focus ban đầu và việc khôi phục. Để có focus trap đầy đủ (Tab/Shift+Tab xoay vòng trong modal), hãy dùng thư viện như [`focus-trap-react`](https://github.com/focus-trap/focus-trap-react), thư viện này xử lý các edge case như nội dung động và portal lồng nhau.

```tsx
export function Modal({ isOpen, onClose, title, children }: { isOpen: boolean; onClose: () => void; title: string; children: React.ReactNode }) {
  const modalRef = useRef<HTMLDivElement>(null);
  const previousFocusRef = useRef<HTMLElement | null>(null);

  useEffect(() => {
    if (isOpen) {
      // Lưu phần tử đang focus và chuyển focus vào modal
      previousFocusRef.current = document.activeElement as HTMLElement;
      modalRef.current?.focus();
    } else {
      // Khôi phục focus về phần tử đã mở modal
      previousFocusRef.current?.focus();
    }
  }, [isOpen]);

  if (!isOpen) return null;

  return (
    <div ref={modalRef} role="dialog" aria-modal="true" aria-labelledby="modal-title" tabIndex={-1} onKeyDown={e => e.key === 'Escape' && onClose()}>
      <h2 id="modal-title">{title}</h2>
      {children}
      <button onClick={onClose}>Close</button>
    </div>
  );
}
```

## Ảnh và Icon

```tsx
// BAD: icon trang trí bị đọc là ảnh không có nhãn
<img src="/icon.svg" />

// GOOD: ảnh trang trí được ẩn khỏi screen reader
<img src="/decoration.png" alt="" aria-hidden="true" />

// GOOD: ảnh có ý nghĩa với alt text mô tả
<img src="/chart.png" alt="Monthly revenue increased 23% from January to March" />

// GOOD: nút icon có nhãn accessible
<button aria-label="Delete item">
  <TrashIcon aria-hidden="true" />
</button>
```

## Giảm chuyển động (Reduced Motion)

Hãy tôn trọng người dùng đã yêu cầu giảm chuyển động trong thiết lập OS.

```tsx
export function useReducedMotion(): boolean {
  const [prefersReduced, setPrefersReduced] = useState(false);

  useEffect(() => {
    const mq = window.matchMedia('(prefers-reduced-motion: reduce)');
    setPrefersReduced(mq.matches);
    const handler = (e: MediaQueryListEvent) => setPrefersReduced(e.matches);
    mq.addEventListener('change', handler);
    return () => mq.removeEventListener('change', handler);
  }, []);

  return prefersReduced;
}

// Cách dùng
export function AnimatedCard({ children }: { children: React.ReactNode }) {
  const reduceMotion = useReducedMotion();

  return (
    <div
      style={{
        transition: reduceMotion ? 'none' : 'transform 300ms ease'
      }}
    >
      {children}
    </div>
  );
}
```

## Anti-Patterns

```tsx
// BAD: onClick trên phần tử không tương tác và không hỗ trợ bàn phím
<div onClick={handleClick}>Click me</div>

// BAD: aria-label trên div không có role
<div aria-label="Navigation">...</div>

// BAD: dùng placeholder thay cho label
<input placeholder="Enter your email" />

// BAD: tabIndex dương tạo thứ tự tab khó đoán
<button tabIndex={3}>Submit</button>

// BAD: aria-hidden trên phần tử focus được — người dùng bàn phím bị kẹt
<button aria-hidden="true">Open</button>

// BAD: role="button" trên div không có keyboard handler
<div role="button" onClick={handleClick}>Submit</div>
// Thiếu: tabIndex={0}, onKeyDown cho Enter/Space
```

## Checklist

Trước khi gửi bất kỳ component tương tác nào đi review:

- [ ] Mọi `<input>`, `<select>` và `<textarea>` đều có `<label>` được kết nối qua `htmlFor`/`id`
- [ ] Thông báo lỗi được liên kết bằng `aria-describedby` và đánh dấu `role="alert"`
- [ ] Không có `onClick` trên `<div>` hoặc `<span>` mà thiếu `role`, `tabIndex` và `onKeyDown`
- [ ] Nút chỉ có icon có `aria-label`
- [ ] Ảnh trang trí dùng `alt=""` và `aria-hidden="true"`
- [ ] Modal khôi phục focus khi đóng (để có focus trap đầy đủ với Tab/Shift+Tab xoay vòng, hãy dùng thư viện như `focus-trap-react`)
- [ ] Cập nhật nội dung động dùng `aria-live`
- [ ] `prefers-reduced-motion` được tôn trọng cho animation

## Skill liên quan

- `frontend-patterns` — pattern component và state chung cho React
- `design-system` — tính nhất quán của design token và component
- `motion-foundations` và `motion-patterns`: pattern animation có xét đến accessibility
