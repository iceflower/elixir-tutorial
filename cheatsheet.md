# Elixir 치트시트

빠른 참조를 위한 Elixir 핵심 문법 모음입니다.
**Elixir 1.18 / OTP 27 기준 (2025년 1월 업데이트)**

---

## 데이터 타입

```elixir
# 숫자
42              # 정수
3.14            # 실수
1_000_000       # 가독성 (= 1000000)
0xFF            # 16진수 (= 255)
0b1010          # 2진수 (= 10)
0o777           # 8진수 (= 511)

# 원자
:ok
:error
true            # = :true
false           # = :false
nil             # = :nil

# 문자열
"Hello"
"Hello, #{name}"    # 보간
"""
여러 줄
문자열
"""

# 문자 리스트 (1.18+)
~c"hello"           # 새로운 방식 (권장)
'hello'             # 기존 방식

# 리스트
[1, 2, 3]
[head | tail]       # 분해
[0 | list]          # 앞에 추가

# 튜플
{:ok, "value"}
{a, b} = {1, 2}

# 맵
%{key: "value"}
%{"key" => "value"}
map.key             # 접근 (원자 키)
map[:key]           # 접근 (모든 키)

# 키워드 리스트
[name: "Kim", age: 25]

# Range
1..10               # 1부터 10까지
1..10//2            # step 2 (1.12+)

# MapSet
MapSet.new([1, 2, 3])
```

---

## Sigils (시길)

```elixir
~s(문자열)              # 일반 문자열
~S(문자열)              # 이스케이프 없는 문자열
~c(charlist)           # 문자 리스트 (1.18+)
~C(charlist)           # 이스케이프 없는 문자 리스트
~w(foo bar baz)        # 단어 리스트 ["foo", "bar", "baz"]
~w(foo bar baz)a       # 원자 리스트 [:foo, :bar, :baz]
~r/패턴/               # 정규식
~D[2025-01-01]         # Date
~T[12:30:00]           # Time
~U[2025-01-01 12:30:00Z]  # DateTime (UTC)
~N[2025-01-01 12:30:00]   # NaiveDateTime
```

---

## 연산자

```elixir
# 산술
+ - * /
div(10, 3)    # 정수 나눗셈 = 3
rem(10, 3)    # 나머지 = 1

# 비교
== != > < >= <=
===           # 타입도 비교 (1 === 1.0 # false)

# 논리
and or not    # boolean만
&& || !       # 모든 값

# 문자열
"a" <> "b"    # 연결

# 리스트
[1] ++ [2]    # [1, 2]
[1, 2] -- [1] # [2]
1 in [1, 2]   # true

# 파이프
|>            # 왼쪽 결과를 오른쪽 첫 인자로

# 매칭
=             # 패턴 매칭
^             # 핀 연산자 (재바인딩 방지)
```

---

## 패턴 매칭

```elixir
# 기본
x = 1
1 = x         # OK
^x = 1        # 핀 연산자 (재바인딩 방지)

# 튜플
{a, b} = {1, 2}
{:ok, result} = {:ok, "value"}

# 리스트
[h | t] = [1, 2, 3]      # h=1, t=[2,3]
[a, b | rest] = [1, 2, 3, 4]

# 맵
%{name: name} = %{name: "Kim", age: 25}
%{name: name, age: age} = user

# 구조체 (타입 매칭)
%User{name: name} = user

# 바이너리
<<a::8, b::8, rest::binary>> = <<1, 2, 3, 4>>

# 무시
{_, b} = {1, 2}
{_ignored, b} = {1, 2}  # 명시적 무시
```

---

## 제어 흐름

```elixir
# if
if condition do
  ...
else
  ...
end
result = if x > 0, do: "positive", else: "negative"

# unless
unless condition, do: ...

# cond
cond do
  x > 0 -> "positive"
  x < 0 -> "negative"
  true -> "zero"
end

# case
case value do
  {:ok, result} -> result
  {:error, _} -> "error"
  _ -> "default"
end

# case with guard
case value do
  x when is_integer(x) and x > 0 -> "positive int"
  x when is_integer(x) -> "non-positive int"
  _ -> "not an integer"
end

# with
with {:ok, a} <- func1(),
     {:ok, b} <- func2(a),
     true <- valid?(b) do
  {:ok, b}
else
  {:error, reason} -> {:error, reason}
  false -> {:error, :invalid}
end
```

---

## 함수

