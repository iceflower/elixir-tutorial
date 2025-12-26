# ===========================================
# 04. Stream 모듈 - 지연 평가 (Lazy Evaluation)
# ===========================================

# Stream은 Enum과 비슷하지만 지연 평가됩니다.
# 실제로 값이 필요할 때까지 계산을 미룹니다.
# 큰 데이터나 무한 시퀀스를 다룰 때 유용합니다.

# -------------------------------------------
# Enum vs Stream 비교
# -------------------------------------------

IO.puts("=== Enum vs Stream ===")

# Enum: 즉시 평가 - 각 단계마다 전체 리스트 생성
enum_result = 1..5
  |> Enum.map(fn x ->
    IO.write("[Enum map #{x}] ")
    x * 2
  end)
  |> Enum.filter(fn x ->
    IO.write("[Enum filter #{x}] ")
    x > 4
  end)

IO.puts("\nEnum 결과: #{inspect(enum_result)}")

IO.puts("")

# Stream: 지연 평가 - 필요할 때만 계산
stream_result = 1..5
  |> Stream.map(fn x ->
    IO.write("[Stream map #{x}] ")
    x * 2
  end)
  |> Stream.filter(fn x ->
    IO.write("[Stream filter #{x}] ")
    x > 4
  end)
  |> Enum.to_list()  # 여기서 실제 계산 시작

IO.puts("\nStream 결과: #{inspect(stream_result)}")

# -------------------------------------------
# 무한 스트림
# -------------------------------------------

IO.puts("\n=== 무한 스트림 ===")

# iterate - 초기값에서 함수를 반복 적용
naturals = Stream.iterate(1, &(&1 + 1))
first_10 = naturals |> Enum.take(10)
IO.inspect(first_10, label: "자연수 10개")

# 피보나치 수열
fibs = Stream.unfold({0, 1}, fn {a, b} -> {a, {b, a + b}} end)
fib_10 = fibs |> Enum.take(10)
IO.inspect(fib_10, label: "피보나치 10개")

# cycle - 무한 반복
colors = Stream.cycle([:red, :green, :blue])
colors_6 = colors |> Enum.take(6)
IO.inspect(colors_6, label: "색상 6개")

# repeatedly - 함수를 반복 호출
randoms = Stream.repeatedly(fn -> :rand.uniform(100) end)
random_5 = randoms |> Enum.take(5)
IO.inspect(random_5, label: "랜덤 5개")

# -------------------------------------------
# Stream 함수들
# -------------------------------------------

IO.puts("\n=== Stream 함수들 ===")

# map, filter (지연 버전)
result = 1..1_000_000
  |> Stream.map(&(&1 * 2))
  |> Stream.filter(&(rem(&1, 3) == 0))
  |> Enum.take(5)

IO.inspect(result, label: "100만개 중 5개만 계산")

# take_while - 조건 만족하는 동안만
until_10 = Stream.iterate(1, &(&1 + 1))
  |> Stream.take_while(&(&1 <= 10))
  |> Enum.to_list()
IO.inspect(until_10, label: "10까지")

# drop_while - 조건 만족하는 동안 건너뛰기
from_5 = 1..10
  |> Stream.drop_while(&(&1 < 5))
  |> Enum.to_list()
IO.inspect(from_5, label: "5부터")

# chunk_every - 청크 분할 (지연)
chunks = 1..10
  |> Stream.chunk_every(3)
  |> Enum.to_list()
IO.inspect(chunks, label: "3개씩 청크")

# with_index - 인덱스 추가
indexed = ["a", "b", "c"]
  |> Stream.with_index()
  |> Enum.to_list()
IO.inspect(indexed, label: "인덱스")

# -------------------------------------------
# 실용적 예제
# -------------------------------------------

IO.puts("\n=== 실용적 예제 ===")

