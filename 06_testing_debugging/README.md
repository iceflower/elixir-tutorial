# 06. 테스트와 디버깅

Elixir의 테스트 프레임워크와 디버깅 도구 사용법을 알아봅니다.

---

## 목차

1. [ExUnit 기초](#exunit-기초)
2. [테스트 구조화](#테스트-구조화)
3. [Assertions](#assertions)
4. [Setup과 Fixtures](#setup과-fixtures)
5. [비동기 테스트](#비동기-테스트)
6. [Mocking과 Stub](#mocking과-stub)
7. [Property-Based Testing](#property-based-testing)
8. [디버깅 도구](#디버깅-도구)
9. [로깅](#로깅)
10. [프로파일링](#프로파일링)

---

## ExUnit 기초

Elixir는 내장 테스트 프레임워크인 **ExUnit**을 제공합니다.

### 프로젝트 설정

```elixir
# test/test_helper.exs
ExUnit.start()
```

### 기본 테스트 작성

```elixir
# test/calculator_test.exs
defmodule CalculatorTest do
  use ExUnit.Case

  test "addition" do
    assert Calculator.add(2, 3) == 5
  end

  test "subtraction" do
    assert Calculator.subtract(5, 3) == 2
  end
end
```

### 테스트 실행

```bash
# 모든 테스트 실행
mix test

# 특정 파일 실행
mix test test/calculator_test.exs

# 특정 라인 실행
mix test test/calculator_test.exs:5

# 실패한 테스트만 재실행 (1.17+)
mix test --failed

# 시드 고정 (재현 가능)
mix test --seed 12345

# 상세 출력
mix test --trace
```

---

## 테스트 구조화

### describe 블록

관련 테스트를 그룹화합니다.

```elixir
defmodule UserTest do
  use ExUnit.Case

  describe "create_user/1" do
    test "creates user with valid data" do
      attrs = %{name: "Kim", email: "kim@example.com"}
      assert {:ok, user} = User.create_user(attrs)
      assert user.name == "Kim"
    end

    test "returns error with invalid email" do
      attrs = %{name: "Kim", email: "invalid"}
      assert {:error, changeset} = User.create_user(attrs)
      assert "is invalid" in errors_on(changeset).email
    end
  end

  describe "get_user/1" do
    test "returns user by id" do
      # ...
    end

    test "returns nil for non-existent id" do
      # ...
    end
  end
end
```

### 태그 사용

```elixir
defmodule SlowTest do
  use ExUnit.Case

  @tag :slow
  test "takes a long time" do
    Process.sleep(5000)
    assert true
  end

  @tag :external
  test "calls external API" do
    # ...
  end

  @moduletag :integration
  # 이 모듈의 모든 테스트에 적용
end
```

```bash
# 특정 태그만 실행
mix test --only slow

# 특정 태그 제외
mix test --exclude external

# 여러 태그 조합
mix test --only integration --exclude slow
```

### 매개변수화된 테스트 (Elixir 1.18+)

```elixir
defmodule MathTest do
  use ExUnit.Case

  # 컴파일 타임에 여러 테스트 생성
  for {input, expected} <- [{1, 1}, {2, 4}, {3, 9}, {4, 16}] do
    test "square of #{input} is #{expected}" do
      assert Math.square(unquote(input)) == unquote(expected)
    end
  end

  # 테이블 기반 테스트
  @test_cases [
    %{input: "", expected: true, desc: "empty string"},
    %{input: "hello", expected: false, desc: "regular string"},
    %{input: "   ", expected: true, desc: "whitespace only"}
  ]

  for %{input: input, expected: expected, desc: desc} <- @test_cases do
    test "blank?/1 with #{desc}" do
      assert String.blank?(unquote(input)) == unquote(expected)
    end
  end
end
```

---

## Assertions

### 기본 Assertions

```elixir
# 동등성
assert value == expected
assert value != unexpected

# 진실성
assert value                  # truthy
refute value                  # falsy

# 패턴 매칭
assert {:ok, _} = some_function()
assert %User{name: "Kim"} = get_user()

# 근사값 (실수)
assert_in_delta 3.14159, calculated_pi, 0.001
```

### 예외 테스트

```elixir
# 예외 발생 확인
assert_raise ArgumentError, fn ->
  some_function(invalid_arg)
end

# 예외 메시지 확인
assert_raise ArgumentError, "invalid argument", fn ->
  some_function(invalid_arg)
end

# 정규식으로 메시지 확인
assert_raise ArgumentError, ~r/invalid/, fn ->
  some_function(invalid_arg)
end
```

### 메시지 수신 테스트

```elixir
test "sends notification" do
  NotificationService.notify(self(), :user_created)

  # 메시지 수신 확인
  assert_receive {:notification, :user_created}

  # 타임아웃 지정
  assert_receive {:notification, _}, 1000

  # 메시지 미수신 확인
  refute_receive {:notification, :deleted}
end
```

### 종료 테스트

```elixir
test "process exits on error" do
  pid = spawn_link(fn -> raise "boom" end)

  assert_receive {:EXIT, ^pid, _}
end
```

---

## Setup과 Fixtures

### setup 콜백

```elixir
defmodule UserServiceTest do
  use ExUnit.Case

  # 각 테스트 전에 실행
  setup do
    user = %User{id: 1, name: "Test User"}
    {:ok, user: user, timestamp: DateTime.utc_now()}
  end

  test "uses setup data", %{user: user, timestamp: ts} do
    assert user.name == "Test User"
    assert ts
  end
end
```

### setup_all 콜백

```elixir
defmodule DatabaseTest do
  use ExUnit.Case

  # 모든 테스트 전에 한 번만 실행
  setup_all do
    {:ok, conn} = Database.connect()

    on_exit(fn ->
      Database.disconnect(conn)
    end)

    {:ok, conn: conn}
  end

  test "queries database", %{conn: conn} do
    assert {:ok, _} = Database.query(conn, "SELECT 1")
  end
end
```

### 명명된 Setup

```elixir
defmodule ComplexTest do
  use ExUnit.Case

  # 재사용 가능한 setup 함수
  def create_user(_context) do
    {:ok, user: %User{name: "Test"}}
  end

  def create_post(%{user: user}) do
    {:ok, post: %Post{author: user, title: "Test Post"}}
  end

  describe "with user and post" do
    setup [:create_user, :create_post]

    test "has both", %{user: user, post: post} do
      assert post.author == user
    end
  end

  describe "with user only" do
    setup :create_user

    test "has user", %{user: user} do
      assert user.name == "Test"
    end
  end
end
```

### start_supervised!/1

GenServer 등을 테스트에서 안전하게 시작합니다.

```elixir
defmodule CounterTest do
  use ExUnit.Case

  setup do
    # 테스트 종료 시 자동 정리
    counter = start_supervised!(Counter)
    {:ok, counter: counter}
  end

  test "increments", %{counter: counter} do
    Counter.increment(counter)
    assert Counter.get(counter) == 1
  end
end
```

---

## 비동기 테스트

### async: true

독립적인 테스트를 병렬로 실행합니다.

```elixir
defmodule FastTest do
  use ExUnit.Case, async: true  # 다른 async 테스트와 병렬 실행

  test "quick operation" do
    assert 1 + 1 == 2
  end
end
```

**주의**: 공유 상태(DB, 파일 등)에 접근하는 테스트는 `async: false`로 설정하세요.

### Ecto Sandbox

Phoenix에서 DB 테스트를 위한 샌드박스 모드:

```elixir
# test/support/data_case.ex
defmodule MyApp.DataCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      alias MyApp.Repo
      import Ecto
      import Ecto.Query
      import MyApp.DataCase
    end
  end

  setup tags do
    pid = Ecto.Adapters.SQL.Sandbox.start_owner!(MyApp.Repo, shared: not tags[:async])
    on_exit(fn -> Ecto.Adapters.SQL.Sandbox.stop_owner(pid) end)
    :ok
  end
end
```

---

## Mocking과 Stub

### Mox 라이브러리

행위 기반 모킹을 위한 표준 라이브러리입니다.

```elixir
# mix.exs
{:mox, "~> 1.1", only: :test}
```

### Behaviour 정의

```elixir
# lib/my_app/http_client.ex
defmodule MyApp.HTTPClient do
  @callback get(String.t()) :: {:ok, map()} | {:error, term()}
  @callback post(String.t(), map()) :: {:ok, map()} | {:error, term()}
end

# lib/my_app/http_client/httpoison.ex
defmodule MyApp.HTTPClient.HTTPoison do
  @behaviour MyApp.HTTPClient

  @impl true
  def get(url) do
    case HTTPoison.get(url) do
      {:ok, %{body: body}} -> {:ok, Jason.decode!(body)}
      error -> error
    end
  end

  @impl true
  def post(url, body) do
    # ...
  end
end
```

### Mock 설정

```elixir
# test/support/mocks.ex
Mox.defmock(MyApp.MockHTTPClient, for: MyApp.HTTPClient)

# config/test.exs
config :my_app, :http_client, MyApp.MockHTTPClient
```

### 테스트에서 사용

```elixir
defmodule WeatherServiceTest do
  use ExUnit.Case, async: true
  import Mox

  # 각 테스트에서 mock 검증
  setup :verify_on_exit!

  test "fetches weather data" do
    expect(MyApp.MockHTTPClient, :get, fn url ->
      assert url =~ "api.weather.com"
      {:ok, %{"temp" => 25, "condition" => "sunny"}}
    end)

    assert {:ok, weather} = WeatherService.get_weather("Seoul")
    assert weather.temperature == 25
  end

  test "handles API error" do
    expect(MyApp.MockHTTPClient, :get, fn _url ->
      {:error, :timeout}
    end)

    assert {:error, :service_unavailable} = WeatherService.get_weather("Seoul")
  end
end
```

### Stub vs Expect

```elixir
# stub: 호출 횟수 검증 안 함 (0번 이상)
stub(MyApp.MockHTTPClient, :get, fn _ -> {:ok, %{}} end)

# expect: 정확히 지정된 횟수만큼 호출되어야 함
expect(MyApp.MockHTTPClient, :get, 3, fn _ -> {:ok, %{}} end)
```

---

## Property-Based Testing

### StreamData 라이브러리

```elixir
# mix.exs
{:stream_data, "~> 1.1", only: [:dev, :test]}
```

### 기본 사용법

```elixir
defmodule StringPropertiesTest do
  use ExUnit.Case
  use ExUnitProperties

  property "reversing a string twice gives original" do
    check all string <- string(:alphanumeric) do
      assert String.reverse(String.reverse(string)) == string
    end
  end

  property "length is non-negative" do
    check all string <- string(:printable) do
      assert String.length(string) >= 0
    end
  end
end
```

### 커스텀 생성기

```elixir
defmodule UserPropertiesTest do
  use ExUnit.Case
  use ExUnitProperties

  # 커스텀 생성기 정의
  def user_generator do
    gen all name <- string(:alphanumeric, min_length: 1, max_length: 50),
            age <- integer(0..150),
            email <- email_generator() do
      %User{name: name, age: age, email: email}
    end
  end

  def email_generator do
    gen all local <- string(:alphanumeric, min_length: 1, max_length: 20),
            domain <- member_of(["example.com", "test.org", "mail.co"]) do
      "#{local}@#{domain}"
    end
  end

  property "user serialization roundtrips" do
    check all user <- user_generator() do
      assert user == user |> User.to_json() |> User.from_json()
    end
  end
end
```

---

## 디버깅 도구

### dbg/2 매크로 (Elixir 1.14+)

파이프라인 디버깅에 최적화된 매크로입니다.

```elixir
# 기본 사용
x = 10
dbg(x * 2)
# [iex:2] x * 2 #=> 20

# 파이프라인 디버깅
[1, 2, 3, 4, 5]
|> Enum.filter(&(&1 > 2))
|> dbg()
|> Enum.map(&(&1 * 2))
|> dbg()
|> Enum.sum()
# [file:line] Enum.filter(&(&1 > 2)) #=> [3, 4, 5]
# [file:line] Enum.map(&(&1 * 2)) #=> [6, 8, 10]
```

### IO.inspect/2

```elixir
# 레이블 붙이기
data
|> IO.inspect(label: "before filter")
|> Enum.filter(&valid?/1)
|> IO.inspect(label: "after filter")
|> process()

# 옵션
IO.inspect(complex_data,
  pretty: true,
  limit: :infinity,
  width: 120,
  syntax_colors: [
    number: :yellow,
    atom: :cyan,
    string: :green
  ]
)

# 구조체 내부 보기
IO.inspect(struct, structs: false)

# 바이너리를 바이트로 표시
IO.inspect(binary, binaries: :as_binaries)
```

### IEx.pry

대화형 디버깅 세션을 시작합니다.

```elixir
defmodule MyModule do
  def complex_function(data) do
    intermediate = process(data)

    # 실행 중 IEx 세션 시작
    require IEx
    IEx.pry()

    final_result(intermediate)
  end
end
```

```bash
# pry 활성화하여 실행
iex -S mix
```

### :debugger (Erlang)

GUI 디버거 사용:

```elixir
# 디버거 시작
:debugger.start()

# 모듈 인터프리트
:int.ni(MyModule)

# 브레이크포인트 설정
:int.break(MyModule, :function_name, 2)  # 모듈, 함수, arity
```

### IEx 브레이크포인트

```elixir
# IEx 세션에서
break!(MyModule, :function_name, 2)
break!(MyModule.function_name/2)  # 동일

# 브레이크포인트 목록
breaks()

# 브레이크포인트 제거
remove_breaks(MyModule)

# 계속 실행
continue()

# 다음 브레이크포인트
next()
```

---

## 로깅

### Logger 설정

```elixir
# config/config.exs
config :logger,
  level: :info,
  backends: [:console]

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id, :user_id]

# config/test.exs
config :logger, level: :warning  # 테스트 시 로그 감소
```

### Logger 사용

```elixir
require Logger

Logger.debug("Debug message")
Logger.info("Info message")
Logger.warning("Warning message")  # warn -> warning (1.15+)
Logger.error("Error message")

# 메타데이터 포함
Logger.info("User logged in", user_id: user.id, ip: conn.remote_ip)

# 지연 평가 (비용이 큰 연산)
Logger.debug(fn -> "Expensive: #{inspect(heavy_computation())}" end)
```

### 구조화된 로깅

```elixir
# JSON 로깅 백엔드
# mix.exs: {:logger_json, "~> 6.0"}

config :logger, backends: [LoggerJSON]

config :logger_json, :backend,
  metadata: :all,
  formatter: LoggerJSON.Formatters.Basic
```

### 테스트에서 로그 캡처

```elixir
import ExUnit.CaptureLog

test "logs warning" do
  log = capture_log(fn ->
    MyModule.risky_operation()
  end)

  assert log =~ "Warning:"
end

test "logs at specific level" do
  log = capture_log([level: :warning], fn ->
    MyModule.operation()
  end)

  assert log =~ "Something went wrong"
end
```

---

## 프로파일링

### :timer.tc

간단한 실행 시간 측정:

```elixir
{time_microseconds, result} = :timer.tc(fn ->
  expensive_operation()
end)

IO.puts("Took #{time_microseconds / 1000}ms")
```

### Benchee

정밀한 벤치마킹:

```elixir
# mix.exs
{:benchee, "~> 1.3", only: :dev}
```

```elixir
# bench/list_vs_map.exs
list = Enum.to_list(1..10_000)
map = Map.new(list, fn x -> {x, x} end)

Benchee.run(%{
  "list lookup" => fn -> Enum.find(list, &(&1 == 5000)) end,
  "map lookup" => fn -> Map.get(map, 5000) end
},
  time: 5,
  memory_time: 2,
  formatters: [
    Benchee.Formatters.Console,
    {Benchee.Formatters.HTML, file: "bench/output/results.html"}
  ]
)
```

### :fprof (Erlang)

함수별 프로파일링:

```elixir
:fprof.trace([:start, procs: self()])
my_function()
:fprof.trace(:stop)
:fprof.profile()
:fprof.analyse(totals: true, dest: 'fprof.analysis')
```

### Mix Tasks

```bash
# 컴파일 경고
mix compile --warnings-as-errors

# 사용하지 않는 의존성
mix deps.unlock --check-unused

# Dialyzer (정적 분석)
mix dialyzer

# Credo (코드 품질)
mix credo --strict
```

---

## 테스트 커버리지

### 내장 커버리지

```bash
mix test --cover
```

### ExCoveralls

상세한 커버리지 리포트:

```elixir
# mix.exs
{:excoveralls, "~> 0.18", only: :test}

def project do
  [
    # ...
    test_coverage: [tool: ExCoveralls],
    preferred_cli_env: [
      coveralls: :test,
      "coveralls.html": :test
    ]
  ]
end
```

```bash
# HTML 리포트 생성
mix coveralls.html

# GitHub Actions용
mix coveralls.github
```

---

## 실전 테스트 예제

### Phoenix Controller 테스트

```elixir
defmodule MyAppWeb.UserControllerTest do
  use MyAppWeb.ConnCase

  describe "GET /users" do
    test "lists all users", %{conn: conn} do
      user = insert(:user)

      conn = get(conn, ~p"/users")

      assert html_response(conn, 200) =~ user.name
    end
  end

  describe "POST /users" do
    test "creates user with valid data", %{conn: conn} do
      attrs = %{name: "New User", email: "new@example.com"}

      conn = post(conn, ~p"/users", user: attrs)

      assert redirected_to(conn) == ~p"/users"
      assert get_flash(conn, :info) =~ "created"
    end

    test "returns errors with invalid data", %{conn: conn} do
      attrs = %{name: "", email: "invalid"}

      conn = post(conn, ~p"/users", user: attrs)

      assert html_response(conn, 200) =~ "can&#39;t be blank"
    end
  end
end
```

### LiveView 테스트

```elixir
defmodule MyAppWeb.CounterLiveTest do
  use MyAppWeb.ConnCase
  import Phoenix.LiveViewTest

  test "increments counter", %{conn: conn} do
    {:ok, view, html} = live(conn, ~p"/counter")

    assert html =~ "Count: 0"

    html = view
           |> element("button", "+")
           |> render_click()

    assert html =~ "Count: 1"
  end

  test "form submission", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/search")

    html = view
           |> form("#search-form", query: "elixir")
           |> render_submit()

    assert html =~ "Results for: elixir"
  end
end
```

### GenServer 테스트

```elixir
defmodule CounterServerTest do
  use ExUnit.Case, async: true

  setup do
    counter = start_supervised!({CounterServer, 0})
    {:ok, counter: counter}
  end

  test "starts with initial value", %{counter: counter} do
    assert CounterServer.get(counter) == 0
  end

  test "increments value", %{counter: counter} do
    CounterServer.increment(counter)
    assert CounterServer.get(counter) == 1
  end

  test "handles concurrent increments", %{counter: counter} do
    tasks = for _ <- 1..100 do
      Task.async(fn -> CounterServer.increment(counter) end)
    end

    Task.await_many(tasks)

    assert CounterServer.get(counter) == 100
  end
end
```

---

## 다음 단계

- [Elixir 공식 테스팅 가이드](https://hexdocs.pm/ex_unit/ExUnit.html)
- [Phoenix 테스팅 가이드](https://hexdocs.pm/phoenix/testing.html)
- [Mox 문서](https://hexdocs.pm/mox/Mox.html)
- [StreamData 문서](https://hexdocs.pm/stream_data/StreamData.html)

---

> 📅 마지막 업데이트: 2025년 1월
> 📚 Elixir 1.18 / ExUnit / Phoenix 1.8 기준