```elixir
# 익명 함수
add = fn a, b -> a + b end
add.(1, 2)                    # 호출 시 점 필요

# 축약 (캡처 연산자)
double = &(&1 * 2)
add = &(&1 + &2)

# 함수 캡처
upcase = &String.upcase/1
sort = &Enum.sort/1

# 명명 함수
def greet(name), do: "Hello, #{name}"

def greet(name, greeting \\ "Hello") do
  "#{greeting}, #{name}"
end

# 프라이빗
defp secret(), do: ...

# 가드
def abs(n) when n < 0, do: -n
def abs(n), do: n

# 다중 절
def process({:ok, v}), do: v
def process({:error, _}), do: nil

# @spec 타입 명세
@spec add(integer(), integer()) :: integer()
def add(a, b), do: a + b
```

---

## 모듈

```elixir
defmodule MyModule do
  @moduledoc "모듈 문서"
  @doc "함수 문서"

  @constant 42              # 모듈 상수
  @type my_type :: String.t() | nil  # 타입 정의

  def public_func, do: ...
  defp private_func, do: ...
end

# 구조체
defmodule User do
  @enforce_keys [:name]     # 필수 필드
  defstruct name: "", age: 0, active: true
end

user = %User{name: "Kim"}
%{user | age: 25}           # 업데이트

# 프로토콜
defprotocol Printable do
  @doc "문자열로 변환"
  def to_string(data)
end

defimpl Printable, for: User do
  def to_string(user), do: user.name
end

# Behaviour
defmodule MyBehaviour do
  @callback required_func(term()) :: term()
  @optional_callbacks optional_func: 1
end
```

---

## Enum (즉시 평가)

```elixir
Enum.map(list, fn x -> x * 2 end)
Enum.filter(list, &(&1 > 0))
Enum.reject(list, &(&1 < 0))
Enum.reduce(list, 0, &(&1 + &2))
Enum.reduce_while(list, 0, fn x, acc ->
  if x > 10, do: {:halt, acc}, else: {:cont, acc + x}
end)
Enum.find(list, &(&1 > 5))
Enum.find_index(list, &(&1 > 5))

Enum.sort(list)
Enum.sort_by(users, & &1.age)
Enum.sort_by(users, & &1.age, :desc)

Enum.take(list, 5)
Enum.drop(list, 5)
Enum.take_while(list, &(&1 < 5))
Enum.drop_while(list, &(&1 < 5))

Enum.any?(list, &(&1 > 0))
Enum.all?(list, &(&1 > 0))
Enum.member?(list, elem)

Enum.count(list)
Enum.sum(list)
Enum.product(list)
Enum.min(list)
Enum.max(list)

Enum.zip(list1, list2)
Enum.zip_with(list1, list2, fn a, b -> a + b end)
Enum.uniq(list)
Enum.uniq_by(list, &key_func/1)
Enum.group_by(list, &key_func/1)
Enum.frequencies(list)
Enum.frequencies_by(list, &key_func/1)

Enum.flat_map(list, fn x -> [x, x] end)
Enum.map_reduce(list, 0, fn x, acc -> {x * 2, acc + x} end)
Enum.chunk_every(list, 2)
Enum.chunk_by(list, &key_func/1)
Enum.slide(list, from, to)        # 1.13+
Enum.split_with(list, &(&1 > 0))
```

---

## Stream (지연 평가)

```elixir
Stream.map(enum, func)
Stream.filter(enum, func)
Stream.take(enum, n)
Stream.drop(enum, n)
Stream.reject(enum, func)

# 무한 스트림
Stream.iterate(0, &(&1 + 1))
Stream.cycle([:a, :b, :c])
Stream.repeatedly(fn -> :rand.uniform() end)
Stream.unfold(0, fn n -> {n, n + 1} end)

# 파일 스트림
File.stream!("data.txt")
|> Stream.map(&String.trim/1)
|> Stream.filter(&(&1 != ""))
|> Enum.to_list()

# 리소스 관리
Stream.resource(
  fn -> File.open!("file.txt") end,
  fn file ->
    case IO.read(file, :line) do
      :eof -> {:halt, file}
      line -> {[line], file}
    end
  end,
  fn file -> File.close(file) end
)
```

---

## 컴프리헨션

```elixir
for x <- 1..10, do: x * x
for x <- 1..10, rem(x, 2) == 0, do: x
for x <- 1..3, y <- 1..3, do: {x, y}

# into 옵션
for x <- 1..5, into: %{}, do: {x, x * x}
for <<c <- "hello">>, into: "", do: <<c + 1>>

# reduce 옵션 (1.8+)
for x <- 1..10, reduce: 0 do
  acc -> acc + x
end

# uniq 옵션 (1.8+)
for x <- [1, 2, 2, 3], uniq: true, do: x  # [1, 2, 3]
```

