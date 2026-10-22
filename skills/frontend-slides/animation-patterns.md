# Tham chiếu Animation Pattern

Dùng tài liệu tham chiếu này khi tạo bài thuyết trình. Hãy khớp animation với cảm giác mong muốn.

## Hướng dẫn Hiệu ứng theo Cảm giác

| Cảm giác | Animation | Gợi ý thị giác |
|---------|-----------|-------------|
| **Kịch tính / Điện ảnh** | Fade-in chậm (1-1.5s), transition quy mô lớn (0.9 đến 1), parallax scrolling | Nền tối, hiệu ứng spotlight, ảnh tràn viền (full-bleed) |
| **Công nghệ / Tương lai** | Neon glow (box-shadow), chữ glitch/scramble, grid reveal | Hệ thống hạt (canvas), pattern lưới, điểm nhấn monospace, cyan/magenta/xanh điện |
| **Vui tươi / Thân thiện** | Easing nảy (vật lý lò xo), lơ lửng/nhấp nhô | Góc bo tròn, màu pastel/tươi sáng, phần tử vẽ tay |
| **Chuyên nghiệp / Doanh nghiệp** | Animation tinh tế và nhanh (200-300ms), slide gọn gàng | Navy/slate/charcoal, khoảng cách chính xác, tập trung vào trực quan hóa dữ liệu |
| **Tĩnh lặng / Tối giản** | Chuyển động rất chậm và tinh tế, fade nhẹ nhàng | Nhiều khoảng trắng, bảng màu trầm, typography serif, padding rộng rãi |
| **Biên tập / Tạp chí** | Hiện chữ so le (staggered), tương tác giữa ảnh và chữ | Phân cấp chữ mạnh, pull quote, layout phá vỡ lưới, tiêu đề serif + nội dung sans |

## Animation xuất hiện (Entrance)

```css
/* Fade + Slide Up (most versatile) */
.reveal {
    opacity: 0;
    transform: translateY(30px);
    transition: opacity 0.6s var(--ease-out-expo),
                transform 0.6s var(--ease-out-expo);
}
.visible .reveal {
    opacity: 1;
    transform: translateY(0);
}

/* Scale In */
.reveal-scale {
    opacity: 0;
    transform: scale(0.9);
    transition: opacity 0.6s, transform 0.6s var(--ease-out-expo);
}
.visible .reveal-scale {
    opacity: 1;
    transform: scale(1);
}

/* Slide from Left */
.reveal-left {
    opacity: 0;
    transform: translateX(-50px);
    transition: opacity 0.6s, transform 0.6s var(--ease-out-expo);
}
.visible .reveal-left {
    opacity: 1;
    transform: translateX(0);
}

/* Blur In */
.reveal-blur {
    opacity: 0;
    filter: blur(10px);
    transition: opacity 0.8s, filter 0.8s var(--ease-out-expo);
}
.visible .reveal-blur {
    opacity: 1;
    filter: blur(0);
}
```

## Hiệu ứng nền (Background)

```css
/* Gradient Mesh — layered radial gradients for depth */
.gradient-bg {
    background:
        radial-gradient(ellipse at 20% 80%, rgba(120, 0, 255, 0.3) 0%, transparent 50%),
        radial-gradient(ellipse at 80% 20%, rgba(0, 255, 200, 0.2) 0%, transparent 50%),
        var(--bg-primary);
}

/* Noise Texture — inline SVG for grain */
.noise-bg {
    background-image: url("data:image/svg+xml,..."); /* Inline SVG noise */
}

/* Grid Pattern — subtle structural lines */
.grid-bg {
    background-image:
        linear-gradient(rgba(255,255,255,0.03) 1px, transparent 1px),
        linear-gradient(90deg, rgba(255,255,255,0.03) 1px, transparent 1px);
    background-size: 50px 50px;
}
```

## Hiệu ứng tương tác

```javascript
/* 3D Tilt on Hover — adds depth to cards/panels */
class TiltEffect {
    constructor(element) {
        this.element = element;
        this.element.style.transformStyle = 'preserve-3d';
        this.element.style.perspective = '1000px';

        this.element.addEventListener('mousemove', (e) => {
            const rect = this.element.getBoundingClientRect();
            const x = (e.clientX - rect.left) / rect.width - 0.5;
            const y = (e.clientY - rect.top) / rect.height - 0.5;
            this.element.style.transform = `rotateY(${x * 10}deg) rotateX(${-y * 10}deg)`;
        });

        this.element.addEventListener('mouseleave', () => {
            this.element.style.transform = 'rotateY(0) rotateX(0)';
        });
    }
}
```

## Xử lý sự cố

| Vấn đề | Cách khắc phục |
|---------|-----|
| Font không tải | Kiểm tra URL Fontshare/Google Fonts; đảm bảo tên font khớp trong CSS |
| Animation không kích hoạt | Xác minh Intersection Observer đang chạy; kiểm tra class `.visible` đang được thêm vào |
| Scroll snap không hoạt động | Đảm bảo `scroll-snap-type: y mandatory` trên html; mỗi slide cần `scroll-snap-align: start` |
| Vấn đề trên mobile | Tắt các hiệu ứng nặng ở breakpoint 768px; test sự kiện touch; giảm số lượng hạt |
| Vấn đề hiệu năng | Dùng `will-change` tiết kiệm; ưu tiên animation `transform`/`opacity`; throttle scroll handler |