# 1. 큰 파일 읽기 시뮬레이션
defmodule FileSimulator do
  def read_lines do
    Stream.iterate(1, &(&1 + 1))
    |> Stream.map(&"Line #{&1}: Some content here")
    |> Stream.take(1000)  # 1000줄
  end

  def process_file do
    read_lines()
    |> Stream.filter(&String.contains?(&1, "5"))  # 5 포함된 줄만
    |> Stream.map(&String.upcase/1)
    |> Enum.take(5)  # 처음 5개만
  end
end

IO.inspect(FileSimulator.process_file(), label: "파일 처리")

# 2. 무한 ID 생성기
defmodule IdGenerator do
  def ids(prefix \\ "ID") do
    Stream.iterate(1, &(&1 + 1))
    |> Stream.map(&"#{prefix}-#{String.pad_leading(to_string(&1), 6, "0")}")
  end
end

IO.inspect(IdGenerator.ids() |> Enum.take(5), label: "ID 5개")
IO.inspect(IdGenerator.ids("USER") |> Enum.take(3), label: "USER ID")

# 3. 페이지네이션 시뮬레이션
defmodule Paginator do
  def pages(items, page_size) do
    items
    |> Stream.chunk_every(page_size)
    |> Stream.with_index(1)  # 페이지 번호 (1부터)
    |> Stream.map(fn {items, page} ->
      %{page: page, items: items, count: length(items)}
    end)
  end
end

all_items = Enum.to_list(1..25)
pages = Paginator.pages(all_items, 10) |> Enum.to_list()
IO.inspect(pages, label: "페이지네이션")

# -------------------------------------------
# Stream.resource - 리소스 관리
# -------------------------------------------

IO.puts("\n=== Stream.resource ===")

# 파일이나 DB 연결 같은 리소스를 안전하게 다룸
defmodule Counter do
  def count_stream(max) do
    Stream.resource(
      # 초기화: 리소스 열기
      fn ->
        IO.puts("  [Counter 시작]")
        1
      end,
      # 다음 값 생성
      fn
        n when n > max -> {:halt, n}
        n -> {[n], n + 1}
      end,
      # 정리: 리소스 닫기
      fn n ->
        IO.puts("  [Counter 종료, 마지막: #{n}]")
      end
    )
  end
end

result = Counter.count_stream(5) |> Enum.to_list()
IO.inspect(result, label: "카운터 결과")

# -------------------------------------------
# concat과 flat_map
# -------------------------------------------

IO.puts("\n=== concat과 flat_map ===")

# concat - 여러 스트림/리스트 연결
combined = Stream.concat([1..3, 4..6, 7..9]) |> Enum.to_list()
IO.inspect(combined, label: "concat")

# flat_map - 각 요소에서 스트림 생성 후 병합
expanded = 1..3
  |> Stream.flat_map(fn x -> [x, x * 10, x * 100] end)
  |> Enum.to_list()
IO.inspect(expanded, label: "flat_map")

# -------------------------------------------
# 성능 비교
# -------------------------------------------

IO.puts("\n=== 성능 비교 ===")

# 큰 데이터에서 Stream의 장점
large_range = 1..1_000_000

# Stream: 필요한 만큼만 계산
{stream_time, stream_result} = :timer.tc(fn ->
  large_range
  |> Stream.map(&(&1 * 2))
  |> Stream.filter(&(rem(&1, 1000) == 0))
  |> Enum.take(10)
end)

IO.puts("Stream: #{stream_time}μs, 결과: #{inspect(stream_result)}")

# Enum: 전체 계산 (비교용 - 주석 처리)
# 실제로 실행하면 오래 걸림
# {enum_time, enum_result} = :timer.tc(fn ->
#   large_range
#   |> Enum.map(&(&1 * 2))
#   |> Enum.filter(&(rem(&1, 1000) == 0))
#   |> Enum.take(10)
# end)

# ============================================
# 실습: 로그 분석기
# ============================================

# TODO: 무한 로그 스트림을 생성하고 분석하세요
# 1. 타임스탬프와 레벨(info/warn/error)을 가진 로그 스트림 생성
# 2. error 로그만 필터링
# 3. 처음 5개의 error 로그 출력
