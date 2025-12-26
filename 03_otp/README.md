# 03. OTP (Open Telecom Platform)

> **2025년 12월 기준** - Elixir 1.18, OTP 27

## 목차

1. [OTP 소개](#otp-소개)
2. [프로세스](#프로세스)
3. [메시지 전달](#메시지-전달)
4. [GenServer](#genserver)
5. [Supervisor](#supervisor)
6. [Application](#application)
7. [Task와 Agent](#task와-agent)
8. [Registry](#registry)
9. [PartitionSupervisor](#partitionsupervisor)

---

## OTP 소개

OTP는 동시성, 분산 시스템을 구축하기 위한 라이브러리와 설계 원칙입니다.

### 핵심 철학: "Let it crash"

- 에러를 예방하려 하지 말고, 에러가 발생하면 프로세스를 재시작
- Supervisor가 자식 프로세스를 감시하고 재시작
- 시스템 전체는 항상 안정적으로 유지

### OTP 컴포넌트

```text
Application
└── Supervisor (감독자)
    ├── GenServer (상태 있는 서버)
    ├── GenServer
    └── Supervisor
        ├── Worker
        └── Worker
```

---

## 프로세스

Elixir 프로세스는 **경량 프로세스**로, OS 스레드와 다릅니다.

### 특징

| 특성 | Elixir 프로세스 | OS 스레드 |
|------|----------------|----------|
| 메모리 | ~2KB | ~1MB |
| 생성 가능 수 | 수백만 개 | 수천 개 |
| 메모리 공유 | 없음 (격리) | 있음 |
| 통신 방식 | 메시지 패싱 | 공유 메모리 |
| GC | 프로세스별 | 전체 |

### 기본 사용

```elixir
# 현재 프로세스 ID
self()  # #PID<0.123.0>

# 새 프로세스 생성
pid = spawn(fn ->
  IO.puts("새 프로세스에서 실행!")
end)

# 프로세스 정보
Process.alive?(pid)  # false (이미 종료)
Process.info(self(), :memory)
Process.info(self(), :message_queue_len)

# 프로세스 종료
Process.exit(pid, :normal)
Process.exit(pid, :kill)  # 강제 종료
```

### spawn 변형

```elixir
# spawn - 독립 프로세스
pid = spawn(fn -> ... end)

# spawn_link - 연결된 프로세스 (한쪽이 죽으면 다른 쪽도)
pid = spawn_link(fn -> ... end)

# spawn_monitor - 모니터링 (죽으면 알림 받음)
{pid, ref} = spawn_monitor(fn -> ... end)

# 모니터 메시지 수신
receive do
  {:DOWN, ^ref, :process, ^pid, reason} ->
    IO.puts("프로세스 종료: #{inspect(reason)}")
end
```

### 프로세스 딕셔너리 (주의해서 사용)

```elixir
Process.put(:key, "value")
Process.get(:key)  # "value"
Process.delete(:key)
```

---

## 메시지 전달

프로세스 간 통신은 **메시지 전달**로만 가능합니다.

### send와 receive

```elixir
# 메시지 보내기
send(pid, {:hello, "World"})

# 메시지 받기
receive do
  {:hello, name} ->
    IO.puts("Hello, #{name}!")
  {:error, reason} ->
    IO.puts("Error: #{reason}")
after
  5000 ->
    IO.puts("5초 타임아웃")
end
```

### 프로세스 간 통신 예제

```elixir
parent = self()

# 자식 프로세스 생성
child = spawn(fn ->
  receive do
    {:ping, from} ->
      IO.puts("Ping 받음!")
      send(from, :pong)
  end
end)

# 메시지 교환
send(child, {:ping, parent})

receive do
  :pong -> IO.puts("Pong 받음!")
end
```

### 선택적 수신

```elixir
# 특정 메시지만 먼저 처리
receive do
  {:urgent, msg} -> handle_urgent(msg)
after
  0 -> :no_urgent  # 즉시 반환
end

# 나머지 메시지 처리
receive do
  msg -> handle_normal(msg)
end
```

---

## GenServer

GenServer는 **상태를 가진 서버 프로세스**를 구현하는 표준 패턴입니다.

### 기본 구조

```elixir
defmodule Counter do
  use GenServer

  # =========== 클라이언트 API ===========

  def start_link(initial \\ 0) do
    GenServer.start_link(__MODULE__, initial, name: __MODULE__)
  end

  def get do
    GenServer.call(__MODULE__, :get)
  end

  def increment do
    GenServer.call(__MODULE__, :increment)
  end

  def add(n) do
    GenServer.cast(__MODULE__, {:add, n})
  end

  def reset do
    GenServer.call(__MODULE__, :reset)
  end

  # =========== 서버 콜백 ===========

  @impl true
  def init(initial) do
    {:ok, initial}
  end

  @impl true
  def handle_call(:get, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_call(:increment, _from, state) do
    new_state = state + 1
    {:reply, new_state, new_state}
  end

  @impl true
  def handle_call(:reset, _from, _state) do
    {:reply, :ok, 0}
  end

  @impl true
  def handle_cast({:add, n}, state) do
    {:noreply, state + n}
  end
end
```

### 사용

```elixir
{:ok, _pid} = Counter.start_link(0)
Counter.get()        # 0
Counter.increment()  # 1
Counter.add(10)      # 비동기
Counter.get()        # 11
Counter.reset()      # :ok
Counter.get()        # 0
```

### call vs cast

| | `call` | `cast` |
|---|--------|--------|
| 동기/비동기 | 동기 (응답 대기) | 비동기 (응답 없음) |
| 반환값 | `{:reply, reply, state}` | `{:noreply, state}` |
| 용도 | 값 조회, 중요한 작업 | 단순 업데이트, 알림 |
| 타임아웃 | 기본 5초 | 없음 |

### handle_info

`send/2`로 보낸 일반 메시지 처리:

```elixir
@impl true
def handle_info(:cleanup, state) do
  # 정리 작업
  {:noreply, state}
end

@impl true
def handle_info({:DOWN, ref, :process, pid, reason}, state) do
  # 모니터링 중인 프로세스 종료 알림
  {:noreply, state}
end

@impl true
def handle_info(msg, state) do
  # 알 수 없는 메시지 처리 (로깅 등)
  require Logger
  Logger.warning("Unknown message: #{inspect(msg)}")
  {:noreply, state}
end
```

### 주기적 작업

```elixir
@impl true
def init(state) do
  # 1초마다 :tick 메시지
  :timer.send_interval(1000, :tick)
  {:ok, state}
end

# 또는 Process.send_after 사용
@impl true
def init(state) do
  schedule_tick()
  {:ok, state}
end

@impl true
def handle_info(:tick, state) do
  # 작업 수행
  schedule_tick()
  {:noreply, state}
end

defp schedule_tick do
  Process.send_after(self(), :tick, 1000)
end
```

### continue 콜백 (1.7+)

긴 초기화를 나누어 처리:

```elixir
@impl true
def init(args) do
  {:ok, initial_state, {:continue, :load_data}}
end

@impl true
def handle_continue(:load_data, state) do
  # 시간이 오래 걸리는 초기화
  data = load_from_database()
  {:noreply, %{state | data: data}}
end
```

### 상태 초기화 옵션

```elixir
def init(args) do
  {:ok, state}                          # 정상 시작
  {:ok, state, {:continue, term}}       # continue 콜백 호출
  {:ok, state, timeout}                 # 타임아웃 후 handle_info(:timeout, ...) 호출
  {:ok, state, :hibernate}              # 메모리 최적화 (대기 상태)
  :ignore                               # 시작하지 않음
  {:stop, reason}                       # 시작 실패
end
```

---

## Supervisor

Supervisor는 자식 프로세스를 **감시하고 재시작**합니다.

### 기본 구조

```elixir
defmodule MyApp.Supervisor do
  use Supervisor

  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    children = [
      {Counter, 0},
      {KVStore, []},
      {MyWorker, []}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
```

### 재시작 전략

```elixir
# :one_for_one - 죽은 것만 재시작
# 자식들이 독립적일 때
Supervisor.init(children, strategy: :one_for_one)

# :one_for_all - 하나 죽으면 모두 재시작
# 자식들이 서로 의존할 때
Supervisor.init(children, strategy: :one_for_all)

# :rest_for_one - 죽은 것 + 이후 시작된 것들 재시작
# 시작 순서에 의존성이 있을 때
Supervisor.init(children, strategy: :rest_for_one)
```

### child_spec

```elixir
defmodule MyWorker do
  use GenServer

  def child_spec(arg) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [arg]},
      restart: :permanent,    # 항상 재시작
      shutdown: 5000,         # 종료 대기 시간 (ms)
      type: :worker
    }
  end

  def start_link(arg) do
    GenServer.start_link(__MODULE__, arg)
  end
end
```

restart 옵션:
- `:permanent` - 항상 재시작 (기본값)
- `:temporary` - 재시작 안 함
- `:transient` - 비정상 종료 시에만 재시작

shutdown 옵션:
- `:brutal_kill` - 즉시 종료
- `5000` - 5초 대기 후 강제 종료
- `:infinity` - 무한 대기 (Supervisor에 권장)

### 재시작 제한

```elixir
Supervisor.init(children,
  strategy: :one_for_one,
  max_restarts: 3,      # 최대 재시작 횟수
  max_seconds: 5        # 시간 윈도우 (초)
)
# 5초 내 3번 이상 재시작하면 Supervisor도 종료
```

### DynamicSupervisor

동적으로 자식 추가/제거:

```elixir
defmodule MyApp.WorkerSupervisor do
  use DynamicSupervisor

  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  def start_worker(args) do
    DynamicSupervisor.start_child(__MODULE__, {Worker, args})
  end

  def stop_worker(pid) do
    DynamicSupervisor.terminate_child(__MODULE__, pid)
  end

  @impl true
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end

# 사용
{:ok, pid} = MyApp.WorkerSupervisor.start_worker(args)
DynamicSupervisor.count_children(MyApp.WorkerSupervisor)
# %{active: 1, specs: 1, supervisors: 0, workers: 1}
```

---

## Application

Application은 **시작점**이자 **설정 컨테이너**입니다.

### 구조

```elixir
# lib/my_app/application.ex
defmodule MyApp.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      MyApp.Repo,
      {Phoenix.PubSub, name: MyApp.PubSub},
      MyAppWeb.Endpoint,
      {MyApp.Scheduler, []}
    ]

    opts = [strategy: :one_for_one, name: MyApp.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # 애플리케이션 종료 전 콜백
  @impl true
  def stop(_state) do
    :ok
  end
end
```

### mix.exs 설정

```elixir
def application do
  [
    mod: {MyApp.Application, []},
    extra_applications: [:logger, :runtime_tools]
  ]
end
```

### 설정 읽기

```elixir
# config/config.exs
config :my_app,
  api_key: "secret",
  timeout: 5000

# 읽기
Application.get_env(:my_app, :api_key)
Application.get_env(:my_app, :missing, "default")
Application.fetch_env!(:my_app, :api_key)  # 없으면 에러

# 런타임에 설정 (권장하지 않음)
Application.put_env(:my_app, :key, "value")
```

### Supervision Tree

```text
MyApp.Supervisor
├── MyApp.Repo
├── Phoenix.PubSub
├── MyAppWeb.Endpoint
│   ├── Phoenix.PubSub
│   └── Phoenix.Endpoint.Server
└── MyApp.Scheduler
```

---

## Task와 Agent

간단한 동시성 작업을 위한 고수준 추상화입니다.

### Task

비동기 작업 실행:

```elixir
# async/await
task = Task.async(fn ->
  # 무거운 작업
  Process.sleep(1000)
  "결과"
end)

# 다른 작업 수행...

result = Task.await(task)  # "결과" (기본 5초 타임아웃)
result = Task.await(task, 10_000)  # 10초 타임아웃

# 여러 Task 병렬 실행
tasks = for url <- urls do
  Task.async(fn -> fetch(url) end)
end
results = Task.await_many(tasks)

# fire-and-forget (결과 무시)
Task.start(fn ->
  send_email(user)
end)

# 타임아웃과 함께
case Task.yield(task, 5000) do
  {:ok, result} -> result
  nil ->
    Task.shutdown(task)
    :timeout
end

# 실패해도 계속 진행
Task.yield_many(tasks, timeout: 5000)
|> Enum.map(fn {task, res} ->
  res || Task.shutdown(task, :brutal_kill)
end)
```

### Task.Supervisor (권장)

프로덕션에서는 Task.Supervisor 사용:

```elixir
# Application에 추가
children = [
  {Task.Supervisor, name: MyApp.TaskSupervisor}
]

# 사용
Task.Supervisor.start_child(MyApp.TaskSupervisor, fn ->
  send_email(user)
end)

# async/await
task = Task.Supervisor.async(MyApp.TaskSupervisor, fn ->
  fetch_data()
end)
Task.await(task)
```

### Agent

간단한 상태 관리:

```elixir
# 시작
{:ok, agent} = Agent.start_link(fn -> [] end)
{:ok, agent} = Agent.start_link(fn -> [] end, name: :my_agent)

# 상태 조회
Agent.get(agent, fn list -> list end)
Agent.get(agent, & &1)  # 축약

# 상태 업데이트
Agent.update(agent, fn list -> ["new" | list] end)

# 조회 + 업데이트
Agent.get_and_update(agent, fn [head | tail] ->
  {head, tail}
end)

# 비동기 업데이트
Agent.cast(agent, fn list -> ["async" | list] end)

# 종료
Agent.stop(agent)
```

---

## Registry

프로세스 이름 관리와 검색:

### 기본 사용

```elixir
# Application에 추가
children = [
  {Registry, keys: :unique, name: MyApp.Registry}
]

# GenServer에서 via_tuple 사용
defmodule Worker do
  use GenServer

  def start_link(id) do
    GenServer.start_link(__MODULE__, id, name: via_tuple(id))
  end

  def get(id) do
    GenServer.call(via_tuple(id), :get)
  end

  defp via_tuple(id) do
    {:via, Registry, {MyApp.Registry, id}}
  end

  # ... 콜백들
end

# 사용
Worker.start_link("user:123")
Worker.get("user:123")

# 조회
Registry.lookup(MyApp.Registry, "user:123")  # [{pid, nil}]
```

### 중복 키 Registry (PubSub 패턴)

```elixir
# 설정
{Registry, keys: :duplicate, name: MyApp.PubSub}

# 구독
Registry.register(MyApp.PubSub, "topic:news", [])

# 발행
Registry.dispatch(MyApp.PubSub, "topic:news", fn entries ->
  for {pid, _value} <- entries do
    send(pid, {:news, "새 뉴스!"})
  end
end)
```

---

## PartitionSupervisor

멀티코어 활용을 위한 파티션된 Supervisor (1.14+):

```elixir
# Application에 추가
children = [
  {PartitionSupervisor,
    child_spec: DynamicSupervisor,
    name: MyApp.DynamicSupervisors}
]

# 사용 - 자동으로 파티션 선택
DynamicSupervisor.start_child(
  {:via, PartitionSupervisor, {MyApp.DynamicSupervisors, self()}},
  {Worker, args}
)

# 파티션 수 확인 (기본: System.schedulers_online)
PartitionSupervisor.count(MyApp.DynamicSupervisors)
```

---

## 실전 패턴

### 상태 초기화가 긴 경우

```elixir
@impl true
def init(_args) do
  # 빈 상태로 빠르게 시작
  {:ok, %{data: nil}, {:continue, :load}}
end

@impl true
def handle_continue(:load, state) do
  # 무거운 초기화
  data = load_from_database()
  {:noreply, %{state | data: data}}
end
```

### Graceful Shutdown

```elixir
@impl true
def init(args) do
  Process.flag(:trap_exit, true)  # EXIT 신호를 메시지로 받음
  {:ok, state}
end

@impl true
def terminate(reason, state) do
  # 정리 작업 (DB 연결 닫기 등)
  save_state(state)
  :ok
end
```

### 상태 영속화

```elixir
defmodule PersistentCounter do
  use GenServer

  def init(_) do
    state = load_from_disk() || 0
    {:ok, state}
  end

  def handle_call(:increment, _from, state) do
    new_state = state + 1
    save_to_disk(new_state)
    {:reply, new_state, new_state}
  end

  defp load_from_disk do
    case File.read("counter.txt") do
      {:ok, data} -> String.to_integer(String.trim(data))
      _ -> nil
    end
  end

  defp save_to_disk(value) do
    File.write!("counter.txt", to_string(value))
  end
end
```

---

## 연습 문제

### 1. 은행 계좌 GenServer
- 입금, 출금, 잔액 조회
- 잔액 부족 시 에러 반환
- 거래 내역 저장

### 2. 작업 큐
- 작업 추가, 처리
- Supervisor로 워커 관리
- 실패한 작업 재시도

### 3. 채팅 서버
- 사용자 접속/퇴장
- 메시지 브로드캐스트
- Registry로 사용자 관리

---

## 다음 단계

[04. Plug 웹서버](../04_plug_server/README.md)에서 웹 애플리케이션 기초를 학습합니다.
