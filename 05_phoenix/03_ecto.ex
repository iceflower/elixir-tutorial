# ===========================================
# 03. Ecto - 데이터베이스
# ===========================================
# Ecto는 Elixir의 데이터베이스 래퍼입니다.

# =========================================
# 스키마 정의
# =========================================

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

    timestamps()  # inserted_at, updated_at 자동 추가
  end

  @doc "생성/수정 시 유효성 검사"
  def changeset(post, attrs) do
    post
    |> cast(attrs, [:title, :body, :published, :user_id])
    |> validate_required([:title, :body])
    |> validate_length(:title, min: 3, max: 100)
    |> validate_length(:body, min: 10)
    |> foreign_key_constraint(:user_id)
  end

  @doc "발행 시 추가 유효성 검사"
  def publish_changeset(post, attrs) do
    post
    |> changeset(attrs)
    |> put_change(:published, true)
    |> put_change(:published_at, DateTime.utc_now())
  end
end

# =========================================
# 마이그레이션
# =========================================

# mix ecto.gen.migration create_posts 실행 후 생성됨
defmodule MyApp.Repo.Migrations.CreatePosts do
  use Ecto.Migration

  def change do
    create table(:posts) do
      add :title, :string, null: false
      add :body, :text
      add :published, :boolean, default: false
      add :view_count, :integer, default: 0
      add :published_at, :utc_datetime
      add :user_id, references(:users, on_delete: :delete_all)

      timestamps()
    end

    create index(:posts, [:user_id])
    create index(:posts, [:published])
    create index(:posts, [:published_at])
  end
end

# =========================================
# Context (비즈니스 로직)
# =========================================

defmodule MyApp.Blog do
  @moduledoc """
  Blog 컨텍스트 - 블로그 관련 비즈니스 로직
  """

  import Ecto.Query, warn: false
  alias MyApp.Repo
  alias MyApp.Blog.Post

  # -----------------------------------------
  # 조회
  # -----------------------------------------

  @doc "모든 게시물 조회"
  def list_posts do
    Repo.all(Post)
  end

  @doc "발행된 게시물만 조회 (최신순)"
  def list_published_posts do
    Post
    |> where([p], p.published == true)
    |> order_by([p], desc: p.published_at)
    |> Repo.all()
  end

  @doc "페이지네이션"
  def list_posts_paginated(page \\ 1, per_page \\ 10) do
    offset = (page - 1) * per_page

    Post
    |> where([p], p.published == true)
    |> order_by([p], desc: p.inserted_at)
    |> limit(^per_page)
    |> offset(^offset)
    |> Repo.all()
  end

  @doc "사용자의 게시물 조회"
  def list_user_posts(user_id) do
    Post
    |> where([p], p.user_id == ^user_id)
    |> Repo.all()
  end

  @doc "ID로 게시물 조회 (없으면 예외)"
  def get_post!(id), do: Repo.get!(Post, id)

  @doc "ID로 게시물 조회 (없으면 nil)"
  def get_post(id), do: Repo.get(Post, id)

  @doc "연관 데이터와 함께 조회"
  def get_post_with_comments!(id) do
    Post
    |> Repo.get!(id)
    |> Repo.preload([:comments, :user, :tags])
  end

  # -----------------------------------------
  # 검색
  # -----------------------------------------

  @doc "제목/내용 검색"
  def search_posts(query) do
    search_term = "%#{query}%"

    Post
    |> where([p], ilike(p.title, ^search_term) or ilike(p.body, ^search_term))
    |> Repo.all()
  end

  @doc "복합 필터"
  def filter_posts(filters) do
    Post
    |> apply_filters(filters)
    |> Repo.all()
  end

  defp apply_filters(query, filters) do
    Enum.reduce(filters, query, fn
      {:published, published}, query ->
        where(query, [p], p.published == ^published)

      {:user_id, user_id}, query ->
        where(query, [p], p.user_id == ^user_id)

      {:since, date}, query ->
        where(query, [p], p.inserted_at >= ^date)

      _, query ->
        query
    end)
  end

  # -----------------------------------------
  # 생성/수정/삭제
  # -----------------------------------------

  @doc "게시물 생성"
  def create_post(attrs \\ %{}) do
    %Post{}
    |> Post.changeset(attrs)
    |> Repo.insert()
  end

  @doc "게시물 수정"
  def update_post(%Post{} = post, attrs) do
    post
    |> Post.changeset(attrs)
    |> Repo.update()
  end

  @doc "게시물 삭제"
  def delete_post(%Post{} = post) do
    Repo.delete(post)
  end

  @doc "게시물 발행"
  def publish_post(%Post{} = post) do
    post
    |> Post.publish_changeset(%{})
    |> Repo.update()
  end

  @doc "조회수 증가"
  def increment_view_count(%Post{} = post) do
    {1, [%{view_count: new_count}]} =
      Post
      |> where([p], p.id == ^post.id)
      |> select([p], %{view_count: p.view_count})
      |> Repo.update_all(inc: [view_count: 1])

    {:ok, %{post | view_count: new_count}}
  end

  @doc "폼용 changeset"
  def change_post(%Post{} = post, attrs \\ %{}) do
    Post.changeset(post, attrs)
  end

  # -----------------------------------------
  # 트랜잭션
  # -----------------------------------------

  @doc "여러 작업을 트랜잭션으로 실행"
  def create_post_with_tags(post_attrs, tag_names) do
    Repo.transaction(fn ->
      with {:ok, post} <- create_post(post_attrs),
           :ok <- attach_tags(post, tag_names) do
        post
      else
        {:error, reason} -> Repo.rollback(reason)
      end
    end)
  end

  defp attach_tags(_post, []), do: :ok
  defp attach_tags(post, tag_names) do
    # 태그 연결 로직
    :ok
  end
end

# =========================================
# Ecto 쿼리 예제
# =========================================

defmodule MyApp.Blog.Queries do
  import Ecto.Query

  # 기본 쿼리
  def recent_posts do
    from p in Post,
      where: p.published == true,
      order_by: [desc: p.inserted_at],
      limit: 10
  end

  # 조인
  def posts_with_authors do
    from p in Post,
      join: u in assoc(p, :user),
      where: p.published == true,
      select: %{title: p.title, author: u.name}
  end

  # 서브쿼리
  def popular_posts do
    avg_views = from p in Post, select: avg(p.view_count)

    from p in Post,
      where: p.view_count > subquery(avg_views)
  end

  # 그룹화 및 집계
  def posts_per_user do
    from p in Post,
      group_by: p.user_id,
      select: {p.user_id, count(p.id)}
  end

  # 동적 쿼리
  def build_query(params) do
    Post
    |> maybe_filter_by_user(params["user_id"])
    |> maybe_filter_by_published(params["published"])
    |> maybe_order_by(params["order"])
  end

  defp maybe_filter_by_user(query, nil), do: query
  defp maybe_filter_by_user(query, user_id) do
    where(query, [p], p.user_id == ^user_id)
  end

  defp maybe_filter_by_published(query, nil), do: query
  defp maybe_filter_by_published(query, "true") do
    where(query, [p], p.published == true)
  end
  defp maybe_filter_by_published(query, _), do: query

  defp maybe_order_by(query, "views"), do: order_by(query, [p], desc: p.view_count)
  defp maybe_order_by(query, _), do: order_by(query, [p], desc: p.inserted_at)
end
