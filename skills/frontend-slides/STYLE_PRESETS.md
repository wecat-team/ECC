# Tham chiếu Style Preset

Các phong cách thị giác được tuyển chọn cho `frontend-slides`.

Dùng file này cho:
- CSS nền bắt buộc để vừa khít viewport
- chọn preset và ánh xạ tâm trạng
- các cạm bẫy CSS và quy tắc xác thực

Chỉ dùng hình khối trừu tượng. Tránh hình minh họa trừ khi người dùng yêu cầu rõ ràng.

## Vừa khít Viewport là bất di bất dịch

Mọi slide phải nằm trọn trong một viewport.

### Quy tắc vàng

```text
Each slide = exactly one viewport height.
Too much content = split into more slides.
Never scroll inside a slide.
```

### Giới hạn mật độ

| Loại slide | Nội dung tối đa |
|------------|-----------------|
| Title slide | 1 heading + 1 subtitle + tagline tùy chọn |
| Content slide | 1 heading + 4-6 bullet hoặc 2 đoạn |
| Feature grid | tối đa 6 card |
| Code slide | tối đa 8-10 dòng |
| Quote slide | 1 trích dẫn + ghi nguồn |
| Image slide | 1 ảnh, lý tưởng dưới 60vh |

## CSS nền bắt buộc

Sao chép khối này vào mọi bài thuyết trình được tạo ra rồi áp theme lên trên nó.

```css
/* ===========================================
   VIEWPORT FITTING: MANDATORY BASE STYLES
   =========================================== */

html, body {
    height: 100%;
    overflow-x: hidden;
}

html {
    scroll-snap-type: y mandatory;
    scroll-behavior: smooth;
}

.slide {
    width: 100vw;
    height: 100vh;
    height: 100dvh;
    overflow: hidden;
    scroll-snap-align: start;
    display: flex;
    flex-direction: column;
    position: relative;
}

.slide-content {
    flex: 1;
    display: flex;
    flex-direction: column;
    justify-content: center;
    max-height: 100%;
    overflow: hidden;
    padding: var(--slide-padding);
}

:root {
    --title-size: clamp(1.5rem, 5vw, 4rem);
    --h2-size: clamp(1.25rem, 3.5vw, 2.5rem);
    --h3-size: clamp(1rem, 2.5vw, 1.75rem);
    --body-size: clamp(0.75rem, 1.5vw, 1.125rem);
    --small-size: clamp(0.65rem, 1vw, 0.875rem);

    --slide-padding: clamp(1rem, 4vw, 4rem);
    --content-gap: clamp(0.5rem, 2vw, 2rem);
    --element-gap: clamp(0.25rem, 1vw, 1rem);
}

.card, .container, .content-box {
    max-width: min(90vw, 1000px);
    max-height: min(80vh, 700px);
}

.feature-list, .bullet-list {
    gap: clamp(0.4rem, 1vh, 1rem);
}

.feature-list li, .bullet-list li {
    font-size: var(--body-size);
    line-height: 1.4;
}

.grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(min(100%, 250px), 1fr));
    gap: clamp(0.5rem, 1.5vw, 1rem);
}

img, .image-container {
    max-width: 100%;
    max-height: min(50vh, 400px);
    object-fit: contain;
}

@media (max-height: 700px) {
    :root {
        --slide-padding: clamp(0.75rem, 3vw, 2rem);
        --content-gap: clamp(0.4rem, 1.5vw, 1rem);
        --title-size: clamp(1.25rem, 4.5vw, 2.5rem);
        --h2-size: clamp(1rem, 3vw, 1.75rem);
    }
}

@media (max-height: 600px) {
    :root {
        --slide-padding: clamp(0.5rem, 2.5vw, 1.5rem);
        --content-gap: clamp(0.3rem, 1vw, 0.75rem);
        --title-size: clamp(1.1rem, 4vw, 2rem);
        --body-size: clamp(0.7rem, 1.2vw, 0.95rem);
    }

    .nav-dots, .keyboard-hint, .decorative {
        display: none;
    }
}

@media (max-height: 500px) {
    :root {
        --slide-padding: clamp(0.4rem, 2vw, 1rem);
        --title-size: clamp(1rem, 3.5vw, 1.5rem);
        --h2-size: clamp(0.9rem, 2.5vw, 1.25rem);
        --body-size: clamp(0.65rem, 1vw, 0.85rem);
    }
}

@media (max-width: 600px) {
    :root {
        --title-size: clamp(1.25rem, 7vw, 2.5rem);
    }

    .grid {
        grid-template-columns: 1fr;
    }
}

@media (prefers-reduced-motion: reduce) {
    *, *::before, *::after {
        animation-duration: 0.01ms !important;
        transition-duration: 0.2s !important;
    }

    html {
        scroll-behavior: auto;
    }
}
```

