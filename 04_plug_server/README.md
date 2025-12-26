# 04. Plug 웹서버

## 목차

1. [Plug 소개](#plug-소개)
2. [Plug.Conn](#plugconn)
3. [함수 Plug vs 모듈 Plug](#함수-plug-vs-모듈-plug)
4. [Plug.Router](#plugrouter)
5. [미들웨어](#미들웨어)
6. [JSON API 만들기](#json-api-만들기)
7. [에러 처리](#에러-처리)

---

## Plug 소개

Plug는 Elixir의 **웹 요청/응답 추상화**입니다. Phoenix의 기반이 됩니다.

### Plug란?

```
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
    {:plug_cowboy, "~> 2.6"},
    {:jason, "~> 1.4"}
  ]
end
```

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

# 쿼리 파라미터 파싱
conn = fetch_query_params(conn)
conn.query_params["page"]

# 요청 헤더 조회
get_req_header(conn, "authorization")
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

  def init(opts) do
    # 컴파일 타임에 실행
    # 옵션 전처리
    Keyword.get(opts, :greeting, "Hello")
  end

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

  get "/" do
    send_resp(conn, 200, "Main")
  end
end

defmodule ApiRouter do
  use Plug.Router

  plug :match
  plug :dispatch

  # /api/users
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

  def init(opts), do: opts

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
    json_decoder: Jason

  plug :dispatch

  # GET /api/users
  get "/users" do
    users = [
      %{id: 1, name: "Kim"},
      %{id: 2, name: "Lee"}
    ]
    json(conn, 200, %{users: users})
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

### RESTful 패턴

```elixir
# GET    /users      - index (목록)
# GET    /users/:id  - show (상세)
# POST   /users      - create (생성)
# PUT    /users/:id  - update (수정)
# DELETE /users/:id  - delete (삭제)

get "/users" do
  # 목록 조회
end

get "/users/:id" do
  # 상세 조회
end

post "/users" do
  # 생성
end

put "/users/:id" do
  # 수정
end

delete "/users/:id" do
  # 삭제
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
  def handle_errors(conn, %{kind: _kind, reason: reason, stack: _stack}) do
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

# 사용
get "/users/:id" do
  case find_user(id) do
    nil -> raise NotFoundError
    user -> json(conn, 200, user)
  end
end
```

---

## 전체 예제

```elixir
# lib/my_app/application.ex
defmodule MyApp.Application do
  use Application

  def start(_type, _args) do
    children = [
      {Plug.Cowboy, scheme: :http, plug: MyApp.Router, options: [port: 4000]}
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end

# lib/my_app/router.ex
defmodule MyApp.Router do
  use Plug.Router
  use Plug.ErrorHandler

  plug Plug.Logger
  plug :match
  plug Plug.Parsers, parsers: [:json], json_decoder: Jason
  plug :dispatch

  get "/" do
    send_resp(conn, 200, "Welcome!")
  end

  forward "/api", to: MyApp.ApiRouter

  match _ do
    send_resp(conn, 404, "Not Found")
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

[05. Phoenix Framework](./05_phoenix.md)에서 풀스택 웹 개발을 학습합니다.
