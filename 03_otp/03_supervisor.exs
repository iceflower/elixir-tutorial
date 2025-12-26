# ===========================================
# 03. Supervisor (감독자)
# ===========================================

# Supervisor는 자식 프로세스를 감시하고 장애 시 재시작합니다.
# "Let it crash" 철학: 에러가 발생하면 프로세스를 재시작하는 게 낫다.

# -------------------------------------------
# 기본 Worker 정의
# -------------------------------------------

defmodule Worker do
  use GenServer

  def start_link(name) do
    IO.puts("[Worker] #{name} 시작 중...")
    GenServer.start_link(__MODULE__, name, name: via_tuple(name))
  end

  def get_name(name) do
    GenServer.call(via_tuple(name), :get_name)
  end

  def crash(name) do
    GenServer.cast(via_tuple(name), :crash)
  end

  defp via_tuple(name), do: {:via, Registry, {WorkerRegistry, name}}

  # 콜백
  @impl true
  def init(name) do
    IO.puts("[Worker] #{name} 초기화 완료")
    {:ok, %{name: name, started_at: DateTime.utc_now()}}
  end

  @impl true
  def handle_call(:get_name, _from, state) do
    {:reply, state.name, state}
  end

  @impl true
  def handle_cast(:crash, state) do
    IO.puts("[Worker] #{state.name} 크래시!")
    raise "의도적 크래시"
  end

  @impl true
  def terminate(reason, state) do
    IO.puts("[Worker] #{state.name} 종료: #{inspect(reason)}")
  end
end

# -------------------------------------------
# Supervisor 정의 (모듈 기반)
# -------------------------------------------

defmodule MySupervisor do
  use Supervisor

  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    children = [
      # Registry 먼저 시작 (Worker가 사용)
      {Registry, keys: :unique, name: WorkerRegistry},
      # Worker들
      {Worker, "worker_1"},
      {Worker, "worker_2"},
      {Worker, "worker_3"}
    ]

    # :one_for_one - 하나 죽으면 그것만 재시작
    Supervisor.init(children, strategy: :one_for_one)
  end
end

# -------------------------------------------
# Supervisor 실행
# -------------------------------------------

IO.puts("=== Supervisor 시작 ===\n")

{:ok, sup_pid} = MySupervisor.start_link([])

Process.sleep(100)

IO.puts("\n=== Worker 상태 확인 ===")
IO.puts("Worker 1: #{Worker.get_name("worker_1")}")
IO.puts("Worker 2: #{Worker.get_name("worker_2")}")
IO.puts("Worker 3: #{Worker.get_name("worker_3")}")

IO.puts("\n=== Worker 1 크래시 ===")
Worker.crash("worker_1")

Process.sleep(200)

IO.puts("\n=== 크래시 후 상태 확인 ===")
IO.puts("Worker 1 (재시작됨): #{Worker.get_name("worker_1")}")
IO.puts("Worker 2 (영향 없음): #{Worker.get_name("worker_2")}")

# 자식 프로세스 목록
IO.puts("\n=== Supervisor 자식 목록 ===")
children = Supervisor.which_children(MySupervisor)
Enum.each(children, fn {id, pid, type, _modules} ->
  IO.puts("  #{inspect(id)} - #{inspect(pid)} (#{type})")
end)

Supervisor.stop(MySupervisor)
Process.sleep(100)

# -------------------------------------------
# 재시작 전략
# -------------------------------------------

IO.puts("\n=== 재시작 전략 ===")

IO.puts("""
1. :one_for_one
   - 하나가 죽으면 그것만 재시작
   - 자식들이 독립적일 때 사용

2. :one_for_all
   - 하나가 죽으면 모두 재시작
   - 자식들이 서로 의존할 때 사용

3. :rest_for_one
   - 하나가 죽으면 그 이후 시작된 것들도 재시작
   - 시작 순서에 의존성이 있을 때 사용
""")

# -------------------------------------------
# 동적 Supervisor
# -------------------------------------------

IO.puts("=== DynamicSupervisor ===\n")

