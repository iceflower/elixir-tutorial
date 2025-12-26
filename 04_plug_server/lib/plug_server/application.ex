defmodule PlugServer.Application do
  @moduledoc """
  Plug 서버 애플리케이션
  """
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Cowboy 웹서버 시작
      {Plug.Cowboy, scheme: :http, plug: PlugServer.Router, options: [port: 4000]}
    ]

    opts = [strategy: :one_for_one, name: PlugServer.Supervisor]

    IO.puts("""

    ========================================
    🚀 Plug Server 시작됨!
    ----------------------------------------
    URL: http://localhost:4000
    ----------------------------------------
    엔드포인트:
      GET  /              환영 메시지
      GET  /hello/:name   인사
      GET  /api/users     사용자 목록
      POST /api/users     사용자 생성
      GET  /api/users/:id 사용자 조회
    ========================================
    """)

    Supervisor.start_link(children, opts)
  end
end
