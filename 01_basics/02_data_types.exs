# ===========================================
# 02. 기본 데이터 타입
# ===========================================

# -------------------------------------------
# 숫자 (Numbers)
# -------------------------------------------

# 정수 (Integer)
integer = 42
big_integer = 1_000_000  # 언더스코어로 가독성 향상
hex = 0xFF               # 16진수 = 255
binary = 0b1010          # 2진수 = 10
octal = 0o777            # 8진수 = 511

IO.puts("정수: #{integer}, 큰 정수: #{big_integer}")
IO.puts("16진수: #{hex}, 2진수: #{binary}, 8진수: #{octal}")

# 실수 (Float)
float = 3.14
scientific = 1.5e10  # 과학적 표기법

IO.puts("실수: #{float}, 과학적 표기: #{scientific}")

# 산술 연산
IO.puts("10 + 3 = #{10 + 3}")
IO.puts("10 - 3 = #{10 - 3}")
IO.puts("10 * 3 = #{10 * 3}")
IO.puts("10 / 3 = #{10 / 3}")      # 항상 float 반환
IO.puts("div(10, 3) = #{div(10, 3)}")  # 정수 나눗셈
IO.puts("rem(10, 3) = #{rem(10, 3)}")  # 나머지

# -------------------------------------------
# 원자 (Atoms)
# -------------------------------------------

# 원자: 이름 자체가 값인 상수
status = :ok
error = :error
custom = :my_custom_atom

IO.puts("상태: #{status}")
IO.inspect([:ok, :error, :pending], label: "원자 리스트")

# 불리언은 원자의 특수한 형태
IO.puts("true는 원자인가? #{is_atom(true)}")
IO.puts("false는 원자인가? #{is_atom(false)}")
IO.puts("nil은 원자인가? #{is_atom(nil)}")

# -------------------------------------------
# 문자열 (Strings)
# -------------------------------------------

string = "Hello, Elixir!"
korean = "안녕하세요"

# 문자열 연결
combined = "Hello" <> " " <> "World"
IO.puts("연결: #{combined}")

# 문자열 함수들
IO.puts("길이: #{String.length(string)}")
IO.puts("대문자: #{String.upcase(string)}")
IO.puts("소문자: #{String.downcase(string)}")
IO.puts("분할: #{inspect(String.split(string, ", "))}")
IO.puts("포함?: #{String.contains?(string, "Elixir")}")

# 문자 리스트 (Charlist) - 작은따옴표 사용
charlist = 'hello'
IO.inspect(charlist, label: "문자 리스트")  # [104, 101, 108, 108, 111]

# -------------------------------------------
# 튜플 (Tuples)
# -------------------------------------------

# 튜플: 고정 크기, 연속 메모리
point = {10, 20}
rgb = {255, 128, 0}
result = {:ok, "성공했습니다"}
error_result = {:error, "실패했습니다"}

IO.inspect(point, label: "좌표")
IO.puts("첫 번째 요소: #{elem(point, 0)}")
IO.puts("두 번째 요소: #{elem(point, 1)}")
IO.puts("튜플 크기: #{tuple_size(rgb)}")

# 튜플 수정 (새 튜플 반환)
new_point = put_elem(point, 0, 100)
IO.inspect(new_point, label: "수정된 좌표")

# -------------------------------------------
# 비교 연산자
# -------------------------------------------

IO.puts("\n=== 비교 연산자 ===")
IO.puts("1 == 1.0: #{1 == 1.0}")   # 값 비교 (true)
IO.puts("1 === 1.0: #{1 === 1.0}") # 타입까지 비교 (false)
IO.puts("1 != 2: #{1 != 2}")       # 같지 않음
IO.puts("1 !== 1.0: #{1 !== 1.0}") # 타입까지 다름

IO.puts("1 < 2: #{1 < 2}")
IO.puts("1 <= 1: #{1 <= 1}")
IO.puts("2 > 1: #{2 > 1}")
IO.puts("2 >= 2: #{2 >= 2}")

# -------------------------------------------
# 논리 연산자
# -------------------------------------------

IO.puts("\n=== 논리 연산자 ===")
# and, or, not - 첫 인자가 반드시 boolean
IO.puts("true and false: #{true and false}")
IO.puts("true or false: #{true or false}")
IO.puts("not true: #{not true}")

# &&, ||, ! - 모든 값에 사용 가능 (falsy: nil, false)
IO.puts("nil || 42: #{nil || 42}")
IO.puts("42 && 13: #{42 && 13}")
IO.puts("!nil: #{!nil}")

# ============================================
# 실습: 타입을 확인해보세요
# ============================================

IO.puts("\n=== 타입 확인 함수 ===")
IO.puts("is_integer(42): #{is_integer(42)}")
IO.puts("is_float(3.14): #{is_float(3.14)}")
IO.puts("is_atom(:ok): #{is_atom(:ok)}")
IO.puts("is_binary(\"hello\"): #{is_binary("hello")}")  # 문자열은 binary
IO.puts("is_tuple({1, 2}): #{is_tuple({1, 2})}")
