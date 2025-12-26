# ===========================================
# 02. Phoenix Controller
# ===========================================
# 컨트롤러는 요청을 받아 처리하고 응답을 반환합니다.

defmodule MyAppWeb.PostController do
  use MyAppWeb, :controller

  alias MyApp.Blog
  alias MyApp.Blog.Post

  # =========================================
  # 기본 CRUD 액션
  # =========================================

  # GET /posts
  def index(conn, _params) do
    posts = Blog.list_posts()
    render(conn, :index, posts: posts)
  end

  # GET /posts/:id
  def show(conn, %{"id" => id}) do
    post = Blog.get_post!(id)
    render(conn, :show, post: post)
  end

  # GET /posts/new
  def new(conn, _params) do
    changeset = Blog.change_post(%Post{})
    render(conn, :new, changeset: changeset)
  end

  # POST /posts
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

  # GET /posts/:id/edit
  def edit(conn, %{"id" => id}) do
    post = Blog.get_post!(id)
    changeset = Blog.change_post(post)
    render(conn, :edit, post: post, changeset: changeset)
  end

  # PUT/PATCH /posts/:id
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

  # DELETE /posts/:id
  def delete(conn, %{"id" => id}) do
    post = Blog.get_post!(id)
    {:ok, _post} = Blog.delete_post(post)

    conn
    |> put_flash(:info, "Post deleted successfully.")
    |> redirect(to: ~p"/posts")
  end
end

# =========================================
# API 컨트롤러
# =========================================

defmodule MyAppWeb.Api.V1.UserController do
  use MyAppWeb, :controller

  alias MyApp.Accounts
  alias MyApp.Accounts.User

  action_fallback MyAppWeb.FallbackController

  # GET /api/v1/users
  def index(conn, _params) do
    users = Accounts.list_users()
    render(conn, :index, users: users)
  end

  # GET /api/v1/users/:id
  def show(conn, %{"id" => id}) do
    user = Accounts.get_user!(id)
    render(conn, :show, user: user)
  end

  # POST /api/v1/users
  def create(conn, %{"user" => user_params}) do
    with {:ok, %User{} = user} <- Accounts.create_user(user_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", ~p"/api/v1/users/#{user}")
      |> render(:show, user: user)
    end
  end

  # PUT /api/v1/users/:id
  def update(conn, %{"id" => id, "user" => user_params}) do
    user = Accounts.get_user!(id)

    with {:ok, %User{} = user} <- Accounts.update_user(user, user_params) do
      render(conn, :show, user: user)
    end
  end

  # DELETE /api/v1/users/:id
  def delete(conn, %{"id" => id}) do
    user = Accounts.get_user!(id)

    with {:ok, %User{}} <- Accounts.delete_user(user) do
      send_resp(conn, :no_content, "")
    end
  end
end

# =========================================
# JSON 뷰 (API 응답)
# =========================================

defmodule MyAppWeb.Api.V1.UserJSON do
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
      email: user.email,
      inserted_at: user.inserted_at
    }
  end
end

# =========================================
# Fallback 컨트롤러 (에러 처리)
# =========================================

defmodule MyAppWeb.FallbackController do
  use MyAppWeb, :controller

  def call(conn, {:error, %Ecto.Changeset{} = changeset}) do
    conn
    |> put_status(:unprocessable_entity)
    |> put_view(json: MyAppWeb.ChangesetJSON)
    |> render(:error, changeset: changeset)
  end

  def call(conn, {:error, :not_found}) do
    conn
    |> put_status(:not_found)
    |> put_view(json: MyAppWeb.ErrorJSON)
    |> render(:"404")
  end

  def call(conn, {:error, :unauthorized}) do
    conn
    |> put_status(:unauthorized)
    |> put_view(json: MyAppWeb.ErrorJSON)
    |> render(:"401")
  end
end

# =========================================
# 컴포넌트 (Phoenix 1.7+)
# =========================================

defmodule MyAppWeb.PostHTML do
  use MyAppWeb, :html

  embed_templates "post_html/*"

  attr :post, MyApp.Blog.Post, required: true

  def post_card(assigns) do
    ~H"""
    <div class="post-card">
      <h2><%= @post.title %></h2>
      <p><%= @post.body %></p>
      <span class="date"><%= @post.inserted_at %></span>
    </div>
    """
  end
end