## Checklist Viewport

- mọi `.slide` có `height: 100vh`, `height: 100dvh` và `overflow: hidden`
- toàn bộ typography dùng `clamp()`
- toàn bộ khoảng cách dùng `clamp()` hoặc đơn vị viewport
- ảnh có ràng buộc `max-height`
- grid thích ứng với `auto-fit` + `minmax()`
- có breakpoint cho chiều cao thấp tại `700px`, `600px` và `500px`
- nếu có chỗ nào cảm thấy chật chội, hãy tách slide

## Ánh xạ Tâm trạng sang Preset

| Tâm trạng | Preset phù hợp |
|------|--------------|
| Ấn tượng / Tự tin | Bold Signal, Electric Studio, Dark Botanical |
| Hào hứng / Tràn năng lượng | Creative Voltage, Neon Cyber, Split Pastel |
| Bình tĩnh / Tập trung | Notebook Tabs, Paper & Ink, Swiss Modern |
| Truyền cảm hứng / Xúc động | Dark Botanical, Vintage Editorial, Pastel Geometry |

## Danh mục Preset

### 1. Bold Signal

- Phong cách: tự tin, tác động mạnh, sẵn sàng cho keynote
- Phù hợp cho: pitch deck, ra mắt sản phẩm, tuyên bố
- Font: Archivo Black + Space Grotesk
- Bảng màu: nền charcoal, card tiêu điểm màu cam rực, chữ trắng sắc nét
- Đặc trưng: số section cỡ lớn, card tương phản cao trên nền tối

### 2. Electric Studio

- Phong cách: sạch, đậm, trau chuốt kiểu agency
- Phù hợp cho: thuyết trình khách hàng, review chiến lược
- Font: chỉ Manrope
- Bảng màu: đen, trắng, màu nhấn cobalt bão hòa
- Đặc trưng: chia hai panel và căn lề biên tập sắc nét

### 3. Creative Voltage

- Phong cách: tràn năng lượng, retro-hiện đại, tự tin vui tươi
- Phù hợp cho: studio sáng tạo, công việc thương hiệu, kể chuyện về sản phẩm
- Font: Syne + Space Mono
- Bảng màu: xanh điện, vàng neon, navy đậm
- Đặc trưng: texture halftone, huy hiệu, tương phản mạnh

### 4. Dark Botanical

- Phong cách: thanh lịch, cao cấp, giàu khí quyển
- Phù hợp cho: thương hiệu xa xỉ, câu chuyện sâu sắc, deck sản phẩm cao cấp
- Font: Cormorant + IBM Plex Sans
- Bảng màu: gần đen, ngà ấm, hồng phấn, vàng gold, đất nung (terracotta)
- Đặc trưng: vòng tròn trừu tượng mờ, đường kẻ mảnh, chuyển động tiết chế

### 5. Notebook Tabs

- Phong cách: biên tập, ngăn nắp, giàu xúc giác
- Phù hợp cho: báo cáo, review, kể chuyện có cấu trúc
- Font: Bodoni Moda + DM Sans
- Bảng màu: giấy kem trên nền charcoal với tab pastel
- Đặc trưng: tờ giấy, tab màu bên cạnh, chi tiết kiểu binder

### 6. Pastel Geometry

- Phong cách: dễ gần, hiện đại, thân thiện
- Phù hợp cho: tổng quan sản phẩm, onboarding, deck thương hiệu nhẹ nhàng hơn
- Font: chỉ Plus Jakarta Sans
- Bảng màu: nền xanh nhạt, card kem, màu nhấn hồng/bạc hà/oải hương dịu
- Đặc trưng: viên thuốc dọc (pill), card bo tròn, đổ bóng mềm

### 7. Split Pastel

