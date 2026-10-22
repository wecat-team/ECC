---
name: click-path-audit
description: "Truy vết mọi button/touchpoint hướng người dùng qua toàn bộ chuỗi thay đổi state để tìm các bug mà từng hàm riêng lẻ chạy đúng nhưng lại triệt tiêu lẫn nhau, tạo ra state cuối sai, hoặc để UI ở trạng thái không nhất quán. Dùng khi: systematic debugging không tìm ra bug nhưng người dùng báo button hỏng, hoặc sau bất kỳ refactor lớn nào đụng tới shared state store."
metadata:
  origin: community
---

# /click-path-audit — Kiểm tra luồng hành vi (Behavioural Flow Audit)

Tìm các bug mà việc đọc code tĩnh bỏ sót: side effect do tương tác state, race condition giữa các lời gọi tuần tự, và các handler âm thầm hoàn tác lẫn nhau.

## Vấn đề skill này giải quyết

Debugging truyền thống kiểm tra:
- Hàm có tồn tại không? (thiếu wiring)
- Nó có crash không? (lỗi runtime)
- Nó có trả về đúng type không? (luồng dữ liệu)

Nhưng KHÔNG kiểm tra:
- **State UI cuối cùng có khớp với những gì label của button hứa hẹn không?**
- **Hàm B có âm thầm hoàn tác việc hàm A vừa làm không?**
- **Shared state (Zustand/Redux/context) có side effect triệt tiêu hành động dự định không?**

Ví dụ thực tế: Một button "New Email" gọi `setComposeMode(true)` rồi `selectThread(null)`. Cả hai đều chạy đúng khi đứng riêng. Nhưng `selectThread` có side effect đặt lại `composeMode: false`. Button không làm gì cả. 54 bug đã được tìm thấy bằng systematic debugging — bug này bị bỏ sót.

---

## Cách hoạt động

Với MỌI touchpoint tương tác trong khu vực mục tiêu:

```
1. IDENTIFY the handler (onClick, onSubmit, onChange, etc.)
2. TRACE every function call in the handler, IN ORDER
3. For EACH function call:
   a. What state does it READ?
   b. What state does it WRITE?
   c. Does it have SIDE EFFECTS on shared state?
   d. Does it reset/clear any state as a side effect?
4. CHECK: Does any later call UNDO a state change from an earlier call?
5. CHECK: Is the FINAL state what the user expects from the button label?
6. CHECK: Are there race conditions (async calls that resolve in wrong order)?
```

---

## Các bước thực hiện

### Bước 1: Lập bản đồ State Store

Trước khi audit bất kỳ touchpoint nào, hãy xây dựng bản đồ side effect của mọi action trong state store:

```
For each Zustand store / React context in scope:
  For each action/setter:
    - What fields does it set?
    - Does it RESET other fields as a side effect?
    - Document: actionName → {sets: [...], resets: [...]}
```

Đây là tài liệu tham chiếu then chốt. Bug "New Email" không thể thấy được nếu không biết rằng `selectThread` đặt lại `composeMode`.

**Định dạng output:**
```
STORE: emailStore
  setComposeMode(bool) → sets: {composeMode}
  selectThread(thread|null) → sets: {selectedThread, selectedThreadId, messages, drafts, selectedDraft, summary} RESETS: {composeMode: false, composeData: null, redraftOpen: false}
  setDraftGenerating(bool) → sets: {draftGenerating}
  ...

DANGEROUS RESETS (actions that clear state they don't own):
  selectThread → resets composeMode (owned by setComposeMode)
  reset → resets everything
```

### Bước 2: Audit từng touchpoint

Với mỗi button/toggle/form submit trong khu vực mục tiêu:

```
TOUCHPOINT: [Button label] in [Component:line]
  HANDLER: onClick → {
    call 1: functionA() → sets {X: true}
    call 2: functionB() → sets {Y: null} RESETS {X: false}  ← CONFLICT
  }
  EXPECTED: User sees [description of what button label promises]
  ACTUAL: X is false because functionB reset it
  VERDICT: BUG — [description]
```

**Kiểm tra từng bug pattern sau:**

#### Pattern 1: Sequential Undo (Hoàn tác tuần tự)
```
handler() {
  setState_A(true)     // sets X = true
  setState_B(null)     // side effect: resets X = false
}
// Result: X is false. First call was pointless.
```

#### Pattern 2: Async Race (Race condition bất đồng bộ)
```
handler() {
  fetchA().then(() => setState({ loading: false }))
  fetchB().then(() => setState({ loading: true }))
}
// Result: final loading state depends on which resolves first
```

#### Pattern 3: Stale Closure (Closure cũ)
```
const [count, setCount] = useState(0)
const handler = useCallback(() => {
  setCount(count + 1)  // captures stale count
  setCount(count + 1)  // same stale count — increments by 1, not 2
}, [count])
```

