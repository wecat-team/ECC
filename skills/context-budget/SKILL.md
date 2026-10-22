---
name: context-budget
description: Định tuyến các kiểm tra context trực tiếp tới bộ đo gốc của Codex hoặc Claude Code mà không quét file, và chỉ thực hiện audit tĩnh các component có giới hạn khi được yêu cầu rõ ràng. Dùng cho các yêu cầu context-budget về dung lượng còn lại hoặc chi phí context của các thành phần đã cài.
metadata:
  origin: ECC
---

# Context Budget

Dùng bộ đo gốc của nhà cung cấp để xem mức sử dụng session trực tiếp. Giữ
audit cài đặt ước tính riêng biệt, chỉ chạy khi người dùng chủ động chọn (opt-in) rõ ràng.

## Mặc định: Context trực tiếp

Coi một lần gọi không có yêu cầu audit là yêu cầu về context trực tiếp. Điều này
bao gồm các yêu cầu về cửa sổ hiện tại, dung lượng còn lại, headroom, mức sử dụng
token, hoặc bảng phân tích context.

Với đường mặc định này:

- KHÔNG gọi hoặc dùng tool.
- KHÔNG quét hoặc đọc file.
- KHÔNG chạy lệnh shell, CLI của nhà cung cấp, debug logging hoặc khám phá MCP.
- Chỉ trả lời bằng lệnh gốc và một lời giải thích ngắn.

Định tuyến theo harness đang hoạt động:

| Harness | Lệnh gốc | Hướng dẫn |
| --- | --- | --- |
| Codex CLI | `/status` | Hiển thị mức sử dụng token hiện tại và dung lượng context còn lại. Dùng `/statusline` và bật **Context stats** cùng **Token counters** để có bộ đo cố định ở footer. |
| Codex app | `/status` | Hiển thị mức sử dụng context của thread hiện tại và các giới hạn tốc độ (rate limit). |
| Claude Code | `/context` | Hiển thị bảng phân tích context trực tiếp. Dùng `/context all` để xem các mục mở rộng. |
| Khác hoặc không rõ | Chưa xác minh | Nêu rõ rằng ECC không thể đọc trạng thái trực tiếp của nhà cung cấp và hỏi harness nào đang hoạt động. |

