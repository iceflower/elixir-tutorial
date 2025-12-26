# ===========================================
# 03. Enum 모듈 - 즉시 평가 (Eager Evaluation)
# ===========================================

# Enum은 컬렉션을 다루는 핵심 모듈입니다.
# 모든 연산은 즉시 실행되어 결과를 반환합니다.

# -------------------------------------------
# 기본 순회
# -------------------------------------------

IO.puts("=== 기본 순회 ===")

list = [1, 2, 3, 4, 5]

# each - 부수 효과용 (반환값 :ok)
Enum.each(list, fn x -> IO.write("#{x} ") end)
IO.puts("")

# map - 각 요소 변환
squares = Enum.map(list, fn x -> x * x end)
IO.inspect(squares, label: "제곱")

# 축약 문법
squares2 = Enum.map(list, &(&1 * &1))
IO.inspect(squares2, label: "제곱 (축약)")

# -------------------------------------------
# 필터링
# -------------------------------------------

IO.puts("\n=== 필터링 ===")

numbers = 1..20 |> Enum.to_list()

# filter - 조건에 맞는 것만
evens = Enum.filter(numbers, fn x -> rem(x, 2) == 0 end)
IO.inspect(evens, label: "짝수")

# reject - 조건에 맞지 않는 것만
odds = Enum.reject(numbers, fn x -> rem(x, 2) == 0 end)
IO.inspect(odds, label: "홀수")

# take - 앞에서 n개
IO.inspect(Enum.take(numbers, 5), label: "앞 5개")

# take_while - 조건 만족하는 동안
IO.inspect(Enum.take_while(numbers, &(&1 < 5)), label: "5 미만")

# drop - 앞에서 n개 제외
IO.inspect(Enum.drop(numbers, 15), label: "15개 제외")

# slice - 범위 추출
IO.inspect(Enum.slice(numbers, 5..10), label: "인덱스 5~10")

# -------------------------------------------
# 검색
# -------------------------------------------

IO.puts("\n=== 검색 ===")

users = [
  %{name: "Kim", age: 25},
  %{name: "Lee", age: 30},
  %{name: "Park", age: 35}
]

# find - 첫 번째 매칭
found = Enum.find(users, fn u -> u.age > 28 end)
IO.inspect(found, label: "28세 초과 첫 번째")

# find_index - 인덱스 반환
index = Enum.find_index(users, fn u -> u.name == "Lee" end)
IO.puts("Lee의 인덱스: #{index}")

# any? - 하나라도 만족하면 true
IO.puts("30세 이상 있나? #{Enum.any?(users, &(&1.age >= 30))}")

# all? - 모두 만족해야 true
IO.puts("모두 20세 이상? #{Enum.all?(users, &(&1.age >= 20))}")

# member? - 포함 여부
IO.puts("3 포함? #{Enum.member?([1, 2, 3], 3)}")

# -------------------------------------------
# 정렬
# -------------------------------------------

IO.puts("\n=== 정렬 ===")

numbers = [3, 1, 4, 1, 5, 9, 2, 6]

IO.inspect(Enum.sort(numbers), label: "오름차순")
IO.inspect(Enum.sort(numbers, :desc), label: "내림차순")

# 커스텀 정렬
sorted_users = Enum.sort_by(users, & &1.age, :desc)
IO.inspect(sorted_users, label: "나이순 내림차순")

# min/max
IO.puts("최소: #{Enum.min(numbers)}")
IO.puts("최대: #{Enum.max(numbers)}")
IO.inspect(Enum.min_by(users, & &1.age), label: "최연소")
IO.inspect(Enum.max_by(users, & &1.age), label: "최연장")

# -------------------------------------------
# 집계 (Aggregation)
# -------------------------------------------

IO.puts("\n=== 집계 ===")

numbers = 1..10

IO.puts("합계: #{Enum.sum(numbers)}")
IO.puts("개수: #{Enum.count(numbers)}")
IO.puts("짝수 개수: #{Enum.count(numbers, &(rem(&1, 2) == 0))}")

