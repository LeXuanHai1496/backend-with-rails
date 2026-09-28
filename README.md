# Backend-With-Rails

Dự án học Ruby on Rails, chạy trên Docker. Đây là backend API/app được khởi tạo với Rails 8, dùng PostgreSQL làm database chính
## Cấu trúc thư mục (chuẩn Rails)

```
.
├── app/                        # Toàn bộ code nghiệp vụ của ứng dụng
│   ├── assets/                 # Ảnh, stylesheet (biên dịch qua Propshaft)
│   │   ├── images/
│   │   └── stylesheets/
│   ├── controllers/            # Xử lý request, gọi model, trả response/view
│   │   ├── concerns/           # Module dùng chung giữa nhiều controller
│   │   └── application_controller.rb
│   ├── helpers/                # Helper method dùng trong view
│   ├── javascript/             # Entry point JS (Stimulus controllers, importmap)
│   │   └── controllers/
│   ├── jobs/                   # Background job (Solid Queue / Active Job)
│   ├── mailers/                # Gửi email
│   ├── models/                 # ActiveRecord model, business logic, validation
│   │   ├── concerns/            # Module dùng chung giữa nhiều model
│   │   ├── application_record.rb
│   │   ├── user.rb
│   │   └── session.rb
│   └── views/                  # Template render HTML (ERB)
│       ├── layouts/
│       └── pwa/
│
├── bin/                        # Script thực thi: rails, rake, dev, setup, docker-entrypoint...
│
├── config/                     # Toàn bộ cấu hình ứng dụng
│   ├── environments/           # Cấu hình riêng cho development/test/production
│   ├── initializers/           # Code chạy khi boot app (CSP, filter params, inflections...)
│   ├── locales/                # File i18n (en.yml...)
│   ├── application.rb          # Cấu hình chung của app (namespace, autoload, timezone...)
│   ├── boot.rb                 # Load bundler + bootsnap trước khi app khởi động
│   ├── credentials.yml.enc      # Secrets đã mã hoá (giải mã bằng config/master.key)
│   ├── database.yml            # Cấu hình kết nối database theo từng environment
│   ├── deploy.yml               # Cấu hình deploy bằng Kamal
│   ├── environment.rb           # Load Rails environment
│   ├── puma.rb                  # Cấu hình Puma web server
│   ├── routes.rb                # Định nghĩa route (URL -> controller#action)
│   └── storage.yml              # Cấu hình Active Storage (local/cloud)
│
├── db/                         # Liên quan đến database
│   ├── migrate/                 # Các file migration (versioned schema changes)
│   ├── schema.rb                 # Schema hiện tại của database chính (tự sinh, không sửa tay)
│   ├── cable_schema.rb           # Schema riêng cho Action Cable (Solid Cable)
│   ├── cache_schema.rb           # Schema riêng cho cache (Solid Cache)
│   ├── queue_schema.rb           # Schema riêng cho job queue (Solid Queue)
│   └── seeds.rb                  # Data mẫu để seed database (rails db:seed)
│
├── lib/
│   └── tasks/                   # Custom Rake task (*.rake)
│
├── log/                        # File log runtime (development.log, production.log...)
│
├── public/                     # File tĩnh phục vụ trực tiếp, không qua Rails router
│   └── *.html                   # Trang lỗi mặc định (404, 422, 500...)
│
├── script/                     # Script one-off, không phải một phần app chính
│
├── storage/                    # File Active Storage lưu local (SQLite cho solid_* ở dev)
│
├── test/                       # Test suite (Minitest mặc định của Rails)
│   ├── controllers/
│   ├── fixtures/                # Dữ liệu mẫu cho test
│   ├── helpers/
│   ├── integration/
│   ├── mailers/
│   ├── models/
│   ├── system/                  # Test end-to-end qua trình duyệt (Capybara)
│   └── test_helper.rb
│
├── tmp/                        # File tạm, cache, pid... (không commit)
├── vendor/                     # Thư viện bên thứ ba không quản lý qua gem
│
├── .github/workflows/          # CI pipeline (GitHub Actions)
├── .kamal/                     # Hook triển khai Kamal (pre/post deploy...)
├── Dockerfile                  # Build image production
├── .dockerignore
├── Gemfile / Gemfile.lock      # Khai báo & khoá version các gem
├── Rakefile                     # Entry point cho Rake task
├── config.ru                    # Entry point cho Rack server
└── .rubocop.yml                 # Cấu hình lint style
```

### Quy ước đặt code (MVC)

- **Model** (`app/models`): chứa logic nghiệp vụ, validation, association, scope. Không viết logic HTTP ở đây.
- **Controller** (`app/controllers`): chỉ điều phối — nhận request, gọi model/service, trả response. Giữ mỏng (skinny controller).
- **View** (`app/views`): chỉ hiển thị dữ liệu, tránh viết logic nghiệp vụ trong template.
- **Job** (`app/jobs`): công việc chạy nền (gửi mail, xử lý nặng...) qua Solid Queue.
- **Concern** (`app/models/concerns`, `app/controllers/concerns`): tách logic dùng chung giữa nhiều model/controller.

