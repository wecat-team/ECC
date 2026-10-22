# Quy trình phát triển

> File này mở rộng [common/git-workflow.md](./git-workflow.md) với quy trình phát triển tính năng đầy đủ diễn ra trước các thao tác git.

Quy trình triển khai tính năng (Feature Implementation Workflow) mô tả pipeline phát triển: nghiên cứu, lập kế hoạch, TDD, code review, rồi commit lên git.

## Quy trình triển khai tính năng

0. **Nghiên cứu & Tái sử dụng** _(bắt buộc trước mọi triển khai mới)_
   - **Tìm code trên GitHub trước:** Chạy `gh search repos` và `gh search code` để tìm các triển khai, template và pattern sẵn có trước khi viết bất cứ thứ gì mới.
   - **Tài liệu thư viện thứ hai:** Dùng Context7 hoặc tài liệu chính thức của nhà cung cấp để xác nhận hành vi API, cách dùng package và các chi tiết theo phiên bản trước khi triển khai.
   - **Chỉ dùng Exa khi hai bước trên chưa đủ:** Dùng Exa để nghiên cứu web rộng hơn hoặc khám phá sau khi đã tìm trên GitHub và tra tài liệu chính thức.
   - **Kiểm tra package registry:** Tìm trên npm, PyPI, crates.io và các registry khác trước khi viết code utility. Ưu tiên thư viện đã được kiểm chứng thực tế thay vì giải pháp tự viết.
   - **Tìm các triển khai có thể điều chỉnh:** Tìm các dự án mã nguồn mở giải quyết 80%+ vấn đề và có thể fork, port hoặc bọc lại (wrap).
   - Ưu tiên áp dụng hoặc port một cách tiếp cận đã được kiểm chứng hơn là viết code hoàn toàn mới khi nó đáp ứng yêu cầu.

1. **Lập kế hoạch trước**
   - Dùng agent **planner** để tạo kế hoạch triển khai
   - Tạo tài liệu lập kế hoạch trước khi code: PRD, architecture, system_design, tech_doc, task_list
   - Xác định dependency và rủi ro
   - Chia nhỏ thành các giai đoạn

2. **Cách tiếp cận TDD**
   - Dùng agent **tdd-guide**
   - Viết test trước (RED)
   - Triển khai để test pass (GREEN)
   - Refactor (IMPROVE)
   - Xác minh coverage 80%+

3. **Code Review**
   - Dùng agent **code-reviewer** ngay sau khi viết code
   - Xử lý các vấn đề CRITICAL và HIGH
   - Sửa các vấn đề MEDIUM khi có thể

4. **Commit & Push**
   - Commit message chi tiết
   - Tuân theo định dạng conventional commits
   - Xem [git-workflow.md](./git-workflow.md) về định dạng commit message và quy trình PR

5. **Kiểm tra trước khi Review**
   - Xác minh mọi kiểm tra tự động (CI/CD) đều pass
   - Giải quyết mọi merge conflict
   - Đảm bảo branch đã cập nhật so với branch đích
   - Chỉ yêu cầu review sau khi các kiểm tra này pass
