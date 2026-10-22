# Tiêu chí đánh giá — Hướng dẫn chấm điểm chi tiết

Tài liệu tham chiếu này cung cấp các mốc chấm điểm cụ thể cho từng trục. Dùng nó khi bạn không chắc một khoảng thiếu sót đáng 4 hay 3, hoặc 2 hay 1.

## Accuracy

| Điểm | Mốc | Ví dụ |
|---|---|---|
| 5 | Mọi sự kiện đều được xác minh với output của tool, tài liệu hoặc nguồn có thẩm quyền. Không có lỗi. | Cấu hình retry qua httpx transport — đã xác nhận trong tài liệu httpx. Mọi tên phương thức được xác minh bằng grep trên codebase. |
| 4 | Một điểm không chính xác nhỏ không ảnh hưởng đến tính đúng đắn. | Đúng thư viện, sai giá trị mặc định của một tham số (nói 0.5s, tài liệu ghi 1.0s). |
| 3 | Một lỗi sự kiện đáng kể, hoặc 3+ điểm không chính xác nhỏ. | Dùng `urllib3.Retry` trong codebase httpx. Chạy được trong trường hợp này nhưng sai thư viện. |
| 2 | Nhiều lỗi đáng kể. Output sẽ thất bại nếu làm theo. | Nói "thêm vào package.json" nhưng dự án dùng pyproject.toml. Hai khẳng định cấu hình khác cũng sai. |
| 1 | Sai về căn bản. Output tự mâu thuẫn hoặc mâu thuẫn với sự thật đã biết. | Code có lỗi cú pháp. API endpoint không tồn tại. Nêu chữ ký hàm mà grep bác bỏ. |

## Completeness

| Điểm | Mốc | Ví dụ |
|---|---|---|
| 5 | Mọi yêu cầu tường minh và ngầm định đều được bao phủ. Edge case được xử lý. Đường dẫn lỗi được giải quyết. | Người dùng nói "thêm retry cho tất cả HTTP request." Bao phủ GET, POST, PUT, DELETE. Xử lý timeout, 429, 5xx. |
| 4 | Mọi yêu cầu tường minh được bao phủ. Bỏ sót một yêu cầu ngầm định. | Bao phủ mọi phương thức HTTP. Quên xử lý connection timeout (không được nhắc tới nhưng được kỳ vọng). |
| 3 | Bỏ sót một yêu cầu tường minh, hoặc 2+ khoảng thiếu ngầm định. | Người dùng nói "thêm cả logging." Đã thêm logic retry nhưng không có logging. |
| 2 | Bỏ sót nhiều yêu cầu tường minh. Output là một giải pháp một phần. | Yêu cầu retry + circuit breaker. Chỉ triển khai retry. |
| 1 | Bỏ lỡ yêu cầu cốt lõi. Giao thứ gì đó gần với điều được yêu cầu. | Yêu cầu logic retry. Lại viết một endpoint health check. |

## Clarity

| Điểm | Mốc | Ví dụ |
|---|---|---|
| 5 | Cấu trúc hoàn hảo. Thuật ngữ được giải thích hoặc tránh dùng. Phân cấp thị giác giúp quét nhanh. Không mơ hồ. | README có các phần rõ ràng, code block và bản tóm tắt 10 giây ở đầu. |
| 4 | Nhìn chung rõ ràng. Một phần có thể được tổ chức tốt hơn hoặc một thuật ngữ chưa được định nghĩa. | Cấu trúc tốt nhưng dùng `exponential backoff` mà không giải thích — giả định người đọc đã biết. |
| 3 | Hiểu được sau khi đọc lại. Nhiều vấn đề về tổ chức hoặc thuật ngữ chưa định nghĩa. | Phần giải thích vòng vo trước khi vào điểm chính. Nhiều thuật ngữ được dùng trước khi được định nghĩa. |
| 2 | Gây khó hiểu ở một số chỗ. Người đọc sẽ phải hỏi thêm. | Code chạy được nhưng mô tả PR không giải thích vì sao cần retry hay nó sửa điều gì. |
| 1 | Không thể hiểu hoặc mâu thuẫn. Người đọc không thể xác định điều gì đã được làm hoặc vì sao. | Output là một khối chữ không có cấu trúc. Kết luận mâu thuẫn với các phát biểu trước đó. |

