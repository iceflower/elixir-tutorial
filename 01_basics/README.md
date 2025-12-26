# 01. Elixir 기초 문법

## 목차

1. [Hello World](#hello-world)
2. [기본 데이터 타입](#기본-데이터-타입)
3. [연산자](#연산자)
4. [패턴 매칭](#패턴-매칭)
5. [제어 흐름](#제어-흐름)
6. [함수](#함수)
7. [모듈](#모듈)

---

## Hello World

### 첫 번째 프로그램

```elixir
# hello.exs
IO.puts("Hello, World!")
IO.puts("안녕하세요, Elixir!")
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

```elixir
IO.puts("Hello")        # Hello\n
IO.write("Hello ")      # Hello (줄바꿈 없음)
IO.inspect([1,2,3])     # [1, 2, 3] (값 반환)

# inspect는 파이프라인에서 유용
[1, 2, 3]
|> IO.inspect(label: "before")
|> Enum.map(&(&1 * 2))
|> IO.inspect(label: "after")
```

### 문자열 보간 (Interpolation)

```elixir
name = "Elixir"
version = 1.15

IO.puts("#{name} version #{version}")
# => Elixir version 1.15

# 표현식도 가능
IO.puts("2 + 2 = #{2 + 2}")
# => 2 + 2 = 4
```

---

## 기본 데이터 타입

### 숫자 (Numbers)

```elixir
# 정수 (Integer)
integer = 42
big_int = 1_000_000      # 언더스코어로 가독성 향상
hex = 0xFF               # 16진수 = 255
binary = 0b1010          # 2진수 = 10
octal = 0o777            # 8진수 = 511

# 실수 (Float)
float = 3.14159
scientific = 1.5e-10     # 과학적 표기법
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

# 여러 줄 문자열
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
```

### 문자 리스트 (Charlists)

```elixir
# 작은따옴표 = 문자 리스트 (정수 리스트)
charlist = 'hello'
charlist == [104, 101, 108, 108, 111]  # true

# 문자열과 다름!
"hello" == 'hello'  # false

# 변환
to_charlist("hello")  # 'hello'
to_string('hello')    # "hello"
```

### 튜플 (Tuples)

```elixir
# 고정 크기, 연속 메모리
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
is_atom(:ok)         # true
is_binary("hello")   # true (문자열)
is_list([1, 2, 3])   # true
is_tuple({1, 2})     # true
is_map(%{a: 1})      # true
is_function(fn -> end)  # true
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

### 문자열 연산자

```elixir
"Hello" <> " " <> "World"  # 연결
```

### 리스트 연산자

```elixir
[1, 2] ++ [3, 4]   # [1, 2, 3, 4] (연결)
[1, 2, 3] -- [2]   # [1, 3] (빼기)
1 in [1, 2, 3]     # true (포함 확인)
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
  true -> "F"  # else
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

---

## 함수

### 익명 함수

```elixir
# 정의
add = fn a, b -> a + b end

# 호출 (점 필요!)
add.(3, 5)  # 8

# 축약 문법
multiply = &(&1 * &2)
multiply.(4, 7)  # 28

square = &(&1 * &1)
square.(9)  # 81
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
  def type(_), do: "기타"
end
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

  @doc """
  두 숫자를 더합니다.
  """
  def add(a, b), do: a + b

  def circle_area(radius) do
    @pi * radius * radius
  end
end
```

### 구조체 (Structs)

```elixir
defmodule User do
  defstruct name: "Unknown", age: 0, email: nil

  def adult?(%User{age: age}), do: age >= 18
end

# 생성
user = %User{name: "Kim", age: 25}

# 업데이트
older = %{user | age: 26}

# 패턴 매칭
%User{name: name} = user
```

### alias, import, use

```elixir
defmodule MyApp do
  # 모듈 이름 줄이기
  alias MyApp.Accounts.User
  # User로 바로 사용 가능

  # 함수 가져오기
  import String, only: [upcase: 1]
  # upcase("hello") 바로 사용

  # 매크로/콜백 주입
  use GenServer
end
```

---

## 연습 문제

### 1. FizzBuzz
1부터 100까지 출력하되:
- 3의 배수: "Fizz"
- 5의 배수: "Buzz"
- 15의 배수: "FizzBuzz"

### 2. 팩토리얼
재귀를 사용해 팩토리얼 함수 구현

### 3. 피보나치
n번째 피보나치 수를 반환하는 함수 구현

---

## 다음 단계

[02. 컬렉션과 Enum](./02_collections.md)에서 리스트, 맵, Enum 모듈을 학습합니다.
