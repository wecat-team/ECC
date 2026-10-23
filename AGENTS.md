# ECC — Hướng dẫn cho Agent

Đây là một **plugin AI coding sẵn sàng cho production**, cung cấp 71 agent chuyên biệt, 311 skill, 97 command và các workflow hook tự động cho phát triển phần mềm.
<!-- Dòng cho scripts/ci/catalog.js (giữ nguyên tiếng Anh): providing 71 specialized agents, 311 skills, 97 commands -->

**Phiên bản:** 2.2.3

## Nguyên tắc cốt lõi

1. **Agent-First** — Giao việc cho các agent chuyên biệt với các tác vụ theo lĩnh vực
2. **Test-Driven** — Viết test trước khi triển khai, yêu cầu coverage 80%+
3. **Security-First** — Không bao giờ thỏa hiệp về bảo mật; kiểm tra mọi đầu vào
4. **Immutability (bất biến)** — Luôn tạo object mới, không bao giờ mutate object hiện có
5. **Lập kế hoạch trước khi thực thi** — Lập kế hoạch cho tính năng phức tạp trước khi viết code

## Các Agent hiện có

| Agent | Mục đích | Khi nào dùng |
|-------|---------|-------------|
| planner | Lập kế hoạch triển khai | Tính năng phức tạp, refactor |
| architect | Thiết kế hệ thống và khả năng mở rộng | Các quyết định kiến trúc |
| tdd-guide | Phát triển hướng kiểm thử (TDD) | Tính năng mới, sửa lỗi |
| code-reviewer | Chất lượng code và khả năng bảo trì | Sau khi viết/sửa code |
| bengali-reviewer | Review văn bản tiếng Bengali | Unicode, chuẩn hóa (normalization), grapheme, tìm kiếm và tính đúng đắn về locale |
| security-reviewer | Phát hiện lỗ hổng | Trước khi commit, code nhạy cảm |
| spec-miner | Trích xuất spec từ brownfield | Đưa các dự án brownfield vào quy trình phát triển hướng spec |
| build-error-resolver | Sửa lỗi build/type | Khi build thất bại |
| e2e-runner | Kiểm thử end-to-end với Playwright | Các luồng người dùng quan trọng |
| refactor-cleaner | Dọn dẹp dead code | Bảo trì code |
| doc-updater | Tài liệu và codemap | Cập nhật tài liệu |
| cpp-reviewer | Review code C/C++ | Dự án C và C++ |
| cpp-build-resolver | Lỗi build C/C++ | Build C và C++ thất bại |
| fsharp-reviewer | Review code hàm F# | Dự án F# |
| docs-lookup | Tra cứu tài liệu qua Context7 | Câu hỏi về API/tài liệu |
| go-reviewer | Review code Go | Dự án Go |
| go-build-resolver | Lỗi build Go | Build Go thất bại |
| kotlin-reviewer | Review code Kotlin | Dự án Kotlin/Android/KMP |
| kotlin-build-resolver | Lỗi build Kotlin/Gradle | Build Kotlin thất bại |
| database-reviewer | Chuyên gia PostgreSQL/Supabase | Thiết kế schema, tối ưu truy vấn |
| python-reviewer | Review code Python | Dự án Python |
| django-reviewer | Review code Django | Ứng dụng Django, API DRF, ORM, migration |
| django-build-resolver | Lỗi build, migration và thiết lập Django | Django khởi động, dependency, migration, collectstatic thất bại |
| java-reviewer | Review code Java và Spring Boot | Dự án Java/Spring Boot |
| java-build-resolver | Lỗi build Java/Maven/Gradle | Build Java thất bại |
| loop-operator | Thực thi vòng lặp tự động | Chạy loop an toàn, theo dõi tình trạng đình trệ, can thiệp |
| harness-optimizer | Tinh chỉnh cấu hình harness | Độ tin cậy, chi phí, thông lượng |
| rust-reviewer | Review code Rust | Dự án Rust |
| rust-build-resolver | Lỗi build Rust | Build Rust thất bại |
| pytorch-build-resolver | Lỗi runtime/CUDA/training của PyTorch | Build/training PyTorch thất bại |
| mle-reviewer | Review pipeline ML production | Pipeline ML, eval, serving, giám sát, rollback |
| rag-pipeline-reviewer | Review pipeline RAG | Chất lượng retrieval, chunking, reranking, độ phủ đánh giá RAGAS |
| typescript-reviewer | Review code TypeScript/JavaScript | Dự án TypeScript/JavaScript |
| react-reviewer | Review code React/JSX | Thay đổi component và hook React |
| react-build-resolver | Lỗi build React/Vite/Next.js/webpack | Build React thất bại |
| vue-reviewer | Review Vue.js Composition API và reactivity | Thay đổi component Vue, Pinia và Nuxt |
| swift-reviewer | Review code Swift/iOS | Thay đổi code Swift |
| swift-build-resolver | Lỗi build Swift/Xcode/SPM | Build Swift thất bại |
| flutter-reviewer | Review widget và state Flutter/Dart | Thay đổi ứng dụng Flutter |
| dart-build-resolver | Lỗi build Dart/Flutter và dependency pub | Biên dịch Flutter thất bại |
| csharp-reviewer | Pattern async, nullability, bảo mật của C#/.NET | Mọi thay đổi code C# |
| fastapi-reviewer | Tính đúng đắn async, Pydantic, OpenAPI của FastAPI | Thay đổi endpoint và schema FastAPI |
| php-reviewer | PHP/PSR-12, Eloquent, review bảo mật | Thay đổi code PHP |
| harmonyos-app-resolver | Review code và API ArkTS/ArkUI của HarmonyOS | Thay đổi ứng dụng HarmonyOS/OpenHarmony |
| healthcare-reviewer | An toàn lâm sàng, tuân thủ PHI, độ chính xác CDSS | Code ứng dụng y tế, EMR/EHR |
| a11y-architect | Kiến trúc khả năng truy cập WCAG 2.2 | Thiết kế component UI, audit khả năng truy cập |
| code-architect | Bản thiết kế kiến trúc tính năng từ các pattern trong codebase | Tính năng mới cần thiết kế triển khai |
| network-architect | Kiến trúc mạng doanh nghiệp đa site | Các quyết định thiết kế mạng phức tạp |
| homelab-architect | Thiết kế mạng gia đình/lab nhỏ | Lập kế hoạch hạ tầng gia đình |
| network-config-reviewer | Bảo mật và tính đúng đắn của cấu hình router/switch | Thay đổi cấu hình mạng |
| network-troubleshooter | Chẩn đoán kết nối và định tuyến theo tầng OSI | Sự cố kết nối và định tuyến mạng |
| performance-optimizer | Phát hiện nút thắt cổ chai, kích thước bundle, memory leak | Code chậm hoặc dùng nhiều tài nguyên |
| silent-failure-hunter | Lỗi bị nuốt và thiếu lan truyền lỗi | Audit độ tin cậy của code |
| type-design-analyzer | Đóng gói type và thiết kế invariant | Review thiết kế type và invariant |
| pr-test-analyzer | Chất lượng và độ đầy đủ của test coverage trong PR | Trước khi merge pull request |
| code-explorer | Truy vết đường thực thi và lập bản đồ kiến trúc | Tìm hiểu các đường code lạ |
| code-simplifier | Tinh chỉnh code hướng đến sự rõ ràng mà không đổi hành vi | Dọn dẹp sau khi triển khai |
| comment-analyzer | Độ chính xác, độ mới và rủi ro lỗi thời của comment | Audit comment trong code |
| agent-evaluator | Chấm điểm chất lượng đầu ra của agent theo 5 trục | Đánh giá chất lượng hoàn thành tác vụ |
| chief-of-staff | Phân loại và soạn thảo giao tiếp đa kênh | Quản lý workflow giao tiếp email/Slack |
| conversation-analyzer | Trích xuất hành vi hook từ transcript phiên làm việc | Tạo hook từ các pattern quan sát được |
| marketing-agent | Lập kế hoạch chiến dịch, viết copy, lịch nội dung | Ra mắt sản phẩm, chiến dịch marketing |
| seo-specialist | Audit SEO kỹ thuật, structured data, Core Web Vitals | Audit site, vấn đề meta tag và schema |
| opensource-forker | Fork dự án và loại bỏ secret để mở mã nguồn | Bắt đầu một bản phát hành mã nguồn mở |
| opensource-sanitizer | Xác minh bản fork đã làm sạch sẵn sàng phát hành | Trước mọi bản phát hành công khai |
| opensource-packager | Tạo boilerplate đóng gói OSS (README, LICENSE, v.v.) | Hoàn tất một bản phát hành mã nguồn mở |
| gan-planner | Mở rộng một prompt thành đặc tả sản phẩm đầy đủ | Bắt đầu một phiên GAN harness |
| gan-generator | Triển khai tính năng theo spec, lặp lại theo phản hồi của evaluator | Giai đoạn triển khai của GAN harness |
| gan-evaluator | Kiểm thử ứng dụng đang chạy qua Playwright và chấm điểm | Giai đoạn đánh giá của GAN harness |

