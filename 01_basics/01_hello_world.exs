# ===========================================
# 01. Hello World - 첫 번째 Elixir 프로그램
# ===========================================

# IO.puts - 문자열 출력 후 줄바꿈
IO.puts("Hello, World!")
IO.puts("안녕하세요, Elixir!")

# IO.write - 줄바꿈 없이 출력
IO.write("Hello ")
IO.write("Elixir")
IO.puts("")  # 줄바꿈

# IO.inspect - 디버깅용 출력 (값을 그대로 반환)
IO.inspect([1, 2, 3], label: "리스트")
IO.inspect(%{name: "Kim", age: 25}, label: "맵")

# 문자열 보간 (String Interpolation)
name = "Elixir"
version = 1.15
IO.puts("#{name} version #{version}")

# 여러 줄 문자열 (Heredoc)
message = """
여러 줄에 걸친
문자열을 작성할 수 있습니다.
들여쓰기도 유지됩니다.
"""
IO.puts(message)

# ============================================
# 실습: 아래 코드를 수정해보세요
# ============================================

# TODO: 자신의 이름을 출력해보세요
# my_name = "..."
# IO.puts("제 이름은 #{my_name}입니다.")
