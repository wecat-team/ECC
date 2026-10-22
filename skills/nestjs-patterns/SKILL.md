---
name: nestjs-patterns
description: Các pattern kiến trúc NestJS cho module, controller, provider, validation DTO, guard, interceptor, config và backend TypeScript cấp production. Dùng khi xây dựng hoặc review một backend NestJS — module, provider, validation DTO, guard hoặc interceptor.
metadata:
  origin: ECC
---

# Pattern phát triển NestJS

Các pattern NestJS cấp production cho backend TypeScript dạng module.

## Khi nào kích hoạt

- Xây dựng API hoặc service NestJS
- Cấu trúc module, controller và provider
- Thêm validation DTO, guard, interceptor hoặc exception filter
- Cấu hình thiết lập theo môi trường và tích hợp database
- Test unit NestJS hoặc HTTP endpoint

## Cấu trúc dự án

```text
src/
├── app.module.ts
├── main.ts
├── common/
│   ├── filters/
│   ├── guards/
│   ├── interceptors/
│   └── pipes/
├── config/
│   ├── configuration.ts
│   └── validation.ts
├── modules/
│   ├── auth/
│   │   ├── auth.controller.ts
│   │   ├── auth.module.ts
│   │   ├── auth.service.ts
│   │   ├── dto/
│   │   ├── guards/
│   │   └── strategies/
│   └── users/
│       ├── dto/
│       ├── entities/
│       ├── users.controller.ts
│       ├── users.module.ts
│       └── users.service.ts
└── prisma/ or database/
```

- Giữ code domain bên trong các feature module.
- Đặt các filter, decorator, guard và interceptor cắt ngang (cross-cutting) trong `common/`.
- Giữ DTO gần module sở hữu chúng.

## Bootstrap và Global Validation

```ts
async function bootstrap() {
  const app = await NestFactory.create(AppModule, { bufferLogs: true });

  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
      transformOptions: { enableImplicitConversion: true },
    }),
  );

  app.useGlobalInterceptors(new ClassSerializerInterceptor(app.get(Reflector)));
  app.useGlobalFilters(new HttpExceptionFilter());

  await app.listen(process.env.PORT ?? 3000);
}
bootstrap();
```

- Luôn bật `whitelist` và `forbidNonWhitelisted` trên các API công khai.
- Ưu tiên một global validation pipe thay vì lặp lại cấu hình validation cho từng route.

## Module, Controller và Provider

```ts
@Module({
  controllers: [UsersController],
  providers: [UsersService],
  exports: [UsersService],
})
export class UsersModule {}

@Controller('users')
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  @Get(':id')
  getById(@Param('id', ParseUUIDPipe) id: string) {
    return this.usersService.getById(id);
  }

  @Post()
  create(@Body() dto: CreateUserDto) {
    return this.usersService.create(dto);
  }
}

@Injectable()
export class UsersService {
  constructor(private readonly usersRepo: UsersRepository) {}

  async create(dto: CreateUserDto) {
    return this.usersRepo.create(dto);
  }
}
```

- Controller nên giữ mỏng: parse input HTTP, gọi một provider, trả về response DTO.
- Đặt business logic trong injectable service, không đặt trong controller.
- Chỉ export những provider mà các module khác thực sự cần.

## DTO và Validation

```ts
export class CreateUserDto {
  @IsEmail()
  email!: string;

  @IsString()
  @Length(2, 80)
  name!: string;

  @IsOptional()
  @IsEnum(UserRole)
  role?: UserRole;
}
```

- Validate mọi request DTO bằng `class-validator`.
- Dùng response DTO hoặc serializer chuyên dụng thay vì trả về trực tiếp ORM entity.
- Tránh làm lộ các trường nội bộ như password hash, token hoặc cột audit.

## Auth, Guard và Request Context

```ts
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles('admin')
@Get('admin/report')
getAdminReport(@Req() req: AuthenticatedRequest) {
  return this.reportService.getForUser(req.user.id);
}
```

- Giữ auth strategy và guard ở phạm vi module trừ khi chúng thực sự được dùng chung.
- Mã hóa các quy tắc truy cập thô trong guard, rồi thực hiện phân quyền theo từng resource trong service.
- Ưu tiên kiểu request tường minh cho các đối tượng request đã xác thực.

## Exception Filter và hình dạng lỗi

```ts
@Catch()
export class HttpExceptionFilter implements ExceptionFilter {
  catch(exception: unknown, host: ArgumentsHost) {
    const response = host.switchToHttp().getResponse<Response>();
    const request = host.switchToHttp().getRequest<Request>();

    if (exception instanceof HttpException) {
      return response.status(exception.getStatus()).json({
        path: request.url,
        error: exception.getResponse(),
      });
    }

    return response.status(500).json({
      path: request.url,
      error: 'Internal server error',
    });
  }
}
```

- Giữ một error envelope nhất quán trên toàn API.
- Ném framework exception cho các lỗi client dự kiến; log và bọc các lỗi không mong đợi tại một nơi tập trung.

## Config và Environment Validation

```ts
ConfigModule.forRoot({
  isGlobal: true,
  load: [configuration],
  validate: validateEnv,
});
```

- Validate env lúc boot, không phải lazily ở request đầu tiên.
- Giữ việc truy cập config phía sau các helper có kiểu hoặc config service.
- Tách các mối quan tâm dev/staging/prod trong config factory thay vì rẽ nhánh khắp code tính năng.

## Persistence và Transaction

- Giữ code repository / ORM phía sau các provider nói ngôn ngữ domain.
- Với Prisma hoặc TypeORM, cô lập các workflow transaction trong service sở hữu unit of work.
- Không để controller điều phối trực tiếp các thao tác ghi nhiều bước.

## Testing

```ts
describe('UsersController', () => {
  let app: INestApplication;

  beforeAll(async () => {
    const moduleRef = await Test.createTestingModule({
      imports: [UsersModule],
    }).compile();

    app = moduleRef.createNestApplication();
    app.useGlobalPipes(new ValidationPipe({ whitelist: true, transform: true }));
    await app.init();
  });
});
```

- Unit test provider một cách cô lập với các dependency được mock.
- Thêm test ở mức request cho guard, validation pipe và exception filter.
- Dùng lại các global pipe/filter giống như trong production khi test.

## Mặc định cho Production

- Bật structured logging và request correlation id.
- Dừng khi env/config không hợp lệ thay vì boot một phần.
- Ưu tiên khởi tạo provider bất đồng bộ cho client DB/cache với health check tường minh.
- Giữ background job và event consumer trong module riêng, không đặt trong HTTP controller.
- Làm cho rate limiting, auth và audit logging tường minh đối với các endpoint công khai.
