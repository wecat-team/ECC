---
name: laravel-patterns
description: "Các pattern kiến trúc Laravel, routing/controller, Eloquent ORM, service layer, queue, event, caching và API resource cho ứng dụng production. Dùng khi xây dựng hoặc review ứng dụng Laravel — controller, Eloquent, service layer, queue hoặc API resource."
metadata:
  origin: ECC
---

# Các pattern phát triển Laravel

Các pattern kiến trúc Laravel chuẩn production cho ứng dụng có khả năng mở rộng và dễ bảo trì.

## Khi nào dùng

- Xây dựng ứng dụng web hoặc API Laravel
- Cấu trúc controller, service và logic domain
- Làm việc với Eloquent model và quan hệ (relationship)
- Thiết kế API với resource và pagination
- Thêm queue, event, caching và background job

## Cách hoạt động

- Cấu trúc ứng dụng xoay quanh các ranh giới rõ ràng (controllers -> services/actions -> models).
- Dùng binding tường minh và scoped binding để routing dễ dự đoán; vẫn phải thực thi authorization để kiểm soát truy cập.
- Ưu tiên model có kiểu, cast và scope để logic domain nhất quán.
- Đưa công việc nặng về IO vào queue và cache các lần đọc tốn kém.
- Tập trung config trong `config/*` và giữ các môi trường tường minh.

## Ví dụ

### Cấu trúc dự án

Dùng bố cục Laravel quy ước với ranh giới các tầng rõ ràng (HTTP, services/actions, models).

### Bố cục khuyến nghị

```
app/
├── Actions/            # Single-purpose use cases
├── Console/
├── Events/
├── Exceptions/
├── Http/
│   ├── Controllers/
│   ├── Middleware/
│   ├── Requests/       # Form request validation
│   └── Resources/      # API resources
├── Jobs/
├── Models/
├── Policies/
├── Providers/
├── Services/           # Coordinating domain services
└── Support/
config/
database/
├── factories/
├── migrations/
└── seeders/
resources/
├── views/
└── lang/
routes/
├── api.php
├── web.php
└── console.php
```

### Controllers -> Services -> Actions

Giữ controller mỏng. Đặt phần điều phối vào service và logic đơn mục đích vào action.

```php
final class CreateOrderAction
{
    public function __construct(private OrderRepository $orders) {}

    public function handle(CreateOrderData $data): Order
    {
        return $this->orders->create($data);
    }
}

final class OrdersController extends Controller
{
    public function __construct(private CreateOrderAction $createOrder) {}

    public function store(StoreOrderRequest $request): JsonResponse
    {
        $order = $this->createOrder->handle($request->toDto());

        return response()->json([
            'success' => true,
            'data' => OrderResource::make($order),
            'error' => null,
            'meta' => null,
        ], 201);
    }
}
```

### Routing và Controller

Ưu tiên route-model binding và resource controller cho rõ ràng.

```php
use Illuminate\Support\Facades\Route;

Route::middleware('auth:sanctum')->group(function () {
    Route::apiResource('projects', ProjectController::class);
});
```

### Route Model Binding (Scoped)

Dùng scoped binding để ngăn truy cập chéo giữa các tenant (cross-tenant).

```php
Route::scopeBindings()->group(function () {
    Route::get('/accounts/{account}/projects/{project}', [ProjectController::class, 'show']);
});
```

### Route lồng nhau và tên Binding

- Giữ prefix và path nhất quán để tránh lồng đôi (ví dụ: `conversation` so với `conversations`).
- Dùng một tên tham số duy nhất khớp với model được bind (ví dụ: `{conversation}` cho `Conversation`).
- Ưu tiên scoped binding khi lồng route để thực thi quan hệ cha-con.

```php
use App\Http\Controllers\Api\ConversationController;
use App\Http\Controllers\Api\MessageController;
use Illuminate\Support\Facades\Route;

Route::middleware('auth:sanctum')->prefix('conversations')->group(function () {
    Route::post('/', [ConversationController::class, 'store'])->name('conversations.store');

    Route::scopeBindings()->group(function () {
        Route::get('/{conversation}', [ConversationController::class, 'show'])
            ->name('conversations.show');

        Route::post('/{conversation}/messages', [MessageController::class, 'store'])
            ->name('conversation-messages.store');

        Route::get('/{conversation}/messages/{message}', [MessageController::class, 'show'])
            ->name('conversation-messages.show');
    });
});
```

Nếu muốn một tham số resolve sang một class model khác, hãy định nghĩa binding tường minh. Với logic binding tùy chỉnh, dùng `Route::bind()` hoặc triển khai `resolveRouteBinding()` trên model.

```php
use App\Models\AiConversation;
use Illuminate\Support\Facades\Route;

Route::model('conversation', AiConversation::class);
```

### Binding của Service Container

Bind interface với phần triển khai trong service provider để wiring dependency rõ ràng.

```php
use App\Repositories\EloquentOrderRepository;
use App\Repositories\OrderRepository;
use Illuminate\Support\ServiceProvider;

final class AppServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        $this->app->bind(OrderRepository::class, EloquentOrderRepository::class);
    }
}
```

