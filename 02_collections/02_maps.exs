# ===========================================
# 02. 맵 (Maps)
# ===========================================

# -------------------------------------------
# 기본 맵
# -------------------------------------------

IO.puts("=== 기본 맵 ===")

# 맵 생성 - 다양한 키 타입 가능
map1 = %{:name => "Kim", :age => 25}
map2 = %{"name" => "Lee", "age" => 30}  # 문자열 키
map3 = %{1 => "one", 2 => "two"}        # 숫자 키

IO.inspect(map1, label: "원자 키")
IO.inspect(map2, label: "문자열 키")
IO.inspect(map3, label: "숫자 키")

# 원자 키 단축 문법
user = %{name: "Kim", age: 25, city: "Seoul"}
IO.inspect(user, label: "단축 문법")

# 값 접근
IO.puts("\n=== 값 접근 ===")
IO.puts("user[:name] = #{user[:name]}")           # 키가 없으면 nil
IO.puts("user.name = #{user.name}")               # 원자 키만 가능, 없으면 에러
IO.puts("Map.get = #{Map.get(user, :name)}")
IO.puts("기본값 = #{Map.get(user, :email, "없음")}")

# Map.fetch - {:ok, value} 또는 :error 반환
case Map.fetch(user, :name) do
  {:ok, name} -> IO.puts("찾음: #{name}")
  :error -> IO.puts("없음")
end

# -------------------------------------------
# 맵 업데이트
# -------------------------------------------

IO.puts("\n=== 맵 업데이트 ===")

user = %{name: "Kim", age: 25}

# 기존 키 업데이트 (키가 반드시 존재해야 함)
updated = %{user | age: 26}
IO.inspect(updated, label: "나이 업데이트")

# 키 추가/업데이트 (Map.put)
with_email = Map.put(user, :email, "kim@test.com")
IO.inspect(with_email, label: "이메일 추가")

# 여러 키 한번에 추가/업데이트
merged = Map.merge(user, %{email: "kim@test.com", city: "Seoul"})
IO.inspect(merged, label: "병합")

# 키 삭제
without_age = Map.delete(user, :age)
IO.inspect(without_age, label: "나이 삭제")

# 키 이름 변경
renamed = user
  |> Map.put(:username, user.name)
  |> Map.delete(:name)
IO.inspect(renamed, label: "이름 변경")

# -------------------------------------------
# 맵 함수들
# -------------------------------------------

IO.puts("\n=== Map 모듈 함수 ===")

user = %{name: "Kim", age: 25, city: "Seoul"}

IO.puts("키 존재? #{Map.has_key?(user, :name)}")
IO.inspect(Map.keys(user), label: "모든 키")
IO.inspect(Map.values(user), label: "모든 값")
IO.inspect(Map.to_list(user), label: "리스트로")

# take - 특정 키만 추출
IO.inspect(Map.take(user, [:name, :age]), label: "take")

# drop - 특정 키 제외
IO.inspect(Map.drop(user, [:city]), label: "drop")

# update - 값 변환
incremented = Map.update(user, :age, 0, &(&1 + 1))
IO.inspect(incremented, label: "나이 증가")

# update! - 키가 반드시 있어야 함
doubled = Map.update!(user, :age, &(&1 * 2))
IO.inspect(doubled, label: "나이 2배")

# -------------------------------------------
# 패턴 매칭
# -------------------------------------------

IO.puts("\n=== 패턴 매칭 ===")

user = %{name: "Kim", age: 25, role: :admin}

# 일부 키만 매칭 (나머지 무시)
%{name: name} = user
IO.puts("이름: #{name}")

# 여러 키 매칭
%{name: n, age: a} = user
IO.puts("#{n}님은 #{a}살")

# 조건부 매칭
case user do
  %{role: :admin} -> IO.puts("관리자입니다")
  %{role: :user} -> IO.puts("일반 사용자입니다")
  _ -> IO.puts("알 수 없는 역할")
end

# 함수 인자에서 패턴 매칭
defmodule UserHandler do
  def greet(%{name: name, role: :admin}) do
    "안녕하세요, 관리자 #{name}님!"
  end

  def greet(%{name: name}) do
    "안녕하세요, #{name}님!"
  end

  # 맵 전체와 특정 키 둘 다 받기
  def update_age(%{age: age} = user, delta) do
    %{user | age: age + delta}
  end
end

IO.puts(UserHandler.greet(user))
IO.inspect(UserHandler.update_age(user, 5), label: "5년 후")

# -------------------------------------------
# 중첩 맵 다루기
# -------------------------------------------

IO.puts("\n=== 중첩 맵 ===")

data = %{
  user: %{
    name: "Kim",
    address: %{
      city: "Seoul",
      zip: "12345"
    }
  },
  settings: %{
    theme: "dark",
    notifications: true
  }
}

# 중첩 접근
IO.puts("도시: #{data.user.address.city}")

# get_in - 안전한 중첩 접근
IO.puts("zip: #{get_in(data, [:user, :address, :zip])}")
IO.puts("없는 경로: #{inspect(get_in(data, [:user, :phone]))}")

# put_in - 중첩 업데이트
updated = put_in(data, [:user, :address, :city], "Busan")
IO.puts("변경된 도시: #{updated.user.address.city}")

# update_in - 중첩 값 변환
updated2 = update_in(data, [:user, :name], &String.upcase/1)
IO.puts("대문자 이름: #{updated2.user.name}")

# -------------------------------------------
# MapSet (집합)
# -------------------------------------------

IO.puts("\n=== MapSet ===")

set1 = MapSet.new([1, 2, 3, 2, 1])  # 중복 제거
set2 = MapSet.new([2, 3, 4])

IO.inspect(set1, label: "set1")
IO.puts("포함? #{MapSet.member?(set1, 2)}")
IO.puts("크기: #{MapSet.size(set1)}")

IO.inspect(MapSet.union(set1, set2), label: "합집합")
IO.inspect(MapSet.intersection(set1, set2), label: "교집합")
IO.inspect(MapSet.difference(set1, set2), label: "차집합")

# ============================================
# 실습: 사용자 프로필 관리
# ============================================

# TODO: 다음 기능을 가진 Profile 모듈 만들기
# - new(name, email) - 새 프로필 생성
# - add_skill(profile, skill) - 스킬 추가 (skills는 MapSet)
# - has_skill?(profile, skill) - 스킬 보유 확인
# - update_email(profile, email) - 이메일 업데이트
