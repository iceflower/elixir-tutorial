# 06. Phoenix 배포 가이드

## 배포 옵션

| 옵션 | 장점 | 단점 |
|------|------|------|
| Fly.io | 쉬운 배포, 무료 티어 | 리전 제한 |
| Gigalixir | Elixir 특화 | 무료 티어 제한적 |
| Render | 간편한 설정 | 콜드 스타트 |
| Docker | 유연성 | 직접 관리 필요 |
| Mix Release | 네이티브 성능 | 환경 의존성 |

## 1. Fly.io 배포 (권장)

### 설치 및 설정

```bash
# Fly CLI 설치 (Windows)
powershell -Command "iwr https://fly.io/install.ps1 -useb | iex"

# 로그인
fly auth login

# 앱 초기화
fly launch

# 시크릿 설정
fly secrets set SECRET_KEY_BASE=$(mix phx.gen.secret)
fly secrets set DATABASE_URL=your_database_url

# 배포
fly deploy
```

### fly.toml 예시

```toml
app = "my-phoenix-app"
primary_region = "nrt"  # 도쿄

[build]
  [build.args]
    MIX_ENV = "prod"

[env]
  PHX_HOST = "my-phoenix-app.fly.dev"
  PORT = "8080"

[http_service]
  internal_port = 8080
  force_https = true

  [[http_service.checks]]
    interval = "10s"
    timeout = "2s"
    path = "/health"
```

## 2. Docker 배포

### Dockerfile

```dockerfile
# 빌드 스테이지
FROM elixir:1.15-alpine AS builder

RUN apk add --no-cache build-base git

WORKDIR /app

ENV MIX_ENV=prod

# 의존성 설치
COPY mix.exs mix.lock ./
RUN mix deps.get --only prod
RUN mix deps.compile

# 에셋 빌드
COPY assets assets
COPY priv priv
RUN mix assets.deploy

# 컴파일
COPY lib lib
RUN mix compile

# 릴리스 빌드
RUN mix release

# 런타임 스테이지
FROM alpine:3.18 AS runner

RUN apk add --no-cache libstdc++ openssl ncurses-libs

WORKDIR /app

COPY --from=builder /app/_build/prod/rel/my_app ./

ENV HOME=/app
ENV PORT=4000

EXPOSE 4000

CMD ["bin/my_app", "start"]
```

### docker-compose.yml

```yaml
version: '3.8'

services:
  app:
    build: .
    ports:
      - "4000:4000"
    environment:
      - DATABASE_URL=ecto://postgres:postgres@db/my_app_prod
      - SECRET_KEY_BASE=${SECRET_KEY_BASE}
      - PHX_HOST=localhost
    depends_on:
      - db

  db:
    image: postgres:15-alpine
    volumes:
      - postgres_data:/var/lib/postgresql/data
    environment:
      - POSTGRES_PASSWORD=postgres

volumes:
  postgres_data:
```

## 3. Mix Release (네이티브)

### config/runtime.exs

```elixir
import Config

if config_env() == :prod do
  database_url =
    System.get_env("DATABASE_URL") ||
      raise "DATABASE_URL not set"

  config :my_app, MyApp.Repo,
    url: database_url,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10")

  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise "SECRET_KEY_BASE not set"

  host = System.get_env("PHX_HOST") || "example.com"
  port = String.to_integer(System.get_env("PORT") || "4000")

  config :my_app, MyAppWeb.Endpoint,
    url: [host: host, port: 443, scheme: "https"],
    http: [ip: {0, 0, 0, 0}, port: port],
    secret_key_base: secret_key_base
end
```

### 릴리스 빌드

```bash
# 환경 변수 설정
export MIX_ENV=prod
export SECRET_KEY_BASE=$(mix phx.gen.secret)

# 의존성 및 컴파일
mix deps.get --only prod
mix compile

# 에셋 빌드
mix assets.deploy

# 릴리스 생성
mix release

# 실행
_build/prod/rel/my_app/bin/my_app start
```

## 4. 환경 설정

### 필수 환경 변수

```bash
# 보안 키 생성
mix phx.gen.secret

# 필수 변수
SECRET_KEY_BASE=생성된_키
DATABASE_URL=ecto://user:pass@host/database
PHX_HOST=your-domain.com
PORT=4000
POOL_SIZE=10
```

### config/prod.exs

```elixir
import Config

config :my_app, MyAppWeb.Endpoint,
  cache_static_manifest: "priv/static/cache_manifest.json",
  server: true

config :logger, level: :info
```

## 5. 데이터베이스 마이그레이션

```bash
# Fly.io
fly ssh console
/app/bin/my_app eval "MyApp.Release.migrate"

# Docker
docker exec -it container_name /app/bin/my_app eval "MyApp.Release.migrate"

# 직접
_build/prod/rel/my_app/bin/my_app eval "MyApp.Release.migrate"
```

### lib/my_app/release.ex

```elixir
defmodule MyApp.Release do
  @app :my_app

  def migrate do
    load_app()

    for repo <- repos() do
      {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :up, all: true))
    end
  end

  def rollback(repo, version) do
    load_app()
    {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :down, to: version))
  end

  defp repos do
    Application.fetch_env!(@app, :ecto_repos)
  end

  defp load_app do
    Application.load(@app)
  end
end
```

## 6. 모니터링

### 헬스 체크 엔드포인트

```elixir
# router.ex
get "/health", HealthController, :index

# health_controller.ex
defmodule MyAppWeb.HealthController do
  use MyAppWeb, :controller

  def index(conn, _params) do
    json(conn, %{status: "ok", time: DateTime.utc_now()})
  end
end
```

### 로깅

```elixir
# config/prod.exs
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]
```

## 7. 성능 최적화

### 권장 설정

```elixir
# endpoint.ex
plug Plug.Static,
  at: "/",
  from: :my_app,
  gzip: true,  # gzip 압축
  cache_control_for_etags: "public, max-age=31536000"

# config/prod.exs
config :my_app, MyApp.Repo,
  pool_size: 10,
  queue_target: 50,
  queue_interval: 1000
```

## 체크리스트

- [ ] `SECRET_KEY_BASE` 생성 및 설정
- [ ] `DATABASE_URL` 설정
- [ ] `PHX_HOST` 설정
- [ ] HTTPS 설정
- [ ] 에셋 컴파일 (`mix assets.deploy`)
- [ ] 마이그레이션 실행
- [ ] 헬스 체크 엔드포인트 추가
- [ ] 로깅 설정
- [ ] 에러 트래킹 (Sentry 등)
