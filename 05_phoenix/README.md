# 05. Phoenix Framework

## 목차

1. [Phoenix 소개](#phoenix-소개)
2. [프로젝트 생성](#프로젝트-생성)
3. [프로젝트 구조](#프로젝트-구조)
4. [Router](#router)
5. [Controller](#controller)
6. [View와 Template](#view와-template)
7. [Ecto (데이터베이스)](#ecto-데이터베이스)
8. [LiveView](#liveview)
9. [Channels](#channels)
10. [배포](#배포)

---

## Phoenix 소개

Phoenix는 Elixir의 **풀스택 웹 프레임워크**입니다.

### 특징

| 특징 | 설명 |
|------|------|
| **성능** | 마이크로초 응답 시간 |
| **실시간** | LiveView, Channels 내장 |
| **생산성** | 코드 생성기, 핫 리로드 |
| **확장성** | 수백만 동시 연결 |

### Rails와 비교

| | Phoenix | Rails |
|--|---------|-------|
| 언어 | Elixir | Ruby |
| 동시성 | BEAM (수백만) | Thread (수천) |
| 실시간 | LiveView (기본) | Hotwire (추가) |
| 성능 | ~1ms 응답 | ~10ms 응답 |

---

## 프로젝트 생성

### 설치

```bash
# Phoenix 생성기 설치
mix archive.install hex phx_new
```

### 생성 옵션

```bash
# 기본 (PostgreSQL + 모든 기능)
mix phx.new my_app

# 데이터베이스 없이
mix phx.new my_app --no-ecto

# API 전용
mix phx.new my_app --no-html --no-assets

# SQLite 사용
mix phx.new my_app --database sqlite3

# 실시간 기능 없이
mix phx.new my_app --no-live
```

### 시작

```bash
cd my_app
mix deps.get        # 의존성 설치
mix ecto.create     # DB 생성
mix phx.server      # 서버 시작

# 또는 iex와 함께
iex -S mix phx.server
```

http://localhost:4000 접속

---

## 프로젝트 구조

```
my_app/
├── config/                 # 설정
│   ├── config.exs         # 공통
│   ├── dev.exs            # 개발
│   ├── prod.exs           # 운영
│   └── runtime.exs        # 런타임
├── lib/
│   ├── my_app/            # 비즈니스 로직
│   │   ├── application.ex # Application
│   │   ├── repo.ex        # Ecto Repo
│   │   └── accounts/      # Context
│   │       ├── accounts.ex
│   │       └── user.ex
│   └── my_app_web/        # 웹 계층
│       ├── controllers/
│       ├── components/
│       ├── live/          # LiveView
│       ├── router.ex
│       └── endpoint.ex
├── priv/
│   ├── repo/migrations/   # DB 마이그레이션
│   └── static/            # 정적 파일
├── test/                  # 테스트
└── mix.exs               # 프로젝트 설정
```

---

## Router

### 기본 라우팅

```elixir
# lib/my_app_web/router.ex
defmodule MyAppWeb.Router do
  use MyAppWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {MyAppWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", MyAppWeb do
    pipe_through :browser

    get "/", PageController, :home
    resources "/posts", PostController
    live "/counter", CounterLive
  end

  scope "/api", MyAppWeb.Api do
    pipe_through :api

    resources "/users", UserController, except: [:new, :edit]
  end
end
```

### resources가 생성하는 라우트

```elixir
resources "/posts", PostController
```

| HTTP | 경로 | 액션 | 설명 |
|------|------|------|------|
| GET | /posts | :index | 목록 |
| GET | /posts/:id | :show | 상세 |
| GET | /posts/new | :new | 생성 폼 |
| POST | /posts | :create | 생성 |
| GET | /posts/:id/edit | :edit | 수정 폼 |
| PUT/PATCH | /posts/:id | :update | 수정 |
| DELETE | /posts/:id | :delete | 삭제 |

---

## Controller

### 기본 구조

```elixir
defmodule MyAppWeb.PostController do
  use MyAppWeb, :controller

  alias MyApp.Blog
  alias MyApp.Blog.Post

  def index(conn, _params) do
    posts = Blog.list_posts()
    render(conn, :index, posts: posts)
  end

  def show(conn, %{"id" => id}) do
    post = Blog.get_post!(id)
    render(conn, :show, post: post)
  end

  def create(conn, %{"post" => post_params}) do
    case Blog.create_post(post_params) do
      {:ok, post} ->
        conn
        |> put_flash(:info, "Post created!")
        |> redirect(to: ~p"/posts/#{post}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :new, changeset: changeset)
    end
  end
end
```

### JSON API Controller

```elixir
defmodule MyAppWeb.Api.UserController do
  use MyAppWeb, :controller

  def index(conn, _params) do
    users = Accounts.list_users()
    json(conn, %{users: users})
  end

  def create(conn, %{"user" => params}) do
    case Accounts.create_user(params) do
      {:ok, user} ->
        conn
        |> put_status(:created)
        |> json(%{user: user})

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: format_errors(changeset)})
    end
  end
end
```

---

## View와 Template

### HEEx 템플릿 (Phoenix 1.7+)

```heex
<%# lib/my_app_web/controllers/post_html/index.html.heex %>

<h1>Posts</h1>

<ul>
  <%= for post <- @posts do %>
    <li>
      <a href={~p"/posts/#{post}"}><%= post.title %></a>
      <span><%= post.inserted_at %></span>
    </li>
  <% end %>
</ul>

<a href={~p"/posts/new"}>New Post</a>
```

### 컴포넌트

```elixir
defmodule MyAppWeb.Components do
  use Phoenix.Component

  attr :type, :string, default: "primary"
  attr :rest, :global
  slot :inner_block, required: true

  def button(assigns) do
    ~H"""
    <button class={"btn btn-#{@type}"} {@rest}>
      <%= render_slot(@inner_block) %>
    </button>
    """
  end
end
```

사용:
```heex
<.button type="danger" phx-click="delete">삭제</.button>
```

---

## Ecto (데이터베이스)

### Schema

```elixir
defmodule MyApp.Blog.Post do
  use Ecto.Schema
  import Ecto.Changeset

  schema "posts" do
    field :title, :string
    field :body, :string
    field :published, :boolean, default: false

    belongs_to :user, MyApp.Accounts.User
    has_many :comments, MyApp.Blog.Comment

    timestamps()
  end

  def changeset(post, attrs) do
    post
    |> cast(attrs, [:title, :body, :published])
    |> validate_required([:title, :body])
    |> validate_length(:title, min: 3, max: 100)
  end
end
```

### Context (비즈니스 로직)

```elixir
defmodule MyApp.Blog do
  import Ecto.Query
  alias MyApp.Repo
  alias MyApp.Blog.Post

  def list_posts do
    Repo.all(Post)
  end

  def get_post!(id) do
    Repo.get!(Post, id)
  end

  def create_post(attrs) do
    %Post{}
    |> Post.changeset(attrs)
    |> Repo.insert()
  end

  def update_post(%Post{} = post, attrs) do
    post
    |> Post.changeset(attrs)
    |> Repo.update()
  end

  def delete_post(%Post{} = post) do
    Repo.delete(post)
  end
end
```

### 쿼리

```elixir
# 기본 쿼리
from p in Post,
  where: p.published == true,
  order_by: [desc: p.inserted_at],
  limit: 10

# 조인
from p in Post,
  join: u in assoc(p, :user),
  where: p.published == true,
  preload: [user: u]

# 동적 쿼리
def list_posts(filters) do
  Post
  |> maybe_filter_by_user(filters[:user_id])
  |> maybe_filter_by_published(filters[:published])
  |> Repo.all()
end
```

---

## LiveView

서버 렌더링 실시간 UI:

```elixir
defmodule MyAppWeb.CounterLive do
  use MyAppWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, assign(socket, count: 0)}
  end

  def handle_event("increment", _params, socket) do
    {:noreply, update(socket, :count, &(&1 + 1))}
  end

  def render(assigns) do
    ~H"""
    <div>
      <h1>Count: <%= @count %></h1>
      <button phx-click="increment">+1</button>
    </div>
    """
  end
end
```

### LiveView 이벤트

```heex
<%# 클릭 %>
<button phx-click="save">저장</button>

<%# 폼 제출 %>
<form phx-submit="create" phx-change="validate">
  <input name="name" phx-debounce="300" />
</form>

<%# 키보드 %>
<div phx-keydown="keydown" phx-key="Enter">

<%# 포커스 %>
<input phx-focus="focus" phx-blur="blur" />
```

---

## Channels

WebSocket 실시간 통신:

```elixir
defmodule MyAppWeb.RoomChannel do
  use MyAppWeb, :channel

  def join("room:lobby", _payload, socket) do
    {:ok, socket}
  end

  def handle_in("new_msg", %{"body" => body}, socket) do
    broadcast!(socket, "new_msg", %{body: body})
    {:noreply, socket}
  end
end
```

JavaScript:
```javascript
let channel = socket.channel("room:lobby", {})

channel.on("new_msg", payload => {
  console.log("Message:", payload.body)
})

channel.push("new_msg", {body: "Hello!"})

channel.join()
```

---

## 배포

### Fly.io (권장)

```bash
# 설치
fly auth login

# 앱 생성
fly launch

# 시크릿 설정
fly secrets set SECRET_KEY_BASE=$(mix phx.gen.secret)

# 배포
fly deploy
```

### Docker

```dockerfile
FROM elixir:1.15-alpine AS builder
WORKDIR /app
ENV MIX_ENV=prod

COPY mix.exs mix.lock ./
RUN mix deps.get --only prod && mix deps.compile

COPY assets assets
COPY priv priv
RUN mix assets.deploy

COPY lib lib
RUN mix compile && mix release

FROM alpine:3.18
WORKDIR /app
COPY --from=builder /app/_build/prod/rel/my_app ./
CMD ["bin/my_app", "start"]
```

### 마이그레이션

```bash
# 운영 환경에서
_build/prod/rel/my_app/bin/my_app eval "MyApp.Release.migrate"
```

---

## 코드 생성기

```bash
# HTML CRUD
mix phx.gen.html Blog Post posts title:string body:text

# JSON API
mix phx.gen.json Api User users name:string email:string

# LiveView CRUD
mix phx.gen.live Blog Post posts title:string body:text

# 인증 시스템
mix phx.gen.auth Accounts User users

# 마이그레이션만
mix ecto.gen.migration create_posts
```

---

## 유용한 명령어

```bash
# 라우트 확인
mix phx.routes

# iex 콘솔
iex -S mix phx.server

# 테스트
mix test

# 포맷팅
mix format

# 의존성 업데이트
mix deps.update --all
```

---

## 다음 단계

- [Phoenix 공식 가이드](https://hexdocs.pm/phoenix/)
- [Phoenix LiveView](https://hexdocs.pm/phoenix_live_view/)
- [Ecto](https://hexdocs.pm/ecto/)
- [Elixir School](https://elixirschool.com/ko/)
