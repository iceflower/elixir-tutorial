# 03. OTP (Open Telecom Platform)

## 목차

1. [OTP 소개](#otp-소개)
2. [프로세스](#프로세스)
3. [메시지 전달](#메시지-전달)
4. [GenServer](#genserver)
5. [Supervisor](#supervisor)
6. [Application](#application)
7. [Task와 Agent](#task와-agent)

---

## OTP 소개

OTP는 동시성, 분산 시스템을 구축하기 위한 라이브러리와 설계 원칙입니다.

### 핵심 철학: "Let it crash"

- 에러를 예방하려 하지 말고, 에러가 발생하면 프로세스를 재시작
- Supervisor가 자식 프로세스를 감시하고 재시작
- 시스템 전체는 항상 안정적으로 유지

### OTP 컴포넌트

```
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
```

### spawn 변형

```elixir
# spawn - 독립 프로세스
pid = spawn(fn -> ... end)

# spawn_link - 연결된 프로세스 (한쪽이 죽으면 다른 쪽도)
pid = spawn_link(fn -> ... end)

# spawn_monitor - 모니터링 (죽으면 알림 받음)
{pid, ref} = spawn_monitor(fn -> ... end)
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

---

## GenServer

GenServer는 **상태를 가진 서버 프로세스**를 구현하는 표준 패턴입니다.

### 기본 구조

```elixir
defmodule Counter do
  use GenServer

  # =========== 클라이언트 API ===========

  def start_link(initial) do
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
```

### call vs cast

| | `call` | `cast` |
|---|--------|--------|
| 동기/비동기 | 동기 (응답 대기) | 비동기 (응답 없음) |
| 반환값 | `{:reply, reply, state}` | `{:noreply, state}` |
| 용도 | 값 조회, 중요한 작업 | 단순 업데이트, 알림 |

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
```

### 주기적 작업

```elixir
def init(state) do
  # 1초마다 :tick 메시지
  :timer.send_interval(1000, :tick)
  {:ok, state}
end

def handle_info(:tick, state) do
  # 매초 실행
  {:noreply, state}
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
      shutdown: 5000,         # 종료 대기 시간
      type: :worker
    }
  end
end
```

restart 옵션:
- `:permanent` - 항상 재시작 (기본값)
- `:temporary` - 재시작 안 함
- `:transient` - 비정상 종료 시에만 재시작

### DynamicSupervisor

동적으로 자식 추가/제거:

```elixir
# 시작
{:ok, sup} = DynamicSupervisor.start_link(strategy: :one_for_one)

# 자식 추가
DynamicSupervisor.start_child(sup, {Worker, arg})

# 자식 제거
DynamicSupervisor.terminate_child(sup, pid)

# 자식 수
DynamicSupervisor.count_children(sup)
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
      MyAppWeb.Endpoint,
      {MyApp.Scheduler, []}
    ]

    opts = [strategy: :one_for_one, name: MyApp.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
```

### mix.exs 설정

```elixir
def application do
  [
    mod: {MyApp.Application, []},
    extra_applications: [:logger]
  ]
end
```

### Supervision Tree

```
MyApp.Supervisor
├── MyApp.Repo
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

result = Task.await(task)  # "결과"

# 여러 Task 병렬 실행
tasks = for url <- urls do
  Task.async(fn -> fetch(url) end)
end
results = Task.await_many(tasks)

# fire-and-forget
Task.start(fn ->
  send_email(user)
end)
```

### Agent

간단한 상태 관리:

```elixir
# 시작
{:ok, agent} = Agent.start_link(fn -> [] end)

# 상태 조회
Agent.get(agent, fn list -> list end)

# 상태 업데이트
Agent.update(agent, fn list -> ["new" | list] end)

# 조회 + 업데이트
Agent.get_and_update(agent, fn [head | tail] ->
  {head, tail}
end)

# 종료
Agent.stop(agent)
```

---

## 실전 패턴

### Registry로 프로세스 이름 관리

```elixir
# 시작 시 Registry 추가
children = [
  {Registry, keys: :unique, name: MyApp.Registry},
  {DynamicSupervisor, name: MyApp.WorkerSupervisor}
]

# via_tuple로 이름 지정
def start_link(id) do
  GenServer.start_link(__MODULE__, id, name: via_tuple(id))
end

defp via_tuple(id) do
  {:via, Registry, {MyApp.Registry, id}}
end

# 조회
GenServer.call(via_tuple("user:123"), :get)
```

### 프로세스 풀

```elixir
# Poolboy 사용
:poolboy.transaction(:worker_pool, fn pid ->
  Worker.do_work(pid, task)
end)
```

---

## 연습 문제

### 1. 은행 계좌 GenServer
- 입금, 출금, 잔액 조회
- 잔액 부족 시 에러 반환

### 2. 작업 큐
- 작업 추가, 처리
- Supervisor로 워커 관리

---

## 다음 단계

[04. Plug 웹서버](./04_plug.md)에서 웹 애플리케이션 기초를 학습합니다.