defmodule DynamicWorker do
  use GenServer

  def start_link(id) do
    GenServer.start_link(__MODULE__, id, name: {:global, {:worker, id}})
  end

  def get_id(id) do
    GenServer.call({:global, {:worker, id}}, :get_id)
  end

  @impl true
  def init(id) do
    IO.puts("[DynamicWorker] #{id} 시작됨")
    {:ok, %{id: id}}
  end

  @impl true
  def handle_call(:get_id, _from, state) do
    {:reply, state.id, state}
  end
end

# DynamicSupervisor 시작
{:ok, dynamic_sup} = DynamicSupervisor.start_link(
  strategy: :one_for_one,
  name: MyDynamicSupervisor
)

# 동적으로 자식 추가
{:ok, _} = DynamicSupervisor.start_child(MyDynamicSupervisor, {DynamicWorker, "dyn_1"})
{:ok, _} = DynamicSupervisor.start_child(MyDynamicSupervisor, {DynamicWorker, "dyn_2"})
{:ok, pid3} = DynamicSupervisor.start_child(MyDynamicSupervisor, {DynamicWorker, "dyn_3"})

Process.sleep(50)

IO.puts("\n동적 Worker 확인:")
IO.puts("dyn_1: #{DynamicWorker.get_id("dyn_1")}")
IO.puts("dyn_2: #{DynamicWorker.get_id("dyn_2")}")
IO.puts("dyn_3: #{DynamicWorker.get_id("dyn_3")}")

# 자식 제거
DynamicSupervisor.terminate_child(MyDynamicSupervisor, pid3)
IO.puts("\ndyn_3 종료됨")

IO.puts("현재 자식 수: #{DynamicSupervisor.count_children(MyDynamicSupervisor).active}")

DynamicSupervisor.stop(MyDynamicSupervisor)

# -------------------------------------------
# Application 구조
# -------------------------------------------

IO.puts("\n=== Application 구조 예시 ===")

IO.puts("""
mix.exs:
  def application do
    [
      mod: {MyApp.Application, []},
      extra_applications: [:logger]
    ]
  end

lib/my_app/application.ex:
  defmodule MyApp.Application do
    use Application

    def start(_type, _args) do
      children = [
        MyApp.Repo,
        MyAppWeb.Endpoint,
        {MyApp.Scheduler, []}
      ]

      opts = [strategy: :one_for_one, name: MyApp.Supervisor]
      Supervisor.start_link(children, opts)
    end
  end

Supervision Tree:
  MyApp.Supervisor
  ├── MyApp.Repo (Ecto)
  ├── MyAppWeb.Endpoint (Phoenix)
  └── MyApp.Scheduler (작업 스케줄러)
""")

# -------------------------------------------
# child_spec 커스터마이징
# -------------------------------------------

IO.puts("=== child_spec ===")

defmodule CustomWorker do
  use GenServer

  def start_link(arg) do
    GenServer.start_link(__MODULE__, arg)
  end

  # child_spec 커스터마이징
  def child_spec(arg) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [arg]},
      restart: :transient,  # 비정상 종료 시에만 재시작
      shutdown: 5000,       # 종료 대기 시간 (ms)
      type: :worker
    }
  end

  @impl true
  def init(arg) do
    {:ok, arg}
  end
end

IO.puts("""
restart 옵션:
  :permanent - 항상 재시작 (기본값)
  :temporary - 절대 재시작 안 함
  :transient - 비정상 종료 시에만 재시작

shutdown 옵션:
  :brutal_kill - 즉시 종료
  timeout (ms) - 대기 후 강제 종료
  :infinity - 무한 대기

type 옵션:
  :worker - 일반 워커
  :supervisor - 감독자
""")

# ============================================
# 실습: 작업 처리 시스템
# ============================================

# TODO: 작업 처리 시스템 만들기
# 1. JobProcessor GenServer - 작업 처리
# 2. JobQueue GenServer - 작업 대기열 관리
# 3. JobSupervisor - 위 두 개 감독
# 4. 작업 실패 시 재시작되어 복구
