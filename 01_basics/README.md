# 01. Elixir 기초 문법

> **2025년 12월 기준** - Elixir 1.18

## 목차

1. [Hello World](#hello-world)
2. [기본 데이터 타입](#기본-데이터-타입)
3. [연산자](#연산자)
4. [패턴 매칭](#패턴-매칭)
5. [제어 흐름](#제어-흐름)
6. [함수](#함수)
7. [모듈](#모듈)
8. [시길 (Sigils)](#시길-sigils)
9. [문서화](#문서화)

---

## Hello World

### 첫 번째 프로그램

```elixir
# hello.exs
IO.puts("Hello, World!")
IO.puts("안녕하세요, Elixir 1.18!")
```

실행:

```bash
elixir hello.exs
```

### 출력 함수들

| 함수 | 설명 | 반환값 |
|------|------|--------|
| `IO.puts/1` | 줄바꿈 포함 출력 | `:ok` |
| `IO.write/1` | 줄바꿈 없이 출력 | `:ok` |
| `IO.inspect/2` | 디버깅용 출력 | 입력값 그대로 |
| `dbg/2` | 디버그 매크로 (1.14+) | 입력값 그대로 |

```elixir
IO.puts("Hello")        # Hello\n
IO.write("Hello ")      # Hello (줄바꿈 없음)
IO.inspect([1,2,3])     # [1, 2, 3] (값 반환)

# inspect는 파이프라인에서 유용
[1, 2, 3]
|> IO.inspect(label: "before")
|> Enum.map(&(&1 * 2))
|> IO.inspect(label: "after")

# dbg 매크로 (권장) - 코드와 결과 함께 출력
[1, 2, 3]
|> Enum.map(&(&1 * 2))
|> dbg()
# [1, 2, 3] #=> [1, 2, 3]
# |> Enum.map(&(&1 * 2)) #=> [2, 4, 6]
```

### 문자열 보간 (Interpolation)

```elixir
name = "Elixir"
version = 1.18

IO.puts("#{name} version #{version}")
# => Elixir version 1.18

# 표현식도 가능
IO.puts("2 + 2 = #{2 + 2}")
# => 2 + 2 = 4
```

---

## 기본 데이터 타입

### 숫자 (Numbers)

```elixir
# 정수 (Integer) - 임의 정밀도
integer = 42
big_int = 1_000_000        # 언더스코어로 가독성 향상
hex = 0xFF                 # 16진수 = 255
binary = 0b1010            # 2진수 = 10
octal = 0o777              # 8진수 = 511
very_big = 10_000_000_000_000_000_000  # 빅넘 자동 지원

# 실수 (Float) - IEEE 754 64비트
float = 3.14159
scientific = 1.5e-10       # 과학적 표기법
```

### 원자 (Atoms)

원자는 이름 자체가 값인 상수입니다.

```elixir
:ok
:error
:my_atom
:"atom with spaces"

# 불리언은 원자의 특수한 형태
true  == :true   # true
false == :false  # true
nil   == :nil    # true

# 모듈 이름도 원자
is_atom(String)  # true
String == :"Elixir.String"  # true
```

### 문자열 (Strings)

```elixir
# 큰따옴표 = 문자열 (UTF-8 바이너리)
string = "Hello, 안녕하세요"

# 문자열 연결
"Hello" <> " " <> "World"  # "Hello World"

# 여러 줄 문자열 (heredoc)
multi = """
첫 번째 줄
두 번째 줄
세 번째 줄
"""

# 주요 함수
String.length("안녕")           # 2 (문자 수)
byte_size("안녕")               # 6 (바이트 수)
String.upcase("hello")          # "HELLO"
String.split("a,b,c", ",")      # ["a", "b", "c"]
String.contains?("hello", "ll") # true
String.trim("  hello  ")        # "hello"
String.replace("hello", "l", "L")  # "heLLo"

# 1.18: 내장 JSON
JSON.encode!(%{name: "test"})   # "{\"name\":\"test\"}"
```

### 문자 리스트 (Charlists)

```elixir
# 1.18부터 ~c 시길 권장
charlist = ~c"hello"
charlist == [104, 101, 108, 108, 111]  # true

# 레거시 문법 (여전히 동작하지만 경고 발생 가능)
# 'hello' -> ~c"hello"로 마이그레이션 권장

# 문자열과 다름!
"hello" == ~c"hello"  # false

# 변환
to_charlist("hello")  # ~c"hello"
to_string(~c"hello")  # "hello"
```

### 튜플 (Tuples)

```elixir
# 고정 크기, 연속 메모리 - 인덱스 접근 O(1)
point = {10, 20}
rgb = {255, 128, 0}
result = {:ok, "성공"}

# 요소 접근
elem(point, 0)      # 10
elem(point, 1)      # 20
tuple_size(rgb)     # 3

# 수정 (새 튜플 반환)
put_elem(point, 0, 100)  # {100, 20}
```

### 타입 확인

```elixir
is_integer(42)       # true
is_float(3.14)       # true
is_number(42)        # true (integer or float)
is_atom(:ok)         # true
is_binary("hello")   # true (문자열)
is_list([1, 2, 3])   # true
is_tuple({1, 2})     # true
is_map(%{a: 1})      # true
is_function(fn -> end)     # true
is_function(fn -> end, 0)  # true (arity 0)
is_struct(%User{})  # true (1.16+)
```

---

## 연산자

### 산술 연산자

```elixir
10 + 3   # 13
10 - 3   # 7
10 * 3   # 30
10 / 3   # 3.3333... (항상 float)

div(10, 3)  # 3 (정수 나눗셈)
rem(10, 3)  # 1 (나머지)
abs(-5)     # 5 (절대값)

# 거듭제곱 (Erlang/OTP 26+, Elixir 1.13+)
2 ** 10     # 1024
2 ** 0.5    # 1.4142...
```

### 비교 연산자

```elixir
1 == 1.0   # true  (값만 비교)
1 === 1.0  # false (타입도 비교)
1 != 2     # true
1 !== 1.0  # true

1 < 2      # true
1 <= 1     # true
2 > 1      # true
2 >= 2     # true

# 구조적 비교 (모든 타입 비교 가능)
# number < atom < reference < function < port < pid < tuple < map < list < bitstring
:atom > 999  # true
```

### 논리 연산자

```elixir
# and, or, not - 첫 인자가 반드시 boolean
true and false   # false
true or false    # true
not true         # false

# &&, ||, ! - 모든 값에 사용 (falsy: nil, false)
nil || "default"     # "default"
"hello" && "world"   # "world"
!nil                 # true

# 단축 평가 (Short-circuit)
false and raise("never")  # false (뒤는 평가 안 함)
true or raise("never")    # true
```

### 문자열/리스트 연산자

```elixir
# 문자열 연결
"Hello" <> " " <> "World"  # "Hello World"

# 리스트 연산
[1, 2] ++ [3, 4]   # [1, 2, 3, 4] (연결)
[1, 2, 3] -- [2]   # [1, 3] (빼기)
1 in [1, 2, 3]     # true (포함 확인)
4 not in [1,2,3]   # true
```

---

## 패턴 매칭

Elixir에서 `=`는 할당이 아닌 **매치 연산자**입니다.

### 기본 매칭

```elixir
# 변수 바인딩
x = 1
x  # 1

# 매칭 확인
1 = x  # OK (x는 1)
2 = x  # MatchError!

# 재바인딩
x = 2  # OK
x  # 2
```

### 핀 연산자 (^)

```elixir
x = 1
^x = 1   # OK (x의 값인 1과 매칭)
^x = 2   # MatchError! (1 != 2)

# 함수 인자에서도 사용
defmodule Matcher do
  def check(x, x), do: "같음"      # 두 인자가 같을 때
  def check(x, y), do: "다름: #{x}, #{y}"
end
```

### 튜플 매칭

```elixir
{a, b, c} = {1, 2, 3}
a  # 1
b  # 2
c  # 3

# 일부만 추출
{first, _, _} = {10, 20, 30}
first  # 10

# 자주 사용되는 패턴
{:ok, result} = {:ok, "성공"}
result  # "성공"

{:error, reason} = {:error, "실패"}
reason  # "실패"
```

### 리스트 매칭

```elixir
[head | tail] = [1, 2, 3, 4, 5]
head  # 1
tail  # [2, 3, 4, 5]

[first, second | rest] = [1, 2, 3, 4, 5]
first   # 1
second  # 2
rest    # [3, 4, 5]

# 빈 리스트 매칭
[head | tail] = []  # MatchError!
```

### 맵 매칭

```elixir
user = %{name: "Kim", age: 25, city: "Seoul"}

# 일부 키만 매칭
%{name: name} = user
name  # "Kim"

# 여러 키 매칭
%{name: n, age: a} = user
n  # "Kim"
a  # 25

# 키가 없으면 MatchError
%{email: email} = user  # MatchError!
```

### 바이너리 매칭

```elixir
# 바이너리 패턴 매칭
<<a, b, c>> = <<1, 2, 3>>
a  # 1

# 문자열 매칭
<<"Hello, ", rest::binary>> = "Hello, World!"
rest  # "World!"

# 비트 단위 매칭
<<x::4, y::4>> = <<0xAB>>
x  # 10 (0xA)
y  # 11 (0xB)
```

---

## 제어 흐름

### if / else

```elixir
if age >= 18 do
  "성인"
else
  "미성년자"
end

# 한 줄
status = if age >= 18, do: :adult, else: :minor
```

### unless

```elixir
unless logged_in do
  "로그인 필요"
end

# if not과 동일
if not logged_in do
  "로그인 필요"
end
```

### cond

여러 조건 분기:

```elixir
cond do
  score >= 90 -> "A"
  score >= 80 -> "B"
  score >= 70 -> "C"
  score >= 60 -> "D"
  true -> "F"  # else 역할
end
```

### case

패턴 매칭 기반 분기:

```elixir
case response do
  {:ok, data} ->
    "성공: #{data}"
  {:error, reason} ->
    "실패: #{reason}"
  _ ->
    "알 수 없음"
end

# 가드 사용
case number do
  n when n < 0 -> "음수"
  0 -> "영"
  n when n > 0 -> "양수"
end
```

### with

연속 매칭 (실패 시 조기 반환):

```elixir
with {:ok, user} <- find_user(id),
     {:ok, post} <- find_post(user, post_id),
     :ok <- authorize(user, post) do
  {:ok, post}
else
  {:error, reason} -> {:error, reason}
  nil -> {:error, :not_found}
end
```

### for (Comprehensions)

리스트 컴프리헨션:

```elixir
# 기본
for x <- [1, 2, 3], do: x * 2
# => [2, 4, 6]

# 필터
for x <- 1..10, rem(x, 2) == 0, do: x
# => [2, 4, 6, 8, 10]

# 여러 제너레이터
for x <- [1, 2], y <- [:a, :b], do: {x, y}
# => [{1, :a}, {1, :b}, {2, :a}, {2, :b}]

# into: 결과 컬렉션 지정
for {k, v} <- %{a: 1, b: 2}, into: %{}, do: {k, v * 2}
# => %{a: 2, b: 4}

# uniq: 중복 제거 (1.17+)
for x <- [1, 1, 2, 2, 3], uniq: true, do: x
# => [1, 2, 3]

# reduce: 값 누적
for x <- 1..5, reduce: 0 do
  acc -> acc + x
end
# => 15
```

---

## 함수

### 익명 함수

```elixir
# 정의
add = fn a, b -> a + b end

# 호출 (점 필요!)
add.(3, 5)  # 8

# 축약 문법 (캡처 연산자)
multiply = &(&1 * &2)
multiply.(4, 7)  # 28

square = &(&1 * &1)
square.(9)  # 81

# 기존 함수 캡처
upcase = &String.upcase/1
upcase.("hello")  # "HELLO"
```

### 명명된 함수

```elixir
defmodule Math do
  def add(a, b) do
    a + b
  end

  # 한 줄
  def subtract(a, b), do: a - b

  # 기본값
  def multiply(a, b \\ 1), do: a * b

  # 프라이빗 함수
  defp secret(x), do: x * 42
end

Math.add(5, 3)       # 8
Math.multiply(5)     # 5
Math.multiply(5, 4)  # 20
```

### 패턴 매칭 함수

```elixir
defmodule Greeting do
  def hello(%{name: name, lang: "ko"}), do: "안녕하세요, #{name}님!"
  def hello(%{name: name, lang: "en"}), do: "Hello, #{name}!"
  def hello(%{name: name}), do: "Hi, #{name}!"
end

Greeting.hello(%{name: "Kim", lang: "ko"})  # "안녕하세요, Kim님!"
```

### 가드 (Guards)

```elixir
defmodule Check do
  def type(x) when is_integer(x), do: "정수"
  def type(x) when is_float(x), do: "실수"
  def type(x) when is_binary(x), do: "문자열"
  def type(x) when is_list(x) and length(x) > 0, do: "비어있지 않은 리스트"
  def type(_), do: "기타"
end

# 가드에서 사용 가능한 함수들
# is_atom/1, is_binary/1, is_boolean/1, is_float/1, is_function/1,
# is_integer/1, is_list/1, is_map/1, is_nil/1, is_number/1, is_pid/1,
# is_port/1, is_reference/1, is_tuple/1, is_struct/1,
# abs/1, ceil/1, floor/1, round/1, trunc/1,
# hd/1, tl/1, length/1, map_size/1, tuple_size/1,
# elem/2, binary_part/3, bit_size/1, byte_size/1,
# +, -, *, /, and, or, not, <, >, <=, >=, ==, !=, ===, !==
```

### 파이프 연산자 (|>)

```elixir
# Before
result = String.upcase(String.trim("  hello  "))

# After
result = "  hello  "
  |> String.trim()
  |> String.upcase()

# 복잡한 예제
1..100
|> Enum.filter(&(rem(&1, 3) == 0))
|> Enum.map(&(&1 * &1))
|> Enum.sum()

# then/2 - 인자 위치가 첫 번째가 아닐 때
"hello"
|> String.upcase()
|> then(fn s -> "**#{s}**" end)
# => "**HELLO**"
```

### 재귀 함수

```elixir
defmodule Recursion do
  # 팩토리얼
  def factorial(0), do: 1
  def factorial(n) when n > 0 do
    n * factorial(n - 1)
  end

  # 꼬리 재귀 최적화 버전
  def factorial_tail(n), do: factorial_tail(n, 1)
  defp factorial_tail(0, acc), do: acc
  defp factorial_tail(n, acc), do: factorial_tail(n - 1, n * acc)

  # 리스트 합계
  def sum([]), do: 0
  def sum([head | tail]), do: head + sum(tail)

  # 꼬리 재귀 버전
  def sum_tail(list), do: sum_tail(list, 0)
  defp sum_tail([], acc), do: acc
  defp sum_tail([head | tail], acc), do: sum_tail(tail, acc + head)
end
```

---

## 모듈

### 기본 구조

```elixir
defmodule MyApp.Calculator do
  @moduledoc """
  간단한 계산기 모듈
  """

  @pi 3.14159  # 모듈 속성 (상수)
  @default_precision 2

  @doc """
  두 숫자를 더합니다.

  ## Examples

      iex> MyApp.Calculator.add(1, 2)
      3
  """
  @spec add(number(), number()) :: number()
  def add(a, b), do: a + b

  def circle_area(radius) do
    Float.round(@pi * radius * radius, @default_precision)
  end
end
```

### 구조체 (Structs)

```elixir
defmodule User do
  @enforce_keys [:name]  # 필수 키
  defstruct name: nil, age: 0, email: nil, active: true

  @type t :: %__MODULE__{
    name: String.t(),
    age: non_neg_integer(),
    email: String.t() | nil,
    active: boolean()
  }

  def adult?(%User{age: age}), do: age >= 18
  def activate(%User{} = user), do: %{user | active: true}
end

# 생성
user = %User{name: "Kim", age: 25}

# 업데이트
older = %{user | age: 26}

# 패턴 매칭
%User{name: name} = user
```

### alias, import, use, require

```elixir
defmodule MyApp do
  # 모듈 이름 줄이기
  alias MyApp.Accounts.User
  alias MyApp.Accounts.{User, Profile}  # 여러 개
  alias MyApp.Accounts.User, as: U      # 별칭 지정

  # 함수 가져오기
  import String, only: [upcase: 1]
  import String, except: [split: 2]
  import Enum  # 모든 함수 가져오기 (주의!)

  # 매크로 사용을 위한 require
  require Logger
  Logger.info("Hello")

  # 매크로/콜백 주입
  use GenServer
  # use Mod는 require Mod; Mod.__using__(__MODULE__) 와 동일
end
```

---

## 시길 (Sigils)

시길은 텍스트 표현을 위한 문법적 설탕입니다.

```elixir
# 문자열
~s(hello world)        # "hello world"
~s(hello "world")      # "hello \"world\""

# 문자 리스트 (1.18 권장)
~c(hello)              # ~c"hello"

# 단어 리스트
~w(foo bar baz)        # ["foo", "bar", "baz"]
~w(foo bar baz)a       # [:foo, :bar, :baz] (atoms)
~w(foo bar baz)c       # [~c"foo", ~c"bar", ~c"baz"] (charlists)

# 정규표현식
~r/hello/
~r/hello/i             # 대소문자 무시
"Hello" =~ ~r/hello/i  # true

# 날짜/시간 (1.14+)
~D[2025-12-26]         # Date
~T[13:45:00]           # Time
~N[2025-12-26 13:45:00]  # NaiveDateTime
~U[2025-12-26 13:45:00Z] # DateTime (UTC)

# 여러 줄 시길
~s"""
여러 줄
문자열
"""

# 커스텀 시길 정의
defmodule MySigils do
  def sigil_u(string, []), do: String.upcase(string)
end

import MySigils
~u(hello)  # "HELLO"
```

---

## 문서화

### @moduledoc과 @doc

```elixir
defmodule MyModule do
  @moduledoc """
  모듈에 대한 설명입니다.

  ## Features

  - 기능 1
  - 기능 2

  ## Examples

      iex> MyModule.hello()
      "world"
  """

  @doc """
  함수에 대한 설명입니다.

  ## Parameters

  - `name` - 인사할 대상의 이름

  ## Examples

      iex> MyModule.greet("Elixir")
      "Hello, Elixir!"

  """
  @doc since: "1.0.0"
  @spec greet(String.t()) :: String.t()
  def greet(name) do
    "Hello, #{name}!"
  end

  @doc false  # 문서에서 숨김
  def internal_function, do: :ok
end
```

### 타입 스펙 (@spec)

```elixir
defmodule Types do
  @type user :: %{name: String.t(), age: non_neg_integer()}

  @spec add(number(), number()) :: number()
  def add(a, b), do: a + b

  @spec find_user(integer()) :: {:ok, user()} | {:error, String.t()}
  def find_user(id) do
    # ...
  end

  # 기본 타입들
  # any(), none(), atom(), map(), pid(), port(), reference(),
  # tuple(), float(), integer(), neg_integer(), non_neg_integer(),
  # pos_integer(), list(type), nonempty_list(type),
  # maybe_improper_list(), mfa(), module(), node(),
  # timeout(), no_return(), term(), binary(), bitstring(),
  # boolean(), byte(), char(), charlist(), nonempty_charlist(),
  # fun(), function(), identifier(), iodata(), iolist(),
  # keyword(), keyword(type), list(), nonempty_list(),
  # number(), struct(), String.t()
end
```

---

## 연습 문제

### 1. FizzBuzz
1부터 100까지 출력하되:
- 3의 배수: "Fizz"
- 5의 배수: "Buzz"
- 15의 배수: "FizzBuzz"

```elixir
# 힌트
defmodule FizzBuzz do
  def run do
    1..100
    |> Enum.map(&fizzbuzz/1)
    |> Enum.each(&IO.puts/1)
  end

  defp fizzbuzz(n) when rem(n, 15) == 0, do: "FizzBuzz"
  defp fizzbuzz(n) when rem(n, 3) == 0, do: "Fizz"
  defp fizzbuzz(n) when rem(n, 5) == 0, do: "Buzz"
  defp fizzbuzz(n), do: n
end
```

### 2. 팩토리얼
재귀를 사용해 팩토리얼 함수 구현

### 3. 피보나치
n번째 피보나치 수를 반환하는 함수 구현 (꼬리 재귀 사용)

### 4. 리스트 뒤집기
Enum.reverse/1 없이 리스트를 뒤집는 함수 구현

---

## 다음 단계

[02. 컬렉션과 Enum](../02_collections/README.md)에서 리스트, 맵, Enum 모듈을 학습합니다.
