# 04. Plug 웹서버

> **2025년 12월 기준** - Plug 1.16, Bandit 1.5

## 목차

1. [Plug 소개](#plug-소개)
2. [Plug.Conn](#plugconn)
3. [함수 Plug vs 모듈 Plug](#함수-plug-vs-모듈-plug)
4. [Plug.Router](#plugrouter)
5. [미들웨어](#미들웨어)
6. [JSON API 만들기](#json-api-만들기)
7. [에러 처리](#에러-처리)
8. [Bandit vs Cowboy](#bandit-vs-cowboy)
9. [테스트](#테스트)

---

## Plug 소개

Plug는 Elixir의 **웹 요청/응답 추상화**입니다. Phoenix의 기반이 됩니다.

### Plug란?

```text
요청 → [Plug] → [Plug] → [Plug] → 응답
         ↓        ↓        ↓
       로깅     인증      처리
```

모든 Plug는 `%Plug.Conn{}` 구조체를 받아서 변환합니다.

### 프로젝트 설정

```elixir
# mix.exs
defp deps do
  [
    {:bandit, "~> 1.5"},     # Bandit HTTP 서버 (권장)
    # 또는 {:plug_cowboy, "~> 2.7"},  # Cowboy 사용 시
    {:jason, "~> 1.4"}       # JSON 라이브러리 (1.18에서 선택적)
  ]
end
```

> **Note**: Elixir 1.18부터 내장 JSON 모듈이 있어 Jason 없이도 기본적인 JSON 처리 가능

---

## Plug.Conn

`%Plug.Conn{}`은 요청과 응답 정보를 담은 구조체입니다.

### 주요 필드

```elixir
%Plug.Conn{
  # 요청 정보
  method: "GET",              # HTTP 메서드
  host: "localhost",          # 호스트
  port: 4000,                 # 포트
  path_info: ["api", "users"], # 경로 세그먼트
  request_path: "/api/users", # 전체 경로
  query_string: "page=1",     # 쿼리 스트링
  params: %{"page" => "1"},   # 파싱된 파라미터

  # 요청 헤더/바디
  req_headers: [...],
  body_params: %{},

  # 응답 정보
  status: nil,                # 응답 상태 코드
  resp_headers: [...],        # 응답 헤더
  resp_body: nil,             # 응답 바디

  # 상태
  state: :unset,              # :unset | :set | :sent
  halted: false,              # 파이프라인 중단 여부
  assigns: %{}                # 커스텀 데이터 저장
}
```

### 주요 함수

```elixir
import Plug.Conn

# 응답 전송
send_resp(conn, 200, "Hello")

# 응답 설정 (전송 전)
conn
|> put_resp_content_type("application/json")
|> put_resp_header("x-custom", "value")
|> send_resp(200, body)

# 커스텀 데이터 저장
conn = assign(conn, :user, current_user)
conn.assigns.user

# 여러 값 한번에 저장 (1.11+)
conn = merge_assigns(conn, user: user, role: :admin)

# 쿼리 파라미터 파싱
conn = fetch_query_params(conn)
conn.query_params["page"]

# 요청 헤더 조회
get_req_header(conn, "authorization")  # 리스트 반환
```

### 상태 변경 함수

```elixir
# 응답 상태 설정
put_status(conn, 201)
put_status(conn, :created)  # atom도 가능

# 응답 헤더
put_resp_header(conn, "x-request-id", request_id)
delete_resp_header(conn, "x-powered-by")

# 쿠키
put_resp_cookie(conn, "session", token, max_age: 86400)
fetch_cookies(conn)
conn.cookies["session"]
delete_resp_cookie(conn, "session")
```

---

## 함수 Plug vs 모듈 Plug

### 함수 Plug

```elixir
def hello(conn, _opts) do
  send_resp(conn, 200, "Hello, World!")
end

# 파이프라인에서 사용
plug :hello
```

### 모듈 Plug

더 복잡한 로직, 설정이 필요할 때:

```elixir
defmodule MyPlug do
  @behaviour Plug

  @impl true
  def init(opts) do
    # 컴파일 타임에 실행
    # 옵션 전처리
    Keyword.get(opts, :greeting, "Hello")
  end

  @impl true
  def call(conn, greeting) do
    # 런타임에 실행
    send_resp(conn, 200, greeting)
  end
end

# 사용
plug MyPlug, greeting: "안녕하세요"
```

---

## Plug.Router

라우팅을 위한 DSL:

```elixir
defmodule MyRouter do
  use Plug.Router

  plug :match
  plug :dispatch

  # GET /
  get "/" do
    send_resp(conn, 200, "Home")
  end

  # GET /hello/:name
  get "/hello/:name" do
    send_resp(conn, 200, "Hello, #{name}!")
  end

  # POST /users
  post "/users" do
    send_resp(conn, 201, "Created")
  end

  # PUT/PATCH
  put "/users/:id" do
    send_resp(conn, 200, "Updated #{id}")
  end

  patch "/users/:id" do
    send_resp(conn, 200, "Patched #{id}")
  end

  # DELETE
  delete "/users/:id" do
    send_resp(conn, 204, "")
  end

  # 모든 메서드
  match "/any" do
    send_resp(conn, 200, "Method: #{conn.method}")
  end

  # 404
  match _ do
    send_resp(conn, 404, "Not Found")
  end
end
```

### forward (하위 라우터)

```elixir
defmodule MainRouter do
  use Plug.Router

  plug :match
  plug :dispatch

  # /api/* 요청을 ApiRouter로 위임
  forward "/api", to: ApiRouter

  # /admin/* 요청
  forward "/admin", to: AdminRouter, init_opts: [role: :admin]

  get "/" do
    send_resp(conn, 200, "Main")
  end
end

defmodule ApiRouter do
  use Plug.Router

  plug :match
  plug :dispatch

  # /api/users (원래 경로에서 /api는 제거됨)
  get "/users" do
    send_resp(conn, 200, "Users")
  end
end
```

---

## 미들웨어

### Plug 파이프라인

```elixir
defmodule MyRouter do
  use Plug.Router

  # 순서대로 실행
  plug Plug.Logger
  plug Plug.RequestId
  plug :authenticate
  plug :match
  plug :dispatch

  defp authenticate(conn, _opts) do
    case get_req_header(conn, "authorization") do
      ["Bearer " <> token] ->
        case verify_token(token) do
          {:ok, user} -> assign(conn, :current_user, user)
          :error -> unauthorized(conn)
        end
      _ ->
        conn  # 인증 없이 진행
    end
  end

  defp unauthorized(conn) do
    conn
    |> send_resp(401, "Unauthorized")
    |> halt()  # 파이프라인 중단!
  end

  # ... 라우트
end
```

### halt()

`halt()`는 이후 Plug 실행을 중단합니다:

```elixir
def my_plug(conn, _opts) do
  if should_stop?(conn) do
    conn
    |> send_resp(403, "Forbidden")
    |> halt()  # 여기서 멈춤
  else
    conn  # 다음 Plug로 계속
  end
end
```

### 커스텀 미들웨어 예제

```elixir
defmodule RequestIdPlug do
  import Plug.Conn

  @behaviour Plug

  @impl true
  def init(opts), do: opts

  @impl true
  def call(conn, _opts) do
    request_id = generate_id()

    conn
    |> put_resp_header("x-request-id", request_id)
    |> assign(:request_id, request_id)
  end

  defp generate_id do
    :crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)
  end
end

# CORS 미들웨어
defmodule CORSPlug do
  import Plug.Conn

  @impl true
  def init(opts), do: opts

  @impl true
  def call(conn, _opts) do
    conn
    |> put_resp_header("access-control-allow-origin", "*")
    |> put_resp_header("access-control-allow-methods", "GET, POST, PUT, DELETE, OPTIONS")
    |> put_resp_header("access-control-allow-headers", "content-type, authorization")
    |> handle_preflight()
  end

  defp handle_preflight(%{method: "OPTIONS"} = conn) do
    conn |> send_resp(204, "") |> halt()
  end
  defp handle_preflight(conn), do: conn
end
```

---

## JSON API 만들기

### 설정

```elixir
defmodule ApiRouter do
  use Plug.Router

  plug Plug.Logger
  plug :match

  # JSON 파싱
  plug Plug.Parsers,
    parsers: [:json],
    pass: ["application/json"],
    json_decoder: Jason  # 또는 JSON (1.18 내장)

  plug :dispatch

  # GET /api/users
  get "/users" do
    users = [
      %{id: 1, name: "Kim"},
      %{id: 2, name: "Lee"}
    ]
    json(conn, 200, %{users: users})
  end

  # GET /api/users/:id
  get "/users/:id" do
    case Integer.parse(id) do
      {user_id, ""} ->
        user = %{id: user_id, name: "User #{user_id}"}
        json(conn, 200, %{user: user})
      _ ->
        json(conn, 400, %{error: "Invalid ID"})
    end
  end

  # POST /api/users
  post "/users" do
    %{"name" => name, "email" => email} = conn.body_params

    user = %{id: 3, name: name, email: email}
    json(conn, 201, %{user: user})
  end

  # 404
  match _ do
    json(conn, 404, %{error: "Not Found"})
  end

  # JSON 헬퍼
  defp json(conn, status, data) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(status, Jason.encode!(data))
  end
end
```

### 내장 JSON 사용 (Elixir 1.18+)

```elixir
defp json(conn, status, data) do
  conn
  |> put_resp_content_type("application/json")
  |> send_resp(status, JSON.encode!(data))
end
```

### RESTful 패턴

```elixir
# GET    /users      - index (목록)
# GET    /users/:id  - show (상세)
# POST   /users      - create (생성)
# PUT    /users/:id  - update (전체 수정)
# PATCH  /users/:id  - update (부분 수정)
# DELETE /users/:id  - delete (삭제)

defmodule UsersRouter do
  use Plug.Router
  import Plug.Conn

  plug :match
  plug Plug.Parsers, parsers: [:json], json_decoder: Jason
  plug :dispatch

  get "/" do
    users = list_users()
    json(conn, 200, %{data: users})
  end

  get "/:id" do
    case get_user(id) do
      nil -> json(conn, 404, %{error: "User not found"})
      user -> json(conn, 200, %{data: user})
    end
  end

  post "/" do
    case create_user(conn.body_params) do
      {:ok, user} -> json(conn, 201, %{data: user})
      {:error, errors} -> json(conn, 422, %{errors: errors})
    end
  end

  put "/:id" do
    case update_user(id, conn.body_params) do
      {:ok, user} -> json(conn, 200, %{data: user})
      {:error, :not_found} -> json(conn, 404, %{error: "User not found"})
      {:error, errors} -> json(conn, 422, %{errors: errors})
    end
  end

  delete "/:id" do
    case delete_user(id) do
      :ok -> send_resp(conn, 204, "")
      :error -> json(conn, 404, %{error: "User not found"})
    end
  end

  defp json(conn, status, data) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(status, Jason.encode!(data))
  end
end
```

---

## 에러 처리

### ErrorHandler

```elixir
defmodule MyRouter do
  use Plug.Router
  use Plug.ErrorHandler

  plug :match
  plug :dispatch

  # 의도적 에러
  get "/error" do
    raise "Something went wrong!"
  end

  # 에러 핸들러
  @impl Plug.ErrorHandler
  def handle_errors(conn, %{kind: kind, reason: reason, stack: stack}) do
    # 로깅
    require Logger
    Logger.error(Exception.format(kind, reason, stack))

    message = case reason do
      %{message: msg} -> msg
      _ -> "Internal Server Error"
    end

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(conn.status || 500, Jason.encode!(%{error: message}))
  end
end
```

### 커스텀 예외

```elixir
defmodule NotFoundError do
  defexception message: "Resource not found", plug_status: 404
end

defmodule UnauthorizedError do
  defexception message: "Unauthorized", plug_status: 401
end

defmodule ValidationError do
  defexception message: "Validation failed", plug_status: 422, errors: []
end

# 사용
get "/users/:id" do
  case find_user(id) do
    nil -> raise NotFoundError, message: "User #{id} not found"
    user -> json(conn, 200, user)
  end
end
```

---

## Bandit vs Cowboy

### Bandit (권장)

Elixir로 작성된 순수 HTTP 서버. Phoenix 1.8부터 기본값.

```elixir
# mix.exs
{:bandit, "~> 1.5"}

# Application
children = [
  {Bandit, plug: MyRouter, port: 4000}
]
```

장점:
- 순수 Elixir 구현
- HTTP/2 지원
- WebSocket 지원 (WebSock 라이브러리)
- 더 나은 성능 (많은 경우)
- 더 나은 에러 메시지

### Cowboy

Erlang HTTP 서버. 오랜 역사와 안정성.

```elixir
# mix.exs
{:plug_cowboy, "~> 2.7"}

# Application
children = [
  {Plug.Cowboy, scheme: :http, plug: MyRouter, options: [port: 4000]}
]
```

---

## 테스트

### Plug.Test 사용

```elixir
defmodule MyRouterTest do
  use ExUnit.Case, async: true
  use Plug.Test

  @opts MyRouter.init([])

  test "GET / returns 200" do
    conn = conn(:get, "/")
    conn = MyRouter.call(conn, @opts)

    assert conn.status == 200
    assert conn.resp_body == "Home"
  end

  test "GET /users returns JSON" do
    conn = conn(:get, "/users")
    conn = MyRouter.call(conn, @opts)

    assert conn.status == 200
    assert get_resp_header(conn, "content-type") == ["application/json; charset=utf-8"]

    body = Jason.decode!(conn.resp_body)
    assert is_list(body["users"])
  end

  test "POST /users creates user" do
    conn =
      conn(:post, "/users", Jason.encode!(%{name: "Test", email: "test@test.com"}))
      |> put_req_header("content-type", "application/json")

    conn = MyRouter.call(conn, @opts)

    assert conn.status == 201
    body = Jason.decode!(conn.resp_body)
    assert body["user"]["name"] == "Test"
  end

  test "GET /unknown returns 404" do
    conn = conn(:get, "/unknown")
    conn = MyRouter.call(conn, @opts)

    assert conn.status == 404
  end
end
```

### 헬퍼 함수

```elixir
defmodule ConnCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      use Plug.Test

      def json_conn(method, path, body \\ nil) do
        conn = conn(method, path, body && Jason.encode!(body))

        if body do
          put_req_header(conn, "content-type", "application/json")
        else
          conn
        end
      end

      def json_response(conn) do
        Jason.decode!(conn.resp_body)
      end
    end
  end
end
```

---

## 전체 예제

```elixir
# lib/my_app/application.ex
defmodule MyApp.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Bandit, plug: MyApp.Router, port: 4000}
    ]

    opts = [strategy: :one_for_one, name: MyApp.Supervisor]
    Supervisor.start_link(children, opts)
  end
end

# lib/my_app/router.ex
defmodule MyApp.Router do
  use Plug.Router
  use Plug.ErrorHandler

  plug Plug.Logger
  plug Plug.RequestId
  plug MyApp.CORSPlug
  plug :match
  plug Plug.Parsers, parsers: [:json], json_decoder: Jason
  plug :dispatch

  get "/" do
    send_resp(conn, 200, "Welcome to MyApp API!")
  end

  forward "/api/v1", to: MyApp.ApiRouter

  match _ do
    json(conn, 404, %{error: "Not Found"})
  end

  @impl Plug.ErrorHandler
  def handle_errors(conn, %{reason: reason}) do
    message = Map.get(reason, :message, "Internal Server Error")
    json(conn, conn.status || 500, %{error: message})
  end

  defp json(conn, status, data) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(status, Jason.encode!(data))
  end
end
```

실행:
```bash
mix deps.get
mix run --no-halt
# http://localhost:4000
```

---

## 다음 단계

[05. Phoenix Framework](../05_phoenix/README.md)에서 풀스택 웹 개발을 학습합니다.