Các lệnh này được ghi trong [tài liệu tham chiếu lệnh của Codex](https://developers.openai.com/codex/cli/slash-commands) và [tài liệu tham chiếu lệnh của Claude Code](https://code.claude.com/docs/en/commands).

Một skill không thể gọi slash command của TUI thay cho người dùng. KHÔNG BAO GIỜ thay thế
lệnh gốc bằng một lần quét ước tính và KHÔNG BAO GIỜ suy ra yêu cầu audit từ
các cụm như “context is heavy” hay “how much is left.”

## Audit tĩnh tường minh

Chỉ chạy audit cài đặt/cấu hình khi người dùng nói rõ ràng
`--audit`, “audit installed components,” hoặc cách diễn đạt tương đương không mơ hồ.
`--verbose` thay đổi mức chi tiết của báo cáo; bản thân nó không phải là opt-in audit.

Nếu phạm vi audit mơ hồ, hãy hỏi harness và thư mục gốc cài đặt
trước khi đọc bất cứ thứ gì. Giữ mọi audit có giới hạn và chỉ đọc (read-only):

1. Chỉ kiểm tra thư mục gốc plugin/cài đặt được nêu tên và các file
   cấu hình đã biết của harness được nêu tên.
2. KHÔNG BAO GIỜ liệt kê đệ quy thư mục gốc workspace, thư mục home, cache của nhà cung cấp,
   transcript, debug log hoặc các worktree không liên quan.
3. KHÔNG BAO GIỜ khởi chạy CLI của nhà cung cấp, MCP server hay phiên debug để đếm tool.
4. Giới hạn output kiểm kê ở 50 mục cho mỗi loại component. Tóm tắt phần còn lại.
5. KHÔNG ghi log tạm hay sao chép nội dung cấu hình vào báo cáo.

Chỉ audit metadata của component liên quan đến eager discovery:

- mô tả của agent và skill;
- mô tả của command khi harness khám phá chúng theo kiểu eager;
- các file chỉ dẫn luôn được nạp trong phạm vi được nêu tên rõ ràng;
- schema tool MCP đã cấu hình khi một manifest có giới hạn sẵn có phơi bày chúng.

Nội dung đầy đủ của skill, agent, command và rule nhìn chung là nội dung theo yêu cầu (on-demand).
Hãy báo cáo kích thước trên đĩa của chúng riêng, tách khỏi chi phí eager ước tính, thay vì
cộng mọi nội dung vào baseline của session.

## Output của Audit

Trả về một báo cáo gọn gồm:

- harness và đường dẫn chính xác đã kiểm tra;
- chi phí eager/discovery ước tính theo loại component;
- số lượng đã cài và các mục metadata nặng nhất;
- các giả định, phép đo không khả dụng, và tối đa ba đề xuất tối ưu hóa.

Mọi con số token được tính toán đều là ước tính chi phí cấu hình tĩnh,
không phải context session trực tiếp. KHÔNG tuyên bố rằng một ước tính do nhà cung cấp báo cáo,
hiện tại, chính xác, hay là bằng chứng của mức tiết kiệm thực tế. Hướng người dùng quay lại
lệnh context trực tiếp gốc để xem mức sử dụng hiện tại.

## Chẩn đoán Selected-Record tùy chọn

Chỉ kiểm tra một bản ghi được lưu bền khi người dùng chọn rõ ràng file đó cho chẩn đoán này. Việc này tách biệt với yêu cầu context trực tiếp mặc định và audit cài đặt.

Với chẩn đoán file cục bộ, hãy chọn rõ ràng một file JSONL thông thường, ổn định hoặc một snapshot mà bạn
định kiểm tra. Thay đường dẫn ví dụ bên dưới; việc này không tìm hay kết nối lại một session.
Đoạn mã chỉ in ra tổng số byte tổng hợp. Nó đọc từng dòng một, nên mức dùng bộ nhớ phụ thuộc
vào bản ghi lớn nhất; tránh các bản ghi rất lớn và các file đang tăng trưởng liên tục.

```sh
python3 - "/path/to/selected-session.jsonl" <<'EOF'
import json
import sys

total = attachment = other = unclassified = 0
try:
    with open(sys.argv[1], "rb") as source:
        for raw in source:
            size = len(raw)
            total += size
            try:
                record = json.loads(raw.decode("utf-8"))
            except (UnicodeDecodeError, json.JSONDecodeError):
                unclassified += size
                continue
            record_type = record.get("type") if isinstance(record, dict) else None
            if not isinstance(record_type, str):
                unclassified += size
            elif record_type == "attachment":
                attachment += size
            else:
                other += size
except OSError:
    print("Cannot read selected JSONL file.", file=sys.stderr)
    raise SystemExit(1)

pct = attachment * 100.0 / total if total else 0.0
print(f"persisted {total}B | attachment records {attachment}B ({pct:.1f}%) | "
      f"other records {other}B | unclassified {unclassified}B")
EOF
```

Ba nhóm cộng lại bằng đúng số byte của file gốc, bao gồm ký tự xuống dòng và dòng trống.
`attachment` là bộ lọc theo record-type chính xác, không phải đảm bảo về schema nội bộ hiện tại
của harness. Các bản ghi khác có `type` là chuỗi khác; JSON sai định dạng, UTF-8 không hợp lệ, giá trị
không phải object, type bị thiếu hoặc không phải chuỗi, và dòng trống đều thuộc nhóm unclassified. Không nhóm nào
có nghĩa là "cuộc hội thoại," và phần trăm chỉ là tỷ lệ trên số byte đã lưu bền.

Các số đếm này không xác lập context đang hoạt động, dung lượng còn lại, mức sử dụng token, thanh toán, hay những gì một lần
kết nối lại nạp vào. Để xem context và mức sử dụng do harness báo cáo hiện tại, hãy dùng
[các lệnh `/context` và `/usage` (`/cost` là alias)](https://code.claude.com/docs/en/commands) phù hợp với phiên bản.