---

## 프로세스

```elixir
self()                      # 현재 PID
spawn(fn -> ... end)        # 새 프로세스
spawn_link(fn -> ... end)   # 연결된 프로세스 (크래시 전파)
spawn_monitor(fn -> ... end) # 모니터링 (크래시 알림)

send(pid, message)          # 메시지 전송 (비동기)
receive do
  {:msg, data} -> handle(data)
  pattern -> ...
after
  1000 -> :timeout          # 타임아웃 (ms)
end

Process.alive?(pid)
Process.link(pid)
Process.monitor(pid)
Process.exit(pid, :kill)
```

---

## GenServer

```elixir
defmodule MyServer do
  use GenServer

  # 클라이언트 API
  def start_link(arg) do
    GenServer.start_link(__MODULE__, arg, name: __MODULE__)
  end
  def get(pid), do: GenServer.call(pid, :get)
  def set(pid, v), do: GenServer.cast(pid, {:set, v})

  # 서버 콜백
  @impl true
  def init(arg), do: {:ok, arg}

  @impl true
  def handle_call(:get, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_cast({:set, v}, _state) do
    {:noreply, v}
  end

  @impl true
  def handle_info(msg, state) do
    {:noreply, state}
  end

  # 초기화 후 추가 작업 (1.7+)
  @impl true
  def handle_continue(:load_data, state) do
    data = load_from_db()
    {:noreply, Map.put(state, :data, data)}
  end

  @impl true
  def terminate(_reason, _state) do
    # 정리 작업
    :ok
  end
end
```

---

## Supervisor

```elixir
defmodule MyApp.Supervisor do
  use Supervisor

  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    children = [
      {MyWorker, arg},
      {AnotherWorker, []},
      # 동적 자식 (DynamicSupervisor)
      {DynamicSupervisor, name: MyApp.DynamicSup, strategy: :one_for_one}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end

# 전략
# :one_for_one  - 하나 실패 시 하나만 재시작
# :one_for_all  - 하나 실패 시 모두 재시작
# :rest_for_one - 하나 실패 시 이후 것들 재시작

# DynamicSupervisor 사용
DynamicSupervisor.start_child(MyApp.DynamicSup, {Worker, arg})
DynamicSupervisor.terminate_child(MyApp.DynamicSup, pid)
```

---

## Task

```elixir
# 단순 비동기 실행
Task.start(fn -> expensive_operation() end)

# 결과 기다리기
task = Task.async(fn -> compute() end)
result = Task.await(task)
result = Task.await(task, 10_000)  # 10초 타임아웃

# 여러 Task 병렬 실행
tasks = Enum.map(urls, fn url ->
  Task.async(fn -> fetch(url) end)
end)
results = Task.await_many(tasks)

# 결과가 나오는 대로 처리
tasks
|> Task.yield_many(5000)
|> Enum.map(fn {task, res} ->
  res || Task.shutdown(task, :brutal_kill)
end)

# Task.Supervisor 사용 (권장)
Task.Supervisor.start_child(MyApp.TaskSup, fn -> work() end)
Task.Supervisor.async(MyApp.TaskSup, fn -> work() end)
```

---

## 문자열 함수

```elixir
String.length("hello")          # 5
String.upcase("hello")          # "HELLO"
String.downcase("HELLO")        # "hello"
String.capitalize("hello")      # "Hello"

String.trim("  hi  ")           # "hi"
String.trim_leading("  hi")     # "hi"
String.trim_trailing("hi  ")    # "hi"

String.split("a,b,c", ",")      # ["a", "b", "c"]
String.split("a  b  c")         # ["a", "b", "c"] (공백)

String.replace("hello", "l", "L")   # "heLLo"
String.replace("hello", "l", "L", global: false)  # "heLlo"

String.contains?("hello", "ll")     # true
String.starts_with?("hello", "he")  # true
String.ends_with?("hello", "lo")    # true

String.slice("hello", 1, 3)         # "ell"
String.at("hello", 0)               # "h"
String.reverse("hello")             # "olleh"
String.duplicate("ab", 3)           # "ababab"

String.to_integer("42")             # 42
String.to_float("3.14")             # 3.14
Integer.to_string(42)               # "42"
```

---

## Map 함수

