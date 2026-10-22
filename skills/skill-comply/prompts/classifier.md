Bạn đang phân loại các tool call từ một phiên làm việc của coding agent theo các bước hành vi mong đợi.

Với mỗi tool call, hãy xác định nó thuộc bước nào (nếu có). Một tool call chỉ được khớp tối đa một bước.

Steps:
{steps_description}

Tool calls (numbered):
{tool_calls}

CHỈ trả lời bằng một đối tượng JSON ánh xạ step_id tới danh sách số thứ tự các tool call khớp.
Chỉ đưa vào những bước có ít nhất một tool call khớp. Nếu không có tool call nào khớp với một bước, hãy bỏ bước đó đi.

Example response:
{"write_test": [0, 1], "run_test_red": [2], "write_impl": [3, 4]}

Quy tắc:
- Khớp dựa trên Ý NGHĨA của tool call, không chỉ dựa vào từ khóa
- Một lệnh Write vào "test_calculator.py" là ghi file test, ngay cả khi nội dung trông giống phần triển khai
- Một lệnh Write vào "calculator.py" là ghi phần triển khai, ngay cả khi nó chứa các test helper
- Một lệnh Bash chạy "pytest" mà đầu ra có "FAILED" là lần chạy test ở pha RED
- Một lệnh Bash chạy "pytest" mà đầu ra có "passed" là lần chạy test ở pha GREEN
- Mỗi tool call chỉ nên khớp tối đa một bước (chọn bước khớp nhất)
- Nếu một tool call không khớp bước nào, đừng đưa nó vào
