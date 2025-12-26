# Elixir 치트시트

빠른 참조를 위한 Elixir 핵심 문법 모음입니다.

---

## 데이터 타입

```elixir
# 숫자
42              # 정수
3.14            # 실수
1_000_000       # 가독성 (= 1000000)
0xFF            # 16진수 (= 255)
0b1010          # 2진수 (= 10)

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
===           # 타입도 비교

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

# 무시
{_, b} = {1, 2}
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

# with
with {:ok, a} <- func1(),
     {:ok, b} <- func2(a) do
  {:ok, b}
else
  {:error, reason} -> {:error, reason}
end
```

---

## 함수

```elixir
# 익명 함수
add = fn a, b -> a + b end
add.(1, 2)                    # 호출 시 점 필요

# 축약
double = &(&1 * 2)
add = &(&1 + &2)

# 함수 캡처
upcase = &String.upcase/1

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
```

---

## 모듈

```elixir
defmodule MyModule do
  @moduledoc "모듈 문서"
  @doc "함수 문서"

  @constant 42              # 모듈 상수

  def public_func, do: ...
  defp private_func, do: ...
end

# 구조체
defmodule User do
  defstruct name: "", age: 0
end

user = %User{name: "Kim"}
%{user | age: 25}
```

---

## Enum (즉시 평가)

```elixir
Enum.map(list, fn x -> x * 2 end)
Enum.filter(list, &(&1 > 0))
Enum.reduce(list, 0, &(&1 + &2))
Enum.find(list, &(&1 > 5))

Enum.sort(list)
Enum.sort_by(users, & &1.age)

Enum.take(list, 5)
Enum.drop(list, 5)

Enum.any?(list, &(&1 > 0))
Enum.all?(list, &(&1 > 0))

Enum.count(list)
Enum.sum(list)
Enum.min(list)
Enum.max(list)

Enum.zip(list1, list2)
Enum.group_by(list, &key_func/1)
Enum.frequencies(list)
```

---

## Stream (지연 평가)

```elixir
Stream.map(enum, func)
Stream.filter(enum, func)
Stream.take(enum, n)

# 무한 스트림
Stream.iterate(0, &(&1 + 1))
Stream.cycle([:a, :b, :c])
Stream.repeatedly(fn -> :rand.uniform() end)
```

---

## 컴프리헨션

```elixir
for x <- 1..10, do: x * x
for x <- 1..10, rem(x, 2) == 0, do: x
for x <- 1..3, y <- 1..3, do: {x, y}
for x <- 1..5, into: %{}, do: {x, x * x}
```

---

## 프로세스

```elixir
self()                      # 현재 PID
spawn(fn -> ... end)        # 새 프로세스
spawn_link(fn -> ... end)   # 연결된 프로세스

send(pid, message)          # 메시지 전송
receive do
  pattern -> ...
after
  1000 -> :timeout
end
```

---

## GenServer

```elixir
defmodule MyServer do
  use GenServer

  # 클라이언트
  def start_link(arg), do: GenServer.start_link(__MODULE__, arg)
  def get(pid), do: GenServer.call(pid, :get)
  def set(pid, v), do: GenServer.cast(pid, {:set, v})

  # 서버
  def init(arg), do: {:ok, arg}
  def handle_call(:get, _from, state), do: {:reply, state, state}
  def handle_cast({:set, v}, _), do: {:noreply, v}
  def handle_info(msg, state), do: {:noreply, state}
end
```

---

## 문자열 함수

```elixir
String.length("hello")        # 5
String.upcase("hello")        # "HELLO"
String.downcase("HELLO")      # "hello"
String.trim("  hi  ")         # "hi"
String.split("a,b,c", ",")    # ["a", "b", "c"]
String.replace("hi", "i", "o") # "ho"
String.contains?("hello", "ll") # true
String.starts_with?("hello", "he") # true
```

---

## Map 함수

```elixir
Map.get(map, key)
Map.get(map, key, default)
Map.put(map, key, value)
Map.delete(map, key)
Map.merge(map1, map2)
Map.keys(map)
Map.values(map)
Map.has_key?(map, key)
Map.take(map, [:a, :b])
Map.drop(map, [:c])
```

---

## 에러 처리

```elixir
# try/rescue
try do
  risky_function()
rescue
  e in RuntimeError -> "Runtime: #{e.message}"
  _ -> "Unknown error"
after
  cleanup()
end

# raise
raise "Error message"
raise ArgumentError, message: "Invalid"

# 예외 정의
defmodule MyError do
  defexception message: "default message"
end
```

---

## Mix 명령어

```bash
mix new app_name        # 새 프로젝트
mix deps.get            # 의존성 설치
mix compile             # 컴파일
mix test                # 테스트
mix format              # 코드 포맷
iex -S mix              # iex + 프로젝트

# Phoenix
mix phx.new app_name
mix phx.server
mix phx.routes
mix ecto.create
mix ecto.migrate
mix phx.gen.html Context Model models field:type
mix phx.gen.live Context Model models field:type
```

---

## IEx 명령어

```elixir
h Module.function       # 도움말
i value                 # 정보
recompile               # 재컴파일
v(1)                    # 이전 결과
c "file.exs"            # 파일 컴파일
import_file "file.exs"  # 파일 로드
```
