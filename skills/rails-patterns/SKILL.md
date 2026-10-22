---
name: rails-patterns
description: Các pattern framework Ruby on Rails cho ứng dụng Rails 7.1+ và 8.x. Bao gồm quy ước thư mục (directory contract), skinny controller với service object, form object, query object, ActiveRecord idiomatic, background job, ViewComponent, Hotwire và Rails 8 Solid stack. Dùng khi xây dựng hoặc review ứng dụng Rails, controller, model, service, job hoặc view.
origin: community
---

# Rails Patterns

Các pattern framework cho ứng dụng Ruby on Rails hiện đại (Rails 7.1+ và 8.x). Rails vốn có chủ kiến (opinionated) trong thiết kế; đây là các pattern mà cộng đồng đã hội tụ cho những ứng dụng vẫn dễ bảo trì khi vượt mốc 50 model. Skill này nói về "cách làm" (how). Về "cái gì" và "khi nào" (quyết định nên chọn pattern nào), xem các rule về Ruby patterns — `rules/ruby/patterns.md` trong repo này, được cài thành `rules/ecc/ruby/patterns.md`.

## Khi nào kích hoạt

- Xây dựng ứng dụng Rails (full-stack, API-only hoặc hybrid)
- Review PR có đụng đến `app/` hoặc `config/`
- Sinh model, controller, service hoặc job
- Một controller action dài quá ~10 dòng
- Một file model dài quá ~200 dòng
- Các query ActiveRecord bắt đầu xuất hiện trong controller hoặc view

## Khái niệm cốt lõi

### Quy ước thư mục (directory contract)

Ứng dụng Rails theo một cấu trúc có thể dự đoán được. Hãy thêm thư mục một cách có chủ đích, không tùy tiện.

```
app/
  models/         ActiveRecord models. Persistence and domain logic close to the data.
  controllers/    HTTP request handling. Thin orchestration only.
  views/          ERB templates. No business logic.
  components/     ViewComponent classes. View logic that needs tests.
  services/       Service objects. Multi-step business operations.
  forms/          Form objects. Complex form handling across multiple models.
  queries/        Query objects. Reusable, composable ActiveRecord queries.
  jobs/           Background jobs. Async work via Solid Queue, Sidekiq, or GoodJob.
  mailers/        ActionMailer classes.
  helpers/        View helpers. Tiny presentational logic only.
  policies/       Authorization policies (if using Pundit). Optional.
  channels/       ActionCable channels for WebSocket work.
```

Tránh `app/lib/`, `app/utils/`, `app/managers/`. Nếu thứ gì đó không khớp với các thư mục ở trên, thường là thiết kế cần suy nghĩ lại chứ không phải cần thêm thư mục mới. Code thực sự generic thì đặt trong `lib/`.

### Skinny controller

Controller nhận request, ủy thác cho đúng object và render response. Business logic nằm ở nơi khác. (Theo các rule về Ruby patterns, hãy tách ra service object khi controller bắt đầu gánh nhiều trách nhiệm.)

### Service object

Là lựa chọn mặc định cho các thao tác nghiệp vụ động đến nhiều hơn một lần save model. Các quy ước giữ cho chúng nhất quán:

- Đặt namespace theo domain (`Invoices::Create`), không theo hậu tố (`InvoiceCreator`).
- Class method `.call` ủy thác cho instance `#call`.
- Trả về một Result object, không phải boolean hay record trần, để phía gọi có thể rẽ nhánh theo thành công, lỗi và record bị ảnh hưởng.
- Bọc các thao tác ghi nhiều record trong một transaction.
- Giữ mỗi service chỉ có một mục đích (`Invoices::Create`, `Invoices::MarkPaid`), KHÔNG BAO GIỜ dùng `Invoices::Manager`.

### Form object

Khi một form trải rộng nhiều model hoặc có các field không ánh xạ tới cột, hãy dùng form object thay vì nested attributes hay virtual attribute đặt sai model. Nó "quack" như một model đối với view (`form_with model: @form`) trong khi vẫn tổ hợp các record một cách gọn gàng.

### Query object

Với các query ActiveRecord được dùng lại giữa các controller hoặc service, hoặc quá phức tạp cho một scope, hãy tách ra một query object nhận scope làm đầu vào để có thể kết hợp (compose). Quy tắc kinh nghiệm: một scope dài quá ba điều kiện nối chuỗi hoặc bắt đầu nhận tham số thì nên trở thành query object.

### Background job

