---
paths:
  - "**/*.vue"
---

# Kiểm thử Vue

> File này mở rộng [common/testing.md](../common/testing.md) với nội dung riêng cho Vue.

## Stack

- Vitest (runner gốc của Vite) cùng `@vue/test-utils`. `create-vue` scaffold sẵn `@vitejs/plugin-vue`.
- Môi trường DOM qua `happy-dom` hoặc `jsdom`, đặt trong `vite.config.ts` tại `test.environment`.

## Render và Async

- `mount` để render đầy đủ. `shallowMount` để stub mọi component con.
- `trigger` và `setValue` trả về promise, hãy `await` chúng.
- `flushPromises` xả các handler của promise đã resolve. `nextTick` làm DOM ổn định sau khi state thay đổi.

## Test gì

- Chỉ test giao diện công khai: props, event được emit, slot, output đã render.
- Không assert state private hay method nội bộ, và không chỉ dựa vào snapshot.

## Composable

- Composable chỉ dùng các API reactivity thì unit test trực tiếp: gọi hàm, assert trên các ref được trả về.
- Composable dùng lifecycle hook hoặc `inject` phải được test thông qua một host component.

## Pinia

- Trong component: `createTestingPinia()` từ `@pinia/testing`, truyền qua `global.plugins`. Action bị stub theo mặc định, đặt `stubActions: false` để chạy chúng. `createSpy: vi.fn` là bắt buộc dưới Vitest (không có global của Jest).
- Độc lập: `beforeEach(() => setActivePinia(createPinia()))` cho một store mới mỗi test và ngăn rò rỉ state.

## Cấu hình Mount

- `global.plugins`, `global.stubs` (mặc định stub `Transition` / `TransitionGroup`), `global.mocks` (ví dụ `$router`), `global.provide` (cho `inject`, hỗ trợ key Symbol).
- `RouterLinkStub` stub `router-link` mà không cần mount cả router.

```ts
const wrapper = mount(AuctionCard, {
  props: { id: 1 },
  global: { plugins: [createTestingPinia({ createSpy: vi.fn })] },
})
await wrapper.find('button').trigger('click')
expect(wrapper.emitted('bid')).toBeTruthy()
```

## Tham chiếu

- Skill ECC: `frontend-patterns`, `vite-patterns`.
- Tài liệu: <https://test-utils.vuejs.org/api/> · <https://pinia.vuejs.org/cookbook/testing.html> · <https://vitest.dev/>