#### Pattern 4: Missing State Transition (Thiếu chuyển đổi state)
```
// Button says "Save" but handler only validates, never actually saves
// Button says "Delete" but handler sets a flag without calling the API
// Button says "Send" but the API endpoint is removed/broken
```

#### Pattern 5: Conditional Dead Path (Nhánh điều kiện chết)
```
handler() {
  if (someState) {        // someState is ALWAYS false at this point
    doTheActualThing()    // never reached
  }
}
```

#### Pattern 6: useEffect Interference (useEffect can thiệp)
```
// Button sets stateX = true
// A useEffect watches stateX and resets it to false
// User sees nothing happen
```

### Bước 3: Báo cáo

Với mỗi bug tìm thấy:

```
CLICK-PATH-NNN: [severity: CRITICAL/HIGH/MEDIUM/LOW]
  Touchpoint: [Button label] in [file:line]
  Pattern: [Sequential Undo / Async Race / Stale Closure / Missing Transition / Dead Path / useEffect Interference]
  Handler: [function name or inline]
  Trace:
    1. [call] → sets {field: value}
    2. [call] → RESETS {field: value}  ← CONFLICT
  Expected: [what user expects]
  Actual: [what actually happens]
  Fix: [specific fix]
```

---

## Kiểm soát phạm vi

Audit này tốn kém. Hãy giới hạn phạm vi cho phù hợp:

- **Audit toàn bộ ứng dụng:** Dùng khi chuẩn bị launch hoặc sau refactor lớn. Chạy các agent song song theo từng trang.
- **Audit một trang:** Dùng sau khi xây dựng trang mới hoặc sau khi người dùng báo một button hỏng.
- **Audit theo store:** Dùng sau khi sửa một Zustand store — audit tất cả consumer của các action đã thay đổi.

### Cách chia agent được khuyến nghị cho toàn bộ ứng dụng:

```
Agent 1: Map ALL state stores (Step 1) — this is shared context for all other agents
Agent 2: Dashboard (Tasks, Notes, Journal, Ideas)
Agent 3: Chat (DanteChatColumn, JustChatPage)
Agent 4: Emails (ThreadList, DraftArea, EmailsPage)
Agent 5: Projects (ProjectsPage, ProjectOverviewTab, NewProjectWizard)
Agent 6: CRM (all sub-tabs)
Agent 7: Profile, Settings, Vault, Notifications
Agent 8: Management Suite (all pages)
```

Agent 1 PHẢI hoàn thành trước. Output của nó là input cho tất cả các agent khác.

---

## Khi nào dùng

- Sau khi systematic debugging cho kết quả "không có bug" nhưng người dùng báo UI hỏng
- Sau khi sửa bất kỳ action nào của Zustand store (kiểm tra tất cả nơi gọi)
- Sau bất kỳ refactor nào đụng tới shared state
- Trước khi release, trên các luồng người dùng quan trọng
- Khi một button "không làm gì cả" — đây CHÍNH là công cụ cho trường hợp đó

## Khi nào KHÔNG dùng

- Với bug ở mức API (sai shape của response, thiếu endpoint) — dùng systematic-debugging
- Với vấn đề styling/layout — kiểm tra bằng mắt
- Với vấn đề hiệu năng — dùng công cụ profiling

---

## Tích hợp với các skill khác

- Chạy SAU `/superpowers:systematic-debugging` (skill tìm ra 54 loại bug còn lại)
- Chạy TRƯỚC `/superpowers:verification-before-completion` (skill xác minh các bản sửa hoạt động)
- Đưa kết quả vào `/superpowers:test-driven-development` — mỗi bug tìm được ở đây đều nên có một test

---

## Ví dụ: Bug đã truyền cảm hứng cho skill này

**Button "New Email" trong ThreadList.tsx:**
```
onClick={() => {
  useEmailStore.getState().setComposeMode(true)   // ✓ sets composeMode = true
  useEmailStore.getState().selectThread(null)      // ✗ RESETS composeMode = false
}}
```

Định nghĩa store:
```
selectThread: (thread) => set({
  selectedThread: thread,
  selectedThreadId: thread?.id ?? null,
  messages: [],
  drafts: [],
  selectedDraft: null,
  summary: null,
  composeMode: false,     // ← THIS silent reset killed the button
  composeData: null,
  redraftOpen: false,
})
```

**Systematic debugging bỏ sót nó** vì:
- Button có onClick handler (không phải code chết)
- Cả hai hàm đều tồn tại (không thiếu wiring)
- Không hàm nào crash (không có lỗi runtime)
- Kiểu dữ liệu đều đúng (không lệch type)

**Click-path audit bắt được nó** vì:
- Bước 1 lập bản đồ rằng `selectThread` đặt lại `composeMode`
- Bước 2 truy vết handler: lời gọi 1 đặt true, lời gọi 2 đặt lại false
- Kết luận: Sequential Undo — state cuối mâu thuẫn với ý định của button
