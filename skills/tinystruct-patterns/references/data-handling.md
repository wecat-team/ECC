# Xử lý dữ liệu (JSON) trong tinystruct

## Khi nào dùng

Ưu tiên `org.tinystruct.data.component.Builder` và `Builders` cho JSON nhẹ, không phụ thuộc thư viện ngoài. Dùng `Builder` cho JSON object (`{}`), `Builders` cho JSON array (`[]`). **LUÔN LUÔN dùng `Builders` thay vì `List<Builder>`** để tránh các vấn đề về type erasure của generic.

## Cách hoạt động

`Builder` cung cấp giao diện key-value để tạo và đọc JSON object. `Builders` cung cấp danh sách có chỉ mục cho JSON array. Cả hai tích hợp trực tiếp với việc xử lý kết quả của `AbstractApplication`.

### Vì sao dùng Builder/Builders?
- **Không có dependency ngoài** — gọn và nhanh
- **Tích hợp native** — hoạt động cùng cơ chế xử lý kết quả của framework
- **An toàn kiểu (type safety)** — `Builders` serialize đúng thành `[]`; `List<Builder>` có thể gây lỗi ép kiểu

## Ví dụ

### Serialize một object đơn
```java
import org.tinystruct.data.component.Builder;

Builder response = new Builder();
response.put("status", "success");
response.put("count", 42);
return response.toString(); // {"status":"success","count":42}
```

### Serialize một danh sách bằng Builders
```java
import org.tinystruct.data.component.Builder;
import org.tinystruct.data.component.Builders;

Builders dataList = new Builders();
for (MyModel item : myCollection) {
    Builder b = new Builder();
    b.put("id", item.getId());
    b.put("name", item.getName());
    dataList.add(b);
}
Builder response = new Builder();
response.put("data", dataList);
return response.toString(); // {"data":[{"id":1,"name":"X"}]}
```

### Parse một JSON object
```java
Builder parsed = new Builder();
parsed.parse(jsonString);
String status = parsed.get("status").toString();
```

### Parse một JSON array
```java
Builders parsedArray = new Builders();
parsedArray.parse(jsonArrayString);
for (int i = 0; i < parsedArray.size(); i++) {
    Builder item = parsedArray.get(i);
    System.out.println(item.get("name"));
}
```