## Điều phối Agent

Dùng agent một cách chủ động mà không cần người dùng nhắc:
- Yêu cầu tính năng phức tạp → **ecc:planner**
- Code vừa được viết/sửa → **ecc:code-reviewer**
- Sửa lỗi hoặc tính năng mới → **ecc:tdd-guide**
- Quyết định kiến trúc → **ecc:architect**
- Code nhạy cảm về bảo mật → **ecc:security-reviewer**
- Đưa dự án brownfield vào quy trình → **ecc:spec-miner**
- Vòng lặp tự động / giám sát loop → **ecc:loop-operator**
- Độ tin cậy và chi phí của cấu hình harness → **ecc:harness-optimizer**
- Thay đổi pipeline RAG/retrieval → **ecc:rag-pipeline-reviewer**
- Nút thắt hiệu năng hoặc code chậm → **ecc:performance-optimizer**
- Thay đổi React/JSX → **ecc:react-reviewer**
- Thay đổi Vue → **ecc:vue-reviewer**
- Thay đổi Swift → **ecc:swift-reviewer**
- Thay đổi C# → **ecc:csharp-reviewer**
- Thay đổi PHP → **ecc:php-reviewer**
- Thay đổi Flutter/Dart → **ecc:flutter-reviewer**
- Code y tế/lâm sàng → **ecc:healthcare-reviewer**
- Thiết kế component UI → **ecc:a11y-architect**
- Chuẩn bị phát hành mã nguồn mở → **ecc:opensource-forker** → **ecc:opensource-sanitizer** → **ecc:opensource-packager**
- Kiểm tra chất lượng đầu ra của agent → **ecc:agent-evaluator**