# product - 곱셈 (Elixir 1.12+)
IO.puts("곱: #{Enum.product(1..5)}")

# frequencies - 빈도수
items = [:a, :b, :a, :c, :a, :b]
IO.inspect(Enum.frequencies(items), label: "빈도")

# group_by - 그룹화
grouped = Enum.group_by(users, fn u ->
  if u.age >= 30, do: :senior, else: :junior
end)
IO.inspect(grouped, label: "그룹")

# -------------------------------------------
# reduce - 가장 강력한 함수
# -------------------------------------------

IO.puts("\n=== reduce ===")

numbers = [1, 2, 3, 4, 5]

# 합계 (reduce로)
sum = Enum.reduce(numbers, 0, fn x, acc -> x + acc end)
IO.puts("합계: #{sum}")

# 축약 문법
sum2 = Enum.reduce(numbers, 0, &(&1 + &2))
IO.puts("합계 (축약): #{sum2}")

# 최대값 찾기
max = Enum.reduce(numbers, fn x, acc ->
  if x > acc, do: x, else: acc
end)
IO.puts("최대: #{max}")

# 맵으로 변환
map = Enum.reduce(["a", "b", "c"], %{}, fn x, acc ->
  Map.put(acc, x, String.upcase(x))
end)
IO.inspect(map, label: "맵으로")

# 실전 예제: 쇼핑 카트 총액
cart = [
  %{name: "사과", price: 1000, qty: 3},
  %{name: "바나나", price: 2000, qty: 2},
  %{name: "오렌지", price: 1500, qty: 4}
]

total = Enum.reduce(cart, 0, fn item, acc ->
  acc + item.price * item.qty
end)
IO.puts("총액: #{total}원")

# -------------------------------------------
# 변환
# -------------------------------------------

IO.puts("\n=== 변환 ===")

# flat_map - map + flatten
nested = [[1, 2], [3, 4], [5, 6]]
flat = Enum.flat_map(nested, fn x -> x end)
IO.inspect(flat, label: "flat_map")

# 각 요소를 복제
duplicated = Enum.flat_map([1, 2, 3], fn x -> [x, x] end)
IO.inspect(duplicated, label: "복제")

# chunk_every - 청크로 분할
chunks = Enum.chunk_every(1..10, 3)
IO.inspect(chunks, label: "3개씩")

# zip - 두 컬렉션 결합
names = ["Kim", "Lee", "Park"]
ages = [25, 30, 35]
zipped = Enum.zip(names, ages)
IO.inspect(zipped, label: "zip")

# uniq - 중복 제거
IO.inspect(Enum.uniq([1, 2, 1, 3, 2, 4]), label: "중복 제거")

# reverse
IO.inspect(Enum.reverse([1, 2, 3]), label: "역순")

# -------------------------------------------
# 파이프 체이닝
# -------------------------------------------

IO.puts("\n=== 파이프 체이닝 ===")

# 1부터 100까지 중 3의 배수를 제곱하고 합계
result = 1..100
  |> Enum.filter(&(rem(&1, 3) == 0))
  |> Enum.map(&(&1 * &1))
  |> Enum.sum()

IO.puts("3의 배수 제곱 합: #{result}")

# 문자열 처리
words = "  hello   world   elixir  "
processed = words
  |> String.trim()
  |> String.split(~r/\s+/)
  |> Enum.map(&String.capitalize/1)
  |> Enum.join(" ")

IO.puts("처리된 문자열: #{processed}")

# ============================================
# 실습: 데이터 분석
# ============================================

# 주어진 판매 데이터를 분석하세요
sales = [
  %{product: "A", region: "서울", amount: 1000},
  %{product: "B", region: "부산", amount: 1500},
  %{product: "A", region: "서울", amount: 2000},
  %{product: "C", region: "대구", amount: 800},
  %{product: "B", region: "서울", amount: 1200},
  %{product: "A", region: "부산", amount: 900}
]

# TODO: 지역별 총 판매액 계산
# TODO: 제품별 평균 판매액 계산
# TODO: 서울 지역에서 가장 많이 팔린 제품 찾기