### Các pattern Eloquent Model

### Cấu hình Model

```php
final class Project extends Model
{
    use HasFactory;

    protected $fillable = ['name', 'owner_id', 'status'];

    protected $casts = [
        'status' => ProjectStatus::class,
        'archived_at' => 'datetime',
    ];

    public function owner(): BelongsTo
    {
        return $this->belongsTo(User::class, 'owner_id');
    }

    public function scopeActive(Builder $query): Builder
    {
        return $query->whereNull('archived_at');
    }
}
```

### Custom Cast và Value Object

Dùng enum hoặc value object để định kiểu chặt chẽ.

```php
use Illuminate\Database\Eloquent\Casts\Attribute;

protected $casts = [
    'status' => ProjectStatus::class,
];
```

```php
protected function budgetCents(): Attribute
{
    return Attribute::make(
        get: fn (int $value) => Money::fromCents($value),
        set: fn (Money $money) => $money->toCents(),
    );
}
```

### Eager Loading để tránh N+1

```php
$orders = Order::query()
    ->with(['customer', 'items.product'])
    ->latest()
    ->paginate(25);
```

### Query Object cho các bộ lọc phức tạp

```php
final class ProjectQuery
{
    public function __construct(private Builder $query) {}

    public function ownedBy(int $userId): self
    {
        $query = clone $this->query;

        return new self($query->where('owner_id', $userId));
    }

    public function active(): self
    {
        $query = clone $this->query;

        return new self($query->whereNull('archived_at'));
    }

    public function builder(): Builder
    {
        return $this->query;
    }
}
```

### Global Scope và Soft Delete

Dùng global scope cho lọc mặc định và `SoftDeletes` cho các bản ghi có thể khôi phục.
Dùng global scope hoặc named scope cho cùng một bộ lọc, không dùng cả hai, trừ khi bạn chủ ý muốn hành vi nhiều lớp.

```php
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Database\Eloquent\Builder;

final class Project extends Model
{
    use SoftDeletes;

    protected static function booted(): void
    {
        static::addGlobalScope('active', function (Builder $builder): void {
            $builder->whereNull('archived_at');
        });
    }
}
```

### Query Scope cho bộ lọc tái sử dụng

```php
use Illuminate\Database\Eloquent\Builder;

final class Project extends Model
{
    public function scopeOwnedBy(Builder $query, int $userId): Builder
    {
        return $query->where('owner_id', $userId);
    }
}

// In service, repository etc.
$projects = Project::ownedBy($user->id)->get();
```

### Transaction cho cập nhật nhiều bước

```php
use Illuminate\Support\Facades\DB;

DB::transaction(function (): void {
    $order->update(['status' => 'paid']);
    $order->items()->update(['paid_at' => now()]);
});
```

### Migration

### Quy ước đặt tên

- Tên file dùng timestamp: `YYYY_MM_DD_HHMMSS_create_users_table.php`
- Migration dùng anonymous class (không đặt tên class); tên file thể hiện mục đích
- Tên bảng mặc định là `snake_case` và ở dạng số nhiều

### Ví dụ Migration

```php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('orders', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('customer_id')->constrained()->cascadeOnDelete();
            $table->string('status', 32)->index();
            $table->unsignedInteger('total_cents');
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('orders');
    }
};
```

### Form Request và Validation

Giữ validation trong form request và chuyển đầu vào thành DTO.

```php
use App\Models\Order;

final class StoreOrderRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()?->can('create', Order::class) ?? false;
    }

    public function rules(): array
    {
        return [
            'customer_id' => ['required', 'integer', 'exists:customers,id'],
            'items' => ['required', 'array', 'min:1'],
            'items.*.sku' => ['required', 'string'],
            'items.*.quantity' => ['required', 'integer', 'min:1'],
        ];
    }

    public function toDto(): CreateOrderData
    {
        return new CreateOrderData(
            customerId: (int) $this->validated('customer_id'),
            items: $this->validated('items'),
        );
    }
}
```

### API Resource

Giữ API response nhất quán bằng resource và pagination.

```php
$projects = Project::query()->active()->paginate(25);

return response()->json([
    'success' => true,
    'data' => ProjectResource::collection($projects->items()),
    'error' => null,
    'meta' => [
        'page' => $projects->currentPage(),
        'per_page' => $projects->perPage(),
        'total' => $projects->total(),
    ],
]);
```

### Event, Job và Queue

- Phát domain event cho các side effect (email, analytics)
- Dùng queued job cho công việc chậm (báo cáo, export, webhook)
- Ưu tiên handler idempotent có retry và backoff

### Caching

- Cache các endpoint đọc nhiều và các query tốn kém
- Vô hiệu hóa cache theo model event (created/updated/deleted)
- Dùng tag khi cache dữ liệu liên quan để dễ vô hiệu hóa

### Cấu hình và môi trường

- Giữ secret trong `.env` và config trong `config/*.php`
- Dùng override config theo từng môi trường và `config:cache` trong production