```elixir
Map.new([{:a, 1}, {:b, 2}])
Map.get(map, key)
Map.get(map, key, default)
Map.fetch(map, key)            # {:ok, value} | :error
Map.fetch!(map, key)           # 없으면 예외

Map.put(map, key, value)
Map.put_new(map, key, value)   # 없을 때만 추가
Map.update(map, key, default, fn v -> v + 1 end)
Map.update!(map, key, fn v -> v + 1 end)

Map.delete(map, key)
Map.drop(map, [:a, :b])
Map.take(map, [:a, :b])
Map.split(map, [:a, :b])

Map.merge(map1, map2)
Map.merge(map1, map2, fn _k, v1, v2 -> v1 + v2 end)

Map.keys(map)
Map.values(map)
Map.to_list(map)

Map.has_key?(map, key)
Map.equal?(map1, map2)
```

---

## JSON (Elixir 1.18+)

```elixir
# 내장 JSON 모듈 (외부 라이브러리 불필요)
JSON.encode!(%{name: "Kim", age: 25})
# => "{\"name\":\"Kim\",\"age\":25}"

JSON.decode!("{\"name\":\"Kim\"}")
# => %{"name" => "Kim"}

# 안전한 버전 (에러 반환)
{:ok, json} = JSON.encode(data)
{:error, reason} = JSON.decode(invalid)

# 스트림 인코딩
JSON.encode_to_iodata!(data)
```

---

## 에러 처리

```elixir
# try/rescue
try do
  risky_function()
rescue
  e in RuntimeError -> "Runtime: #{e.message}"
  ArgumentError -> "Argument error"
  _ -> "Unknown error"
after
  cleanup()
end

# try/catch (throw 처리)
try do
  throw(:some_value)
catch
  :throw, value -> value
  :exit, reason -> reason
  :error, reason -> reason
end

# raise
raise "Error message"
raise ArgumentError, message: "Invalid"

# 예외 정의
defmodule MyError do
  defexception [:message, :code]

  @impl true
  def message(%{message: msg, code: code}) do
    "Error #{code}: #{msg}"
  end
end

raise MyError, message: "Something wrong", code: 500

# bang 함수 패턴
def process!(data) do
  case process(data) do
    {:ok, result} -> result
    {:error, reason} -> raise "Failed: #{reason}"
  end
end
```

---

## 디버깅 (Elixir 1.18+)

```elixir
# dbg 매크로 (1.14+)
x = 10
y = 20
dbg(x + y)
# [file:line] x + y #=> 30

# 파이프라인 디버깅
[1, 2, 3]
|> Enum.map(&(&1 * 2))
|> dbg()
|> Enum.sum()
|> dbg()

# IO.inspect (기존 방식)
data
|> IO.inspect(label: "after filter")
|> process()

# IEx.pry (대화형 디버깅)
require IEx
IEx.pry()

# :debugger 사용
:debugger.start()
:int.ni(MyModule)
:int.break(MyModule, :function_name, arity)
```

---

## 테스트

```elixir
# test/my_module_test.exs
defmodule MyModuleTest do
  use ExUnit.Case, async: true

  # 설정
  setup do
    {:ok, user: %User{name: "Test"}}
  end

  setup_all do
    # 모든 테스트 전 한 번 실행
    :ok
  end

  # 기본 테스트
  test "basic assertion" do
    assert 1 + 1 == 2
    refute 1 + 1 == 3
  end

  # 컨텍스트 사용
  test "with context", %{user: user} do
    assert user.name == "Test"
  end

  # 예외 테스트
  test "raises error" do
    assert_raise ArgumentError, fn ->
      raise ArgumentError
    end
  end

  # 패턴 매칭 검증
  test "pattern match" do
    assert {:ok, _} = some_function()
  end

  # 매개변수화된 테스트 (1.18+)
  for {input, expected} <- [{1, 2}, {2, 4}, {3, 6}] do
    test "doubles #{input}" do
      assert double(unquote(input)) == unquote(expected)
    end
  end

  # describe 블록
  describe "when logged in" do
    setup do
      {:ok, logged_in: true}
    end

    test "can access dashboard", %{logged_in: logged_in} do
      assert logged_in
    end
  end
end
```

---

## Mix 명령어

