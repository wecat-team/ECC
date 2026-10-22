---
name: agent-introspection-debugging
description: Quy trình tự debug có cấu trúc cho các lỗi của AI agent, gồm capture, chẩn đoán, khôi phục có kiểm soát và báo cáo introspection. Dùng khi một lần chạy agent thất bại và cần chẩn đoán có thể tái hiện thay vì chỉ retry.
metadata:
  origin: ECC
---

# Agent Introspection Debugging

Dùng skill này khi một lần chạy agent liên tục thất bại, tiêu tốn token mà không có tiến triển, lặp đi lặp lại cùng các tool, hoặc trôi khỏi nhiệm vụ dự định.

Đây là skill dạng quy trình (workflow), không phải một runtime ẩn. Nó dạy agent tự debug một cách có hệ thống trước khi chuyển lên con người.

## Khi nào kích hoạt

- Lỗi chạm giới hạn tool call / loop tối đa
- Retry lặp lại mà không có tiến triển
- Context phình to hoặc prompt drift bắt đầu làm giảm chất lượng output
- Trạng thái file-system hoặc môi trường không khớp giữa kỳ vọng và thực tế
- Lỗi tool có khả năng khôi phục được bằng chẩn đoán và một hành động khắc phục nhỏ hơn

## Ranh giới phạm vi

Kích hoạt skill này cho:
- capture trạng thái lỗi trước khi retry một cách mù quáng
- chẩn đoán các pattern lỗi đặc thù của agent thường gặp
- áp dụng các hành động khôi phục có kiểm soát
- tạo báo cáo debug có cấu trúc mà con người đọc được

Không dùng skill này làm nguồn chính cho:
- xác minh tính năng sau khi thay đổi code; hãy dùng `verification-loop`
- debug riêng cho framework khi đã có một skill ECC hẹp hơn
- những lời hứa về runtime mà harness hiện tại không thể tự động thực thi

## Vòng lặp bốn pha

### Pha 1: Failure Capture

Trước khi cố khôi phục, hãy ghi lại lỗi một cách chính xác.

Capture:
- loại lỗi, thông báo và stack trace khi có
- chuỗi tool call có ý nghĩa gần nhất
- agent đang cố làm gì
- áp lực context hiện tại: prompt lặp lại, log dán quá lớn, kế hoạch trùng lặp hoặc ghi chú tràn lan
- các giả định về môi trường hiện tại: cwd, branch, trạng thái service liên quan, các file kỳ vọng

Template capture tối thiểu:

```markdown
## Failure Capture
- Session / task:
- Goal in progress:
- Error:
- Last successful step:
- Last failed tool / command:
- Repeated pattern seen:
- Environment assumptions to verify:
```

### Pha 2: Chẩn đoán nguyên nhân gốc (Root-Cause Diagnosis)

Khớp lỗi với một pattern đã biết trước khi thay đổi bất cứ thứ gì.

| Pattern | Nguyên nhân có khả năng | Kiểm tra |
| --- | --- | --- |
| Maximum tool calls / repeated same command | loop hoặc đường quan sát không có lối thoát | kiểm tra N tool call gần nhất xem có lặp không |
| Context overflow / degraded reasoning | ghi chú không giới hạn, kế hoạch lặp, log quá lớn | kiểm tra context gần đây xem có trùng lặp và khối lượng ít tín hiệu không |
| `ECONNREFUSED` / timeout | service không khả dụng hoặc sai port | xác minh tình trạng service, URL và giả định về port |
| `429` / quota exhaustion | retry storm hoặc thiếu backoff | đếm các lời gọi lặp và kiểm tra khoảng cách giữa các lần retry |
| file missing after write / stale diff | race, sai cwd hoặc branch drift | kiểm tra lại đường dẫn, cwd, git status và sự tồn tại thực tế của file |
| tests still failing after “fix” | giả thuyết sai | cô lập đúng test đang fail và suy ra lại bug |

Câu hỏi chẩn đoán:
- đây là lỗi logic, lỗi state, lỗi môi trường hay lỗi policy?
- agent có làm mất mục tiêu thật và bắt đầu tối ưu sai subtask không?
- lỗi có tính xác định (deterministic) hay chỉ thoáng qua (transient)?
- hành động nhỏ nhất, có thể hoàn tác, giúp xác nhận chẩn đoán là gì?

### Pha 3: Khôi phục có kiểm soát (Contained Recovery)

Khôi phục bằng hành động nhỏ nhất làm thay đổi bề mặt chẩn đoán.

Các hành động khôi phục an toàn:
- dừng retry lặp lại và phát biểu lại giả thuyết
- cắt bớt context ít tín hiệu và chỉ giữ mục tiêu đang làm, blocker và bằng chứng
- kiểm tra lại trạng thái thực tế của filesystem / branch / process
- thu hẹp nhiệm vụ về một lệnh lỗi, một file hoặc một test
- chuyển từ suy luận mang tính suy đoán sang quan sát trực tiếp
- chuyển lên con người khi lỗi có rủi ro cao hoặc bị chặn bởi yếu tố bên ngoài

Không tuyên bố các hành động tự chữa lành không được hỗ trợ như “reset agent state” hay “update harness config” trừ khi bạn thực sự thực hiện chúng qua các tool thật trong môi trường hiện tại.

Checklist khôi phục có kiểm soát:

```markdown
## Recovery Action
- Diagnosis chosen:
- Smallest action taken:
- Why this is safe:
- What evidence would prove the fix worked:
```

### Pha 4: Introspection Report

Kết thúc bằng một báo cáo giúp người hoặc agent tiếp theo hiểu được quá trình khôi phục.

```markdown
## Agent Self-Debug Report
- Session / task:
- Failure:
- Root cause:
- Recovery action:
- Result: success | partial | blocked
- Token / time burn risk:
- Follow-up needed:
- Preventive change to encode later:
```

## Heuristic khôi phục

Ưu tiên các can thiệp theo thứ tự sau:

1. Phát biểu lại mục tiêu thật trong một câu.
2. Xác minh trạng thái thế giới thực thay vì tin vào trí nhớ.
3. Thu hẹp phạm vi lỗi.
4. Chạy một phép kiểm tra phân biệt.
5. Chỉ sau đó mới retry.

Pattern xấu:
- retry cùng một hành động ba lần chỉ với cách diễn đạt hơi khác

Pattern tốt:
- capture lỗi
- phân loại pattern
- chạy một phép kiểm tra trực tiếp
- chỉ đổi kế hoạch nếu phép kiểm tra ủng hộ

## Tích hợp với ECC

- Dùng `verification-loop` sau khi khôi phục nếu code đã bị thay đổi.
- Dùng `continuous-learning-v2` khi pattern lỗi đáng được biến thành instinct hoặc skill sau này.
- Dùng `council` khi vấn đề không phải lỗi kỹ thuật mà là sự mơ hồ trong quyết định.
- Dùng `workspace-surface-audit` nếu lỗi đến từ trạng thái cục bộ xung đột hoặc repo drift.

## Tiêu chuẩn đầu ra

Khi skill này đang hoạt động, không kết thúc chỉ bằng “I fixed it”.

Luôn cung cấp:
- pattern lỗi
- giả thuyết nguyên nhân gốc
- hành động khôi phục
- bằng chứng cho thấy tình huống đã tốt hơn hoặc vẫn đang bị chặn
