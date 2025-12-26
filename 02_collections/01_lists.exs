# ===========================================
# 01. 리스트 (Lists)
# ===========================================

# -------------------------------------------
# 기본 리스트
# -------------------------------------------

IO.puts("=== 기본 리스트 ===")

# 리스트 생성
numbers = [1, 2, 3, 4, 5]
mixed = [1, "hello", :atom, 3.14]
nested = [[1, 2], [3, 4], [5, 6]]

IO.inspect(numbers, label: "숫자 리스트")
IO.inspect(mixed, label: "혼합 리스트")
IO.inspect(nested, label: "중첩 리스트")

# 리스트 연결 (++)
list1 = [1, 2, 3]
list2 = [4, 5, 6]
combined = list1 ++ list2
IO.inspect(combined, label: "연결")

# 리스트 빼기 (--)
subtracted = [1, 2, 3, 4, 5] -- [2, 4]
IO.inspect(subtracted, label: "빼기")

# 요소 확인
IO.puts("1 in [1,2,3]? #{1 in [1, 2, 3]}")
IO.puts("4 in [1,2,3]? #{4 in [1, 2, 3]}")

# -------------------------------------------
# Head와 Tail
# -------------------------------------------

IO.puts("\n=== Head / Tail ===")

list = [1, 2, 3, 4, 5]

# hd와 tl 함수
IO.puts("head: #{hd(list)}")
IO.inspect(tl(list), label: "tail")

# 패턴 매칭으로 분해
[head | tail] = list
IO.puts("head: #{head}")
IO.inspect(tail, label: "tail")

# 여러 요소 추출
[first, second | rest] = list
IO.puts("first: #{first}, second: #{second}")
IO.inspect(rest, label: "rest")

# 앞에 요소 추가 (Cons 연산자) - O(1)
new_list = [0 | list]
IO.inspect(new_list, label: "0 추가")

# 뒤에 추가 - O(n) 주의!
appended = list ++ [6]
IO.inspect(appended, label: "6 추가")

# -------------------------------------------
# 리스트 함수들
# -------------------------------------------

IO.puts("\n=== List 모듈 함수 ===")

list = [1, 2, 3, 4, 5]

IO.puts("length: #{length(list)}")
IO.puts("first: #{List.first(list)}")
IO.puts("last: #{List.last(list)}")
IO.inspect(List.delete(list, 3), label: "3 삭제")
IO.inspect(List.insert_at(list, 2, 100), label: "인덱스 2에 삽입")
IO.inspect(List.flatten([[1, 2], [3, [4, 5]]]), label: "평탄화")

# 리스트를 튜플로
IO.inspect(List.to_tuple([1, 2, 3]), label: "튜플로")

# zip - 두 리스트 결합
names = ["Kim", "Lee", "Park"]
ages = [25, 30, 35]
IO.inspect(Enum.zip(names, ages), label: "zip")

# -------------------------------------------
# 재귀로 리스트 처리
# -------------------------------------------

IO.puts("\n=== 재귀 리스트 처리 ===")

defmodule ListOps do
  # 합계
  def sum([]), do: 0
  def sum([head | tail]), do: head + sum(tail)

  # 최대값
  def max([x]), do: x
  def max([head | tail]) do
    tail_max = max(tail)
    if head > tail_max, do: head, else: tail_max
  end

  # 필터
  def filter([], _func), do: []
  def filter([head | tail], func) do
    if func.(head) do
      [head | filter(tail, func)]
    else
      filter(tail, func)
    end
  end

  # 역순
  def reverse(list), do: reverse(list, [])
  defp reverse([], acc), do: acc
  defp reverse([head | tail], acc), do: reverse(tail, [head | acc])
end

IO.puts("sum([1,2,3,4,5]) = #{ListOps.sum([1, 2, 3, 4, 5])}")
IO.puts("max([3,1,4,1,5,9]) = #{ListOps.max([3, 1, 4, 1, 5, 9])}")
IO.inspect(ListOps.filter([1, 2, 3, 4, 5], &(rem(&1, 2) == 0)), label: "짝수만")
IO.inspect(ListOps.reverse([1, 2, 3, 4, 5]), label: "역순")

# -------------------------------------------
# 키워드 리스트 (Keyword Lists)
# -------------------------------------------

IO.puts("\n=== 키워드 리스트 ===")

# 키워드 리스트: 원자 키를 가진 튜플의 리스트
# [{:name, "Kim"}, {:age, 25}] 와 동일
opts = [name: "Kim", age: 25, city: "Seoul"]

IO.inspect(opts, label: "키워드 리스트")

# 값 접근
IO.puts("name: #{opts[:name]}")
IO.puts("age: #{Keyword.get(opts, :age)}")
IO.puts("없는 키: #{Keyword.get(opts, :email, "기본값")}")

# 키워드 리스트는 중복 키 허용!
duplicates = [a: 1, b: 2, a: 3]
IO.inspect(duplicates, label: "중복 키")
IO.puts("첫 번째 :a = #{duplicates[:a]}")  # 첫 번째 값만
IO.inspect(Keyword.get_values(duplicates, :a), label: "모든 :a 값")

# 주요 사용처: 함수 옵션
defmodule Formatter do
  def format(text, opts \\ []) do
    uppercase = Keyword.get(opts, :uppercase, false)
    prefix = Keyword.get(opts, :prefix, "")

    result = if uppercase, do: String.upcase(text), else: text
    prefix <> result
  end
end

IO.puts(Formatter.format("hello"))
IO.puts(Formatter.format("hello", uppercase: true))
IO.puts(Formatter.format("hello", prefix: "> ", uppercase: true))

# -------------------------------------------
# 리스트 컴프리헨션
# -------------------------------------------

IO.puts("\n=== 리스트 컴프리헨션 ===")

# 기본 형태
squares = for x <- 1..5, do: x * x
IO.inspect(squares, label: "제곱")

# 필터 조건
evens = for x <- 1..10, rem(x, 2) == 0, do: x
IO.inspect(evens, label: "짝수")

# 여러 생성자 (중첩 루프)
pairs = for x <- 1..3, y <- 1..3, do: {x, y}
IO.inspect(pairs, label: "모든 쌍")

# 조건과 함께
valid_pairs = for x <- 1..3, y <- 1..3, x < y, do: {x, y}
IO.inspect(valid_pairs, label: "x < y인 쌍")

# 맵으로 변환
squares_map = for x <- 1..5, into: %{}, do: {x, x * x}
IO.inspect(squares_map, label: "제곱 맵")

# ============================================
# 실습: 리스트 연습
# ============================================

# TODO: 주어진 리스트에서 3의 배수만 추출하고 각 값을 2배로 만들기
# numbers = [1, 3, 5, 6, 9, 10, 12, 15]
# 결과: [6, 12, 18, 24, 30]