Đẩy mọi thứ chậm ra ngoài. (Theo các rule về Ruby patterns: dùng Solid Queue cho Rails 8 greenfield với throughput vừa phải; dùng Sidekiq khi cần observability trưởng thành, throughput cao hoặc đã có sẵn Redis.) Bất kể adapter nào: truyền ID thay vì record, làm cho `perform` idempotent, và đặt `retry_on`/`discard_on` một cách tường minh.

### Ưu tiên ViewComponent hơn partial

Với view logic có render theo điều kiện, nhiều hơn hai tham số, hoặc được dùng lại ở hơn ba nơi, hãy ưu tiên ViewComponent. Component có thể test độc lập và bộc lộ interface của chúng một cách tường minh; partial có logic điều kiện lồng sâu sẽ trở thành nợ kỹ thuật.

### Hotwire: Turbo và Stimulus

Frontend stack mặc định của Rails. (Theo các rule về Ruby patterns, ưu tiên Hotwire cho ứng dụng server-rendered; chỉ dùng React/Vue khi độ phức tạp của tương tác biện minh cho phần client.) Turbo Frames cho cập nhật một phần trang, Turbo Streams cho cập nhật do server điều khiển, Stimulus cho các hành vi nhỏ phía client đặt cạnh markup.

### Rails 8 Solid stack

Rails 8 đi kèm các mặc định dựa trên database mà trước đây cần Redis: Solid Queue (job), Solid Cache (cache), Solid Cable (ActionCable). Đổi lại là tải database nhiều hơn để bớt đi một thành phần hạ tầng; phù hợp với throughput vừa phải, còn Redis vẫn thắng ở quy mô lớn. Kamal là công cụ deploy mặc định dựa trên Docker.

## Ví dụ code

### Skinny controller với service object

```ruby
# Bad: business logic in the controller
class InvoicesController < ApplicationController
  def create
    @invoice = Invoice.new(invoice_params)
    @invoice.user = current_user
    @invoice.line_items.build(invoice_params[:line_items])
    @invoice.tax_total = TaxCalculator.new(@invoice).calculate
    @invoice.total = @invoice.line_items.sum(&:amount) + @invoice.tax_total

    if @invoice.save
      InvoiceMailer.created(@invoice).deliver_later
      AccountingExportJob.perform_later(@invoice.id)
      redirect_to @invoice, notice: "Invoice created"
    else
      render :new
    end
  end
end

# Good: controller orchestrates, service does the work
class InvoicesController < ApplicationController
  def create
    result = Invoices::Create.call(params: invoice_params, user: current_user)

    if result.success?
      redirect_to result.invoice, notice: "Invoice created"
    else
      @invoice = result.invoice
      render :new, status: :unprocessable_entity
    end
  end
end
```

### Service object

```ruby
# app/services/invoices/create.rb
module Invoices
  class Create
    # Struct keeps this runnable on every Ruby that Rails 7.1 supports.
    # On Ruby 3.2+, `Data.define(:success?, :invoice, :errors)` is a more
    # concise immutable alternative.
    Result = Struct.new(:success, :invoice, :errors, keyword_init: true) do
      def success?
        success
      end
    end

    def self.call(params:, user:)
      new(params: params, user: user).call
    end

    def initialize(params:, user:)
      @params = params
      @user = user
    end

    def call
      invoice = build_invoice
      ApplicationRecord.transaction do
        invoice.save!
      end
      begin
        send_notifications(invoice)
      rescue StandardError => e
        Rails.logger.error("Notification dispatch failed for invoice #{invoice.id}: #{e.message}")
      end
      Result.new(success: true, invoice: invoice, errors: nil)
    rescue ActiveRecord::RecordInvalid => e
      Result.new(success: false, invoice: e.record, errors: e.record.errors)
    end

    private

    attr_reader :params, :user

    def build_invoice
      invoice = user.invoices.new(params.except(:line_items))
      invoice.line_items.build(params[:line_items])
      invoice.tax_total = TaxCalculator.call(invoice)
      invoice.total = invoice.line_items.sum(&:amount) + invoice.tax_total
      invoice
    end

    def send_notifications(invoice)
      InvoiceMailer.created(invoice).deliver_later
      AccountingExportJob.perform_later(invoice.id)
    end
  end
end
```

### Form object

```ruby
# app/forms/signup_form.rb
class SignupForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :email, :string
  attribute :password, :string
  attribute :company_name, :string
  attribute :terms_accepted, :boolean

  validates :email, presence: true, format: URI::MailTo::EMAIL_REGEXP
  validates :password, presence: true, length: { minimum: 12 }
  validates :company_name, presence: true
  validates :terms_accepted, acceptance: true

  attr_reader :user, :company

  def save
    return false unless valid?

    ApplicationRecord.transaction do
      @company = Company.create!(name: company_name)
      @user = @company.users.create!(email: email, password: password, role: :owner)
    end
    true
  rescue ActiveRecord::RecordInvalid => e
    errors.merge!(e.record.errors)
    false
  end
end
```

