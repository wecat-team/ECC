---
paths:
  - "**/*.css"
  - "**/*.scss"
  - "**/*.sass"
  - "**/*.less"
  - "**/*.html"
  - "**/*.tsx"
  - "**/*.jsx"
  - "**/*.vue"
  - "**/*.svelte"
---
> File này mở rộng [common/performance.md](../common/performance.md) với nội dung hiệu năng riêng cho web.

# Quy tắc hiệu năng Web

## Mục tiêu Core Web Vitals

| Chỉ số | Mục tiêu |
|--------|--------|
| LCP | < 2.5s |
| INP | < 200ms |
| CLS | < 0.1 |
| FCP | < 1.5s |
| TBT | < 200ms |

## Ngân sách Bundle

| Loại trang | Ngân sách JS (gzipped) | Ngân sách CSS |
|-----------|---------------------|------------|
| Landing page | < 150kb | < 30kb |
| Trang app | < 300kb | < 50kb |
| Microsite | < 80kb | < 15kb |

## Chiến lược tải

1. Inline CSS critical above-the-fold khi có lý do chính đáng
2. Chỉ preload ảnh hero và font chính
3. Defer CSS hoặc JS không critical
4. Import động các thư viện nặng

```js
const gsapModule = await import('gsap');
const { ScrollTrigger } = await import('gsap/ScrollTrigger');
```

## Tối ưu ảnh

- `width` và `height` tường minh
- `loading="eager"` cùng `fetchpriority="high"` chỉ cho media hero
- `loading="lazy"` cho asset dưới màn hình đầu tiên (below-the-fold)
- Ưu tiên AVIF hoặc WebP kèm fallback
- Không bao giờ phát hành ảnh nguồn lớn hơn nhiều so với kích thước render

## Tải Font

- Tối đa hai font family trừ khi có ngoại lệ rõ ràng
- `font-display: swap`
- Subset khi có thể
- Chỉ preload weight/style thực sự quan trọng

## Hiệu năng Animation

- Chỉ animate các thuộc tính thân thiện với compositor
- Dùng `will-change` một cách hạn chế và gỡ nó khi xong
- Ưu tiên CSS cho các transition đơn giản
- Dùng `requestAnimationFrame` hoặc thư viện animation đã được kiểm chứng cho chuyển động bằng JS
- Tránh scroll handler chạy dồn dập; dùng IntersectionObserver hoặc các thư viện hoạt động tốt

## Checklist hiệu năng

- [ ] Mọi ảnh đều có kích thước tường minh
- [ ] Không có resource chặn render ngoài ý muốn
- [ ] Không có layout shift do nội dung động
- [ ] Chuyển động chỉ dùng các thuộc tính thân thiện với compositor
- [ ] Script bên thứ ba tải async/defer và chỉ khi cần