```bash
# 프로젝트 관리
mix new app_name              # 새 프로젝트
mix new app_name --sup        # Supervisor 포함
mix deps.get                  # 의존성 설치
mix deps.update --all         # 모든 의존성 업데이트
mix compile                   # 컴파일
mix clean                     # 빌드 정리

# 실행
iex -S mix                    # iex + 프로젝트
mix run --no-halt             # 앱 실행
mix run -e "MyModule.func()"  # 표현식 실행

# 테스트
mix test                      # 모든 테스트
mix test test/specific_test.exs  # 특정 파일
mix test --only tag_name      # 태그된 테스트
mix test --cover              # 커버리지 포함

# 코드 품질
mix format                    # 코드 포맷
mix format --check-formatted  # CI용
mix format --migrate          # 1.18+ 문법으로 마이그레이션
mix credo                     # 린터 (외부)
mix dialyzer                  # 정적 분석 (외부)

# 문서
mix docs                      # 문서 생성 (ex_doc)

# Phoenix
mix phx.new app_name
mix phx.new app_name --no-ecto  # DB 없이
mix phx.server
mix phx.routes
mix ecto.create
mix ecto.migrate
mix ecto.rollback
mix ecto.gen.migration name
mix phx.gen.html Context Model models field:type
mix phx.gen.live Context Model models field:type
mix phx.gen.auth Accounts User users  # 인증 생성
```

---

## IEx 명령어

```elixir
h Module.function       # 도움말
h Module                # 모듈 도움말
i value                 # 값 정보
t Module                # 타입 정보

recompile               # 재컴파일
r Module                # 특정 모듈 재컴파일

v()                     # 마지막 결과
v(1)                    # 첫 번째 결과
v(-1)                   # 이전 결과

c "file.exs"            # 파일 컴파일
import_file "file.exs"  # 파일 로드
pwd()                   # 현재 디렉토리
ls()                    # 파일 목록

# 자동 리로드 (1.18+)
# .iex.exs에 설정
IEx.configure(auto_reload: true)

# 브레이크포인트
break!(Module, :function, arity)
breaks()                # 브레이크포인트 목록
continue()              # 계속 실행
```

---

## 자주 쓰는 패턴

```elixir
# OK/Error 처리
{:ok, result} = operation()
with {:ok, a} <- step1(),
     {:ok, b} <- step2(a) do
  {:ok, b}
end

# 재시도 패턴
def retry(fun, attempts \\ 3) do
  case fun.() do
    {:ok, result} -> {:ok, result}
    {:error, _} when attempts > 1 ->
      Process.sleep(1000)
      retry(fun, attempts - 1)
    error -> error
  end
end

# 캐시 패턴 (ETS)
:ets.new(:cache, [:set, :public, :named_table])
:ets.insert(:cache, {key, value})
:ets.lookup(:cache, key)

# 상태 업데이트 (중첩)
put_in(state, [:user, :name], "New Name")
update_in(state, [:user, :count], &(&1 + 1))
get_in(state, [:user, :name])

# 옵션 처리
def func(opts \\ []) do
  timeout = Keyword.get(opts, :timeout, 5000)
  retry = Keyword.get(opts, :retry, true)
  ...
end
```

---

## Phoenix 1.8 빠른 참조

```elixir
# 라우터
scope "/", MyAppWeb do
  pipe_through :browser

  get "/", PageController, :home
  resources "/users", UserController
  live "/dashboard", DashboardLive
end

# 컨트롤러
defmodule MyAppWeb.PageController do
  use MyAppWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end

# LiveView
defmodule MyAppWeb.DashboardLive do
  use MyAppWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, assign(socket, count: 0)}
  end

  def handle_event("increment", _, socket) do
    {:noreply, update(socket, :count, &(&1 + 1))}
  end

  def render(assigns) do
    ~H"""
    <div>
      <p>Count: <%= @count %></p>
      <button phx-click="increment">+</button>
    </div>
    """
  end
end

# Function Component
attr :name, :string, required: true
attr :class, :string, default: ""
slot :inner_block, required: true

def button(assigns) do
  ~H"""
  <button class={["btn", @class]}>
    <%= render_slot(@inner_block) %>
  </button>
  """
end

# Verified Routes (1.7+)
~p"/users/#{user}"
~p"/users?page=#{page}"
```

---

## 유용한 라이브러리

```elixir
# mix.exs deps
{:phoenix, "~> 1.8"},
{:phoenix_live_view, "~> 1.1"},
{:ecto_sql, "~> 3.13"},
{:bandit, "~> 1.5"},
{:jason, "~> 1.4"},           # JSON (1.18 미만)
{:httpoison, "~> 2.0"},       # HTTP 클라이언트
{:req, "~> 0.5"},             # 모던 HTTP (권장)
{:tesla, "~> 1.9"},           # HTTP + 미들웨어
{:oban, "~> 2.18"},           # 백그라운드 작업
{:ex_machina, "~> 2.8", only: :test},  # 테스트 팩토리
{:credo, "~> 1.7", only: [:dev, :test]},
{:dialyxir, "~> 1.4", only: [:dev, :test]},
```

---

> 📅 마지막 업데이트: 2025년 1월
> 📚 Elixir 1.18 / OTP 27 / Phoenix 1.8 기준