## Actionability

| Điểm | Mốc | Ví dụ |
|---|---|---|
| 5 | Chỉ cần một hành động. Có đường xác minh kèm theo. Không có bước ngầm định. | "Merge PR này. Test pass: `42 passed`. Deploy bằng `./deploy.sh`." |
| 4 | Chỉ cần một hành động nhưng đường xác minh chỉ được ngầm hiểu, không tường minh. | "Merge PR này." (Test có tồn tại nhưng không được trích dẫn. Người dùng phải tự kiểm tra.) |
| 3 | Cần nhiều hành động, hoặc một hành động với bước tiếp theo không rõ. | "Review và merge. Sau đó cập nhật config." (Config nào? Ở đâu? Không có link hay đường dẫn.) |
| 2 | Người dùng phải tự tìm cách dùng output. Thiếu chỉ dẫn quan trọng. | Đã viết code nhưng không có file test, không có hướng dẫn chạy, không tạo PR. Người dùng phải tự ráp mọi thứ. |
| 1 | Không thể hành động dựa trên output nếu không làm lại đáng kể hoặc làm rõ thêm. | "Đây là một ý tưởng thiết kế." (Không có code, không có file, không có PR. Người dùng phải bắt đầu từ đầu.) |

## Conciseness

| Điểm | Mốc | Ví dụ |
|---|---|---|
| 5 | Mỗi câu đều xứng đáng có mặt. Không dư thừa. Mật độ thông tin cao. | 30 dòng nói được điều mà 60 dòng sẽ nói. Không lặp ý. Không độn chữ. |
| 4 | Dư thừa nhẹ. Một đoạn có thể được cô đọng hơn. | Tốt nhìn chung nhưng lặp lại động cơ ở cả mô tả PR lẫn comment trong code. |
| 3 | Dư thừa đáng chú ý. 20%+ nội dung có thể bỏ đi mà không mất gì. | Giải thích cùng một khái niệm ba lần (trong tóm tắt, thân bài và kết luận). Ví dụ dài dòng. |
| 2 | Phình to đáng kể. 40%+ nội dung là độn chữ hoặc lặp lại. | 200 dòng cho tác vụ chỉ cần 60. Nhắc lại câu hỏi của người dùng. Có bối cảnh không liên quan. |
| 1 | Tỷ lệ nhiễu trên tín hiệu bị đảo ngược. Độn chữ nhiều hơn nội dung thực chất. | Câu trả lời 500 dòng cho câu hỏi 2 dòng. Phần lớn là boilerplate, lặp lại hoặc ngữ cảnh không liên quan. |

## Edge Case

### Khi người dùng đưa ra chỉ dẫn không rõ ràng

Nếu yêu cầu của người dùng mơ hồ, KHÔNG trừ điểm completeness vì không đọc được suy nghĩ. Thay vào đó, hãy ghi chú trong đánh giá: "Yêu cầu của người dùng mơ hồ về [phạm vi]. Tôi chọn cách diễn giải [cách diễn giải đã chọn]. Nếu họ muốn nói [cách diễn giải khác], điểm này sẽ giảm xuống [điểm]."

### Khi tác vụ vốn đã đơn giản

Một bản sửa lỗi 3 dòng hoàn toàn có thể đạt 5/5/5/5/5. Thang điểm co giãn theo độ phức tạp — một tác vụ đơn giản được làm hoàn hảo LÀ 5.0. Đừng bịa ra thiếu sót để biện minh cho điểm thấp hơn.

### Khi bạn tự bắt được lỗi của mình giữa chừng

Nếu bạn mắc lỗi, phát hiện và sửa trước khi giao — đó là 5 về Accuracy cho output cuối cùng. Việc đánh giá dựa trên những gì người dùng nhận được, không phải quy trình nội bộ của bạn. Hãy ghi nhận việc tự sửa như bằng chứng của sự kỹ lưỡng, không phải một điểm trừ.

### Khi output của tool mâu thuẫn với khẳng định của bạn

Nếu bạn khẳng định "tests pass" nhưng output terminal cho thấy một lỗi — Accuracy tự động ≤ 2. Output của tool là ground truth. Khẳng định không có xác minh là nguồn phổ biến nhất của điểm accuracy thấp.
