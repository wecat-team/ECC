# Yêu cầu kiểm thử

## Test Coverage tối thiểu: 80%

Các loại test (TẤT CẢ đều bắt buộc):
1. **Unit Test** - Từng hàm, utility, component riêng lẻ
2. **Integration Test** - API endpoint, thao tác database
3. **E2E Test** - Các luồng người dùng quan trọng (framework chọn theo ngôn ngữ)

## Phát triển hướng kiểm thử (TDD)

Quy trình BẮT BUỘC:
1. Viết test trước (RED)
2. Chạy test - nó PHẢI FAIL
3. Viết triển khai tối thiểu (GREEN)
4. Chạy test - nó PHẢI PASS
5. Refactor (IMPROVE)
6. Xác minh coverage (80%+)

## Xử lý sự cố khi test thất bại

1. Dùng agent **tdd-guide**
2. Kiểm tra tính cô lập của test
3. Xác minh mock đúng
4. Sửa phần triển khai, không sửa test (trừ khi test sai)

## Hỗ trợ từ Agent

- **tdd-guide** - Dùng CHỦ ĐỘNG cho tính năng mới, ép buộc viết test trước

## Cấu trúc Test (AAA Pattern)

Ưu tiên cấu trúc Arrange-Act-Assert cho test:

```typescript
test('calculates similarity correctly', () => {
  // Arrange
  const vector1 = [1, 0, 0]
  const vector2 = [0, 1, 0]

  // Act
  const similarity = calculateCosineSimilarity(vector1, vector2)

  // Assert
  expect(similarity).toBe(0)
})
```

### Đặt tên Test

Dùng tên mô tả giải thích hành vi đang được kiểm thử:

```typescript
test('returns empty array when no markets match query', () => {})
test('throws error when API key is missing', () => {})
test('falls back to substring search when Redis is unavailable', () => {})
```
