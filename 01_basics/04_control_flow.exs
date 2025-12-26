# ===========================================
# 04. 조건문과 제어 흐름
# ===========================================

# -------------------------------------------
# if / else
# -------------------------------------------

IO.puts("=== if / else ===")

age = 20

if age >= 18 do
  IO.puts("성인입니다")
else
  IO.puts("미성년자입니다")
end

# 한 줄 표현
status = if age >= 18, do: :adult, else: :minor
IO.puts("상태: #{status}")

# if만 사용 (else 없이)
if age >= 18 do
  IO.puts("투표할 수 있습니다")
end

# -------------------------------------------
# unless (if not)
# -------------------------------------------

IO.puts("\n=== unless ===")

logged_in = false

unless logged_in do
  IO.puts("로그인이 필요합니다")
end

# 한 줄 표현
message = unless logged_in, do: "로그인 필요", else: "환영합니다"
IO.puts(message)

# -------------------------------------------
# cond - 여러 조건 분기
# -------------------------------------------

IO.puts("\n=== cond ===")

score = 85

grade = cond do
  score >= 90 -> "A"
  score >= 80 -> "B"
  score >= 70 -> "C"
  score >= 60 -> "D"
  true -> "F"  # else 역할 (항상 true)
end

IO.puts("점수 #{score}점 -> 학점 #{grade}")

# 실제 사용 예
defmodule FizzBuzz do
  def run(n) do
    cond do
      rem(n, 15) == 0 -> "FizzBuzz"
      rem(n, 3) == 0 -> "Fizz"
      rem(n, 5) == 0 -> "Buzz"
      true -> to_string(n)
    end
  end
end

IO.puts("\nFizzBuzz 1-15:")
Enum.each(1..15, fn n ->
  IO.write("#{FizzBuzz.run(n)} ")
end)
IO.puts("")

# -------------------------------------------
# case - 패턴 매칭 기반 분기
# -------------------------------------------

IO.puts("\n=== case ===")

# 기본 사용
day = :monday

result = case day do
  :saturday -> "주말"
  :sunday -> "주말"
  _ -> "평일"
end
IO.puts("#{day}은 #{result}입니다")

# 가드 (Guards) 사용
number = 15

description = case number do
  n when n < 0 -> "음수"
  0 -> "영"
  n when n > 0 and rem(n, 2) == 0 -> "양수이며 짝수"
  n when n > 0 -> "양수이며 홀수"
end

IO.puts("#{number}은 #{description}")

# 튜플 매칭과 함께
response = {:ok, %{name: "Kim", role: :admin}}

case response do
  {:ok, %{role: :admin}} ->
    IO.puts("관리자 권한으로 접속")
  {:ok, %{role: :user}} ->
    IO.puts("일반 사용자로 접속")
  {:error, reason} ->
    IO.puts("에러: #{reason}")
end

# -------------------------------------------
# with - 연속적인 패턴 매칭
# -------------------------------------------

IO.puts("\n=== with ===")

# with는 여러 패턴 매칭을 순차적으로 수행
# 모두 성공하면 do 블록 실행, 실패하면 else로

user_input = %{name: "Kim", email: "kim@test.com", age: "25"}

result = with {:ok, name} <- validate_name(user_input.name),
              {:ok, email} <- validate_email(user_input.email),
              {:ok, age} <- parse_age(user_input.age) do
  {:ok, %{name: name, email: email, age: age}}
else
  {:error, field, reason} ->
    {:error, "#{field} 검증 실패: #{reason}"}
end

IO.inspect(result, label: "검증 결과")

# 헬퍼 함수들
defmodule Validators do
end

# 함수 정의 (위 with에서 사용)
defp validate_name(name) when is_binary(name) and byte_size(name) > 0 do
  {:ok, name}
end
defp validate_name(_), do: {:error, :name, "이름이 비어있습니다"}

defp validate_email(email) when is_binary(email) do
  if String.contains?(email, "@") do
    {:ok, email}
  else
    {:error, :email, "올바른 이메일 형식이 아닙니다"}
  end
end

defp parse_age(age_string) when is_binary(age_string) do
  case Integer.parse(age_string) do
    {age, ""} when age > 0 -> {:ok, age}
    _ -> {:error, :age, "올바른 나이가 아닙니다"}
  end
end

# -------------------------------------------
# 삼항 연산자 대안
# -------------------------------------------

IO.puts("\n=== 삼항 연산자 대안 ===")

# Elixir에는 삼항 연산자(?:)가 없음
# 대신 if/else 한 줄 표현 사용
x = 10
result = if x > 5, do: "크다", else: "작다"
IO.puts(result)

# 또는 case 사용
result2 = case x > 5 do
  true -> "크다"
  false -> "작다"
end
IO.puts(result2)

# ============================================
# 실습: HTTP 상태 코드 처리기 만들기
# ============================================

# TODO: case를 사용해서 HTTP 상태 코드를 메시지로 변환하는 함수 작성
# 200 -> "OK"
# 201 -> "Created"
# 400 -> "Bad Request"
# 401 -> "Unauthorized"
# 404 -> "Not Found"
# 500 -> "Internal Server Error"
# 기타 -> "Unknown Status"
