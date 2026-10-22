---
description: Phát triển tính năng có hướng dẫn, tập trung vào việc hiểu codebase và kiến trúc
---

Một workflow phát triển tính năng có cấu trúc, nhấn mạnh việc hiểu code hiện có trước khi viết code mới.

## Các giai đoạn

### 1. Khám phá (Discovery)

- đọc kỹ yêu cầu tính năng
- xác định yêu cầu, ràng buộc và tiêu chí chấp nhận (acceptance criteria)
- đặt câu hỏi làm rõ nếu yêu cầu còn mơ hồ

### 2. Khám phá codebase

- dùng `code-explorer` để phân tích phần code hiện có liên quan
- lần theo các đường thực thi và các tầng kiến trúc
- hiểu các điểm tích hợp và quy ước

### 3. Câu hỏi làm rõ

- trình bày các phát hiện từ bước khám phá
- đặt các câu hỏi có trọng tâm về thiết kế và edge case
- chờ người dùng phản hồi trước khi tiếp tục

### 4. Thiết kế kiến trúc

- dùng `code-architect` để thiết kế tính năng
- cung cấp bản thiết kế triển khai (implementation blueprint)
- chờ được duyệt trước khi triển khai

### 5. Triển khai

- triển khai tính năng theo thiết kế đã được duyệt
- ưu tiên TDD khi phù hợp
- giữ các commit nhỏ và tập trung

### 6. Review chất lượng

- dùng `code-reviewer` để review phần triển khai
- xử lý các vấn đề critical và important
- xác minh test coverage

### 7. Tóm tắt

- tóm tắt những gì đã xây dựng
- liệt kê các hạng mục tiếp theo hoặc hạn chế
- cung cấp hướng dẫn kiểm thử
