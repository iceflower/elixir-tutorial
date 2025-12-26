# ===========================================
# 03. 패턴 매칭 (Pattern Matching)
# ===========================================
# Elixir에서 = 는 할당이 아닌 "매치 연산자"입니다.
# 좌변의 패턴과 우변의 값을 매칭시킵니다.

# -------------------------------------------
# 기본 매칭
# -------------------------------------------

# 변수 바인딩
x = 1
IO.puts("x = #{x}")

# 매칭 확인 (같으면 통과, 다르면 MatchError)
1 = x  # 성공: x는 1이므로 매칭됨
# 2 = x  # 실패: MatchError 발생!

# 변수 재바인딩
x = 2
IO.puts("재바인딩 후 x = #{x}")

# 핀 연산자 (^) - 재바인딩 방지, 기존 값으로 매칭
x = 1
^x = 1  # 성공: x의 값(1)과 매칭
# ^x = 2  # 실패: x는 1인데 2와 매칭 시도

# -------------------------------------------
# 튜플 매칭
# -------------------------------------------

IO.puts("\n=== 튜플 매칭 ===")

# 튜플 분해 (Destructuring)
{a, b, c} = {1, 2, 3}
IO.puts("a=#{a}, b=#{b}, c=#{c}")

# 일부만 추출
{first, _, _} = {10, 20, 30}  # _ 는 무시
IO.puts("first = #{first}")

# 함수 결과 패턴 매칭 (매우 흔한 패턴)
{:ok, result} = {:ok, "성공!"}
IO.puts("result = #{result}")

# 에러 처리 패턴
response = {:error, "파일을 찾을 수 없습니다"}

case response do
  {:ok, data} ->
    IO.puts("성공: #{data}")
  {:error, reason} ->
    IO.puts("실패: #{reason}")
end

# -------------------------------------------
# 리스트 매칭
# -------------------------------------------

IO.puts("\n=== 리스트 매칭 ===")

# 리스트 분해
[head | tail] = [1, 2, 3, 4, 5]
IO.puts("head = #{head}")        # 1
IO.inspect(tail, label: "tail")  # [2, 3, 4, 5]

# 여러 요소 추출
[first, second | rest] = [1, 2, 3, 4, 5]
IO.puts("first=#{first}, second=#{second}")
IO.inspect(rest, label: "rest")

# 정확한 요소 매칭
[a, b, c] = [1, 2, 3]  # 정확히 3개여야 함
IO.puts("a=#{a}, b=#{b}, c=#{c}")

# 첫 번째 요소 고정하고 매칭
[1 | rest] = [1, 2, 3]  # 첫 요소가 1이어야 함
IO.inspect(rest, label: "1 이후")

# -------------------------------------------
# 맵 매칭
# -------------------------------------------

IO.puts("\n=== 맵 매칭 ===")

user = %{name: "Kim", age: 25, city: "Seoul"}

# 일부 키만 매칭 (나머지는 무시됨)
%{name: user_name} = user
IO.puts("이름: #{user_name}")

# 여러 키 매칭
%{name: n, age: a} = user
IO.puts("#{n}님은 #{a}살입니다")

# 변수를 키로 사용
key = :city
%{^key => city_value} = user
IO.puts("도시: #{city_value}")

# -------------------------------------------
# 함수 인자에서의 패턴 매칭
# -------------------------------------------

IO.puts("\n=== 함수에서 패턴 매칭 ===")

defmodule Greeting do
  # 패턴에 따라 다른 함수 실행 (함수 오버로딩)
  def hello(%{name: name, language: "ko"}), do: "안녕하세요, #{name}님!"
  def hello(%{name: name, language: "en"}), do: "Hello, #{name}!"
  def hello(%{name: name}), do: "Hi, #{name}!"

  # 튜플 패턴 매칭
  def handle_result({:ok, value}), do: "성공: #{value}"
  def handle_result({:error, reason}), do: "에러: #{reason}"
end

IO.puts(Greeting.hello(%{name: "Kim", language: "ko"}))
IO.puts(Greeting.hello(%{name: "Kim", language: "en"}))
IO.puts(Greeting.hello(%{name: "Kim"}))

IO.puts(Greeting.handle_result({:ok, "데이터"}))
IO.puts(Greeting.handle_result({:error, "실패"}))

# -------------------------------------------
# case 표현식
# -------------------------------------------

IO.puts("\n=== case 표현식 ===")

value = {:ok, 42}

result = case value do
  {:ok, n} when n > 0 ->
    "양수: #{n}"
  {:ok, n} when n < 0 ->
    "음수: #{n}"
  {:ok, 0} ->
    "영"
  {:error, _} ->
    "에러 발생"
  _ ->
    "알 수 없음"
end

IO.puts(result)

# ============================================
# 실습: 다음 데이터를 패턴 매칭으로 분해해보세요
# ============================================

# data = %{
#   user: %{name: "Lee", email: "lee@example.com"},
#   orders: [{:completed, 1000}, {:pending, 500}]
# }

# TODO: user의 name 추출
# TODO: 첫 번째 order의 금액 추출
