# ===========================================
# 01. Phoenix Router
# ===========================================
# 이 파일은 Phoenix 라우터의 구조와 사용법을 보여줍니다.
# 실제로 실행되지 않고 참고용입니다.

defmodule MyAppWeb.Router do
  use MyAppWeb, :router

  # =========================================
  # 파이프라인 정의
  # =========================================

  # 브라우저 요청용 파이프라인
  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {MyAppWeb.Layouts, :root}
    plug :protect_from_forgery  # CSRF 보호
    plug :put_secure_browser_headers
  end

  # API 요청용 파이프라인
  pipeline :api do
    plug :accepts, ["json"]
  end

  # 인증 필요한 요청용
  pipeline :authenticated do
    plug MyAppWeb.Plugs.RequireAuth
  end

  # =========================================
  # 라우트 정의
  # =========================================

  # 일반 브라우저 라우트
  scope "/", MyAppWeb do
    pipe_through :browser

    # 기본 라우트
    get "/", PageController, :home
    get "/about", PageController, :about

    # 리소스 라우트 (CRUD 전체)
    resources "/posts", PostController

    # 리소스 라우트 (일부만)
    resources "/comments", CommentController, only: [:index, :show]
    resources "/tags", TagController, except: [:delete]

    # 중첩 리소스
    resources "/users", UserController do
      resources "/posts", UserPostController, only: [:index, :show]
    end

    # 커스텀 액션
    get "/posts/:id/publish", PostController, :publish
    post "/posts/:id/like", PostController, :like
  end

  # 인증 필요한 라우트
  scope "/admin", MyAppWeb.Admin, as: :admin do
    pipe_through [:browser, :authenticated]

    get "/", DashboardController, :index
    resources "/users", UserController
  end

  # API 라우트
  scope "/api", MyAppWeb.Api, as: :api do
    pipe_through :api

    scope "/v1", V1, as: :v1 do
      resources "/users", UserController, except: [:new, :edit]
      resources "/posts", PostController, except: [:new, :edit]

      post "/auth/login", AuthController, :login
      delete "/auth/logout", AuthController, :logout
    end
  end

  # LiveView 라우트
  scope "/", MyAppWeb do
    pipe_through :browser

    live "/counter", CounterLive
    live "/chat", ChatLive
    live "/dashboard", DashboardLive, :index
    live "/dashboard/:id", DashboardLive, :show
  end
end

# =========================================
# 생성되는 라우트 예시 (resources)
# =========================================

# resources "/posts", PostController 는 다음을 생성:
#
# GET     /posts           PostController :index   (목록)
# GET     /posts/:id       PostController :show    (상세)
# GET     /posts/new       PostController :new     (생성 폼)
# POST    /posts           PostController :create  (생성)
# GET     /posts/:id/edit  PostController :edit    (수정 폼)
# PUT     /posts/:id       PostController :update  (수정)
# PATCH   /posts/:id       PostController :update  (수정)
# DELETE  /posts/:id       PostController :delete  (삭제)

# =========================================
# 경로 헬퍼 예시
# =========================================

# 라우터에서 정의한 경로에 대해 헬퍼 함수가 자동 생성됩니다:
#
# ~p"/posts"                    # "/posts"
# ~p"/posts/#{post}"            # "/posts/123"
# ~p"/posts/#{post}/edit"       # "/posts/123/edit"
# ~p"/api/v1/users"             # "/api/v1/users"
#
# URL 포함:
# url(~p"/posts")               # "http://localhost:4000/posts"