### Query object

```ruby
# app/queries/invoices/overdue.rb
module Invoices
  class Overdue
    def self.call(scope: Invoice.all, as_of: Time.current)
      new(scope: scope, as_of: as_of).call
    end

    def initialize(scope:, as_of:)
      @scope = scope
      @as_of = as_of
    end

    def call
      scope
        .where(status: :sent)
        .where(due_date: ..as_of)
        .where.not(id: paid_invoice_ids)
        .includes(:customer, :line_items)
    end

    private

    attr_reader :scope, :as_of

    def paid_invoice_ids
      Payment.where(created_at: ..as_of).pluck(:invoice_id)
    end
  end
end
```

Query object nhận một scope nên có thể kết hợp: `Invoices::Overdue.call(scope: current_user.invoices)`.

### Phòng tránh N+1

```ruby
# Bad: N+1 in the view when it calls post.author.name
@posts = Post.published

# Good: eager load
@posts = Post.published.includes(:author)
```

`includes` để Rails tự chọn preload hay eager_load. Ép dùng `preload` cho các query riêng biệt, `eager_load` cho JOIN khi lọc theo association. Từ Rails 6.1, `strict_loading` sẽ báo lỗi khi vô tình lazy load.

### Counter cache

```ruby
class Comment < ApplicationRecord
  belongs_to :post, counter_cache: true
end
```

```ruby
add_column :posts, :comments_count, :integer, default: 0, null: false
```

`post.comments_count` trở thành thao tác đọc một cột thay vì `COUNT(*)`. Ví dụ này
giả định một bảng mới; thêm counter cache vào bảng đã có dữ liệu cần phải
backfill, việc này nằm ngoài phạm vi ở đây.

### Hình dạng của background job

Truyền ID của record, không truyền record. Retry khiến việc giao job là at-least-once, nên mọi job gọi
tới dịch vụ bên ngoài đều phải idempotent — nếu không, một lỗi tạm thời xảy ra sau khi lời gọi
remote đã thành công sẽ làm nhân đôi hiệu ứng ở lần thử kế tiếp.

```ruby
class AccountingExportJob < ApplicationJob
  queue_as :exports

  retry_on AccountingApi::TransientError, wait: :polynomially_longer, attempts: 5
  discard_on AccountingApi::PermanentError

  def perform(invoice_id)
    invoice = Invoice.find(invoice_id)
    export = AccountingExport.create_or_find_by!(
      invoice: invoice,
      idempotency_key: "invoice-export-#{invoice.id}-#{invoice.updated_at.to_i}"
    )
    return if export.completed_at?

    receipt = AccountingApi.export(invoice, idempotency_key: export.idempotency_key)
    export.update!(completed_at: Time.current, external_id: receipt.id)
  end
end
```

```ruby
add_index :accounting_exports, :idempotency_key, unique: true
```

Unique index chính là thứ làm cho việc này an toàn: khi hai lần thử chạy đua, database từ chối
lần insert thứ hai và Active Record xử lý xung đột ngay trong lời gọi, trả về
dòng đã tồn tại. Điều đó xảy ra mà không cần retry ở cấp job — `retry_on` ở trên chỉ bao phủ
`AccountingApi::TransientError`. Guard này
bao phủ khoảng thời gian trước lời gọi remote; việc truyền `idempotency_key` xuống API
bao phủ khoảng thời gian sau đó, nên một crash giữa lời gọi API và `update!` vẫn quy về
đúng một export duy nhất.

### ViewComponent

```ruby
# app/components/invoice_status_badge_component.rb
class InvoiceStatusBadgeComponent < ViewComponent::Base
  STATUS_CLASSES = {
    draft: "bg-gray-100 text-gray-800",
    sent: "bg-blue-100 text-blue-800",
    paid: "bg-green-100 text-green-800",
    overdue: "bg-red-100 text-red-800"
  }.freeze

  def initialize(invoice:)
    @invoice = invoice
  end

  def call
    tag.span(@invoice.status.humanize, class: "rounded-full px-2 py-1 text-sm #{status_class}")
  end

  private

  def status_class
    STATUS_CLASSES.fetch(@invoice.status.to_sym, "bg-gray-100")
  end
end
```

```erb
<%= render InvoiceStatusBadgeComponent.new(invoice: @invoice) %>
```

### Hotwire

```erb
<%# Turbo Frame: clicking Edit replaces only this frame %>
<%= turbo_frame_tag "invoice_#{@invoice.id}" do %>
  <div class="invoice">
    <%= link_to "Edit", edit_invoice_path(@invoice) %>
  </div>
<% end %>
```

