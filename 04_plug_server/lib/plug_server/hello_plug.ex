defmodule PlugServer.HelloPlug do
  @moduledoc """
  모듈 Plug 예제

  Plug는 두 가지 형태로 사용할 수 있습니다:
  1. 함수 Plug - 단순한 경우
  2. 모듈 Plug - 설정이 필요하거나 재사용할 때

  모듈 Plug는 두 개의 콜백을 구현해야 합니다:
  - init/1: 컴파일 타임에 호출, 옵션 전처리
  - call/2: 런타임에 호출, 실제 요청 처리
  """

  import Plug.Conn

  @behaviour Plug

  @impl true
  def init(opts) do
    # 컴파일 타임에 실행됨
    # 옵션을 전처리하여 call/2로 전달
    greeting = Keyword.get(opts, :greeting, "Hello")
    %{greeting: greeting}
  end

  @impl true
  def call(conn, %{greeting: greeting}) do
    # 런타임에 실행됨
    name = conn.params["name"] || "World"

    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(200, "#{greeting}, #{name}!")
  end
end

# ==========================================
# Plug 파이프라인 예제
# ==========================================

defmodule PlugServer.ExamplePipeline do
  @moduledoc """
  Plug 파이프라인 예제

  여러 Plug를 순서대로 연결하여 요청을 처리합니다.
  """

  use Plug.Builder

  # 로깅 Plug
  plug :log_request

  # 인증 Plug (예시)
  plug :check_auth

  # 최종 응답
  plug :respond

  def log_request(conn, _opts) do
    IO.puts("[#{DateTime.utc_now()}] #{conn.method} #{conn.request_path}")
    conn
  end

  def check_auth(conn, _opts) do
    # 실제로는 토큰 검증 등을 수행
    case get_req_header(conn, "authorization") do
      ["Bearer " <> _token] ->
        conn
      _ ->
        # 인증 실패 시 여기서 응답하고 halt
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(401, Jason.encode!(%{error: "Unauthorized"}))
        |> halt()
    end
  end

  def respond(conn, _opts) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{message: "Success!"}))
  end
end

# ==========================================
# 커스텀 미들웨어 예제
# ==========================================

defmodule PlugServer.RequestIdPlug do
  @moduledoc """
  각 요청에 고유 ID를 부여하는 Plug
  """

  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    request_id = generate_request_id()

    conn
    |> put_resp_header("x-request-id", request_id)
    |> assign(:request_id, request_id)
  end

  defp generate_request_id do
    :crypto.strong_rand_bytes(8)
    |> Base.encode16(case: :lower)
  end
end

defmodule PlugServer.TimingPlug do
  @moduledoc """
  요청 처리 시간을 측정하는 Plug
  """

  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    start_time = System.monotonic_time(:microsecond)

    # 응답 전에 콜백 등록
    Plug.Conn.register_before_send(conn, fn conn ->
      end_time = System.monotonic_time(:microsecond)
      duration = end_time - start_time

      IO.puts("[Timing] #{conn.request_path} - #{duration}μs")

      put_resp_header(conn, "x-response-time", "#{duration}μs")
    end)
  end
end
