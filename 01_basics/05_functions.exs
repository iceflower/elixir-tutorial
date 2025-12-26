# ===========================================
# 05. 함수 (Functions)
# ===========================================

# -------------------------------------------
# 익명 함수 (Anonymous Functions)
# -------------------------------------------

IO.puts("=== 익명 함수 ===")

# 익명 함수 정의
add = fn a, b -> a + b end

# 호출 시 점(.) 필요
IO.puts("3 + 5 = #{add.(3, 5)}")

# 여러 줄 익명 함수
greet = fn name ->
  greeting = "안녕하세요"
  "#{greeting}, #{name}님!"
end
IO.puts(greet.("Kim"))

# 축약 문법 (&)
multiply = &(&1 * &2)
IO.puts("4 * 7 = #{multiply.(4, 7)}")

square = &(&1 * &1)
IO.puts("9^2 = #{square.(9)}")

# 기존 함수를 캡처
upcase = &String.upcase/1
IO.puts(upcase.("hello"))

# 패턴 매칭하는 익명 함수
handle = fn
  {:ok, value} -> "성공: #{value}"
  {:error, reason} -> "실패: #{reason}"
end

IO.puts(handle.({:ok, "데이터"}))
IO.puts(handle.({:error, "오류"}))

# -------------------------------------------
# 모듈과 명명된 함수
# -------------------------------------------

IO.puts("\n=== 명명된 함수 ===")

defmodule Math do
  # 기본 함수 정의
  def add(a, b) do
    a + b
  end

  # 한 줄 함수
  def subtract(a, b), do: a - b

  # 기본값 (Default Arguments)
  def multiply(a, b \\ 1), do: a * b

  # 프라이빗 함수 (모듈 내부에서만 사용)
  defp secret_formula(x), do: x * 42

  def apply_secret(x), do: secret_formula(x)

  # 가드 (Guards)를 사용한 함수
  def divide(a, b) when b != 0, do: a / b
  def divide(_, 0), do: {:error, "0으로 나눌 수 없습니다"}

  # 여러 절(clause)을 가진 함수
  def describe(n) when n < 0, do: "음수"
  def describe(0), do: "영"
  def describe(n) when n > 0, do: "양수"
end

IO.puts("5 + 3 = #{Math.add(5, 3)}")
IO.puts("5 - 3 = #{Math.subtract(5, 3)}")
IO.puts("5 * 기본값 = #{Math.multiply(5)}")
IO.puts("5 * 4 = #{Math.multiply(5, 4)}")
IO.puts("10 / 3 = #{Math.divide(10, 3)}")
IO.inspect(Math.divide(10, 0), label: "10 / 0")
IO.puts("describe(-5) = #{Math.describe(-5)}")
IO.puts("apply_secret(2) = #{Math.apply_secret(2)}")

# -------------------------------------------
# 재귀 (Recursion)
# -------------------------------------------

IO.puts("\n=== 재귀 ===")

defmodule Recursion do
  # 팩토리얼
  def factorial(0), do: 1
  def factorial(n) when n > 0 do
    n * factorial(n - 1)
  end

  # 리스트 합계
  def sum([]), do: 0
  def sum([head | tail]), do: head + sum(tail)

  # 꼬리 재귀 최적화 (Tail Call Optimization)
  def sum_tail(list), do: sum_tail(list, 0)
  defp sum_tail([], acc), do: acc
  defp sum_tail([head | tail], acc), do: sum_tail(tail, acc + head)

  # 리스트 길이
  def length([]), do: 0
  def length([_ | tail]), do: 1 + length(tail)

  # map 구현
  def map([], _func), do: []
  def map([head | tail], func), do: [func.(head) | map(tail, func)]
end

IO.puts("5! = #{Recursion.factorial(5)}")
IO.puts("sum([1,2,3,4,5]) = #{Recursion.sum([1, 2, 3, 4, 5])}")
IO.puts("sum_tail([1,2,3,4,5]) = #{Recursion.sum_tail([1, 2, 3, 4, 5])}")
IO.puts("length([1,2,3]) = #{Recursion.length([1, 2, 3])}")
IO.inspect(Recursion.map([1, 2, 3], &(&1 * 2)), label: "map([1,2,3], *2)")

# -------------------------------------------
# 파이프 연산자 (|>)
# -------------------------------------------

IO.puts("\n=== 파이프 연산자 ===")

# 파이프 없이 (중첩 함수 호출)
result1 = String.upcase(String.trim("  hello world  "))
IO.puts("중첩: #{result1}")

# 파이프 사용 (왼쪽 결과를 오른쪽 함수의 첫 인자로)
result2 = "  hello world  "
  |> String.trim()
  |> String.upcase()
  |> String.split()

IO.inspect(result2, label: "파이프")

# 실전 예제
numbers = 1..10
  |> Enum.filter(&(rem(&1, 2) == 0))  # 짝수만
  |> Enum.map(&(&1 * &1))             # 제곱
  |> Enum.sum()                        # 합계

IO.puts("1-10 짝수의 제곱 합: #{numbers}")

# -------------------------------------------
# 고차 함수 (Higher-Order Functions)
# -------------------------------------------

IO.puts("\n=== 고차 함수 ===")

defmodule HigherOrder do
  # 함수를 인자로 받음
  def apply_twice(func, value) do
    func.(func.(value))
  end

  # 함수를 반환
  def multiplier(factor) do
    fn x -> x * factor end
  end

  # 함수 합성
  def compose(f, g) do
    fn x -> f.(g.(x)) end
  end
end

double = fn x -> x * 2 end
IO.puts("apply_twice(double, 3) = #{HigherOrder.apply_twice(double, 3)}")

triple = HigherOrder.multiplier(3)
IO.puts("triple(4) = #{triple.(4)}")

add_one = &(&1 + 1)
square = &(&1 * &1)
add_then_square = HigherOrder.compose(square, add_one)
IO.puts("(3 + 1)^2 = #{add_then_square.(3)}")

# ============================================
# 실습: 피보나치 수열 함수 구현
# ============================================

# TODO: 재귀를 사용해 n번째 피보나치 수를 계산하는 함수
# fib(0) = 0, fib(1) = 1, fib(n) = fib(n-1) + fib(n-2)