```erb
<%# Turbo Stream: app/views/comments/create.turbo_stream.erb %>
<%= turbo_stream.append "comments", @comment %>
<%= turbo_stream.update "comment_form", partial: "form", locals: { comment: Comment.new } %>
```

```javascript
// app/javascript/controllers/copy_to_clipboard_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["source"]

  copy() {
    navigator.clipboard.writeText(this.sourceTarget.value)
  }
}
```

### Callback chấp nhận được và không chấp nhận được

```ruby
# Acceptable: pure data normalization
class User < ApplicationRecord
  before_validation :normalize_email

  private

  def normalize_email
    self.email = email.to_s.downcase.strip
  end
end

# Move to a service instead: side effects hidden in a callback
# class User < ApplicationRecord
#   after_create :send_welcome_email  # hard to opt out of, hard to test
# end
```

### Concern tốt và concern tệ

```ruby
# Good: genuinely cross-cutting, reusable across unrelated models
# app/models/concerns/soft_deletable.rb
module SoftDeletable
  extend ActiveSupport::Concern

  included do
    scope :active, -> { where(deleted_at: nil) }
    scope :deleted, -> { where.not(deleted_at: nil) }
  end

  def soft_delete! = update!(deleted_at: Time.current)
  def restore! = update!(deleted_at: nil)
end

# Bad: a "concern" used by exactly one model, holding logic that belongs on it
# app/models/concerns/invoice_calculations.rb
module InvoiceCalculations
  extend ActiveSupport::Concern

  def calculate_total
    line_items.sum(&:amount) + tax_total
  end
end
# Only Invoice includes this. It isn't cross-cutting; it's Invoice's own logic
# hidden in a module for the appearance of a "skinny" model. Put it back on Invoice.
```

Một concern chỉ được dùng bởi một class thì chỉ là dời code đi chỗ khác; nó thuộc về chính class đó. Một concern phải dùng lại được ở ít nhất hai model không liên quan.

## Anti-Patterns

### God controller

Bất kỳ controller nào dài quá ~80 dòng đều đang làm quá nhiều việc. Hãy chia các action ra nhiều controller hoặc tách sang service.

### Fat model với hơn 30 method

Model chỉ nên biết về dữ liệu của chính nó. Các method điều phối model khác, gửi thông báo hoặc phối hợp workflow thuộc về service.

### Chuỗi callback

`after_save :update_cache, :send_notifications, :enqueue_export` là khởi đầu của cơn ác mộng khi debug. Hãy chuyển chúng vào một service chạy chúng một cách tường minh.

### Nested attributes cho form phức tạp

`accepts_nested_attributes_for` ổn với các trường hợp đơn giản. Với validation có điều kiện hoặc logic xuyên model, hãy dùng form object.

### Default scope trên các model quan trọng

`default_scope { where(deleted: false) }` âm thầm loại bỏ record khỏi mọi query trong ứng dụng, kể cả những query bạn cần cho hỗ trợ và debug. Hãy ưu tiên named scope tường minh.

### Model đặt tên theo khái niệm database

`UserRole`, `OrderStatus`, `InvoiceState` thường là ứng viên cho enum, không phải model.

### Dùng JS framework trước khi cân nhắc Hotwire

Nếu trang được server-render và chỉ thỉnh thoảng có tương tác, Hotwire ship nhanh hơn. Hãy dành React/Vue cho các ứng dụng thực sự có dạng SPA.

## Best Practices

- Giữ controller mỏng; đẩy business logic vào service.
- Trả về Result object từ service để phía gọi rẽ nhánh theo kết quả, không theo exception.
- Bọc các thao tác ghi nhiều record trong transaction; để lỗi thông báo/side-effect chỉ ghi log mà không làm hỏng thao tác ghi chính.
- Truyền ID cho job, giữ `perform` idempotent, đặt retry/discard một cách tường minh.
- Mặc định dùng eager loading; coi N+1 vô tình là bug, không phải chuyện vặt.
- Chỉ dùng concern cho hành vi được chia sẻ giữa ít nhất hai model không liên quan.
- Ưu tiên Hotwire trước khi dùng client-side framework cho ứng dụng server-rendered.

## Skill liên quan

- `backend-patterns` — ranh giới service và các pattern adapter (được các rule về Ruby patterns tham chiếu)
- Các rule về Ruby patterns (`rules/ruby/patterns.md`, được cài thành `rules/ecc/ruby/patterns.md`) — các quyết định và hướng dẫn khi nào dùng mà skill này triển khai
