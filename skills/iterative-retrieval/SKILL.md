---
name: iterative-retrieval
description: "Pattern tinh chỉnh dần việc truy xuất context (context retrieval) để giải quyết vấn đề context của subagent. Dùng khi một subagent thiếu context cần thiết và việc truy xuất phải được tinh chỉnh qua nhiều lượt."
metadata:
  origin: ECC
---

# Pattern Iterative Retrieval

Giải quyết "vấn đề context" trong các workflow multi-agent, nơi các subagent không biết mình cần context gì cho đến khi bắt đầu làm việc.

## Khi nào kích hoạt

- Tạo các subagent cần context của codebase mà không thể dự đoán trước
- Xây dựng workflow multi-agent nơi context được tinh chỉnh dần
- Gặp lỗi "context quá lớn" hoặc "thiếu context" trong các task của agent
- Thiết kế pipeline truy xuất kiểu RAG để khám phá code
- Tối ưu việc sử dụng token trong điều phối agent

## Vấn đề

Các subagent được tạo ra với context hạn chế. Chúng không biết:
- File nào chứa code liên quan
- Codebase có những pattern nào
- Dự án dùng thuật ngữ gì

Các cách tiếp cận tiêu chuẩn đều thất bại:
- **Gửi tất cả**: Vượt quá giới hạn context
- **Không gửi gì**: Agent thiếu thông tin quan trọng
- **Đoán xem cần gì**: Thường sai

## Giải pháp: Iterative Retrieval

Một vòng lặp 4 giai đoạn tinh chỉnh context dần dần:

```
┌─────────────────────────────────────────────┐
│                                             │
│   ┌──────────┐      ┌──────────┐            │
│   │ DISPATCH │─────│ EVALUATE │            │
│   └──────────┘      └──────────┘            │
│        ▲                  │                 │
│        │                  ▼                 │
│   ┌──────────┐      ┌──────────┐            │
│   │   LOOP   │─────│  REFINE  │            │
│   └──────────┘      └──────────┘            │
│                                             │
│        Max 3 cycles, then proceed           │
└─────────────────────────────────────────────┘
```

### Giai đoạn 1: DISPATCH

Truy vấn rộng ban đầu để thu thập các file ứng viên:

```javascript
// Start with high-level intent
const initialQuery = {
  patterns: ['src/**/*.ts', 'lib/**/*.ts'],
  keywords: ['authentication', 'user', 'session'],
  excludes: ['*.test.ts', '*.spec.ts']
};

// Dispatch to retrieval agent
const candidates = await retrieveFiles(initialQuery);
```

### Giai đoạn 2: EVALUATE

Đánh giá mức độ liên quan của nội dung đã truy xuất:

```javascript
function evaluateRelevance(files, task) {
  return files.map(file => ({
    path: file.path,
    relevance: scoreRelevance(file.content, task),
    reason: explainRelevance(file.content, task),
    missingContext: identifyGaps(file.content, task)
  }));
}
```

Tiêu chí chấm điểm:
- **Cao (0.8-1.0)**: Triển khai trực tiếp chức năng mục tiêu
- **Trung bình (0.5-0.7)**: Chứa các pattern hoặc type liên quan
- **Thấp (0.2-0.4)**: Liên quan gián tiếp
- **Không (0-0.2)**: Không liên quan, loại trừ

### Giai đoạn 3: REFINE

Cập nhật tiêu chí tìm kiếm dựa trên kết quả đánh giá:

```javascript
function refineQuery(evaluation, previousQuery) {
  return {
    // Add new patterns discovered in high-relevance files
    patterns: [...previousQuery.patterns, ...extractPatterns(evaluation)],

    // Add terminology found in codebase
    keywords: [...previousQuery.keywords, ...extractKeywords(evaluation)],

    // Exclude confirmed irrelevant paths
    excludes: [...previousQuery.excludes, ...evaluation
      .filter(e => e.relevance < 0.2)
      .map(e => e.path)
    ],

    // Target specific gaps
    focusAreas: evaluation
      .flatMap(e => e.missingContext)
      .filter(unique)
  };
}
```

### Giai đoạn 4: LOOP

Lặp lại với tiêu chí đã tinh chỉnh (tối đa 3 chu kỳ):

```javascript
async function iterativeRetrieve(task, maxCycles = 3) {
  let query = createInitialQuery(task);
  let bestContext = [];

  for (let cycle = 0; cycle < maxCycles; cycle++) {
    const candidates = await retrieveFiles(query);
    const evaluation = evaluateRelevance(candidates, task);

    // Check if we have sufficient context
    const highRelevance = evaluation.filter(e => e.relevance >= 0.7);
    if (highRelevance.length >= 3 && !hasCriticalGaps(evaluation)) {
      return highRelevance;
    }

    // Refine and continue
    query = refineQuery(evaluation, query);
    bestContext = mergeContext(bestContext, highRelevance);
  }

  return bestContext;
}
```

## Ví dụ thực tế

### Ví dụ 1: Context cho việc sửa bug

```
Task: "Fix the authentication token expiry bug"

Cycle 1:
  DISPATCH: Search for "token", "auth", "expiry" in src/**
  EVALUATE: Found auth.ts (0.9), tokens.ts (0.8), user.ts (0.3)
  REFINE: Add "refresh", "jwt" keywords; exclude user.ts

Cycle 2:
  DISPATCH: Search refined terms
  EVALUATE: Found session-manager.ts (0.95), jwt-utils.ts (0.85)
  REFINE: Sufficient context (2 high-relevance files)

Result: auth.ts, tokens.ts, session-manager.ts, jwt-utils.ts
```

### Ví dụ 2: Triển khai tính năng

```
Task: "Add rate limiting to API endpoints"

Cycle 1:
  DISPATCH: Search "rate", "limit", "api" in routes/**
  EVALUATE: No matches - codebase uses "throttle" terminology
  REFINE: Add "throttle", "middleware" keywords

Cycle 2:
  DISPATCH: Search refined terms
  EVALUATE: Found throttle.ts (0.9), middleware/index.ts (0.7)
  REFINE: Need router patterns

Cycle 3:
  DISPATCH: Search "router", "express" patterns
  EVALUATE: Found router-setup.ts (0.8)
  REFINE: Sufficient context

Result: throttle.ts, middleware/index.ts, router-setup.ts
```

## Tích hợp với Agent

Dùng trong prompt của agent:

```markdown
When retrieving context for this task:
1. Start with broad keyword search
2. Evaluate each file's relevance (0-1 scale)
3. Identify what context is still missing
4. Refine search criteria and repeat (max 3 cycles)
5. Return files with relevance >= 0.7
```

## Best Practice

1. **Bắt đầu rộng, thu hẹp dần** - Đừng chỉ định quá cụ thể ở các truy vấn ban đầu
2. **Học thuật ngữ của codebase** - Chu kỳ đầu tiên thường tiết lộ các quy ước đặt tên
3. **Theo dõi những gì còn thiếu** - Việc xác định khoảng trống tường minh thúc đẩy quá trình tinh chỉnh
4. **Dừng ở mức "đủ tốt"** - 3 file có độ liên quan cao tốt hơn 10 file tầm thường
5. **Loại trừ một cách tự tin** - Các file có độ liên quan thấp sẽ không trở nên liên quan

## Liên quan

- [The Longform Guide](https://x.com/affaanmustafa/status/2014040193557471352) - Phần điều phối subagent
- skill `continuous-learning` - Dành cho các pattern cải thiện theo thời gian
- Các định nghĩa agent đi kèm ECC (đường dẫn cài thủ công: `agents/`)
