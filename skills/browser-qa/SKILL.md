---
name: browser-qa
description: "Chạy xác minh UI tự động sau deploy bằng một MCP browser automation (claude-in-chrome, Playwright hoặc Puppeteer): smoke check lỗi console và Core Web Vitals, test tương tác form và luồng auth, visual regression bằng screenshot ở ba breakpoint, và audit accessibility bằng axe-core, kết thúc bằng verdict SHIP / DO-NOT-SHIP. Dùng khi test một tính năng đã deploy trên staging hoặc preview, trước khi ship thay đổi frontend, review PR frontend, hoặc kiểm tra responsive layout và accessibility."
metadata:
  origin: ECC
---

# Browser QA — Visual Testing & Tương tác tự động

## Khi nào dùng

- Sau khi deploy một tính năng lên staging/preview
- Khi cần xác minh hành vi UI trên nhiều trang
- Trước khi ship — xác nhận layout, form, tương tác thực sự hoạt động
- Khi review các PR chạm vào code frontend
- Audit accessibility và test responsive

## Cách hoạt động

Dùng MCP browser automation (claude-in-chrome, Playwright hoặc Puppeteer) để tương tác với các trang đang chạy như một người dùng thật.

### An toàn trước tiên — phạm vi ảnh hưởng (blast radius) (mặc định chạy read-only)

Browser QA điều khiển auth thật và các hành trình người dùng thật, nên hãy xử lý phạm vi ảnh hưởng một cách tường minh.
Mặc định là **read-only**: KHÔNG BAO GIỜ chạy một hành trình **có thay đổi dữ liệu (mutating)** (checkout, thanh toán, xóa,
cập nhật hàng loạt) trên URL production — yêu cầu opt-in tường minh **và** một URL staging/preview.
Dùng **test credential** đã seed, không bao giờ dùng đăng nhập production thật, và **che (redact)**
credential/token/PII trước khi lưu bất kỳ screenshot nào.

### Phase 1: Smoke Test
```
1. Navigate to target URL
2. Check for console errors (filter noise: analytics, third-party)
3. Verify no 4xx/5xx in network requests
4. Screenshot above-the-fold on desktop + mobile viewport
5. Check Core Web Vitals: LCP < 2.5s, CLS < 0.1, INP < 200ms
   (INP replaced FID in March 2024; thresholds per web.dev)
```

### Phase 2: Interaction Test
```
1. Click every nav link — verify no dead links
2. Submit forms with valid data — verify success state
3. Submit forms with invalid data — verify error state
4. Test auth flow: login → protected page → logout (test creds only, never prod)
5. Test critical user journeys (checkout, onboarding, search)
   — read-only by default; only exercise mutating journeys against staging
     with explicit opt-in (see "Safety first" above)
```

### Phase 3: Visual Regression
```
1. Screenshot key pages at 3 breakpoints (375px, 768px, 1440px)
2. Compare against committed baseline screenshots
   — no baseline ⇒ report INCONCLUSIVE, never a silent PASS
3. Flag layout shifts > 5px, missing elements, overflow
4. Check dark mode if applicable
```

### Phase 4: Accessibility
```
1. Run axe-core or equivalent on each page
2. Flag WCAG 2.2 AA violations (contrast, labels, focus order)
3. Verify keyboard navigation works end-to-end
4. Check screen reader landmarks
```

> Lưu ý: axe-core tự động bao phủ khoảng 30–40% WCAG. Một lần chạy sạch là **cần thiết,
> chưa đủ** — keyboard nav, focus order và screen-reader pass vẫn cần kiểm tra thủ công.
> Đừng báo cáo "accessible" chỉ dựa vào kết quả chạy tự động.

## Định dạng Output

```markdown
## QA Report — [URL] — [timestamp]

### Smoke Test
- Console errors: 0 critical, 2 warnings (analytics noise)
- Network: all 200/304, no failures
- Core Web Vitals: LCP 1.2s ✓, CLS 0.02 ✓, INP 89ms ✓

### Interactions
- [✓] Nav links: 12/12 working
- [✗] Contact form: missing error state for invalid email
- [✓] Auth flow: login/logout working

### Visual
- [✗] Hero section overflows on 375px viewport
- [✓] Dark mode: all pages consistent

### Accessibility
- 2 AA violations: missing alt text on hero image, low contrast on footer links

### Verdict: SHIP WITH FIXES (2 issues, 0 blockers)
# verdict ∈ SHIP / SHIP WITH FIXES / DO NOT SHIP; use INCONCLUSIVE if no visual baseline
```

## Tích hợp

Hoạt động với bất kỳ browser MCP nào:
- Các tool `mChild__claude-in-chrome__*` (ưu tiên — dùng Chrome thực của bạn)
- Playwright qua `mcp__browserbase__*`
- Các script Puppeteer trực tiếp

Kết hợp với `/canary-watch` để giám sát sau deploy.