Dùng thực thi song song cho các thao tác độc lập — khởi chạy nhiều agent cùng lúc.

## Hướng dẫn bảo mật

**Trước BẤT KỲ commit nào:**
- Không hardcode secret (API key, mật khẩu, token)
- Mọi đầu vào của người dùng đều được kiểm tra
- Ngăn chặn SQL injection (truy vấn tham số hóa)
- Ngăn chặn XSS (HTML đã được sanitize)
- Bật bảo vệ CSRF
- Đã xác minh authentication/authorization
- Rate limiting trên mọi endpoint
- Thông báo lỗi không làm lộ dữ liệu nhạy cảm

**Quản lý secret:** KHÔNG BAO GIỜ hardcode secret. Dùng biến môi trường hoặc secret manager. Kiểm tra các secret bắt buộc khi khởi động. Xoay vòng (rotate) ngay mọi secret bị lộ.

**Nếu phát hiện vấn đề bảo mật:** DỪNG → dùng agent security-reviewer → sửa các vấn đề CRITICAL → rotate các secret bị lộ → rà soát codebase để tìm các vấn đề tương tự.

## Phong cách code

**Immutability (QUAN TRỌNG):** Luôn tạo object mới, không mutate. Trả về bản sao mới với các thay đổi đã áp dụng.

**Tổ chức file:** Nhiều file nhỏ thay vì ít file lớn. Thường 200-400 dòng, tối đa 800. Tổ chức theo tính năng/domain, không theo loại. Cohesion cao, coupling thấp.

**Xử lý lỗi:** Xử lý lỗi ở mọi tầng. Cung cấp thông báo thân thiện với người dùng trong code UI. Ghi log chi tiết ngữ cảnh ở phía server. Không bao giờ nuốt lỗi một cách âm thầm.

**Kiểm tra đầu vào:** Kiểm tra mọi đầu vào của người dùng tại ranh giới hệ thống. Dùng validation dựa trên schema. Fail fast với thông báo rõ ràng. Không bao giờ tin dữ liệu bên ngoài.

**Checklist chất lượng code:**
- Hàm nhỏ (<50 dòng), file tập trung (<800 dòng)
- Không lồng sâu (>4 cấp)
- Xử lý lỗi đúng cách, không có giá trị hardcode
- Định danh dễ đọc, đặt tên tốt

