# 02. 컬렉션과 Enum/Stream

## 목차

1. [리스트 (Lists)](#리스트-lists)
2. [키워드 리스트 (Keyword Lists)](#키워드-리스트-keyword-lists)
3. [맵 (Maps)](#맵-maps)
4. [구조체 (Structs)](#구조체-structs)
5. [Enum 모듈](#enum-모듈)
6. [Stream 모듈](#stream-모듈)
7. [컴프리헨션](#컴프리헨션)

---

## 리스트 (Lists)

Elixir의 리스트는 **단일 연결 리스트 (Singly Linked List)**입니다.

### 기본 사용

```elixir
# 생성
list = [1, 2, 3, 4, 5]
mixed = [1, "hello", :atom, 3.14]

# 연결
[1, 2] ++ [3, 4]   # [1, 2, 3, 4]
[1, 2, 3] -- [2]   # [1, 3]

# 포함 확인
1 in [1, 2, 3]     # true
```

### Head와 Tail

```elixir
list = [1, 2, 3, 4, 5]

# 함수 사용
hd(list)  # 1
tl(list)  # [2, 3, 4, 5]

# 패턴 매칭
[head | tail] = list
head  # 1
tail  # [2, 3, 4, 5]

# 앞에 요소 추가 (O(1))
[0 | list]  # [0, 1, 2, 3, 4, 5]

# 뒤에 추가 (O(n) - 비효율적!)
list ++ [6]  # [1, 2, 3, 4, 5, 6]
```

### 성능 특성

| 연산 | 시간 복잡도 |
|------|------------|
| 앞에 추가 `[x \| list]` | O(1) |
| 뒤에 추가 `list ++ [x]` | O(n) |
| 길이 `length/1` | O(n) |
| 인덱스 접근 `Enum.at/2` | O(n) |
| 연결 `++` | O(n) |

### List 모듈 함수

```elixir
List.first([1, 2, 3])          # 1
List.last([1, 2, 3])           # 3
List.delete([1, 2, 3], 2)      # [1, 3]
List.insert_at([1, 2, 3], 1, 10)  # [1, 10, 2, 3]
List.flatten([[1, 2], [3, 4]])    # [1, 2, 3, 4]
List.zip([1, 2], [:a, :b])        # [{1, :a}, {2, :b}]
```

---

## 키워드 리스트 (Keyword Lists)

원자 키를 가진 튜플의 리스트입니다.

```elixir
# 이 둘은 동일
opts = [name: "Kim", age: 25]
opts = [{:name, "Kim"}, {:age, 25}]

# 값 접근
opts[:name]                    # "Kim"
Keyword.get(opts, :name)       # "Kim"
Keyword.get(opts, :email, "N/A")  # "N/A" (기본값)

# 중복 키 허용!
[a: 1, b: 2, a: 3][:a]  # 1 (첫 번째만)
Keyword.get_values([a: 1, b: 2, a: 3], :a)  # [1, 3]
```

### 함수 옵션으로 사용

```elixir
def greet(name, opts \\ []) do
  greeting = Keyword.get(opts, :greeting, "Hello")
  punctuation = Keyword.get(opts, :punctuation, "!")
  "#{greeting}, #{name}#{punctuation}"
end

greet("Kim")                        # "Hello, Kim!"
greet("Kim", greeting: "안녕")       # "안녕, Kim!"
greet("Kim", greeting: "Hi", punctuation: "?")  # "Hi, Kim?"
```

---

## 맵 (Maps)

키-값 쌍을 저장하는 자료구조입니다.

### 기본 사용

```elixir
# 생성
map = %{name: "Kim", age: 25}        # 원자 키
map = %{"name" => "Kim", "age" => 25}  # 문자열 키

# 접근
map[:name]              # "Kim" (없으면 nil)
map.name                # "Kim" (원자 키만, 없으면 에러)
Map.get(map, :name)     # "Kim"
Map.get(map, :email, "없음")  # "없음"

# 업데이트 (기존 키만)
%{map | age: 26}        # %{name: "Kim", age: 26}

# 추가/업데이트
Map.put(map, :email, "kim@test.com")
Map.merge(map, %{email: "kim@test.com", city: "Seoul"})

# 삭제
Map.delete(map, :age)
```

### Map 모듈 함수

```elixir
user = %{name: "Kim", age: 25, city: "Seoul"}

Map.keys(user)          # [:age, :city, :name]
Map.values(user)        # [25, "Seoul", "Kim"]
Map.has_key?(user, :name)  # true
Map.take(user, [:name, :age])  # %{age: 25, name: "Kim"}
Map.drop(user, [:city])        # %{age: 25, name: "Kim"}
Map.to_list(user)       # [age: 25, city: "Seoul", name: "Kim"]
```

### 중첩 맵

```elixir
data = %{
  user: %{
    name: "Kim",
    address: %{city: "Seoul", zip: "12345"}
  }
}

# 접근
data.user.address.city           # "Seoul"
get_in(data, [:user, :address, :city])  # "Seoul"

# 업데이트
put_in(data, [:user, :address, :city], "Busan")
update_in(data, [:user, :name], &String.upcase/1)
```

---

## 구조체 (Structs)

맵의 확장으로, 정해진 필드만 가질 수 있습니다.

```elixir
defmodule User do
  defstruct name: "Unknown", age: 0, email: nil

  def adult?(%User{age: age}), do: age >= 18
end

# 생성
user = %User{name: "Kim", age: 25}

# 필드 접근
user.name  # "Kim"

# 업데이트
%{user | age: 26}

# 패턴 매칭
%User{name: name} = user
```

---

## Enum 모듈

Enum은 컬렉션을 다루는 핵심 모듈입니다. **즉시 평가 (Eager)**됩니다.

### 변환

```elixir
# map - 각 요소 변환
Enum.map([1, 2, 3], fn x -> x * 2 end)  # [2, 4, 6]
Enum.map([1, 2, 3], &(&1 * 2))          # [2, 4, 6]

# flat_map - map + flatten
Enum.flat_map([[1, 2], [3, 4]], fn x -> x end)  # [1, 2, 3, 4]
Enum.flat_map([1, 2, 3], fn x -> [x, x] end)    # [1, 1, 2, 2, 3, 3]
```

### 필터링

```elixir
# filter - 조건 만족하는 것만
Enum.filter([1, 2, 3, 4, 5], fn x -> rem(x, 2) == 0 end)  # [2, 4]

# reject - 조건 만족하지 않는 것만
Enum.reject([1, 2, 3, 4, 5], fn x -> rem(x, 2) == 0 end)  # [1, 3, 5]

# take / drop
Enum.take([1, 2, 3, 4, 5], 3)   # [1, 2, 3]
Enum.drop([1, 2, 3, 4, 5], 3)   # [4, 5]

# take_while / drop_while
Enum.take_while([1, 2, 3, 4, 5], &(&1 < 4))  # [1, 2, 3]
```

### 검색

```elixir
Enum.find([1, 2, 3, 4], fn x -> x > 2 end)  # 3
Enum.find_index([1, 2, 3], &(&1 == 2))      # 1

Enum.any?([1, 2, 3], &(&1 > 2))   # true
Enum.all?([1, 2, 3], &(&1 > 0))   # true
Enum.member?([1, 2, 3], 2)        # true
```

### 정렬

```elixir
Enum.sort([3, 1, 2])              # [1, 2, 3]
Enum.sort([3, 1, 2], :desc)       # [3, 2, 1]
Enum.sort_by(users, & &1.age)     # 나이순
Enum.sort_by(users, & &1.age, :desc)  # 나이 역순
```

### 집계

```elixir
Enum.count([1, 2, 3])             # 3
Enum.sum([1, 2, 3, 4, 5])         # 15
Enum.min([3, 1, 2])               # 1
Enum.max([3, 1, 2])               # 3

Enum.min_by(users, & &1.age)      # 최연소
Enum.max_by(users, & &1.age)      # 최연장

Enum.frequencies([:a, :b, :a, :c, :a])  # %{a: 3, b: 1, c: 1}
Enum.group_by(users, & &1.role)   # %{admin: [...], user: [...]}
```

### reduce (가장 강력한 함수)

```elixir
# 합계
Enum.reduce([1, 2, 3, 4, 5], 0, fn x, acc -> x + acc end)  # 15

# 축약
Enum.reduce([1, 2, 3, 4, 5], 0, &(&1 + &2))  # 15

# 맵으로 변환
Enum.reduce(["a", "b", "c"], %{}, fn x, acc ->
  Map.put(acc, x, String.upcase(x))
end)
# %{"a" => "A", "b" => "B", "c" => "C"}
```

### 파이프라인

```elixir
1..100
|> Enum.filter(&(rem(&1, 3) == 0))   # 3의 배수
|> Enum.map(&(&1 * &1))               # 제곱
|> Enum.take(5)                       # 처음 5개
|> Enum.sum()                         # 합계
```

---

## Stream 모듈

Stream은 **지연 평가 (Lazy)**되어 필요할 때만 계산합니다.

### Enum vs Stream

```elixir
# Enum: 즉시 평가 - 각 단계에서 전체 계산
1..1_000_000
|> Enum.map(&(&1 * 2))      # 100만 개 계산
|> Enum.filter(&(&1 > 100)) # 100만 개 필터
|> Enum.take(5)             # 5개만 필요했는데...

# Stream: 지연 평가 - 필요한 만큼만 계산
1..1_000_000
|> Stream.map(&(&1 * 2))
|> Stream.filter(&(&1 > 100))
|> Enum.take(5)             # 딱 5개만 계산!
```

### 무한 스트림

```elixir
# iterate - 반복 적용
naturals = Stream.iterate(1, &(&1 + 1))
Enum.take(naturals, 10)  # [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]

# cycle - 무한 반복
colors = Stream.cycle([:red, :green, :blue])
Enum.take(colors, 7)  # [:red, :green, :blue, :red, :green, :blue, :red]

# repeatedly - 함수 반복 호출
randoms = Stream.repeatedly(fn -> :rand.uniform(10) end)
Enum.take(randoms, 5)  # [3, 7, 1, 9, 4] (랜덤)

# unfold - 상태 기반 생성
fibs = Stream.unfold({0, 1}, fn {a, b} -> {a, {b, a + b}} end)
Enum.take(fibs, 10)  # [0, 1, 1, 2, 3, 5, 8, 13, 21, 34]
```

---

## 컴프리헨션

리스트, 맵 등을 간결하게 생성합니다.

```elixir
# 기본
for x <- 1..5, do: x * x
# [1, 4, 9, 16, 25]

# 필터
for x <- 1..10, rem(x, 2) == 0, do: x
# [2, 4, 6, 8, 10]

# 여러 생성자 (중첩 루프)
for x <- 1..3, y <- 1..3, do: {x, y}
# [{1,1}, {1,2}, {1,3}, {2,1}, ...]

# 조건
for x <- 1..3, y <- 1..3, x < y, do: {x, y}
# [{1,2}, {1,3}, {2,3}]

# 맵으로 변환
for x <- 1..5, into: %{}, do: {x, x * x}
# %{1 => 1, 2 => 4, 3 => 9, 4 => 16, 5 => 25}

# 문자열로 변환
for c <- ?a..?z, into: "", do: <<c>>
# "abcdefghijklmnopqrstuvwxyz"
```

---

## 연습 문제

### 1. 데이터 처리
```elixir
sales = [
  %{product: "A", amount: 1000},
  %{product: "B", amount: 1500},
  %{product: "A", amount: 2000}
]
```
- 제품별 총 판매액 계산
- 가장 많이 팔린 제품 찾기

### 2. 무한 스트림
- 소수(Prime)를 생성하는 무한 스트림 만들기
- 처음 20개 소수 출력

---

## 다음 단계

[03. OTP](./03_otp.md)에서 프로세스, GenServer, Supervisor를 학습합니다.
