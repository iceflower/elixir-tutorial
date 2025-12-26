defmodule PlugServer.Router do
  @moduledoc """
  메인 라우터
  Plug.Router를 사용하여 요청을 라우팅합니다.
  """
  use Plug.Router
  use Plug.ErrorHandler

  # ========================================
  # Plug 파이프라인
  # ========================================

  # 로깅
  plug Plug.Logger

  # URL 경로 매칭
  plug :match

  # JSON 파싱 (POST 요청용)
  plug Plug.Parsers,
    parsers: [:json],
    pass: ["application/json"],
    json_decoder: Jason

  # 매칭된 라우트 실행
  plug :dispatch

  # ========================================
  # 라우트 정의
  # ========================================

  # 홈
  get "/" do
    html = """
    <!DOCTYPE html>
    <html>
    <head>
      <title>Plug Server</title>
      <style>
        body { font-family: system-ui; max-width: 800px; margin: 50px auto; padding: 20px; }
        h1 { color: #6B46C1; }
        code { background: #f0f0f0; padding: 2px 6px; border-radius: 4px; }
        ul { line-height: 2; }
      </style>
    </head>
    <body>
      <h1>🔌 Plug Server에 오신 것을 환영합니다!</h1>
      <p>이 서버는 Elixir Plug로 만들어졌습니다.</p>

      <h2>사용 가능한 엔드포인트:</h2>
      <ul>
        <li><code>GET /hello/:name</code> - 이름으로 인사</li>
        <li><code>GET /api/users</code> - 사용자 목록</li>
        <li><code>POST /api/users</code> - 사용자 생성</li>
        <li><code>GET /api/users/:id</code> - 사용자 조회</li>
      </ul>

      <h2>예시:</h2>
      <ul>
        <li><a href="/hello/World">/hello/World</a></li>
        <li><a href="/api/users">/api/users</a></li>
      </ul>
    </body>
    </html>
    """

    conn
    |> put_resp_content_type("text/html")
    |> send_resp(200, html)
  end

  # 인사 - 경로 파라미터
  get "/hello/:name" do
    message = "안녕하세요, #{name}님! 👋"

    conn
    |> put_resp_content_type("text/plain; charset=utf-8")
    |> send_resp(200, message)
  end

  # API 라우트 - 하위 라우터로 위임
  forward "/api", to: PlugServer.ApiRouter

  # 정적 페이지
  get "/about" do
    json_response(conn, 200, %{
      name: "Plug Server Tutorial",
      version: "0.1.0",
      elixir_version: System.version()
    })
  end

  # 에코 - 쿼리 파라미터 사용
  get "/echo" do
    conn = fetch_query_params(conn)
    params = conn.query_params

    json_response(conn, 200, %{
      message: "쿼리 파라미터를 에코합니다",
      params: params
    })
  end

  # 404 처리
  match _ do
    json_response(conn, 404, %{error: "Not Found", path: conn.request_path})
  end

  # ========================================
  # 헬퍼 함수
  # ========================================

  defp json_response(conn, status, data) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(status, Jason.encode!(data))
  end

  # 에러 핸들러
  @impl Plug.ErrorHandler
  def handle_errors(conn, %{kind: _kind, reason: reason, stack: _stack}) do
    message = case reason do
      %{message: msg} -> msg
      _ -> "Internal Server Error"
    end

    json_response(conn, conn.status, %{error: message})
  end
end
