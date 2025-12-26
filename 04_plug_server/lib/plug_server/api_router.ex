defmodule PlugServer.ApiRouter do
  @moduledoc """
  API 라우터 - RESTful API 엔드포인트
  """
  use Plug.Router

  plug :match
  plug :dispatch

  # 임시 데이터 저장소 (실제로는 데이터베이스 사용)
  # Agent를 사용한 간단한 상태 관리
  @users_agent :users_store

  # ========================================
  # 사용자 API
  # ========================================

  # GET /api/users - 모든 사용자 조회
  get "/users" do
    users = get_users()
    json_response(conn, 200, %{users: users, count: length(users)})
  end

  # GET /api/users/:id - 특정 사용자 조회
  get "/users/:id" do
    case Integer.parse(id) do
      {user_id, ""} ->
        case find_user(user_id) do
          nil ->
            json_response(conn, 404, %{error: "User not found", id: user_id})
          user ->
            json_response(conn, 200, %{user: user})
        end
      _ ->
        json_response(conn, 400, %{error: "Invalid user ID"})
    end
  end

  # POST /api/users - 사용자 생성
  post "/users" do
    case conn.body_params do
      %{"name" => name, "email" => email} ->
        user = create_user(name, email)
        json_response(conn, 201, %{message: "User created", user: user})

      _ ->
        json_response(conn, 400, %{
          error: "Invalid request body",
          required: ["name", "email"]
        })
    end
  end

  # DELETE /api/users/:id - 사용자 삭제
  delete "/users/:id" do
    case Integer.parse(id) do
      {user_id, ""} ->
        case delete_user(user_id) do
          :ok ->
            json_response(conn, 200, %{message: "User deleted", id: user_id})
          :not_found ->
            json_response(conn, 404, %{error: "User not found", id: user_id})
        end
      _ ->
        json_response(conn, 400, %{error: "Invalid user ID"})
    end
  end

  # ========================================
  # 기타 API 엔드포인트
  # ========================================

  # GET /api/health - 헬스 체크
  get "/health" do
    json_response(conn, 200, %{
      status: "healthy",
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601(),
      uptime: System.system_time(:second)
    })
  end

  # POST /api/echo - JSON 에코
  post "/echo" do
    json_response(conn, 200, %{
      received: conn.body_params,
      method: conn.method,
      path: conn.request_path
    })
  end

  # 404
  match _ do
    json_response(conn, 404, %{error: "API endpoint not found"})
  end

  # ========================================
  # 데이터 관리 함수 (간단한 메모리 저장소)
  # ========================================

  defp get_users do
    # 기본 사용자 데이터
    default_users = [
      %{id: 1, name: "Kim", email: "kim@example.com", created_at: "2024-01-01"},
      %{id: 2, name: "Lee", email: "lee@example.com", created_at: "2024-01-02"},
      %{id: 3, name: "Park", email: "park@example.com", created_at: "2024-01-03"}
    ]

    case Process.whereis(@users_agent) do
      nil ->
        # Agent가 없으면 기본 데이터 반환
        default_users
      _pid ->
        Agent.get(@users_agent, & &1)
    end
  end

  defp find_user(id) do
    get_users() |> Enum.find(&(&1.id == id))
  end

  defp create_user(name, email) do
    ensure_agent_started()

    new_id = get_users() |> Enum.map(& &1.id) |> Enum.max(fn -> 0 end) |> Kernel.+(1)
    new_user = %{
      id: new_id,
      name: name,
      email: email,
      created_at: DateTime.utc_now() |> DateTime.to_iso8601()
    }

    Agent.update(@users_agent, fn users -> users ++ [new_user] end)
    new_user
  end

  defp delete_user(id) do
    ensure_agent_started()

    case find_user(id) do
      nil ->
        :not_found
      _ ->
        Agent.update(@users_agent, fn users ->
          Enum.reject(users, &(&1.id == id))
        end)
        :ok
    end
  end

  defp ensure_agent_started do
    case Process.whereis(@users_agent) do
      nil ->
        default_users = [
          %{id: 1, name: "Kim", email: "kim@example.com", created_at: "2024-01-01"},
          %{id: 2, name: "Lee", email: "lee@example.com", created_at: "2024-01-02"},
          %{id: 3, name: "Park", email: "park@example.com", created_at: "2024-01-03"}
        ]
        {:ok, _} = Agent.start_link(fn -> default_users end, name: @users_agent)
      _ ->
        :ok
    end
  end

  # ========================================
  # 헬퍼 함수
  # ========================================

  defp json_response(conn, status, data) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(status, Jason.encode!(data, pretty: true))
  end
end