## Yêu cầu về kiểm thử

**Coverage tối thiểu: 80%**

Các loại test (tất cả đều bắt buộc):
1. **Unit test** — Từng hàm, utility, component riêng lẻ
2. **Integration test** — Endpoint API, thao tác cơ sở dữ liệu
3. **E2E test** — Các luồng người dùng quan trọng

**Workflow TDD (bắt buộc):**
1. Viết test trước (RED) — test phải FAIL
2. Viết triển khai tối thiểu (GREEN) — test phải PASS
3. Refactor (IMPROVE) — xác minh coverage 80%+

Khắc phục lỗi: kiểm tra tính cô lập của test → xác minh mock → sửa phần triển khai (không sửa test, trừ khi test sai).

## Quy trình phát triển

1. **Lập kế hoạch** — Dùng agent ecc:planner, xác định dependency và rủi ro, chia thành các giai đoạn
2. **TDD** — Dùng agent ecc:tdd-guide, viết test trước, triển khai, refactor
3. **Review** — Dùng agent ecc:code-reviewer ngay lập tức, xử lý các vấn đề CRITICAL/HIGH
4. **Ghi lại kiến thức đúng nơi**
   - Ghi chú debug cá nhân, sở thích và ngữ cảnh tạm thời → auto memory
   - Kiến thức của team/dự án (quyết định kiến trúc, thay đổi API, runbook) → cấu trúc tài liệu hiện có của dự án
   - Nếu tác vụ hiện tại đã tạo ra tài liệu hoặc comment trong code liên quan, không nhân bản cùng thông tin ở nơi khác
   - Nếu không có vị trí tài liệu dự án rõ ràng, hãy hỏi trước khi tạo file cấp cao nhất mới
5. **Commit** — Định dạng conventional commits, tóm tắt PR đầy đủ

## Chính sách về bề mặt workflow

- `skills/` là bề mặt workflow chuẩn.
- Các đóng góp workflow mới nên đưa vào `skills/` trước.
- `commands/` là bề mặt tương thích slash-entry kiểu cũ và chỉ nên thêm hoặc cập nhật khi vẫn cần một shim phục vụ migration hoặc đồng bộ giữa các harness.

## Quy trình Git

**Định dạng commit:** `<type>: <description>` — Các type: feat, fix, refactor, docs, test, chore, perf, ci

**Quy trình PR:** Phân tích toàn bộ lịch sử commit → soạn tóm tắt đầy đủ → kèm test plan → push với flag `-u`.

## Các Pattern kiến trúc

**Định dạng response API:** Envelope nhất quán gồm chỉ báo thành công, payload dữ liệu, thông báo lỗi và metadata phân trang.

**Repository pattern:** Đóng gói truy cập dữ liệu sau một interface chuẩn (findAll, findById, create, update, delete). Business logic phụ thuộc vào interface trừu tượng, không phụ thuộc cơ chế lưu trữ.

**Skeleton project:** Tìm các template đã được kiểm chứng, đánh giá bằng các agent song song (bảo mật, khả năng mở rộng, mức độ phù hợp), clone bản phù hợp nhất, lặp lại trong cấu trúc đã được chứng minh.

## Hiệu năng

**Quản lý context:** Tránh 20% cuối của context window khi refactor lớn và làm tính năng nhiều file. Các tác vụ ít nhạy cảm hơn (sửa đơn lẻ, tài liệu, sửa lỗi đơn giản) chịu được mức sử dụng cao hơn.

**Khắc phục lỗi build:** Dùng agent build-error-resolver → phân tích lỗi → sửa từng bước → xác minh sau mỗi lần sửa.

## Cấu trúc dự án

```
agents/          — 71 specialized subagents
skills/          — 311 workflow skills and domain knowledge
commands/        — 97 slash commands
hooks/           — Trigger-based automations
rules/           — Always-follow guidelines (common + per-language)
scripts/         — Cross-platform Node.js utilities
mcp-configs/     — 14 MCP server configurations
tests/           — Test suite
```

`commands/` vẫn được giữ trong repo để đảm bảo tương thích, nhưng định hướng dài hạn là ưu tiên skills.

## Chỉ số thành công

- Mọi test đều pass với coverage 80%+
- Không có lỗ hổng bảo mật
- Code dễ đọc và dễ bảo trì
- Hiệu năng ở mức chấp nhận được
- Đáp ứng yêu cầu của người dùng
