# 05. Phoenix Framework

> **2025년 12월 기준** - Phoenix 1.8, LiveView 1.1, Ecto 3.13

## 목차

1. [Phoenix 소개](#phoenix-소개)
2. [프로젝트 생성](#프로젝트-생성)
3. [프로젝트 구조](#프로젝트-구조)
4. [Router](#router)
5. [Controller](#controller)
6. [Components](#components)
7. [Ecto (데이터베이스)](#ecto-데이터베이스)
8. [LiveView](#liveview)
9. [Channels](#channels)
10. [테스트](#테스트)
11. [배포](#배포)

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

### Phoenix 1.7 → 1.8 주요 변경사항

| 기능 | 변경 내용 |
|------|----------|
| **HTTP 서버** | Bandit 기본값 (Cowboy에서 변경) |
| **LiveView** | 1.1 - Colocated Hooks, 개선된 변경 추적 |
| **Verified Routes** | `~p` 시길 계속 사용 |
| **Tailwind** | 기본 포함 |

---

## 프로젝트 생성

### 설치

```bash
# Phoenix 생성기 설치 (최신)
mix archive.install hex phx_new
```

### 생성 옵션

```bash
# 기본 (PostgreSQL + Bandit + Tailwind)
mix phx.new my_app

# MySQL
mix phx.new my_app --database mysql

# SQLite (개발/소규모에 적합)
mix phx.new my_app --database sqlite3

# 데이터베이스 없이
mix phx.new my_app --no-ecto

# API 전용 (HTML, Assets 없음)
mix phx.new my_app --no-html --no-assets

# LiveView 없이
mix phx.new my_app --no-live

# Umbrella 프로젝트
mix phx.new my_app --umbrella

# 바이너리 ID 사용
mix phx.new my_app --binary-id
```

### 시작

```bash
cd my_app
mix setup          # deps.get + ecto.setup + assets.setup
mix phx.server     # 서버 시작

# 또는 iex와 함께
iex -S mix phx.server
```

http://localhost:4000 접속

---

## 프로젝트 구조

### Phoenix 1.8 구조

```text
my_app/
├── config/                 # 설정
│   ├── config.exs         # 공통 설정
│   ├── dev.exs            # 개발 환경
│   ├── prod.exs           # 운영 환경
│   ├── runtime.exs        # 런타임 설정 (환경변수)
│   └── test.exs           # 테스트 환경
├── lib/
│   ├── my_app/            # 비즈니스 로직 (Context)
│   │   ├── application.ex # Application 시작점
│   │   ├── repo.ex        # Ecto Repo
│   │   └── accounts/      # Accounts Context
│   │       ├── accounts.ex    # Context 모듈
│   │       └── user.ex        # Schema
│   └── my_app_web/        # 웹 계층
│       ├── controllers/   # 컨트롤러
│       │   ├── page_controller.ex
│       │   └── page_html.ex   # View 모듈
│       ├── components/    # 재사용 컴포넌트
│       │   ├── core_components.ex
│       │   └── layouts.ex
│       ├── live/          # LiveView
│       ├── router.ex      # 라우터
│       ├── endpoint.ex    # HTTP Endpoint
│       └── gettext.ex     # 다국어
├── priv/
│   ├── repo/migrations/   # DB 마이그레이션
│   ├── static/            # 정적 파일
│   └── gettext/           # 번역 파일
├── assets/                # 프론트엔드 (JS, CSS)
│   ├── js/
│   ├── css/
│   └── tailwind.config.js
├── test/                  # 테스트
└── mix.exs               # 프로젝트 설정
```

### View → HTML 모듈 변경 (1.7+)

Phoenix 1.7부터 View 대신 HTML 모듈 사용:

```elixir
# 이전 (1.6)
lib/my_app_web/views/page_view.ex
lib/my_app_web/templates/page/index.html.heex

# 현재 (1.7+)
lib/my_app_web/controllers/page_html.ex
lib/my_app_web/controllers/page_html/index.html.heex
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

  # LiveDashboard (개발용)
  if Application.compile_env(:my_app, :dev_routes) do
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser
      live_dashboard "/dashboard", metrics: MyAppWeb.Telemetry
    end
  end
end
```

### Verified Routes (~p 시길)

Phoenix 1.7+에서 컴파일 타임 라우트 검증:

```elixir
# 컨트롤러에서
redirect(conn, to: ~p"/posts/#{post}")

# 템플릿에서
<.link navigate={~p"/posts/#{@post}"}>View Post</.link>
<.link href={~p"/posts"}>All Posts</.link>

# 파라미터 포함
~p"/posts?#{[page: 1, sort: "date"]}"
# => "/posts?page=1&sort=date"

# 정적 파일
~p"/images/logo.png"
```

### resources가 생성하는 라우트

```elixir
resources "/posts", PostController
```

| HTTP | 경로 | 액션 | 헬퍼 |
|------|------|------|------|
| GET | /posts | :index | `~p"/posts"` |
| GET | /posts/:id | :show | `~p"/posts/#{id}"` |
| GET | /posts/new | :new | `~p"/posts/new"` |
| POST | /posts | :create | `~p"/posts"` |
| GET | /posts/:id/edit | :edit | `~p"/posts/#{id}/edit"` |
| PUT/PATCH | /posts/:id | :update | `~p"/posts/#{id}"` |
| DELETE | /posts/:id | :delete | `~p"/posts/#{id}"` |

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

  def new(conn, _params) do
    changeset = Blog.change_post(%Post{})
    render(conn, :new, changeset: changeset)
  end

  def create(conn, %{"post" => post_params}) do
    case Blog.create_post(post_params) do
      {:ok, post} ->
        conn
        |> put_flash(:info, "Post created successfully.")
        |> redirect(to: ~p"/posts/#{post}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :new, changeset: changeset)
    end
  end

  def edit(conn, %{"id" => id}) do
    post = Blog.get_post!(id)
    changeset = Blog.change_post(post)
    render(conn, :edit, post: post, changeset: changeset)
  end

  def update(conn, %{"id" => id, "post" => post_params}) do
    post = Blog.get_post!(id)

    case Blog.update_post(post, post_params) do
      {:ok, post} ->
        conn
        |> put_flash(:info, "Post updated successfully.")
        |> redirect(to: ~p"/posts/#{post}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :edit, post: post, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    post = Blog.get_post!(id)
    {:ok, _post} = Blog.delete_post(post)

    conn
    |> put_flash(:info, "Post deleted successfully.")
    |> redirect(to: ~p"/posts")
  end
end
```

### JSON API Controller

```elixir
defmodule MyAppWeb.Api.UserController do
  use MyAppWeb, :controller

  alias MyApp.Accounts
  alias MyApp.Accounts.User

  action_fallback MyAppWeb.FallbackController

  def index(conn, _params) do
    users = Accounts.list_users()
    render(conn, :index, users: users)
  end

  def create(conn, %{"user" => user_params}) do
    with {:ok, %User{} = user} <- Accounts.create_user(user_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", ~p"/api/users/#{user}")
      |> render(:show, user: user)
    end
  end

  def show(conn, %{"id" => id}) do
    user = Accounts.get_user!(id)
    render(conn, :show, user: user)
  end

  def update(conn, %{"id" => id, "user" => user_params}) do
    user = Accounts.get_user!(id)

    with {:ok, %User{} = user} <- Accounts.update_user(user, user_params) do
      render(conn, :show, user: user)
    end
  end

  def delete(conn, %{"id" => id}) do
    user = Accounts.get_user!(id)

    with {:ok, %User{}} <- Accounts.delete_user(user) do
      send_resp(conn, :no_content, "")
    end
  end
end

# JSON 렌더링 모듈
defmodule MyAppWeb.Api.UserJSON do
  alias MyApp.Accounts.User

  def index(%{users: users}) do
    %{data: for(user <- users, do: data(user))}
  end

  def show(%{user: user}) do
    %{data: data(user)}
  end

  defp data(%User{} = user) do
    %{
      id: user.id,
      name: user.name,
      email: user.email
    }
  end
end
```

---

## Components

### Function Components (Phoenix 1.7+)

```elixir
# lib/my_app_web/components/core_components.ex
defmodule MyAppWeb.CoreComponents do
  use Phoenix.Component

  # 속성 정의
  attr :type, :string, default: "button"
  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(disabled form name value)

  slot :inner_block, required: true

  def button(assigns) do
    ~H"""
    <button
      type={@type}
      class={[
        "phx-submit-loading:opacity-75 rounded-lg bg-zinc-900 hover:bg-zinc-700",
        "py-2 px-3 text-sm font-semibold leading-6 text-white active:text-white/80",
        @class
      ]}
      {@rest}
    >
      <%= render_slot(@inner_block) %>
    </button>
    """
  end

  # 카드 컴포넌트
  attr :class, :string, default: nil
  slot :header
  slot :inner_block, required: true
  slot :footer

  def card(assigns) do
    ~H"""
    <div class={["bg-white rounded-lg shadow", @class]}>
      <div :if={@header != []} class="px-4 py-3 border-b">
        <%= render_slot(@header) %>
      </div>
      <div class="p-4">
        <%= render_slot(@inner_block) %>
      </div>
      <div :if={@footer != []} class="px-4 py-3 border-t bg-gray-50">
        <%= render_slot(@footer) %>
      </div>
    </div>
    """
  end

  # 테이블 컴포넌트
  attr :id, :string, required: true
  attr :rows, :list, required: true
  attr :row_click, :any, default: nil

  slot :col, required: true do
    attr :label, :string
  end

  def table(assigns) do
    ~H"""
    <table class="w-full">
      <thead class="bg-gray-50">
        <tr>
          <th :for={col <- @col} class="px-4 py-3 text-left text-sm font-semibold">
            <%= col[:label] %>
          </th>
        </tr>
      </thead>
      <tbody class="divide-y">
        <tr :for={row <- @rows} id={"#{@id}-#{row.id}"} class="hover:bg-gray-50">
          <td :for={col <- @col} class="px-4 py-3">
            <%= render_slot(col, row) %>
          </td>
        </tr>
      </tbody>
    </table>
    """
  end
end
```

### 사용 예시

```heex
<.button>Save</.button>
<.button type="submit" class="w-full">Submit Form</.button>

<.card>
  <:header>
    <h3 class="text-lg font-semibold">Card Title</h3>
  </:header>

  <p>Card content goes here.</p>

  <:footer>
    <.button>Action</.button>
  </:footer>
</.card>

<.table id="users" rows={@users}>
  <:col :let={user} label="Name"><%= user.name %></:col>
  <:col :let={user} label="Email"><%= user.email %></:col>
  <:col :let={user} label="Actions">
    <.link navigate={~p"/users/#{user}"}>View</.link>
  </:col>
</.table>
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
    field :view_count, :integer, default: 0
    field :published_at, :utc_datetime

    belongs_to :user, MyApp.Accounts.User
    has_many :comments, MyApp.Blog.Comment
    many_to_many :tags, MyApp.Blog.Tag, join_through: "posts_tags"

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(post, attrs) do
    post
    |> cast(attrs, [:title, :body, :published, :published_at, :user_id])
    |> validate_required([:title, :body, :user_id])
    |> validate_length(:title, min: 3, max: 200)
    |> validate_length(:body, min: 10)
    |> foreign_key_constraint(:user_id)
    |> maybe_set_published_at()
  end

  defp maybe_set_published_at(changeset) do
    if get_change(changeset, :published) == true and is_nil(get_field(changeset, :published_at)) do
      put_change(changeset, :published_at, DateTime.utc_now())
    else
      changeset
    end
  end
end
```

### Context (비즈니스 로직)

```elixir
defmodule MyApp.Blog do
  import Ecto.Query, warn: false
  alias MyApp.Repo
  alias MyApp.Blog.Post

  def list_posts(opts \\ []) do
    Post
    |> apply_filters(opts)
    |> order_by([p], desc: p.inserted_at)
    |> Repo.all()
  end

  def list_published_posts do
    Post
    |> where([p], p.published == true)
    |> order_by([p], desc: p.published_at)
    |> Repo.all()
  end

  def get_post!(id) do
    Post
    |> Repo.get!(id)
    |> Repo.preload([:user, :comments, :tags])
  end

  def create_post(attrs \\ %{}) do
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

  def change_post(%Post{} = post, attrs \\ %{}) do
    Post.changeset(post, attrs)
  end

  def increment_view_count(%Post{} = post) do
    {1, [%{view_count: count}]} =
      Post
      |> where(id: ^post.id)
      |> select([p], %{view_count: p.view_count})
      |> Repo.update_all(inc: [view_count: 1])

    %{post | view_count: count}
  end

  # 필터 적용 헬퍼
  defp apply_filters(query, opts) do
    Enum.reduce(opts, query, fn
      {:published, true}, query ->
        where(query, [p], p.published == true)

      {:user_id, user_id}, query ->
        where(query, [p], p.user_id == ^user_id)

      {:search, term}, query when is_binary(term) ->
        where(query, [p], ilike(p.title, ^"%#{term}%") or ilike(p.body, ^"%#{term}%"))

      {:limit, limit}, query ->
        limit(query, ^limit)

      _, query ->
        query
    end)
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

# 집계
from p in Post,
  where: p.user_id == ^user_id,
  select: %{
    total: count(p.id),
    published: count(p.id) |> filter(p.published == true),
    views: sum(p.view_count)
  }

# 서브쿼리
popular_posts =
  from p in Post,
    where: p.view_count > 100,
    select: p.id

from p in Post,
  where: p.id in subquery(popular_posts)
```

---

## LiveView

### 기본 LiveView (Phoenix 1.8 / LiveView 1.1)

```elixir
defmodule MyAppWeb.CounterLive do
  use MyAppWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, count: 0)}
  end

  @impl true
  def handle_event("increment", _params, socket) do
    {:noreply, update(socket, :count, &(&1 + 1))}
  end

  @impl true
  def handle_event("decrement", _params, socket) do
    {:noreply, update(socket, :count, &(&1 - 1))}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="text-center py-10">
      <h1 class="text-4xl font-bold mb-4">Count: <%= @count %></h1>
      <div class="space-x-4">
        <.button phx-click="decrement">-1</.button>
        <.button phx-click="increment">+1</.button>
      </div>
    </div>
    """
  end
end
```

### Streams (대용량 컬렉션 처리)

```elixir
defmodule MyAppWeb.PostsLive do
  use MyAppWeb, :live_view

  alias MyApp.Blog

  @impl true
  def mount(_params, _session, socket) do
    posts = Blog.list_posts()
    {:ok, stream(socket, :posts, posts)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    post = Blog.get_post!(id)
    {:ok, _} = Blog.delete_post(post)
    {:noreply, stream_delete(socket, :posts, post)}
  end

  @impl true
  def handle_info({:post_created, post}, socket) do
    {:noreply, stream_insert(socket, :posts, post, at: 0)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-4" id="posts" phx-update="stream">
      <div :for={{dom_id, post} <- @streams.posts} id={dom_id} class="p-4 bg-white rounded shadow">
        <h2 class="text-xl font-semibold"><%= post.title %></h2>
        <p class="mt-2 text-gray-600"><%= post.body %></p>
        <button phx-click="delete" phx-value-id={post.id} class="mt-2 text-red-600">
          Delete
        </button>
      </div>
    </div>
    """
  end
end
```

### LiveView 폼

```elixir
defmodule MyAppWeb.PostLive.FormComponent do
  use MyAppWeb, :live_component

  alias MyApp.Blog

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.form
        for={@form}
        id="post-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:title]} type="text" label="Title" />
        <.input field={@form[:body]} type="textarea" label="Body" />
        <.input field={@form[:published]} type="checkbox" label="Published" />

        <:actions>
          <.button phx-disable-with="Saving...">Save Post</.button>
        </:actions>
      </.form>
    </div>
    """
  end

  @impl true
  def update(%{post: post} = assigns, socket) do
    changeset = Blog.change_post(post)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"post" => post_params}, socket) do
    changeset =
      socket.assigns.post
      |> Blog.change_post(post_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  @impl true
  def handle_event("save", %{"post" => post_params}, socket) do
    save_post(socket, socket.assigns.action, post_params)
  end

  defp save_post(socket, :edit, post_params) do
    case Blog.update_post(socket.assigns.post, post_params) do
      {:ok, post} ->
        notify_parent({:saved, post})
        {:noreply, socket |> put_flash(:info, "Post updated")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_post(socket, :new, post_params) do
    case Blog.create_post(post_params) do
      {:ok, post} ->
        notify_parent({:saved, post})
        {:noreply, socket |> put_flash(:info, "Post created")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
```

### Colocated Hooks (LiveView 1.1+)

Phoenix 1.8에서 JavaScript를 같은 파일에 작성:

```elixir
defmodule MyAppWeb.ChartLive do
  use MyAppWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, data: [10, 20, 30, 40, 50])}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div id="chart" phx-hook="Chart" data-values={Jason.encode!(@data)}>
      <canvas></canvas>
    </div>

    <script>
      export default {
        mounted() {
          const values = JSON.parse(this.el.dataset.values)
          // Chart.js 또는 다른 라이브러리 사용
          this.chart = new Chart(this.el.querySelector('canvas'), {
            type: 'bar',
            data: { datasets: [{ data: values }] }
          })
        },
        updated() {
          const values = JSON.parse(this.el.dataset.values)
          this.chart.data.datasets[0].data = values
          this.chart.update()
        }
      }
    </script>
    """
  end
end
```

---

## Channels

WebSocket 실시간 통신:

```elixir
# lib/my_app_web/channels/room_channel.ex
defmodule MyAppWeb.RoomChannel do
  use MyAppWeb, :channel

  @impl true
  def join("room:" <> room_id, _payload, socket) do
    if authorized?(socket, room_id) do
      {:ok, assign(socket, :room_id, room_id)}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  @impl true
  def handle_in("new_msg", %{"body" => body}, socket) do
    user = socket.assigns.current_user
    broadcast!(socket, "new_msg", %{body: body, user: user.name})
    {:noreply, socket}
  end

  @impl true
  def handle_in("typing", _params, socket) do
    user = socket.assigns.current_user
    broadcast_from!(socket, "typing", %{user: user.name})
    {:noreply, socket}
  end

  defp authorized?(socket, _room_id) do
    socket.assigns[:current_user] != nil
  end
end
```

JavaScript:
```javascript
import { Socket } from "phoenix"

let socket = new Socket("/socket", { params: { token: userToken } })
socket.connect()

let channel = socket.channel("room:lobby", {})

channel.on("new_msg", payload => {
  console.log("Message:", payload.body, "from:", payload.user)
})

channel.on("typing", payload => {
  console.log(payload.user, "is typing...")
})

channel.join()
  .receive("ok", resp => console.log("Joined!", resp))
  .receive("error", resp => console.log("Unable to join", resp))

// 메시지 전송
channel.push("new_msg", { body: "Hello!" })
```

---

## 테스트

### Controller 테스트

```elixir
defmodule MyAppWeb.PostControllerTest do
  use MyAppWeb.ConnCase

  import MyApp.BlogFixtures

  @create_attrs %{title: "Test Post", body: "Test body content"}
  @invalid_attrs %{title: nil, body: nil}

  describe "index" do
    test "lists all posts", %{conn: conn} do
      conn = get(conn, ~p"/posts")
      assert html_response(conn, 200) =~ "Posts"
    end
  end

  describe "create post" do
    test "redirects to show when data is valid", %{conn: conn} do
      conn = post(conn, ~p"/posts", post: @create_attrs)
      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == ~p"/posts/#{id}"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, ~p"/posts", post: @invalid_attrs)
      assert html_response(conn, 200) =~ "can&#39;t be blank"
    end
  end
end
```

### LiveView 테스트

```elixir
defmodule MyAppWeb.CounterLiveTest do
  use MyAppWeb.ConnCase
  import Phoenix.LiveViewTest

  test "increments counter", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/counter")

    assert view |> element("h1") |> render() =~ "Count: 0"

    view |> element("button", "+1") |> render_click()

    assert view |> element("h1") |> render() =~ "Count: 1"
  end

  test "decrements counter", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/counter")

    view |> element("button", "+1") |> render_click()
    view |> element("button", "-1") |> render_click()

    assert view |> element("h1") |> render() =~ "Count: 0"
  end
end
```

---

## 배포

### Fly.io (권장)

```bash
# Fly CLI 설치 후
fly launch

# 시크릿 설정
fly secrets set SECRET_KEY_BASE=$(mix phx.gen.secret)
fly secrets set DATABASE_URL=your_db_url

# 배포
fly deploy
```

### Docker

```dockerfile
# Dockerfile
ARG ELIXIR_VERSION=1.18.1
ARG OTP_VERSION=27.2
ARG DEBIAN_VERSION=bookworm-20241202-slim

ARG BUILDER_IMAGE="hexpm/elixir:${ELIXIR_VERSION}-erlang-${OTP_VERSION}-debian-${DEBIAN_VERSION}"
ARG RUNNER_IMAGE="debian:${DEBIAN_VERSION}"

FROM ${BUILDER_IMAGE} as builder

ENV MIX_ENV="prod"

RUN apt-get update -y && apt-get install -y build-essential git \
    && apt-get clean && rm -f /var/lib/apt/lists/*_*

WORKDIR /app

RUN mix local.hex --force && \
    mix local.rebar --force

COPY mix.exs mix.lock ./
RUN mix deps.get --only $MIX_ENV
RUN mkdir config

COPY config/config.exs config/${MIX_ENV}.exs config/
RUN mix deps.compile

COPY priv priv
COPY lib lib
COPY assets assets

RUN mix assets.deploy
RUN mix compile
RUN mix release

# Runner
FROM ${RUNNER_IMAGE}

RUN apt-get update -y && \
  apt-get install -y libstdc++6 openssl libncurses5 locales ca-certificates \
  && apt-get clean && rm -f /var/lib/apt/lists/*_*

RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen

ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

WORKDIR /app
RUN chown nobody /app

COPY --from=builder --chown=nobody:root /app/_build/prod/rel/my_app ./

USER nobody

CMD ["/app/bin/server"]
```

### 환경 변수 (runtime.exs)

```elixir
# config/runtime.exs
import Config

if config_env() == :prod do
  database_url =
    System.get_env("DATABASE_URL") ||
      raise "DATABASE_URL environment variable is missing"

  config :my_app, MyApp.Repo,
    url: database_url,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10")

  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise "SECRET_KEY_BASE environment variable is missing"

  host = System.get_env("PHX_HOST") || "example.com"
  port = String.to_integer(System.get_env("PORT") || "4000")

  config :my_app, MyAppWeb.Endpoint,
    url: [host: host, port: 443, scheme: "https"],
    http: [ip: {0, 0, 0, 0, 0, 0, 0, 0}, port: port],
    secret_key_base: secret_key_base
end
```

---

## 코드 생성기

```bash
# HTML CRUD
mix phx.gen.html Blog Post posts title:string body:text published:boolean

# JSON API
mix phx.gen.json Api User users name:string email:string

# LiveView CRUD
mix phx.gen.live Blog Post posts title:string body:text

# 인증 시스템 (phx.gen.auth)
mix phx.gen.auth Accounts User users

# Context만
mix phx.gen.context Accounts User users name:string email:string

# Schema만
mix phx.gen.schema Blog.Comment comments body:text post_id:references:posts

# 마이그레이션만
mix ecto.gen.migration add_published_at_to_posts
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
mix test --cover

# 포맷팅
mix format

# 정적 분석
mix credo
mix dialyzer

# 의존성 업데이트
mix deps.update --all
mix hex.outdated
```

---

## 참고 자료

- [Phoenix 공식 가이드](https://hexdocs.pm/phoenix/)
- [Phoenix LiveView](https://hexdocs.pm/phoenix_live_view/)
- [Ecto](https://hexdocs.pm/ecto/)
- [Phoenix 1.8 릴리스 노트](https://www.phoenixframework.org/blog)
- [Elixir School (한국어)](https://elixirschool.com/ko/)