## Kim chỉ nam khi code lớn dần

Nguyên tắc chung: **bắt đầu đơn giản (chỉ model + controller thuần Rails), chỉ thêm layer mới khi thực sự cần** — đừng tạo sẵn `app/services/` rỗng cho một action chỉ có 1 dòng code.

Các thư mục dưới đây **không có sẵn khi `rails new`**, đó là convention phổ biến của cộng đồng Rails — tự tạo khi cần, không tạo trước.

### `app/services/` — Service Object
Dùng khi 1 hành động nghiệp vụ đụng tới **nhiều model** hoặc **nhiều bước** (vd: tạo đơn hàng + trừ kho + gửi mail).

```ruby
# app/services/orders/create_service.rb
module Orders
  class CreateService
    def initialize(user:, params:)
      @user, @params = user, params
    end

    def call
      order = @user.orders.create!(@params)
      InventoryService.new(order).reserve!
      OrderMailer.confirmation(order).deliver_later
      order
    end
  end
end
```
Quy ước: 1 class = 1 hành động, luôn có method `call`.

### `app/forms/` — Form Object
Dùng khi input không map trực tiếp 1 model (vd: form gộp `User` + `Profile`, hoặc validate dữ liệu không lưu DB).

```ruby
# app/forms/registration_form.rb
class RegistrationForm
  include ActiveModel::Model

  attr_accessor :email, :password, :company_name
  validates :email, :password, :company_name, presence: true

  def save
    return false unless valid?
    ActiveRecord::Base.transaction do
      user = User.create!(email: email, password: password)
      Company.create!(name: company_name, owner: user)
    end
  end
end
```

### `app/queries/` — Query Object
Dùng khi 1 query ActiveRecord dài, nhiều điều kiện `where`/`join`, tái sử dụng ở nhiều nơi.

```ruby
# app/queries/active_users_query.rb
class ActiveUsersQuery
  def self.call(scope = User.all)
    scope.where(status: :active).where.not(confirmed_at: nil)
  end
end
```

### `app/policies/` — Authorization
Dùng khi cần phân quyền (ai được làm gì). Có thể tự viết tay hoặc dùng gem `pundit`.

```ruby
# app/policies/order_policy.rb
class OrderPolicy
  def initialize(user, order)
    @user, @order = user, order
  end

  def update?
    @user.admin? || @order.user_id == @user.id
  end
end
```

### `app/serializers/` và `app/decorators/`
- `app/serializers/`: format JSON trả về khi làm API (có thể dùng `jbuilder` đã có sẵn trong Gemfile).
- `app/decorators/` (hoặc `presenters/`): logic hiển thị (format tiền tệ, ngày tháng...) không nhét vào model/view.

### Quy tắc đặt tên
- Namespace theo domain: `Orders::CreateService`, `Orders::CancelService` → đặt tại `app/services/orders/`.
- Mỗi file 1 class, tên file `snake_case` khớp tên class.
- Test mirror cấu trúc `app/`: `app/services/orders/create_service.rb` → `test/services/orders/create_service_test.rb`.
- Ruby không có `interface` như Java/C# — cần hợp đồng chung giữa nhiều class thì dùng **module (mixin)** hoặc duck typing (cùng tên method `call`), không cố mô phỏng interface.

### Checklist trước khi thêm 1 class mới
1. Logic đụng tới >1 model hoặc gọi service ngoài? → `app/services/`
2. Input validate nhưng không map 1-1 với model? → `app/forms/`
3. Query tái sử dụng ≥2 nơi? → `app/queries/`
4. Có logic phân quyền phức tạp? → `app/policies/`
5. Không rơi vào case nào ở trên → giữ trong model/controller, đừng over-engineer.

## Cài đặt & chạy dự án

### Yêu cầu

- Docker & Docker Compose (khuyến nghị)
- Hoặc: Ruby 3.2.0, PostgreSQL, Bundler (nếu chạy local không dùng Docker)

### Chạy bằng Docker

```bash
docker build -t ror_using_docker .
docker run --rm -it -p 3000:3000 ror_using_docker
```

### Chạy local (không Docker)

```bash
bundle install
bin/rails db:prepare      # tạo database + chạy migration
bin/dev                   # hoặc bin/rails server
```

Ứng dụng chạy tại `http://localhost:3000`.

### Database

```bash
bin/rails db:create       # tạo database
bin/rails db:migrate      # chạy migration
bin/rails db:seed         # seed dữ liệu mẫu
```

### Test

```bash
bin/rails test            # unit/integration test
bin/rails test:system     # system test (Capybara)
```

### Lint & security scan

```bash
bin/rubocop
bin/brakeman
```

## Deploy

Dự án dùng [Kamal](https://kamal-deploy.org) để deploy dưới dạng Docker container, cấu hình tại `config/deploy.yml` và các hook trong `.kamal/hooks/`.

```bash
bin/kamal deploy
```