- Phong cách: vui tươi, hiện đại, sáng tạo
- Phù hợp cho: giới thiệu agency, workshop, portfolio
- Font: chỉ Outfit
- Bảng màu: chia đôi đào + oải hương với huy hiệu bạc hà
- Đặc trưng: nền chia đôi, tag bo tròn, lớp phủ lưới nhẹ

### 8. Vintage Editorial

- Phong cách: dí dỏm, đậm cá tính, lấy cảm hứng từ tạp chí
- Phù hợp cho: thương hiệu cá nhân, talk có quan điểm, kể chuyện
- Font: Fraunces + Work Sans
- Bảng màu: kem, charcoal, màu nhấn ấm bụi
- Đặc trưng: điểm nhấn hình học, callout có viền, tiêu đề serif mạnh mẽ

### 9. Neon Cyber

- Phong cách: tương lai, công nghệ, chuyển động
- Phù hợp cho: AI, hạ tầng, dev tool, talk về tương lai của X
- Font: Clash Display + Satoshi
- Bảng màu: navy nửa đêm, cyan, magenta
- Đặc trưng: glow, hạt, lưới, năng lượng radar dữ liệu

### 10. Terminal Green

- Phong cách: hướng đến developer, hacker nhưng gọn gàng
- Phù hợp cho: API, công cụ CLI, demo kỹ thuật
- Font: chỉ JetBrains Mono
- Bảng màu: GitHub dark + xanh lá terminal
- Đặc trưng: scan line, khung kiểu dòng lệnh, nhịp monospace chính xác

### 11. Swiss Modern

- Phong cách: tối giản, chính xác, ưu tiên dữ liệu
- Phù hợp cho: doanh nghiệp, chiến lược sản phẩm, analytics
- Font: Archivo + Nunito
- Bảng màu: trắng, đen, đỏ tín hiệu
- Đặc trưng: lưới nhìn thấy được, bất đối xứng, kỷ luật hình học

### 12. Paper & Ink

- Phong cách: văn chương, sâu sắc, hướng câu chuyện
- Phù hợp cho: tiểu luận, keynote kể chuyện, deck tuyên ngôn
- Font: Cormorant Garamond + Source Serif 4
- Bảng màu: kem ấm, charcoal, màu nhấn đỏ thẫm
- Đặc trưng: pull quote, drop cap, đường kẻ thanh lịch

## Gợi ý chọn trực tiếp

Nếu người dùng đã biết phong cách mình muốn, hãy để họ chọn trực tiếp từ các tên preset ở trên thay vì ép tạo bản xem trước.

## Ánh xạ Cảm giác Animation

| Cảm giác | Hướng chuyển động |
|---------|------------------|
| Kịch tính / Điện ảnh | fade chậm, parallax, scale-in lớn |
| Công nghệ / Tương lai | glow, hạt, chuyển động lưới, chữ scramble |
| Vui tươi / Thân thiện | easing nảy, hình bo tròn, chuyển động lơ lửng |
| Chuyên nghiệp / Doanh nghiệp | transition tinh tế 200-300ms, slide gọn gàng |
| Tĩnh lặng / Tối giản | chuyển động rất tiết chế, ưu tiên khoảng trắng |
| Biên tập / Tạp chí | phân cấp mạnh, chữ và ảnh đan xen so le |

## Cạm bẫy CSS: Phủ định hàm

KHÔNG BAO GIỜ viết những dòng này:

```css
right: -clamp(28px, 3.5vw, 44px);
margin-left: -min(10vw, 100px);
```

Trình duyệt bỏ qua chúng một cách âm thầm.

Thay vào đó hãy luôn viết:

```css
right: calc(-1 * clamp(28px, 3.5vw, 44px));
margin-left: calc(-1 * min(10vw, 100px));
```

## Kích thước xác thực

Test tối thiểu ở:
- Desktop: `1920x1080`, `1440x900`, `1280x720`
- Tablet: `1024x768`, `768x1024`
- Mobile: `375x667`, `414x896`
- Điện thoại ngang: `667x375`, `896x414`

## Anti-Pattern

Không dùng:
- template startup tím-trên-nền-trắng
- Inter / Roboto / Arial làm giọng điệu thị giác trừ khi người dùng muốn rõ ràng sự trung tính thực dụng
- tường bullet, chữ nhỏ xíu, hoặc khối code cần cuộn
- hình minh họa trang trí khi hình học trừu tượng làm tốt hơn
